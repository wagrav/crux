#!/bin/bash
#help functions

wait_for_pod() {
  service_replicas="0/1"
  service_namespace=$1
  service=$2
  service_replicas_number=$3
  sleep_time_s=$4
  status="Terminating"
  printf "\nWait for service $service pods to be in Running status with interval $sleep_interval"
  until [ "$status" == "Running" ]; do
    sleep $sleep_time_s
    status=$(kubectl -n $service_namespace get po | grep $service | awk '{print $3}' | sort | uniq) # this will display also old pods until they are gone
    printf "\nService $service pods statuses: $(echo $status | xargs)"
  done
}

wait_for_pods() {
  local service_namespace=$1
  local service_replicas_number=$2
  local sleep_time_s=$3
  shift 3
  IFS=' ' read -r -a services <<<"$@"
  for service in "${services[@]}"; do
    wait_for_pod $service_namespace $service $service_replicas_number $sleep_time_s
  done

}

#a bit too many steps but can support both ARM and k8 only
wait_for_cluster_ready(){
  local rootPath=$1
  rootPath="$rootPath"/kubernetes/config/deployments
  local cluster_namespace=$2
  local service_master=$3
  local service_slave=$4
  local scale_up_replicas=$5

  local scale_up_replicas_master=1
  local scale_down_replicas=0
  local sleep_interval=5

  #re-deploy per defaults
  if kubectl get deployments | grep jmeter-master ; then
    echo "Deployments are already present. Skipping new deploy. Use attach.to.existing.kubernetes.yaml if you want to redeploy"
  else
    kubectl create  -n "$cluster_namespace" -f "$rootPath"/jmeter_shared_volume.yaml
    kubectl create  -n "$cluster_namespace" -f "$rootPath"/jmeter_slaves_deploy_v16.yaml
    kubectl create  -n "$cluster_namespace" -f "$rootPath"/jmeter_slaves_svc.yaml
    kubectl create  -n "$cluster_namespace" -f "$rootPath"/jmeter_master_configmap.yaml
    kubectl create  -n "$cluster_namespace" -f "$rootPath"/jmeter_master_deploy_v16.yaml
  fi
  #Wait till ready
  #wait_for_pods "$cluster_namespace" $scale_up_replicas_master $sleep_interval "$service_master"
  echo "Rescaling down and up to assure clean test env "
  echo "Scale to 0 "
  #Assure clean test env by scaling fresh
  kubectl scale -n "$cluster_namespace" --replicas="$scale_down_replicas" -f "$rootPath"/jmeter_master_deploy_v16.yaml
  kubectl scale -n "$cluster_namespace" --replicas="$scale_down_replicas" -f "$rootPath"/jmeter_slaves_deploy_v16.yaml
  echo "Scale up master to $scale_up_replicas_master and slaves to $scale_up_replicas"
  kubectl scale -n "$cluster_namespace" --replicas="$scale_up_replicas_master" -f "$rootPath"/jmeter_master_deploy_v16.yaml
  kubectl scale -n "$cluster_namespace" --replicas="$scale_up_replicas" -f "$rootPath"/jmeter_slaves_deploy_v16.yaml

  wait_for_pods "$cluster_namespace" $scale_up_replicas_master $sleep_interval $service_master
  wait_for_pods "$cluster_namespace" $scale_up_replicas $sleep_interval $service_slave

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  wait_for_cluster_ready "$@"
fi