repo=
test_should_fail=Yes

run_test() {
    repo="$( create_temp_repo )"
    create_simple_tags "$repo" v1 test_tag v2
    run_release_script "$repo" --strict patch
    validate_tags "$repo" test_tag,v1,v2,v2.0.1
}
