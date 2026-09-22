test_repo=
test_should_fail=Yes

test_run() {
    test_repo="$( test_create_repo )"
    test_create_tags "$test_repo" v1 vinvalid v2
    test_run_release_script "$test_repo" --strict patch
    test_validate_tags "$test_repo" vinvalid,v1,v2,v2.0.1
}
