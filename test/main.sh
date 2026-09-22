#!/usr/bin/env bash

# Copyright (c) 2026 Egor Tensin <egor@tensin.name>
# This file is part of the "Tagger" project.
# For details, see https://github.com/egor-tensin/tagger
# Distributed under the MIT License.

set -o errexit -o nounset -o pipefail
shopt -s inherit_errexit lastpipe

script_dir="$( dirname -- "${BASH_SOURCE[0]}" )"
script_dir="$( cd -- "$script_dir" && pwd )"
readonly script_dir

declare -a failed_tests=()

run_test_file() {
    local test_file
    for test_file; do
        echo
        echo ======================================================================
        echo "Running test: $test_file"
        echo ======================================================================

        source "$script_dir/lib/common.sh"
        source "$script_dir/$test_file"

        echo "Should fail? ${test_should_fail:-No}"

        set +e
        (
            set -o errexit -o nounset -o pipefail
            shopt -s inherit_errexit lastpipe

            if [ "$( type -t test_cleanup )" == function ]; then
                trap test_cleanup EXIT
            else
                trap test_cleanup_default EXIT
            fi

            test_run
        )
        local ec="$?"
        set -e

        if [ "$ec" -eq 0 ] || [ -n "${test_should_fail:+Yes}" ]; then
            echo ----------------------------------------------------------------------
            echo "OK: $test_file"
            echo ----------------------------------------------------------------------
        else
            echo ----------------------------------------------------------------------
            echo "FAIL: $test_file"
            echo ----------------------------------------------------------------------
            failed_tests+=("$test_file")
        fi
    done
}

main() {
    local -a test_files=()

    find "$script_dir" \
        -mindepth 1 \
        -maxdepth 1 \
        -type f \
        -regex '.*/tst-.*\.sh$' \
        -regextype posix-basic \
        -printf '%P\0' |
        sort -z |
    while IFS= read -d '' -r test_file; do
        test_files+=("$test_file")
    done

    run_test_file ${test_files[@]+"${test_files[@]}"}

    if [ "${#failed_tests[@]}" -gt 0 ]; then
        echo
        echo ======================================================================
        echo "FAILED TESTS:" ${failed_tests[@]+"${failed_tests[@]}"}
        echo ======================================================================
        return 1
    fi
}

main
