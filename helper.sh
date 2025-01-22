#!/bin/bash

# Function to simulate try-catch
try_catch() {
    local try_command=$1
    local catch_command=$2

    if output=$($try_command 2>&1); then
        echo "✅ Success: $try_command"
    else
        local exit_code=$?
        echo "❌ Error: $try_command failed with exit code $exit_code"
        echo "Output: $output"
        $catch_command
        return $exit_code
    fi
}

# Function to simulate try-catch-finally
try_catch_finally() {
    local try_command=$1
    local catch_command=$2
    local finally_command=$3

    if output=$($try_command 2>&1); then
        echo "✅ Success: $try_command"
    else
        local exit_code=$?
        echo "❌ Error: $try_command failed with exit code $exit_code"
        echo "Command output: $output"
        $catch_command
        return $exit_code
    fi

    $finally_command
}
