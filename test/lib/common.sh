# Copyright (c) 2026 Egor Tensin <egor@tensin.name>
# This file is part of the "Tagger" project.
# For details, see https://github.com/egor-tensin/tagger
# Distributed under the MIT License.

log() {
    local msg
    for msg; do
        echo "$msg" >&2
    done
}

fail() {
    local msg
    for msg; do
        log "FAIL: $msg"
    done
}

fail_details() {
    local msg
    for msg; do
        fail "    $msg"
    done
}

create_temp_repo() {
    local repo
    repo="$( mktemp -d )"

    log "Creating repository: $repo"
    echo "$repo"

    git -C "$repo" init -q
    git -C "$repo" config user.name 'Test user'
    git -C "$repo" config user.email 'test@example.com'

    log "... OK"
}

remove_temp_repo() {
    local repo
    for repo; do
        log "Removing repository: $repo..."
        rm -rf -- "$repo"
        log "... OK"
    done
}

default_cleanup_test() {
    [ -n "${repo:+x}" ] && remove_temp_repo "$repo"
}

create_random_commit() {
    if [ "$#" -ne 1 ]; then
        log "usage: ${FUNCNAME[0]} REPO_DIR"
        return 1
    fi

    local repo="$1"

    local file
    file="$( mktemp "--tmpdir=$repo" )"

    log "Commiting file $file in $repo..."
    touch -- "$file"
    git -C "$repo" add "$file"
    git -C "$repo" commit -q -m "$file"
    log "... OK"
}

get_tags() {
    if [ "$#" -ne 1 ]; then
        log "usage: ${FUNCNAME[0]} REPO_DIR"
        return 1
    fi

    local repo="$1"

    log "Reading tags in $repo..."
    git -C "$repo" for-each-ref '--format=%(refname)' refs/tags/ | sed -e 's/^refs\/tags\///' | sort -V
    log "... OK"
}

create_simple_tags() {
    if [ "$#" -lt 1 ]; then
        log "usage: ${FUNCNAME[0]} REPO_DIR [TAG...]"
        return 1
    fi

    local repo="$1"
    shift

    local tag
    for tag; do
        log "Creating simple tag: $tag"
        touch -- "$repo/$tag"
        git -C "$repo" add "$repo/$tag"
        git -C "$repo" commit -q -m "$tag"
        git -C "$repo" tag "$tag"
        log "... OK"
    done
}

validate_tags() {
    if [ "$#" -ne 2 ]; then
        log "usage: ${FUNCNAME[0]} REPO_DIR EXPECTED_TAGS"
        return 1
    fi

    local repo="$1"
    local expected="$2"

    local actual
    actual="$( get_tags "$repo" | paste -s -d ',' )"

    log "Validating tags in $repo..."

    if [ "$actual" == "$expected" ]; then
        log "... OK"
        return 0
    fi

    fail "Unexpected tags"
    fail_details "Expected tags: $expected"
    fail_details "Actual tags:   $actual"
    return 1
}

run_release_script() {
    if [ "$#" -lt 1 ]; then
        log "usage: ${FUNCNAME[0]} REPO_DIR [ARG...]"
        return 1
    fi

    local repo="$1"
    shift

    log "Running release script..."
    "$script_dir/../src/release.py" "$@" "$repo"
    log "... OK"
}
