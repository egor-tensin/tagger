repo=

run_test() {
    repo="$( create_temp_repo )"
    create_simple_tags "$repo" v1
    run_release_script "$repo" major
    validate_tags "$repo" v1,v2.0.0
}
