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

source "$script_dir/lib/log.sh"

run_test_file() {
    local test_file
    for test_file; do
        source "$script_dir/lib/test.sh"
        source "$script_dir/$test_file"

        log_test_start "$test_file"

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
        local ret="$?"
        set -e

        log_test_finish "$test_file" "$ret"
    done
}

main() {
    local -a test_files=()
    local test_file

    find "$script_dir" \
        -mindepth 1 \
        -maxdepth 1 \
        -type f \
        -regex '.*/tst-.*\.sh$' \
        -regextype posix-basic \
        -printf '%P\0' \
        | sort -z \
        | \
    while IFS= read -d '' -r test_file; do
        test_files+=("$test_file")
    done

    run_test_file ${test_files[@]+"${test_files[@]}"}
    log_tests_summary
}

main
