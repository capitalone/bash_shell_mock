#!/usr/bin/env bats
#--------------------------------------------------------------------------------
# Copyright 2017 Capital One Services, LLC
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

    run ./sample.sh
    [ "$status" = "1" ]
    [ "$output" = "sample not found" ]


    shellmock_verify
    [ "${capture[0]}" = 'grep-stub sample line sample.out' ]

}