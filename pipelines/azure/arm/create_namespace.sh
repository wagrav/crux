#!/bin/bash
create_namespace(){
  local namespace=$1
    #create namespace
  if kubectl get namespaces | grep "$cluster_namespace" ; then
    echo "Namespace $cluster_namespace already present"
  else
    echo "Creating namespace $cluster_namespace"
    kubectl create namespace "$namespace"
  fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  create_namespace "$@"
fi