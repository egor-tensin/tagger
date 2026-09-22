test_repo=

test_run() {
    test_repo="$( test_create_repo )"
    test_make_commit "$test_repo"
    test_run_release_script "$test_repo" patch
    test_validate_tags "$test_repo" v0.0.1
}
