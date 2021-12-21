#!/usr/bin/env bash

load $HOME/test/'test_helper/bats-assert/load.bash'
load $HOME/test/'test_helper/bats-support/load.bash'

TEST_IMAGE_NAME="${TEST_IMAGE_NAME:-objectivityltd/crux-base:jmeter5.4.2-chrome87}"
TEST_IMAGE_NAME_MASTER="${TEST_IMAGE_NAME_MASTER:-objectivityltd/crux-master:jmeter5.4.2-chrome87}"
TEST_IMAGE_NAME_SLAVE="${TEST_IMAGE_NAME_SLAVE:-objectivityltd/crux-slave:jmeter5.4.2-chrome87}"
RUN_OPTS="--shm-size=1g --rm"
JMETER_TESTS_SUCCESSFULL_OUTPUT="Err:     0 (0.00%)"

#These tests shoudl be independent of external services so we spin mock-server as adocker container for tests

setup_file(){
  docker stop mockserver ||:
  docker run --name mockserver -d --rm -p 1080:1080 mockserver/mockserver:mockserver-5.11.1 #sets a service for tests
  until curl -X PUT "http://localhost:1080/status" -H  "accept: application/json"; do sleep 1;done #wait for service to be available
  #all requests return HTTP 200
  curl -X PUT "http://localhost:1080/expectation" -H  "Content-Type: application/json" -d "{\"httpRequest\":{\"method\":\"GET\",\"path\":\"/.*\"},\"httpResponse\":{\"statusCode\":200,\"reasonPhrase\":\"I am mocking all the stuff\"}}"
  source build.sh && _build_all objectivityltd crux jmeter5.4.2-chrome87
}

teardown_file(){
  docker stop mockserver
}
@test "All E2E tests use Mock Server or STS as AUT" {
  #only use localhost:9191 (sts) or localhost:1080 (mock server) as AUT for e2e feature tests
  assert_success
}

@test "Mock server is running" {
  run curl -X PUT "http://localhost:1080/status" -H  "accept: application/json"
  assert_output --partial 5.11.1
}
@test "Mock server returns 200 for any GET call" {
  run curl -v -X GET "http://localhost:1080/i_do_not_exist" -H  "accept: application/json"
  assert_output --partial "HTTP/1.1 200"
}
@test "E2E: JMeter Test works fine with Simple Table Server " {
  local _test_scenario=test_table_server.jmx
  local _cmd_start_sts="screen -A -m -d -S sts /jmeter/apache-jmeter-*/bin/simple-table-server.sh -DjmeterPlugin.sts.addTimestamp=true -DjmeterPlugin.sts.datasetDirectory=/test "
  local _wait_for_sts="sleep 2" #time for sts to start, need to be refactored to conditional loop
  local _cmd_execute_jmeter_test="jmeter -n -t $_test_scenario"
  local _cmd="$_cmd_start_sts && $_wait_for_sts && $_cmd_execute_jmeter_test"
  #WHEN I run a jmeter test that use chrome headless and webdriver and I print result file to stdout
  run docker run $RUN_OPTS "$TEST_IMAGE_NAME" sh -c "$_cmd"
  #Then test is a success
  assert_output --partial  "$JMETER_TESTS_SUCCESSFULL_OUTPUT"
}

@test "E2E: JMeter Simple Table Server and Chrome Headless work fine " {

  local _test_scenario=selenium_chrome_headless_sts.jmx
  local _cmd_start_sts="screen -A -m -d -S sts /jmeter/apache-jmeter-*/bin/simple-table-server.sh -DjmeterPlugin.sts.addTimestamp=true -DjmeterPlugin.sts.datasetDirectory=/test "
  local _wait_for_sts="sleep 2" #time for sts to start, need to be refactored to conditional loop
  local _cmd_execute_jmeter_test="jmeter -n -t $_test_scenario"
  local _cmd="$_cmd_start_sts && $_wait_for_sts && $_cmd_execute_jmeter_test"
  #WHEN I run a jmeter test that use chrome headless and webdriver and I print result file to stdout
  run docker run $RUN_OPTS "$TEST_IMAGE_NAME" sh -c "$_cmd"
  #Then test is a success
  assert_output --partial  "$JMETER_TESTS_SUCCESSFULL_OUTPUT"
}

@test "E2E: JMeter WebDriver Sampler scenario with Chrome Headless is run fine within the container" {
  local _result_file=results.csv
  local _test_scenario=selenium_test_chrome_headless.jmx
  #WHEN I run a jmeter test that use chrome headless and webdriver and I print result file to stdout
  #--net required to acces mock server under host 'localhost'
  run docker run $RUN_OPTS --net=host "$TEST_IMAGE_NAME" sh -c "jmeter -Jwebdriver.sampleresult_class=com.googlecode.jmeter.plugins.webdriver.sampler.SampleResultWithSubs -n -l $_result_file -t $_test_scenario && cat /test/jmeter.log"
  #Then test is a success
  refute_output --partial CannotResolveClassException
  assert_output --partial "$JMETER_TESTS_SUCCESSFULL_OUTPUT"
}

@test "IT: Chromedriver 87 is installed " {
  run docker run $RUN_OPTS "$TEST_IMAGE_NAME" chromedriver --version
  #Then it is successful
  assert_output --partial "ChromeDriver 87."
}

@test "IT: Chrome 87 is installed" {
  run docker run $RUN_OPTS "$TEST_IMAGE_NAME" google-chrome --version
  #Then it is successful
  echo $output
  assert_output --partial "Google Chrome 87."
}

@test "IT: Python 3 is installed" {
  run docker run  $RUN_OPTS "$TEST_IMAGE_NAME" python3 --version
  #Then it is successful
  assert_output --partial "Python 3."
}


@test "IT: Groovy 2.4 is installed" {
  run docker run $RUN_OPTS "$TEST_IMAGE_NAME" groovy --version
  #Then it is successful
  assert_output --partial "Groovy Version: 2.4."
}

@test "IT: OpenJDK 1.8 is installed" {
  run docker run $RUN_OPTS "$TEST_IMAGE_NAME" java -version
  #Then it is successful
  assert_output --partial "1.8."
}

@test "IT: Chrome Headless works fine when used in python script" {
  #WHEN I run test that use chrome headless
  run docker run $RUN_OPTS "$TEST_IMAGE_NAME" python3 test.py
  #Then they are successful
  assert_success
}

@test "IT: JMeter 5.4.2 is present" {
  #WHEN I run test that use chrome headless
  run docker run $RUN_OPTS "$TEST_IMAGE_NAME" jmeter --version
  #Then they are successful
  assert_output --partial "\ 5.4.2"
}

@test "IT: Plugins are present and in correct versions" {
  #WHEN I run test that use chrome headless
  run docker run $RUN_OPTS "$TEST_IMAGE_NAME" sh -c "ls /jmeter/*/lib && ls /jmeter/*/lib/ext"
  #Then they are successful
  assert_output --partial "jmeter-plugins-table-server-2.4.jar"
  assert_output --partial "jmeter.backendlistener.azure-0.2.3.jar"
  assert_output --partial "JMeterPlugins-Standard.jar"
  assert_output --partial "jmeter-parallel-0.8.jar"
  assert_output --partial "selenium-java-3.14.0.jar"

}

@test "IT: Docker Base Image Builds Successfully" {
  docker image rm "$TEST_IMAGE_NAME" ||:
  run docker build -t "$TEST_IMAGE_NAME" -f Dockerfile .
  assert_success
}

@test "IT: Docker Master Image Builds Successfully" {
  docker image rm "$TEST_IMAGE_NAME_MASTER" ||:
  run docker build -t "$TEST_IMAGE_NAME_MASTER" -f Dockerfile-master .
  assert_success
}

@test "IT: Docker Slave Image Builds Successfully" {
  docker image rm "$TEST_IMAGE_NAME_SLAVE" ||:
  run docker build -t "$TEST_IMAGE_NAME_SLAVE" -f Dockerfile-slave .
  assert_success
}