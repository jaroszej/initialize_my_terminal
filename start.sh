#!/bin/bash

set -e

stagename="start"

source_helper() {
    local script_dir="$(dirname "$0")"

    local helper_file="$script_dir/helper.sh"
    if [ -f "$helper_file" ]; then
        source "$helper_file"
    else
        wrapper_frame "$stagename" "!! Error: Helper file not found at $helper_file"
        exit 1
    fi

}

run_stage() {
    local stage_script="stage_$1.sh"
    local stage_number=$1
    local retry=$2
    local autoyes=$3
    echo "run_stage()"

    if [ ! -f "$stage_script" ]; then
        wrapper_frame "$stagename" "!! Error: Stage $stage_number script ($stage_script) not found."
        exit 1
    elif [ ! -x "$stage_script" ]; then
        wrapper_frame "$stagename" "!! Error: Stage $stage_number script ($stage_script) is not executable."
        exit 1
    fi

    wrapper_frame "$stagename" "--> Starting Stage $stage_number..."

    if ! ./"$stage_script" ${retry:+-r} ${autoyes:+-y}; then
        echo ""
        wrapper_frame "$stagename" "!! Error: Stage $stage_number failed."
        echo "Check the logs above for specific errors."
        echo ""
        echo "Refer to the error handler in $stage_script for resolution steps."
        echo "===================================================================================="
        echo "Exiting initialize_my_terminal. Please resolve the issue and re-run."
        exit 1
    else
        echo "No args found. Continuing..."
    fi
}

while [ $# -gt 0 ]; do # parse command line args to pass to stages
    case "$1" in
        -r|--retry)
            RETRY=true
            shift
            ;;
        -y|--yes)
            YES=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -h, --help    Show this help message"
            echo "  -r, --retry   Retry installations if failed"
            echo "  -y, --yes     Auto accept all confirmation prompts"
            exit 0
            ;;
        *)
            echo "!! Error: Unknown option: $1"
            echo "Use -h or --help for usage."
            exit 1
            ;;
    esac
done

if source_helper; then
    if source_files; then
        warn_enable_scroll

        # Run stages
        for i in {1..3}; do
            if check_stage_temp_file "$i"; then
                wrapper_frame "$stagename" "INFO: Stage $i temp file detected. Skipping stage $i."
            else
                num=$(("$i" - 1))
                wrapper_frame "$stagename" " Progress: Stage $num/3"

                if run_stage "$i" "$RETRY" "$YES"; then
                    make_stage_temp_file "$i"
                else
                    wrapper_frame "$stagename" "!! Error: Unexpected failure. You may need to remove temp files in /tmp/initialize_my_terminal/ to restart from scratch."
                    exit 1
                fi
            fi
        done

        clear_scroll_temp_file
        clear_nvm_installed_temp_file
        clear_zsh_setup_temp_file
        clear_stage_temp_files

        echo ""
        wrapper_frame "$stagename" " Stage 3/3"
        echo ""
        echo "OK: All stages completed successfully! Your environment is now set up."
        echo "Restart your terminal."
        echo "===================================================================================="
        echo ""

    else
        wrapper_frame "$stagename" "!! Error: Failed to source needed files."
        exit 1
    fi
else
    wrapper_frame "$stagename" "!! Error: Failed to source helper file."
    exit 1
fi
