#!/usr/bin/env bash

load $HOME/test/'test_helper/bats-assert/load.bash'
load $HOME/test/'test_helper/bats-support/load.bash'

test_image_name=gabrielstar/crux-base
test_image_name_master=gabrielstar/crux-master:0.0.1
run_opts="--shm-size=1g --rm"
jmeter_test_successful_output="Err:     0 (0.00%)"

# setup_file does not work well for this, so I build docker image in first test as an ugly but stable work-around
# whover knows how to fix it, you get a beer. Rememeber this case is equivalent of setup_file.
@test "IT: Chromedriver 83.0.4103.39 is installed flaky" {
  run docker run $run_opts $test_image_name chromedriver --version
  #Then it is successful
  assert_output --partial "ChromeDriver 83.0.4103.39"
}

@test "IT: Chrome 83.0.4103.6 is installed flaky" {
  run docker run $run_opts $test_image_name google-chrome --version
  #Then it is successful
  echo $output
  assert_output --partial "Google Chrome 83.0.4103.61"
}
@test "E2E: JMeter Test works fine with Simple Table Server flaky" {
  local test_scenario=test_table_server.jmx
  local cmd_start_sts="screen -A -m -d -S sts /jmeter/apache-jmeter-*/bin/simple-table-server.sh -DjmeterPlugin.sts.addTimestamp=true -DjmeterPlugin.sts.datasetDirectory=/test "
  local wait_for_sts="sleep 2" #time for sts to start, need to be refactored to conditional loop
  local cmd_execute_jmeter_test="jmeter -n -t $test_scenario"
  local cmd="$cmd_start_sts && $wait_for_sts && $cmd_execute_jmeter_test"
  #WHEN I run a jmeter test that use chrome headless and webdriver and I print result file to stdout
  run docker run $run_opts $test_image_name_master "/bin/bash -c $cmd"
  #Then test is a success
  assert_output --partial  "$jmeter_test_successful_output"
}

@test "E2E: JMeter Simple Table Server and Chrome Headless work fine flaky" {

  local test_scenario=selenium_chrome_headless_sts.jmx
  local cmd_start_sts="screen -A -m -d -S sts /jmeter/apache-jmeter-*/bin/simple-table-server.sh -DjmeterPlugin.sts.addTimestamp=true -DjmeterPlugin.sts.datasetDirectory=/test "
  local wait_for_sts="sleep 2" #time for sts to start, need to be refactored to conditional loop
  local cmd_execute_jmeter_test="jmeter -n -t $test_scenario"
  local cmd="$cmd_start_sts && $wait_for_sts && $cmd_execute_jmeter_test"
  #WHEN I run a jmeter test that use chrome headless and webdriver and I print result file to stdout
  run docker run $run_opts $test_image_name_master "/bin/bash -c $cmd"
  #Then test is a success
  assert_output --partial  "$jmeter_test_successful_output"
}

@test "IT: Docker Base Image Builds Successfully" {
  docker image rm $test_image_name ||:
  docker build -t $test_image_name -f Dockerfile .
}

@test "IT: Image is on the list" {
  run docker image ls $test_image_name
  #Then it is successful
  assert_output --partial $test_image_name
}

@test "IT: Python 2.7.17 is installed" {
  run docker run  $run_opts $test_image_name python --version
  #Then it is successful
  assert_output --partial "Python 2.7.16"
}

@test "IT: Groovy 2.4.16 is installed" {
  run docker run $run_opts $test_image_name groovy --version
  #Then it is successful
  assert_output --partial "Groovy Version: 2.4.16"
}



@test "IT: OpenJDK 1.8.0_252 is installed" {
  run docker run $run_opts $test_image_name java -version
  #Then it is successful
  assert_output --partial "1.8.0_252"
}

@test "IT: Chrome Headless works fine when used in python script" {
  #WHEN I run test that use chrome headless
  run docker run $run_opts $test_image_name python test.py
  #Then they are successful
  assert_success
}

@test "IT: JMeter 5.3 is present" {
  #WHEN I run test that use chrome headless
  run docker run $run_opts $test_image_name jmeter --version
  #Then they are successful
  assert_output --partial "\ 5.3"
}

@test "IT: JMeter WebDriver Sampler scenario with Chrome Headless is run fine within the container" {
  local result_file=results.csv
  local test_scenario=selenium_test_chrome_headless.jmx
  #WHEN I run a jmeter test that use chrome headless and webdriver and I print result file to stdout
  run docker run $run_opts $test_image_name jmeter -Jwebdriver.sampleresult_class=com.googlecode.jmeter.plugins.webdriver.sampler.SampleResultWithSubs -n -l $result_file -t $test_scenario
  #Then test is a success
  refute_output --partial CannotResolveClassException
  assert_output --partial "$jmeter_test_successful_output"
}

@test "IT: Docker Master Image Builds Successfully" {
  docker image rm $test_image_name_master ||:
  docker build -t $test_image_name_master -f Dockerfile-master .
}

