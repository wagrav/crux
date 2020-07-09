#!/usr/bin/env bash
# if you execute these tests on Windows git bash, make sure you install jq via choco: chocolatey install jq

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash


function setup_file(){
    rm -f results/*.xml
}

function setup(){
  source evaluateTestResultsAsJunit.sh
}
function teardown(){
  rm -f results/*.xml
}

@test "UT: getSampleResultsJSON should return correct result" {
  run getSampleResultsJSON test_data/statistics.json "GET /api/skills"
  assert_output --partial 'transaction": "GET /api/skills"'
}

@test "UT: getErrorCount should not return 0 if there are errors in statistics.json" {
  run getErrorCount test_data/statistics.json
  refute_output 0
}

@test "UT: getErrorCount should return 0 if there are no errors in statistics.json" {
  run getErrorCount test_data/statistics.no.errors.json
  assert_output 0
}

@test "IT: run_main should not throw errors when no errors in statistics.json" {
  run run_main test_data/statistics.no.errors.json
  assert_output --partial "Test ended without errors"
}

@test "IT: run_main should  throw errors when  errors in statistics.json" {
  run run_main test_data/statistics.json
  assert_output --partial "Test ended with errors"
}

@test "IT: run_main should  detect when statistics.json does not exist" {
  run run_main test_data/statistics.does.not.exist.json
  assert_output --partial "does not exist"
}

@test "UT: getErrorStackTrace should include transaction, pecentile and errorCount when errors are found " {
  run getErrorStackTrace test_data/statistics.json
  assert_output --partial '"SamplerName": "Total"'
  assert_output --partial '"errorCount": 24,'
  assert_output --partial '"percentile_99_milis": 844.040000000001'
}
@test "UT: copyTestTemplate produces correct test file for FAILED test" {
  run copyTestTemplate "FAILED" "results" "templates" "There are multiple errors in tests" "my stack trace"
  assert_success
  run cat results/FAILED_TEST.xml
  assert_output --partial '<failure message="Performance tests failed">There are multiple errors in tests</failure>'
  assert_output --partial '<system-out>my stack trace</system-out'
}
@test "UT: checkForErrors should produce correctly formatted test results for FAILED test" {
  run checkForErrors test_data/statistics.json "results" "templates"
  assert_success
  run cat results/FAILED_TEST.xml
  assert_output --partial '<failure message="Performance tests failed">There are multiple errors in tests</failure>'
  refute_output --partial '<system-out>my stack trace</system-out'
}
@test "UT: checkForErrors should produce correctly formatted test results for PASS test" {
  run checkForErrors test_data/statistics.no.errors.json "results" "templates"
  assert_success
  run cat results/PASS_TEST.xml
  assert_success
}
@test "UT: checkForErrors should produce correctly formatted test results for SKIP test" {
  run checkForErrors test_data/statistics.does.not.exist.json "results" "templates"
  run cat results/SKIP_TEST.xml
  assert_success
}

@test "E2E: checkForErrors should produce correctly formatted test results for SKIP test" {
  test() {
    local file=$1
    local resDir=$2
    local templatesDir=$3
    local testStatus=$4
    run run_main "$file" "$resDir" "$templatesDir"
    assert_success
    run cat "$resDir/$testStatus"_TEST.xml
    assert_success
  }
  test test_data/statistics.no.errors.json results templates PASS
  test test_data/statistics.json results templates FAILED
  test test_data/statistics.does.not.exist.json results templates SKIP

}
