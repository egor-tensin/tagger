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
export script_dir

run_test_file() (
    set -o errexit -o nounset -o pipefail
    shopt -s inherit_errexit lastpipe

    if [ "$#" -ne 1 ]; then
        echo "usage: ${FUNCNAME[0]} TEST_FILE" >&2
        return 1
    fi
    local file="$1"

    source "$script_dir/lib/common.sh"

    echo
    echo ======================================================================
    echo "Running test: $file"
    echo ======================================================================

    source "$script_dir/$file"

    if [ "$( type -t cleanup_test )" == function ]; then
        trap cleanup_test EXIT
    else
        trap default_cleanup_test EXIT
    fi

    if run_test; then
        echo ----------------------------------------------------------------------
        echo "OK: $file"
        echo ----------------------------------------------------------------------
    else
        echo ----------------------------------------------------------------------
        echo "FAIL: $file"
        echo ----------------------------------------------------------------------
        return 1
    fi
)

main() {
    local test_file

    find "$script_dir" \
        -mindepth 1 \
        -maxdepth 1 \
        -type f \
        -regex '.*/tst-.*\.sh$' \
        -regextype posix-basic \
        -printf '%P\0' |
    while IFS= read -d '' -r test_file; do
        run_test_file "$test_file"
    done
}

main
