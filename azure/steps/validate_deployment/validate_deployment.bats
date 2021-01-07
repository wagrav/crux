#!/usr/bin/env bash
# if you execute these tests on Windows git bash, make sure you install jq via choco: chocolatey install jq

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

function setup(){
  source "$BATS_TEST_DIRNAME/validate_deployment.sh"
}
function teardown(){
  :
}

@test "UT:validate_deployment" {
  :
}
