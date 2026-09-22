test_repo=

test_run() {
    test_repo="$( test_create_repo )"
    test_make_commit "$test_repo"
    test_run_release_script "$test_repo" major
    test_validate_tags "$test_repo" v1.0.0
}
