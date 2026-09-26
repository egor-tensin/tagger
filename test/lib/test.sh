# Copyright (c) 2026 Egor Tensin <egor@tensin.name>
# This file is part of the "Tagger" project.
# For details, see https://github.com/egor-tensin/tagger
# Distributed under the MIT License.

test_should_fail=

test_create_repo() {
    local repo
    repo="$( mktemp -d )"

    log "Creating repository: $repo"
    echo "$repo"

    git -C "$repo" init -q
    git -C "$repo" config user.name 'Test user'
    git -C "$repo" config user.email 'test@example.com'
}

test_remove_repo() {
    local repo
    for repo; do
        log "Removing repository: $repo"
        rm -rf -- "$repo"
    done
}

test_cleanup_default() {
    [ -n "${test_repo:+x}" ] && test_remove_repo "$test_repo"
}

test_make_commit() {
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
}

_validate_tag_kind() {
    if [ "$#" -ne 1 ]; then
        log "usage: ${FUNCNAME[0]} {lightweight|annotated}"
        return 1
    fi

    case "$1" in
        lightweight|annotated)
            echo "$1"
            ;;
        *)
            log "${FUNCNAME[1]}: invalid tag type: $kind"
            return 1
            ;;
    esac
}

test_get_tags() {
    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        log "usage: ${FUNCNAME[0]} REPO_DIR [{lightweight|annotated}]"
        return 1
    fi

    local repo="$1"

    local kind=
    [ "$#" -gt 1 ] && kind="$( _validate_tag_kind "$2" )"

    log "Reading tags in $repo..."

    local objecttype
    local refname

    git -C "$repo" for-each-ref refs/tags/ \
        '--format=%(objecttype)%0a%(refname:short)' |
    while IFS= read -r objecttype; do
        IFS= read -r refname

        case "$kind-$objecttype" in
            lightweight-commit|annotated-tag|-*)
                echo "$refname"
                ;;
        esac
    done | sort -V
}

test_get_tag_message() {
    if [ "$#" -ne 2 ]; then
        log "usage: ${FUNCNAME[0]} REPO_DIR TAG"
        return 1
    fi

    local repo="$1"
    local tag="$2"

    git -C "$repo" for-each-ref "refs/tags/$tag" '--format=%(contents)'
}

test_get_tag_commit() {
    if [ "$#" -ne 2 ]; then
        log "usage: ${FUNCNAME[0]} REPO_DIR TAG"
        return 1
    fi

    local repo="$1"
    local tag="$2"

    git -C "$repo" rev-list -n 1 "$tag" --
}

test_create_tags() {
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
        git -C "$repo" tag -a -m "$tag" "$tag"
    done
}

test_validate_tags() {
    if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
        log "usage: ${FUNCNAME[0]} REPO_DIR EXPECTED_TAGS [{lightweight,annotated}]"
        return 1
    fi

    local repo="$1"
    local expected="$2"

    local kind=
    [ "$#" -gt 2 ] && kind="$( _validate_tag_kind "$3" )"

    local actual
    actual="$( test_get_tags "$repo" $kind | paste -s -d ',' )"

    log "Validating tags in $repo..."

    [ "$actual" == "$expected" ] && return 0

    fail "Unexpected tags"
    fail_details "Expected tags: $expected"
    fail_details "Actual tags:   $actual"
    return 1
}

test_validate_tag_message() {
    if [ "$#" -lt 3 ]; then
        log "usage: ${FUNCNAME[0]} REPO_DIR TAG EXPECTED_MSG"
        return 1
    fi

    local repo="$1"
    local tag="$2"
    local expected="$3"

    log "Validating tag message for tag: $tag"

    local actual
    actual="$( test_get_tag_message "$repo" "$tag" )"

    [ "$actual" == "$expected" ] && return 0

    fail "Unexpected message for tag $tag:"
    fail_details "Expected: $expected"
    fail_details "Actual: $actual"
    return 1
}

test_validate_tags_same_target() {
    if [ "$#" -lt 3 ]; then
        log "usage: ${FUNCNAME[0]} REPO_DIR TAG1 TAG2 [TAG...]"
        return 1
    fi

    local repo="$1"
    shift
    local tgt=

    local tag
    for tag; do
        log "Validating tag target for tag: $tag"

        local output
        output="$( test_get_tag_commit "$repo" "$tag" )"

        if [ -z "$tgt" ]; then
            tgt="$output"
            continue
        fi

        if [ "$tgt" != "$output" ]; then
            fail "Tag '$tag' doesn't point to the expected revision"
            fail_details "Expected: $tgt"
            fail_details "Actual: $output"
            return 1
        fi
    done
}

test_run_release_script() {
    if [ "$#" -lt 1 ]; then
        log "usage: ${FUNCNAME[0]} REPO_DIR [ARG...]"
        return 1
    fi

    local repo="$1"
    shift

    log "Running release script..."
    "$script_dir/../src/release.py" "$@" "$repo"
}
