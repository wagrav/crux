#!/usr/bin/env bash
#Script created to launch Jmeter tests directly from the current terminal without accessing the jmeter master pod.
#It requires that you supply the path to the jmx file
#After execution, test script jmx file may be deleted from the pod itself but not locally.

function setVARS() {
  working_dir="$(pwd)"
  #Get namesapce variable
  tenant="$1"
  jmx="$2"
  data_file="$3"
  user_args=$4
  root_dir=$working_dir/../../
  local_report_dir=$working_dir/../tmp/report
  report_dir=report
  test_dir=/test
  tmp=/tmp
  report_args="-o $tmp/$report_dir -l $tmp/results.csv -e"
  test_name="$(basename "$root_dir/$jmx")"
}

prepareEnv(){
  #delete evicted pods first
  kubectl get pods --all-namespaces --field-selector 'status.phase==Failed' -o json | kubectl delete -f -
  master_pod=$(kubectl get po -n $tenant | grep Running | grep jmeter-master | awk '{print $1}')
  #create necessary dirs
  mkdir -p $local_report_dir
}

copyTestFilesToMasterPod(){
  kubectl cp "$root_dir/$jmx" -n $tenant "$master_pod:/$test_dir/$test_name"
  kubectl cp "$root_dir/$data_file" -n $tenant "$master_pod:/$test_dir/"
}
cleanMasterPod(){
  kubectl exec -ti -n $tenant $master_pod -- rm -Rf "$tmp"
  kubectl exec -ti -n $tenant $master_pod -- mkdir -p "$tmp/$report_dir"
}
runTest(){
  printf "\t\n Jmeter user args $user_args"
  kubectl exec -ti -n $tenant $master_pod -- /bin/bash /load_test $test_name " $report_args $user_args "
}
copyTestResultsToLocal(){
  kubectl cp "$tenant/$master_pod:$tmp/$report_dir" "$local_report_dir/"
  kubectl cp "$tenant/$master_pod:$tmp/results.csv" "$working_dir/../tmp/results.csv"
  kubectl cp "$tenant/$master_pod:/test/jmeter.log" "$working_dir/../tmp/jmeter.log"
  head -n10 "$working_dir/../tmp/results.csv"
}

setVARS "$1" "$2" "$3" "$4"
prepareEnv
copyTestFilesToMasterPod
cleanMasterPod
runTest
copyTestResultsToLocal


#USEFUL COMMANDS FOR TROUBLESHOOTING
#enter master pod
# kubectl exec -ti -n jmeter $(kubectl get po -n jmeter | grep jmeter-master | awk '{print $1}') -- bash
# excute scenario
#sh load_test selenium_chrome_headless_sts.jmx -Gsts=$(hostname -i) -Gcsv=google.csv
#enter slave
# kubectl exec -ti -n jmeter $(kubectl get po -n jmeter | grep jmeter-slave | awk '{print $1}'  | head -n1) -- bash
#Get logs from master
# kubectl cp "jmeter/$(kubectl get po -n jmeter | grep jmeter-master | awk '{print $1}'):/test/jmeter.log" "jmeter.log"
#Get results from master
# kubectl cp "jmeter/$(kubectl get po -n jmeter | grep jmeter-master | awk '{print $1}'):/tmp/results.csv" "results.csv"
