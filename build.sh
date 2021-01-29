#!/usr/bin/env bash
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

#---------------------------------------------------------------------------------------------
# Purpose: build.sh is used to run pre-PR publish steps. It performs three primary functions:
# - Runs all bats tests on shellmock
# - Runs all bats tests on the sample-bats
# - Runs shellcheck against the code and fails if lint errors are found.
#---------------------------------------------------------------------------------------------

lint() {
    echo "...linting $1"
    if ! shellcheck -s bash -x "$1"; then
        echo "ERROR: shellcheck of $1 has errors"
        exit 1
    fi
}

# Run linting on scripts that users consume.
(cd sample-bats && lint sample.sh)
(cd sample-bats && lint sample.bats)
lint install.sh
lint build.sh
(cd bin && lint shellmock)
(cd test && lint shellmock.bats)

echo "...Running bats tests for sample-bats"
(cd sample-bats && bats ./*.bats)

echo ".../Running bats tests for test"
(cd test && bats ./*.bats)
