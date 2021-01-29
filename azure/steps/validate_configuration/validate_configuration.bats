#!/usr/bin/env bash

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

function setup(){
  source "$BATS_TEST_DIRNAME/validate_configuration.sh"
}
function teardown(){
  :
}

@test "UT:validate_configuraton should display error for on_aks_pool_created_for_each_test_run if arm connection is _" {
  local _mode="on_aks_pool_created_for_each_test_run"
  local _arm_service_connection="_"
  local _kubernetes_service_connection="_"
  run validate_configuration "$_mode" "$_arm_service_connection" "$_kubernetes_service_connection" "http://dummy.link"
  assert_output --partial "##vso[task.logissue type=error]"
}

@test "UT:validate_configuraton should display error for on_aks_pool_created_for_each_test_run if k8 connection is _" {
  local _mode="on_aks_pool_created_for_each_test_run"
  local _arm_service_connection="dummy"
  local _kubernetes_service_connection="_"
  run validate_configuration "$_mode" "$_arm_service_connection" "$_kubernetes_service_connection"  "http://dummy.link"
  assert_output --partial "##vso[task.logissue type=error]"
}

