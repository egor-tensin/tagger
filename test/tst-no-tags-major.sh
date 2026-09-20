repo=

run_test() {
    repo="$( create_temp_repo )"
    create_random_commit "$repo"
    run_release_script "$repo" major
    validate_tags "$repo" v1.0.0
}
