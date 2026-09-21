repo=
test_should_fail=Yes

run_test() {
    repo="$( create_temp_repo )"
    create_simple_tags "$repo" v1 vinvalid v2
    run_release_script "$repo" --strict patch
    validate_tags "$repo" vinvalid,v1,v2,v2.0.1
}
