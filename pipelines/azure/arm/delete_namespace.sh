#!/bin/bash
deleteNamespace(){
  local namespace=$1
  if [ "$namespace" != "default" ];then
    echo "Deleting namespace $cluster_namespace"
    kubectl delete namespace "$namespace"
  fi

}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  deleteNamespace "$@"
fi