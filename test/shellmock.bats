#!/usr/bin/env bats
#--------------------------------------------------------------------------------
# SPDX-Copyright: Copyright (c) Capital One Services, LLC
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#---------------------------------------------------------------------------------

#---------------------------------------------------------------------
# File: shellmock.bats
# Purpose:
#     This is a bats testing script that is used to test the features
#     of the mock framework itself.
#
#     You can run the tests via:  bats shellmock.bats
#---------------------------------------------------------------------
setup()
{
    # For testing setup the path so that install is not required.
    export PATH=../bin:$PATH
    . shellmock

}

teardown()
{
    if [ -z "$TEST_FUNCTION" ]; then
        shellmock_clean
    fi
    if [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "shellmock_expect --status 0" {

    skipIfNot status-0

    shellmock_clean
    shellmock_expect cp --status 0 --match "a b" --output "mock a b success"

    run cp a b
    [ "$status" = "0" ]
    [ "$output" = "mock a b success" ]
}

@test "shellmock_expect --status 1" {

    skipIfNot status-1

    shellmock_clean
    shellmock_expect cp --status 1 --match "a b" --output "mock a b failed"

    run cp a b
    [ "$status" = "1" ]
    [ "$output" = "mock a b failed" ]
}

@test "shellmock_expect multiple responses" {

    skipIfNot multi-resources

    shellmock_clean
    shellmock_expect cp --status 0 --match "a b" --output "mock a b success"
    shellmock_expect cp --status 1 --match "a b" --output "mock a b failed"

    run cp a b
    [ "$status" = "0" ]
    [ "$output" = "mock a b success" ]

    run cp a b
    [ "$status" = "1" ]
    [ "$output" = "mock a b failed" ]

    # not a match
    run cp a c
    [ "$status" = "99" ]


}

@test "shellmock_expect --status 0 partial-match" {

    skipIfNot partial-match

    shellmock_clean
    shellmock_expect cp --status 0 --type partial --match "a" --output "mock success"

    run cp a b
    [ "$status" = "0" ]
    [ "$output" = "mock success" ]

    run cp a c
    [ "$status" = "0" ]
    [ "$output" = "mock success" ]

}

@test "shellmock_expect failed matches" {

    skipIfNot failed-matches

    shellmock_clean
    shellmock_expect cp --status 0 --type exact --match "a b" --output "mock a b success"

    run cp a b
    [ "$status" = "0" ]
    [ "$output" = "mock a b success" ]

    run cp a c
    [ "$status" = "99" ]

    grep 'No record match found cp \*a c\*' shellmock.err

}

@test "shellmock_expect failed partial matches" {

    skipIfNot failed-partial-matches

    shellmock_clean
    shellmock_expect cp --status 0 --type partial --match "a" --output "mock success"

    run cp a b
    [ "$status" = "0" ]
    [ "$output" = "mock success" ]

    run cp a c
    [ "$status" = "0" ]
    [ "$output" = "mock success" ]

    run cp b b
    [ "$status" = "99" ]
    grep 'No record match found cp \*b b\*' shellmock.err

}

@test "shellmock_expect execute on match" {

    skipIfNot exec-on-match

    shellmock_clean
    shellmock_expect cp --status 0 --type exact  --match "a b" --exec "echo executed."

    run cp a b
    [ "$status" = "0" ]
    [ "$output" = "executed." ]
}

@test "shellmock_expect execute on partial match" {

    skipIfNot exec-on-partial

    shellmock_clean
    shellmock_expect cp --status 0 --type partial  --match "a" --exec "echo executed."

    run cp a b
    [ "$status" = "0" ]
    [ "$output" = "executed." ]

    run cp a c
    [ "$status" = "0" ]
    [ "$output" = "executed." ]
}

@test "shellmock_expect execute on match with {} substitution" {

    skipIfNot substitution

    shellmock_clean
    shellmock_expect cp --status 0 --type exact  --match "a b" --exec "echo t1 {} tn"

    run cp a b
    [ "$status" = "0" ]
    [ "$output" = "t1 a b tn" ]
}

@test "shellmock_expect source" {

    skipIfNot source

    shellmock_clean
    shellmock_expect test.bash --status 0 --type exact  --match "" --source "./test.bash"

    . tmpstubs/test.bash

    [ "$TEST_PROP" = "test-prop" ]
}

@test "shellmock_expect multiple responses outside \$BATS_TEST_DIRNAME" {

    skipIfNot outside-dirname

    shellmock_clean

    export TEST_TEMP_DIR="$BATS_TEST_DIRNAME/tempbin"
    mkdir -p "$TEST_TEMP_DIR"
    export BATS_TEST_DIRNAME=$TEST_TEMP_DIR
    export CAPTURE_FILE=$BATS_TEST_DIRNAME/shellmock.out
    export shellmock_capture_err=$BATS_TEST_DIRNAME/shellmock.err
    export PATH=$BATS_TEST_DIRNAME/tmpstubs:$PATH

    shellmock_clean
    shellmock_expect cp --status 0 --match "a b" --output "mock a b success"
    shellmock_expect cp --status 1 --match "a b" --output "mock a b failed"

    run cp a b
    [ "$status" = "0" ]
    [ "$output" = "mock a b success" ]

    run cp a b
    [ "$status" = "1" ]
    [ "$output" = "mock a b failed" ]

    # not a match
    run cp a c
    [ "$status" = "99" ]
}

@test "shellmock_clean inside directory with spaces" {

    skipIfNot clean-dir-spaces

    export TEST_TEMP_DIR="$BATS_TEST_DIRNAME/temp dir"
    mkdir -p "$TEST_TEMP_DIR"
    export BATS_TEST_DIRNAME="$TEST_TEMP_DIR"
    export CAPTURE_FILE="$BATS_TEST_DIRNAME/shellmock.out"
    export shellmock_capture_err="$BATS_TEST_DIRNAME/shellmock.err"
    export PATH="$BATS_TEST_DIRNAME/tmpstubs:$PATH"

    touch "$CAPTURE_FILE"
    touch "$shellmock_capture_err"
    mkdir -p "$BATS_TEST_DIRNAME/tmpstubs"

    shellmock_clean
    [ ! -f "$CAPTURE_FILE" ]
    [ ! -f "$shellmock_capture_err" ]
    [ ! -d "$BATS_TEST_DIRNAME/tmpstubs" ]
}

@test "shellmock_expect inside directory with spaces" {

    skipIfNot expect-dir-spaces

    shellmock_clean

    TEST_TEMP_DIR="$BATS_TEST_DIRNAME/temp dir"
    mkdir -p "$TEST_TEMP_DIR"
    export BATS_TEST_DIRNAME="$TEST_TEMP_DIR"
    export CAPTURE_FILE="$BATS_TEST_DIRNAME/shellmock.out"
    export shellmock_capture_err="$BATS_TEST_DIRNAME/shellmock.err"
    export PATH="$BATS_TEST_DIRNAME/tmpstubs:$PATH"

    shellmock_clean
    shellmock_expect cp --exec "echo executed."

    run cp
    [ "$status" = "0" ]
    [ "$output" = "executed." ]
}

@test "shellmock_verify inside directory with spaces" {

    skipIfNot verify-dir-spaces

    shellmock_clean
    shellmock_expect cp --exec "echo executed."

    run cp
    [ "$status" = "0" ]
    [ "$output" = "executed." ]

    TEST_TEMP_DIR="$BATS_TEST_DIRNAME/temp dir"
    mkdir -p "$TEST_TEMP_DIR"
    mv "$BATS_TEST_DIRNAME/tmpstubs" "$TEST_TEMP_DIR/tmpstubs"
    export BATS_TEST_DIRNAME="$TEST_TEMP_DIR"

    mv "$CAPTURE_FILE" "$BATS_TEST_DIRNAME/shellmock.out"
    export CAPTURE_FILE="$BATS_TEST_DIRNAME/shellmock.out"

    shellmock_verify
    [ "${#capture[@]}" = "1" ]
    [ "${capture[0]}" = "cp-stub" ]
}

@test "shellmock_expect --match '--version'" {

    skipIfNot match-version

    shellmock_clean
    shellmock_expect foo --match "--version" --output "Foo version"

    run foo --version
    [ "$status" = "0" ]
    [ "$output" = "Foo version" ]
}

@test "shellmock_expect --status 0 regex-match" {

    skipIfNot regex-match

    shellmock_clean
    shellmock_expect cp --status 0 --type regex --match "-a -s script\(\'t.*\)" --output "mock success"

    run cp -a -s "script('testit')"
    [ "$status" = "0" ]
    [ "$output" = "mock success" ]

    run cp -a -s "script('testit2')"
    [ "$status" = "0" ]
    [ "$output" = "mock success" ]

    run cp -a -s "script('Testit2')"
    [ "$status" = "99" ]

}

@test "shellmock_expect --status 1 catch file descriptor 2" {

    shellmock_clean
    shellmock_expect cp --status 1 --match "--help" --output "mock success"

    output=$(cp --help 2>&1) || [ "$?" = 1 ] && [ "$output" = "mock success" ]
}
