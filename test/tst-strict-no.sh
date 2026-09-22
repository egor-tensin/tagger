test_repo=

test_run() {
    test_repo="$( test_create_repo )"
    test_create_tags "$test_repo" v1 test_tag v2
    test_run_release_script "$test_repo" patch
    test_validate_tags "$test_repo" test_tag,v1,v2,v2.0.1
}
