test_repo=
test_should_fail=Yes

test_run() {
    test_repo="$( test_create_repo )"
    test_create_tags "$test_repo" v1 test_tag v2
    test_run_release_script "$test_repo" --strict patch
}
