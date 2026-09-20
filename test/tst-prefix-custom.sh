repo=

run_test() {
    repo="$( create_temp_repo )"
    create_simple_tags "$repo" V1 V2 V2.1
    run_release_script "$repo" -p V major
    validate_tags "$repo" V1,V2,V2.1,V3.0.0
}
