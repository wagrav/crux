#!/usr/bin/env bash
# if you execute these tests on Windows git bash, make sure you install jq via choco: chocolatey install jq

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

function setup(){
  source recreate_service_connection.sh
}


@test "UT: both functions are run" {

  run recreate_service_connection
  assert_success
}