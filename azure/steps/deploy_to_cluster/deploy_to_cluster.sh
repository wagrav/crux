#!/bin/bash
#help functions

_replace_aks_pool_name(){
  local _aks_pool=$1
  local _root_path=$2
  sed -i "s/{{agentpool}}/$_aks_pool/g" "$_root_path"/*.yaml
}

deploy_to_cluster() {
  local _root_path="$1/kubernetes/config/deployments"
  local _cluster_namespace=$2
  local _service_master=$3
  local _service_slave=$4
  local _scale_up_replicas_slave=$5
  local _jmeter_master_deploy_file=$6
  local _jmeter_slaves_deploy_file=$7
  local _sleep_interval=$8
  local _aks_pool=$9
  local _scale_up_replicas_master=1
  local _jmeter_master_configmap_file="jmeter_master_configmap.yaml"
  local _jmeter_shared_volume_file="jmeter_shared_volume.yaml"
  local _jmeter_shared_volume_sc_file="jmeter_shared_volume_sc.yaml"
  local _jmeter_slaves_svc_file="jmeter_slaves_svc.yaml"

  if [ -n "$_aks_pool" ]; then
   _replace_aks_pool_name "$_aks_pool" "$_root_path"
  fi
  echo "Using deployment rules. $_jmeter_master_deploy_file and $_jmeter_slaves_deploy_file"

  if kubectl get deployments -n "$_cluster_namespace" | grep "$_service_master"; then
    echo "Deployments are already present. Skipping new deploy."
  else
    if kubectl get sc -n "$_cluster_namespace" | grep jmeter-shared-disk-sc; then
      echo "Storage class already present. Skipping creation."
    else
      echo "Create storage class."
      kubectl create -n "$_cluster_namespace" -f "$_root_path/$_jmeter_shared_volume_sc_file"
    fi
    kubectl create -n "$_cluster_namespace"  \
                   -f "$_root_path/$_jmeter_shared_volume_file" \
                   -f "$_root_path/$_jmeter_slaves_deploy_file" \
                   -f "$_root_path/$_jmeter_slaves_svc_file" \
                   -f "$_root_path/$_jmeter_master_configmap_file" \
                   -f "$_root_path/$_jmeter_master_deploy_file"
  fi

  echo "Scale up master to $_scale_up_replicas_master and slaves to $_scale_up_replicas_slave"
  kubectl scale -n "$_cluster_namespace" --replicas="$_scale_up_replicas_master" -f "$_root_path/$_jmeter_master_deploy_file"
  kubectl scale -n "$_cluster_namespace" --replicas="$_scale_up_replicas_slave" -f "$_root_path/$_jmeter_slaves_deploy_file"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  deploy_to_cluster "$@"
fi
