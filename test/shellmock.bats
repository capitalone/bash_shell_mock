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
    unset SHELLMOCK_V1_COMPATIBILITY
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

    shellmock_verify
    [ "${#capture[@]}" = "1" ]
    [ "${capture[0]}" = 'cp-stub a b' ]

}

@test "shellmock_expect --status 1" {

    skipIfNot status-1

    shellmock_clean
    shellmock_expect cp --status 1 --match "a b" --output "mock a b failed"

    run cp a b
    [ "$status" = "1" ]
    [ "$output" = "mock a b failed" ]

    shellmock_verify
    [ "${#capture[@]}" = "1" ]
    [ "${capture[0]}" = 'cp-stub a b' ]

}

@test "shellmock_expect-multiple-responses" {

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

    shellmock_verify
    [ "${#capture[@]}" = "3" ]
    [ "${capture[0]}" = 'cp-stub a b' ]
    [ "${capture[1]}" = 'cp-stub a b' ]
    [ "${capture[2]}" = 'cp-stub a c' ]

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

    shellmock_verify
    [ "${#capture[@]}" = "2" ]
    [ "${capture[0]}" = 'cp-stub a b' ]
    [ "${capture[1]}" = 'cp-stub a c' ]

}

@test "shellmock_expect --status 0 partial-match with double quotes" {

    skipIfNot partial-match-double

    shellmock_clean
    shellmock_expect cp --status 0 --type partial --match '"a file.c"' --output "mock success"

    run cp "a file.c" b
    [ "$status" = "0" ]
    [ "$output" = "mock success" ]

    run cp "a file.c" c
    [ "$status" = "0" ]
    [ "$output" = "mock success" ]

    shellmock_verify
    [ "${#capture[@]}" = "2" ]
    [ "${capture[0]}" = 'cp-stub "a file.c" b' ]
    [ "${capture[1]}" = 'cp-stub "a file.c" c' ]

}

@test "shellmock_expect --status 0 partial-match with single quotes" {

    skipIfNot partial-match-single

    shellmock_clean
    shellmock_expect cp --status 0 --type partial --match "'a file.c'" --output "mock success"

    run cp 'a file.c' b
    [ "$status" = "0" ]
    [ "$output" = "mock success" ]

    run cp 'a file.c' c
    [ "$status" = "0" ]
    [ "$output" = "mock success" ]

    # Because the input parameters into the mock are normalized the single
    # quotes will appear as double quotes in the shellmock.out file.

    shellmock_verify
    [ "${#capture[@]}" = "2" ]
    [ "${capture[0]}" = 'cp-stub "a file.c" b' ]
    [ "${capture[1]}" = 'cp-stub "a file.c" c' ]

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

    grep 'No record match found stdin:\*\* cmd:cp args:\*a c\*' shellmock.err

    shellmock_verify
    [ "${#capture[@]}" = "2" ]
    [ "${capture[0]}" = 'cp-stub a b' ]
    [ "${capture[1]}" = 'cp-stub a c' ]

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
    grep 'No record match found stdin:\*\* cmd:cp args:\*b b\*' shellmock.err

    shellmock_verify
    [ "${#capture[@]}" = "3" ]
    [ "${capture[0]}" = 'cp-stub a b' ]
    [ "${capture[1]}" = 'cp-stub a c' ]
    [ "${capture[2]}" = 'cp-stub b b' ]

}

@test "shellmock_expect execute on match" {

    skipIfNot exec-on-match

    shellmock_clean
    shellmock_expect cp --status 0 --type exact  --match "a b" --exec "echo executed."

    run cp a b
    [ "$status" = "0" ]
    [ "$output" = "executed." ]

    shellmock_verify
    [ "${#capture[@]}" = "1" ]
    [ "${capture[0]}" = 'cp-stub a b' ]

}

@test "shellmock_expect execute on match args with double quotes" {

    skipIfNot exec-on-match-with-double-quotes

    shellmock_clean
    shellmock_expect cp --status 0 --type exact  --match '"a b.c" b' --exec "echo executed."

    run cp "a b.c" b
    [ "$status" = "0" ]
    [ "$output" = "executed." ]

    shellmock_verify
    [ "${#capture[@]}" = "1" ]
    [ "${capture[0]}" = 'cp-stub "a b.c" b' ]

}

@test "shellmock_expect execute on match args with single quotes" {

    skipIfNot exec-on-match-with-single-quotes

    shellmock_clean
    shellmock_expect cp --status 0 --type exact  --match "'a b.c' b" --exec "echo executed."

    run cp 'a b.c' b
    [ "$status" = "0" ]
    [ "$output" = "executed." ]

    # Single quotes will be converted to double quotes when the arguments are normalized.
    # so match on double quotes instead.

    shellmock_verify
    [ "${#capture[@]}" = "1" ]
    [ "${capture[0]}" = 'cp-stub "a b.c" b' ]

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

    shellmock_verify
    [ "${#capture[@]}" = "2" ]
    [ "${capture[0]}" = 'cp-stub a b' ]
    [ "${capture[1]}" = 'cp-stub a c' ]

}

@test "shellmock_expect execute on match with {} substitution" {

    skipIfNot substitution

    shellmock_clean
    shellmock_expect cp --status 0 --type exact  --match "a b" --exec "echo t1 {} tn"

    run cp a b
    [ "$status" = "0" ]
    [ "$output" = "t1 a b tn" ]

    shellmock_verify
    [ "${#capture[@]}" = "1" ]
    [ "${capture[0]}" = 'cp-stub a b' ]

}

@test "shellmock_expect source" {

    skipIfNot source

    shellmock_clean
    shellmock_expect test.bash --status 0 --type exact  --match "" --source "./test.bash"

    . tmpstubs/test.bash

    [ "$TEST_PROP" = "test-prop" ]

    shellmock_verify
    [ "${#capture[@]}" = "1" ]
    [ "${capture[0]}" = 'test.bash-stub' ]

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

    shellmock_verify
    [ "${#capture[@]}" = "3" ]
    [ "${capture[0]}" = 'cp-stub a b' ]
    [ "${capture[1]}" = 'cp-stub a b' ]
    [ "${capture[2]}" = 'cp-stub a c' ]

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

    shellmock_verify
    [ "${#capture[@]}" = "1" ]
    [ "${capture[0]}" = 'cp-stub' ]

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

    shellmock_verify
    [ "${#capture[@]}" = "1" ]
    [ "${capture[0]}" = "foo-stub --version" ]

}

@test "shellmock_expect --status 0 regex-match" {

    skipIfNot regex-match

    shellmock_clean
    shellmock_expect cp --status 0 --type regex --match "-a -s script\(\'t.*\'\)" --output "mock success"

    run cp -a -s "script('testit')"
    [ "$status" = "0" ]
    [ "$output" = "mock success" ]

    run cp -a -s "script('testit2')"

    [ "$status" = "0" ]
    [ "$output" = "mock success" ]

    run cp -a -s "script('Testit2')"
    [ "$status" = "99" ]

    shellmock_verify
    [ "${#capture[@]}" = "3" ]
    [ "${capture[0]}" = "cp-stub -a -s script('testit')" ]
    [ "${capture[1]}" = "cp-stub -a -s script('testit2')" ]
    [ "${capture[2]}" = "cp-stub -a -s script('Testit2')" ]

}

@test "shellmock_expect quotes compatibility test" {

    skipIfNot quotes-compatibility-v1.0-test

    export SHELLMOCK_V1_COMPATIBILITY="enabled"

    shellmock_clean
    shellmock_expect cp --status 0 --match "a b c" --output "mock a b success"

    run cp "a b" c
    [ "$status" = "0" ]
    [ "$output" = "mock a b success" ]

    shellmock_verify
    [ "${capture[0]}" = "cp-stub a b c" ]
}

@test "shellmock_expect --status 0 with stdin" {

    skipIfNot status-0-stdin

    shellmock_clean

    #---------------------------------------------------------------
    # Had issues getting the run echo "a b" | cat to work so
    # I used the exec feature to create stubs to invoke the cat-stub
    #---------------------------------------------------------------
    shellmock_expect helper --status 0 --match "a b" --exec 'echo a b | cat'
    shellmock_expect helper --status 0 --match "a c" --exec 'echo a c | cat'

    shellmock_expect cat --status 0 --match-stdin "a b" --output "mock success"

    run helper a b
    [ "$status" = "0" ]
    [ "$output" = "mock success" ]

    run helper a c
    [ "$status" = "99" ]

    shellmock_verify
    [ "${#capture[@]}" = "4" ]
    [ "${capture[0]}" = 'helper-stub a b' ]
    [ "${capture[1]}" = 'a b | cat-stub' ]
    [ "${capture[2]}" = 'helper-stub a c' ]
    [ "${capture[3]}" = 'a c | cat-stub' ]

}

@test "shellmock_expect --status 0 with stdin and args" {

    skipIfNot status-0-stdin-and-args

    shellmock_clean

    #---------------------------------------------------------------
    # Had issues getting the run echo "a b" | cat to work so
    # I used the exec feature to create stubs to invoke the cat-stub
    #---------------------------------------------------------------
    shellmock_expect helper --status 0 --match "a b" --exec 'echo a b | cat -t -v'
    shellmock_expect helper --status 0 --match "a b" --exec 'echo a b | cat -p -q'

    shellmock_expect cat --status 0 --match-args "-t -v" --match-stdin "a b" --output "mock success"

    run helper a b
    [ "$status" = "0" ]
    [ "$output" = "mock success" ]

    run helper a b
    [ "$status" = "99" ]


    shellmock_verify
    [ "${#capture[@]}" = "4" ]
    [ "${capture[0]}" = 'helper-stub a b' ]
    [ "${capture[1]}" = 'a b | cat-stub -t -v' ]
    [ "${capture[2]}" = 'helper-stub a b' ]
    [ "${capture[3]}" = 'a b | cat-stub -p -q' ]

}

@test "shellmock_expect --status 0 with stdin and args multi-response" {

    skipIfNot status-0-stdin-and-args-multi

    shellmock_clean

    #---------------------------------------------------------------
    # Had issues getting the run echo "a b" | cat to work so
    # I used the exec feature to create stubs to invoke the cat-stub
    #---------------------------------------------------------------
    shellmock_expect helper --status 0 --match "a b" --exec 'echo a b | cat -t -v'
    shellmock_expect helper --status 0 --match "a b" --exec 'echo a b | cat -p -q'
    shellmock_expect helper --status 0 --match "a b" --exec 'echo a b | cat -t -v'

    shellmock_expect cat --status 0 --match-args "-t -v" --match-stdin "a b" --output "mock success 1"
    shellmock_expect cat --status 0 --match-args "-t -v" --match-stdin "a b" --output "mock success 2"

    run helper a b
    [ "$status" = "0" ]
    [ "$output" = "mock success 1" ]

    run helper a b
    [ "$status" = "99" ]

    run helper a b
    [ "$status" = "0" ]
    [ "$output" = "mock success 2" ]

    shellmock_verify
    [ "${#capture[@]}" = "6" ]
    [ "${capture[0]}" = 'helper-stub a b' ]
    [ "${capture[1]}" = 'a b | cat-stub -t -v' ]
    [ "${capture[2]}" = 'helper-stub a b' ]
    [ "${capture[3]}" = 'a b | cat-stub -p -q' ]
    [ "${capture[4]}" = 'helper-stub a b' ]
    [ "${capture[5]}" = 'a b | cat-stub -t -v' ]

}

@test "shellmock_expect --status 0 with stdin and regex" {

    skipIfNot status-0-stdin-regex

    shellmock_clean

    #---------------------------------------------------------------
    # Had issues getting the run echo "a b" | cat to work so
    # I used the exec feature to create stubs to invoke the cat-stub
    #---------------------------------------------------------------
    shellmock_expect helper --status 0 --match "a b" --exec 'echo a b | cat'
    shellmock_expect helper --status 0 --match "a c" --exec 'echo a c | cat'

    shellmock_expect cat --status 0 --stdin-match-type regex --match-stdin "a.*" --output "mock success"

    run helper a b
    [ "$status" = "0" ]
    [ "$output" = "mock success" ]

    run helper a c
    [ "$status" = "0" ]
    [ "$output" = "mock success" ]

    shellmock_verify
    [ "${#capture[@]}" = "4" ]
    [ "${capture[0]}" = 'helper-stub a b' ]
    [ "${capture[1]}" = 'a b | cat-stub' ]
    [ "${capture[2]}" = 'helper-stub a c' ]
    [ "${capture[3]}" = 'a c | cat-stub' ]

}

@test "shellmock_expect --status 0 with stdin partial match" {

    skipIfNot status-0-stdin-partial

    shellmock_clean

    #---------------------------------------------------------------
    # Had issues getting the run echo "a b" | cat to work so
    # I used the exec feature to create stubs to invoke the cat-stub
    #---------------------------------------------------------------
    shellmock_expect helper --status 0 --match "a b" --exec 'echo a b | cat'
    shellmock_expect helper --status 0 --match "a c" --exec 'echo a c | cat'

    shellmock_expect cat --status 0 --stdin-match-type regex --match-stdin "a" --output "mock success"

    run helper a b
    [ "$status" = "0" ]
    [ "$output" = "mock success" ]

    run helper a c
    [ "$status" = "0" ]
    [ "$output" = "mock success" ]

    shellmock_verify
    [ "${#capture[@]}" = "4" ]
    [ "${capture[0]}" = 'helper-stub a b' ]
    [ "${capture[1]}" = 'a b | cat-stub' ]
    [ "${capture[2]}" = 'helper-stub a c' ]
    [ "${capture[3]}" = 'a c | cat-stub' ]

}
