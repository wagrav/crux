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
 #rm -f results/*.xml
 echo ""
}

#error-based and general
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
  run run_main test_data/statistics.no.errors.json results templates test_data/thresholds.any.properties
  assert_output --partial "Test ended without errors"
}

@test "IT: run_main should  throw errors when  errors in statistics.json" {
  run run_main test_data/statistics.json results templates test_data/thresholds.any.properties
  assert_output --partial "Test ended with errors"
}

@test "IT: run_main should  detect when statistics.json does not exist" {
  run run_main test_data/statistics.does.not.exist.json results templates test_data/thresholds.any.properties
  assert_output --partial "does not exist"
}

@test "UT: getErrorStackTrace should include transaction, pecentile and errorCount when errors are found " {
  run getErrorStackTrace test_data/statistics.json
  assert_output --partial '"SamplerName": "Total"'
  assert_output --partial '"errorCount": 24,'
  assert_output --partial '"percentile_99_milis": 844.040000000001'
}
@test "UT: copyTestTemplate produces correct test file for FAILED test" {
  run copyTestTemplate "FAILED" "results" "templates" "There are multiple errors in tests" "my stack trace" "Should pass" "Errors"
  assert_success
  run cat results/FAILED_Should_pass_TEST.xml
  assert_output --partial '<failure message="Performance tests failed">There are multiple errors in tests</failure>'
  assert_output --partial '<system-out>my stack trace</system-out'
}
@test "UT: checkForErrors should produce correctly formatted test results for FAILED test" {
  run checkForErrors test_data/statistics.json "results" "templates"
  assert_success
  run cat results/FAILED_Should_pass_without_errors_TEST.xml
  assert_output --partial '<failure message="Performance tests failed">There are multiple errors in tests</failure>'
  refute_output --partial '<system-out>my stack trace</system-out'
}
@test "UT: checkForErrors should produce correctly formatted test results for PASS test" {
  run checkForErrors test_data/statistics.no.errors.json "results" "templates"
  assert_success
  run cat results/PASS_Should_pass_without_errors_TEST.xml
  assert_success
}
@test "UT: checkForErrors should produce correctly formatted test results for SKIP test" {
  run checkForErrors test_data/statistics.does.not.exist.json "results" "templates"
  run cat results/SKIP_Should_pass_without_errors_TEST.xml
  assert_success
}

@test "E2E: checkForErrors should produce correctly formatted test results for SKIP test" {
  test() {
    local file=$1
    local resDir=$2
    local templatesDir=$3
    local testStatus=$4
    local threshold_file=$5
    run run_main "$file" "$resDir" "$templatesDir" "$threshold_file"
    assert_success
    run cat "$resDir/$testStatus"_Should_pass_without_errors_TEST.xml
    assert_success
  }
  test test_data/statistics.no.errors.json results templates PASS test_data/thresholds.any.properties
  test test_data/statistics.json results templates FAILED test_data/thresholds.any.properties
  test test_data/statistics.does.not.exist.json results templates SKIP test_data/thresholds.any.properties

}

#metric-based

@test "UT: getMetricForSampler should return correct result gor given metric and sampler" {
  test() {
    local file=$1
    local sampler=$2
    local metric=$3
    local expected_output=$4
    run getMetricForSampler "$file" "$sampler" "$metric" "$expected_output"
    assert_output "$expected_output"
  }
  test test_data/statistics.json "PUT /api/userskills" pct1ResTime 259
  test test_data/statistics.json "TC_Change Additional Skill Competence" meanResTime 228.4967948717948
  test test_data/statistics.ugly.chars.json "Sampler~!@#$%^&*()_+" minResTime 65.1
}

@test "UT: getAnyMetric should return correct result gor given metric" {
  test() {
    local file=$1
    local metric=$2
    local expected_output=$3
    local index=$4
    run getAnyMetric "$file" "$metric" "$expected_output"
    assert_line --index $index --partial "$expected_output"
  }
  test test_data/statistics.json errorCount 24 26
  test test_data/statistics.json meanResTime 228.4967948717948 7
  test test_data/statistics.ugly.chars.json errorPct 16.666666 1
}

@test "UT: getHighestValueForAnyMetric should return correct results" {
  run getHighestValueForAnyMetric test_data/statistics.json pct1ResTime
  assert_output 1103.8
}

#e2e test, UT i IT na readThresholds z mockami

@test "E2E: readThresholds should produce right JUNIT tests files" {
  run readThresholds test_data/thresholds.no.alert.properties test_data/statistics.json results templates
  assert_success
  run cat results/FAILED_Metric_pct1ResTime_should_not_breach_threshold_for_sampler_ANY_TEST.xml
  assert_success
  run cat results/PASS_Metric_pct1ResTime_should_not_breach_threshold_for_sampler_PUT__api_userskills_TEST.xml
  assert_success
}

@test "E2E: readThresholds JUNIT files should contain correct details inside" {
  run readThresholds test_data/thresholds.no.alert.properties test_data/statistics.json results templates
  run cat results/FAILED_Metric_pct1ResTime_should_not_breach_threshold_for_sampler_ANY_TEST.xml
  assert_output --partial '<system-out>Condition : ANY, metric actual value: 1103.8, max threshold: 1100.5</system-out>'
  assert_output --partial '<failure message="Performance tests failed">Threshold has been breached</failure>'
  run cat results/PASS_Metric_pct1ResTime_should_not_breach_threshold_for_sampler_PUT__api_userskills_TEST.xml
  assert_output --partial '<testcase classname="JMeterTests" name="PASS_Metric_pct1ResTime_should_not_breach_threshold_for_sampler_PUT__api_userskills" time="0" />'
}

@test "UT: readThresholds should properly evaluate thresholds for samplers" {
  test(){
      local value=$1
      local threshold_file=$2
      local statistics_file=$3
      local sampler=$4
      local expected_status=$5

      getHighestValueForAnyMetric(){ #stub
        echo "$value"
     }
      getMetricForSampler(){ #stub
       getHighestValueForAnyMetric
     }
      export -f getHighestValueForAnyMetric getMetricForSampler
      run readThresholds "$threshold_file" "$statistics_file" results templates
      assert_output --partial " -- --> Test for $sampler has $expected_status with metric value: $value"
  }
  test 1001 test_data/thresholds.any.properties test_data/statistics.json ANY failed
  test 99.999 test_data/thresholds.any.properties test_data/statistics.json ANY passed
  test 99.999 test_data/thresholds.no.alert.properties test_data/statistics.json "PUT /api/userskills" passed
  test 299.999 test_data/thresholds.no.alert.properties test_data/statistics.json "PUT /api/userskills" failed

}

@test "UT: readThresholds should ignore comments in thresholds file" {
  run readThresholds test_data/thresholds.comments.properties test_data/statistics.json results templates
  assert_output ""
}