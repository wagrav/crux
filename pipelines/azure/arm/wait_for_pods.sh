#!/bin/bash
#help functions

wait_for_pod() {
  service_replicas="0/1"
  service_namespace=$1
  service=$2
  service_replicas_number=$3
  sleep_time_s=$4

  until [ "$service_replicas" == "$service_replicas_number/$service_replicas_number" ]; do
    printf "\n\tWait for service $service to scale to $service_replicas_number for $sleep_time_s seconds"
    sleep $sleep_time_s
    service_replicas=$(kubectl -n $service_namespace get all | grep deployment.apps/$service | awk '{print $2}')
    printf "\n\tService $service_name pods ready: $service_replicas\n"
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
  local sleep_interval=20

  #Deploy per defaults
  kubectl create  -n "$cluster_namespace" -f "$rootPath"/jmeter_slaves_deploy_v16.yaml
  kubectl create  -n "$cluster_namespace" -f "$rootPath"/jmeter_slaves_svc.yaml
  kubectl create  -n "$cluster_namespace" -f "$rootPath"/jmeter_master_configmap.yaml
  kubectl create  -n "$cluster_namespace" -f "$rootPath"/jmeter_master_deploy_v16.yaml
  #Wait till ready
  wait_for_pods "$cluster_namespace" $scale_up_replicas_master $sleep_interval "$service_master"

  #Assure clean test env by scaling fresh
  kubectl scale -n "$cluster_namespace" --replicas="$scale_down_replicas" -f "$rootPath"/jmeter_master_deploy_v16.yaml
  kubectl scale -n "$cluster_namespace" --replicas="$scale_down_replicas" -f "$rootPath"/jmeter_slaves_deploy_v16.yaml
  kubectl scale -n "$cluster_namespace" --replicas="$scale_up_replicas_master" -f "$rootPath"/jmeter_master_deploy_v16.yaml
  kubectl scale -n "$cluster_namespace" --replicas="$scale_up_replicas" -f "$rootPath"/jmeter_slaves_deploy_v16.yaml

  wait_for_pods "$cluster_namespace" $scale_up_replicas_master $sleep_interval $service_master
  wait_for_pods "$cluster_namespace" $scale_up_replicas $sleep_interval $service_slave

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  wait_for_cluster_ready "$@"
fi