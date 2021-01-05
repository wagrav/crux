#!/bin/bash
delete_volume() { #public: deletes PVC
  local _cluster_namespace=$1
  local _pv=$(kubectl get pv --namespace $(_cluster_namespace) -o=jsonpath='{.items[0].metadata.name}')
  kubectl delete $(_crux_cluster_deployment_namespace) "pv/$_pv"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  delete_volume "$@"
fi
