#!/usr/bin/env bash

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

setup(){
  source "$BATS_TEST_DIRNAME/load_test.sh"
  test_tmp_dir=$BATS_TMPDIR
  _kill_script() { echo $FUNCNAME; }
  _start_sts() { echo $FUNCNAME; }
  _wait_for_sts() { echo $FUNCNAME; }
  hostname() { echo "IP"; }
  export -f _kill_script _start_sts _wait_for_sts _jmeter hostname

}
teardown(){
  unset hostname
}

@test "UT: load_test should call composing functions" {
  _jmeter() { echo $FUNCNAME; }
  export -f _jmeter
  run load_test
  assert_output --partial _kill_script
  assert_output --partial _start_sts
  assert_output --partial _wait_for_sts
  assert_output --partial _jmeter

}

@test "UT: load_tests should call _jmeter with prepended args for shared drive /shared  folder with tests /test and IP" {
  _jmeter() { echo "$FUNCNAME $*"; }
  local _params=(1 2 3 4)
  export -f  _jmeter
  run load_test "${_params[*]}"
  assert_output --partial "_jmeter /test /shared IP ${_params[*]}"
}

@test "UT: _jmeter should call jmeter.sh binary with proper parameters in correct order" {
  getent(){
    cat << EOF
10.244.0.21     STREAM jmeter-slaves-svc.helm.svc.cluster.local
10.244.0.21     DGRAM
10.244.0.21     RAW
10.244.1.15     STREAM
10.244.1.15     DGRAM
10.244.1.15     RAW
10.244.2.22     STREAM
10.244.2.22     DGRAM
10.244.2.22     RAW
EOF
  }
  sh(){
    echo "$FUNCNAME $*"
  }
  export -f getent sh
  run _jmeter /test /shared STS_IP test.jmx user_args
  assert_output --partial "sh /jmeter/apache-jmeter-*/bin/jmeter.sh -n -t //test/test.jmx user_args -Gsts=STS_IP -Gchromedriver=/usr/bin/chromedriver -q //test/user.properties -Dserver.rmi.ssl.disable=true -R 10.244.0.21,10.244.1.15,10.244.2.2"
  unset getent sh

}