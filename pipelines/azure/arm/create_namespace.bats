#!/usr/bin/env bash
# if you execute these tests on Windows git bash, make sure you install jq via choco: chocolatey install jq

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

function setup(){
  source create_namespace.sh
}
function teardown(){
  unset kubectl
}

@test "UT:create_namespace: should report when namespace already exists" {
  kubectl (){
      echo 'dummy'
  }
  export -f kubectl
  run create_namespace "dummy"
  assert_output --partial "Namespace dummy already present"
}

@test "UT:create_namespace: should create namespace if does not exists" {
  kubectl (){
      echo 'does_not_exist'
  }
  export -f kubectl
  run create_namespace "dummy"
  assert_output --partial "Creating namespace"
}