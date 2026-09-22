test_repo=

test_run() {
    test_repo="$( test_create_repo )"
    test_create_tags "$test_repo" 1 2 2.1
    test_run_release_script "$test_repo" -p '' major
    test_validate_tags "$test_repo" 1,2,2.1,3.0.0
}
