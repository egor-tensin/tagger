repo=

run_test() {
    repo="$( create_temp_repo )"
    create_simple_tags "$repo" 1 2 2.1
    run_release_script "$repo" -p '' major
    validate_tags "$repo" 1,2,2.1,3.0.0
}
