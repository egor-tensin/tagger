test_repo=

test_run() {
    test_repo="$( test_create_repo )"
    test_create_tags "$test_repo" v1.0.0

    test_run_release_script "$test_repo" --lightweight major
    test_run_release_script "$test_repo" minor 
    test_run_release_script "$test_repo" --l patch

    test_validate_tags "$test_repo" v1.0.0,v2.0.0,v2.1.0,v2.1.1
    test_validate_tags "$test_repo" v1.0.0,v2.1.0 annotated
    test_validate_tags "$test_repo" v2.0.0,v2.1.1 lightweight
}
