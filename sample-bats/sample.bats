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

#---------------------------------------------------------------------------------
# File: sample.bats
# Purpose:
#     This is a sample bats file that demonstrates the use of the
#     mocking framework.
#---------------------------------------------------------------------------------

setup()
{
    # Source the shellmock functions into the shell.
    . ../bin/shellmock

    skipIfNot "$BATS_TEST_DESCRIPTION"

    shellmock_clean
}

teardown()
{
    if [ -z "$TEST_FUNCTION" ];then
        shellmock_clean
        rm -f sample.out
    fi
}

#-----------------------------------------------------------------------------------
# This test case demonstrates a normal bats test case where sample.sh is under test.
# sample.sh will echo "sample found" based on the response to the grep command.
# The default output will always be "sample found" because the script ensures
# that grep will return 0.
#-----------------------------------------------------------------------------------
@test "sample.sh-success" {

    run ./sample.sh

    [ "$status" = "0" ]

    # Validate using lines array.
    [ "${lines[0]}" = "sample found" ]

    # Optionally since this is a single line you can use $output
    [ "$output" = "sample found" ]

}

#----------------------------------------------------------------------------------------
# This test case demonstrates that the else condition if grep does not find the match.
# By forcing the status of 1 grep will cause the "sample not found" message to be echoed.
# To pull this off we need to mock the grep command.
#----------------------------------------------------------------------------------------
@test "sample.sh-failure" {


    shellmock_expect grep --status 1 --match '"sample line" sample.out'

    shellmock_debug "starting the test"

    run ./sample.sh

    shellmock_dump

    [ "$status" = "1" ]
    [ "$output" = "sample not found" ]


    shellmock_verify
    [ "${capture[0]}" = 'grep-stub "sample line" sample.out' ]

}

#-----------------------------------------------------------------------------------
# This test case demonstrates mocking the grep command using the partial mock feature.
# The sample.sh calls grep with two arguments.  The first argument is "sample line".
#-----------------------------------------------------------------------------------
@test "sample.sh-success-partial-mock" {

    shellmock_expect grep --status 0 --type partial --match '"sample line"'

    run ./sample.sh

    shellmock_dump

    [ "$status" = "0" ]

    # Validate using lines array.
    [ "${lines[0]}" = "sample found" ]

    # Optionally since this is a single line you can use $output
    [ "$output" = "sample found" ]

    shellmock_verify
    [ "${#capture[@]}" = "1" ]
    [ "${capture[0]}" = 'grep-stub "sample line" sample.out' ]

}

#-----------------------------------------------------------------------------------
# This test case demonstrates mocking the grep command using the partial mock feature.
# The sample.sh calls grep with two arguments.  The first argument is "sample line".
#
# The only difference between this and the previous test is that the argument is passed
# as single quotes 'sample line'.
#
# In that case you will notice that the command[] matches show as double quotes vs
# single quotes. That is because the arguments are normalized to double quotes.
#-----------------------------------------------------------------------------------
@test "sample.sh-success-partial-mock-with-single-quotes" {

    shellmock_expect grep --status 0 --type partial --match "'sample line'"

    run ./sample.sh

    shellmock_dump

    [ "$status" = "0" ]

    # Validate using lines array.
    [ "${lines[0]}" = "sample found" ]

    # Optionally since this is a single line you can use $output
    [ "$output" = "sample found" ]

    shellmock_verify
    [ "${#capture[@]}" = "1" ]
    [ "${capture[0]}" = 'grep-stub "sample line" sample.out' ]

}

#-----------------------------------------------------------------------------------
# This sample simply demonstrates the regex matching using grep.
#-----------------------------------------------------------------------------------
@test "sample.sh-mock-with-regex" {

    shellmock_expect grep --status 0 --type regex --match '"sample line" s.*'
    shellmock_expect grep --status 1 --type regex --match '"sample line" b.*'

    run grep "sample line" sample.out
    [ "$status" = "0" ]

    run grep "sample line" sample1.out
    [ "$status" = "0" ]

    run grep "sample line" bfile.out
    [ "$status" = "1" ]

    run grep "sample line" bats.out
    [ "$status" = "1" ]

    shellmock_dump

    shellmock_verify
    [ "${#capture[@]}" = "4" ]
    [ "${capture[0]}" = 'grep-stub "sample line" sample.out' ]
    [ "${capture[1]}" = 'grep-stub "sample line" sample1.out' ]
    [ "${capture[2]}" = 'grep-stub "sample line" bfile.out' ]
    [ "${capture[3]}" = 'grep-stub "sample line" bats.out' ]

}
@test "sample.sh-mock-with-custom-script" {

    shellmock_expect grep --status 0 --type partial --match "string1" --exec "echo mycustom {}"

    run grep string1 file1

    shellmock_dump
    [ "$status" = "0" ]
    [ "${lines[0]}" = "mycustom string1 file1" ]

    run grep string1 file2
    shellmock_dump
    [ "$status" = "0" ]
    [ "${lines[0]}" = "mycustom string1 file2" ]

    shellmock_verify
    [ "${#capture[@]}" = "2" ]
    [ "${capture[0]}" = 'grep-stub string1 file1' ]
    [ "${capture[1]}" = 'grep-stub string1 file2' ]
}