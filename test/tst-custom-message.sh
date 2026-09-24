test_repo=

test_run() {
    test_repo="$( test_create_repo )"
    test_create_tags "$test_repo" v1.0.0

    test_run_release_script "$test_repo" -l -m "shouldn't be visible" major
    test_run_release_script "$test_repo" -m "minor release" minor
    test_run_release_script "$test_repo" -p 'debian/' --message "Debian release {}" patch

    test_validate_tags "$test_repo" debian/0.0.1,v1.0.0,v2.0.0,v2.1.0
    test_validate_tags "$test_repo" debian/0.0.1,v1.0.0,v2.1.0 annotated
    test_validate_tags "$test_repo" v2.0.0 lightweight

    test_validate_tag_message "$test_repo" v2.1.0 'minor release'
    test_validate_tag_message "$test_repo" debian/0.0.1 'Debian release debian/0.0.1'
}
