#!/bin/bash
validate_deployment() { #public: #display warning message if deployment is not correct e.g. more pods on nodes than allowed
  local _cluster_namespace=$1
  printf "$(kubectl -n "$_cluster_namespace" get pods -o wide)" "$(kubectl -n "$_cluster_namespace" get svc)"
  local _pods_nodes="$(kubectl get -n "$_cluster_namespace" pods -o wide | awk '{print $7}')"
  local _pods_deployed_count="$(echo "$_pods_nodes" | wc -l)"
  local _nodes_used_count="$(echo "$_pods_nodes" | sort | uniq | wc -l)"
  #more pods scheduled than nodes in cluster
  echo "$_pods_deployed_count $__nodes_used_count"
  if [ "$_pods_deployed_count" -gt "$_nodes_used_count" ]; then
    echo "##[warning]There are more jmeter pods scheduled than nodes. You should not do that! Read why https://github.com/ObjectivityLtd/crux/wiki/FAQ"
    echo "##vso[task.complete result=SucceededWithIssues;]DONE"
  fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  validate_deployment "$@"
fi