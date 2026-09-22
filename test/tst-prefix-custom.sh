test_repo=

test_run() {
    test_repo="$( test_create_repo )"
    test_create_tags "$test_repo" V1 V2 V2.1
    test_run_release_script "$test_repo" -p V major
    test_validate_tags "$test_repo" V1,V2,V2.1,V3.0.0
}
