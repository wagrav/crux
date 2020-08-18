#!/usr/bin/env bash

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

setup(){
  source jmeter.sh
}

@test "Jmeter BATS tests are run" {
  assert_success
}

@test "run_main calls all composign functions" {
  setVARS(){ echo "__mock"; }
  prepareEnv() { echo "__mock"; }
  getPods() { echo "__mock"; }
  getSlavePods() { echo "__mock"; }
  cleanPods(){ echo "__mock"; }
  copyDataToPods(){ echo "__mock"; }
  copyTestFilesToMasterPod(){ echo "__mock"; }
  cleanMasterPod(){ echo "__mock"; }
  lsPods(){ echo "__mock"; }
  runTest(){ echo "__mock"; }
  copyTestResultsToLocal(){ echo "__mock"; }
  getServerLogs(){ echo "__mock";}
  export -f setVARS prepareEnv getPods getSlavePods cleanPods copyDataToPods copyTestFilesToMasterPod cleanMasterPod lsPods runTest copyTestResultsToLocal getServerLogs
  run run_main
  CALL_NUMBER=12
  [ "$(echo "$output" | grep "__mock" | wc -l)" -eq $CALL_NUMBER ]
}