test_repo=

test_run() {
    test_repo="$( test_create_repo )"

    test_create_tags "$test_repo" v1
    test_make_commit "$test_repo"
    test_run_release_script "$test_repo" minor
    test_make_commit "$test_repo"
    test_run_release_script "$test_repo" patch

    test_validate_tags "$test_repo" v1,v1.1.0,v1.1.1 annotated

    test_make_commit "$test_repo"
    test_run_release_script "$test_repo" -r patch

    test_validate_tags "$test_repo" v1,v1.1,v1.1.0,v1.1.1,v1.1.2 annotated

    test_validate_tags_same_target "$test_repo" v1 v1.1 v1.1.2
    test_validate_tag_message "$test_repo" v1 v1
    test_validate_tag_message "$test_repo" v1.1 v1.1
}
