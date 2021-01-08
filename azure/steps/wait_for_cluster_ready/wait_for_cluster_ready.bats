#!/usr/bin/env bash

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

function setup(){
  source "$BATS_TEST_DIRNAME/wait_for_cluster_ready.sh"
}
function teardown(){
  :
}

@test "UT:wait_for_cluster_ready TBD" {
  :
}
