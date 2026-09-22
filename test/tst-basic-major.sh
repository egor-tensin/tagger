test_repo=

test_run() {
    test_repo="$( test_create_repo )"
    test_create_tags "$test_repo" v1
    test_run_release_script "$test_repo" major
    test_validate_tags "$test_repo" v1,v2.0.0
}
