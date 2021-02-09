#!/bin/bash

_wait_for_pod() { #public: wait for pods of a given type to be in Running state
  local _service_replicas="0/1"
  local _service_namespace=$1
  local _service=$2
  local _service_replicas_number=$3
  local _sleep_time_s=$4
  local _status="Terminating"
  echo "Wait for service $_service pods to be in Running status with interval $_sleep_time_s"
  until [[ "$_status" == "Running" ]]; do
    sleep "$_sleep_time_s"
    _status="$( \
      kubectl -n "$_service_namespace" get po \
      | grep "$_service" \
      | awk '{print $3}' \
      | sort \
      | uniq)" # this will display also old pods until they are gone
    echo "Service $_service pods statuses: $(echo "$_status" | xargs)"
  done
  kubectl -n "$_service_namespace" get all
}

_wait_for_pods() { #public: waits for pods to be running for a list of services
  local _service_namespace=$1
  local _service_replicas_number=$2
  local _sleep_time_s=$3
  shift 3
  IFS=' ' read -r -a _services <<<"$@"
  for _service in "${_services[@]}"; do
    _wait_for_pod "$_service_namespace" "$_service" "$_service_replicas_number" "$_sleep_time_s"
  done

}

wait_for_cluster_ready() { #public: waits until cluster ready
    local _cluster_namespace=$1
    local _sleep_interval=$2
    local _master_service=$3
    local _slave_service=$4
    local _master_service_replicas=$5
    local _slave_service_replicas=$6
    _wait_for_pods "$_cluster_namespace" "$_master_service_replicas" "$_sleep_interval" "$_master_service"
    _wait_for_pods "$_cluster_namespace" "$_slave_service_replicas" "$_sleep_interval" "$_slave_service"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  wait_for_cluster_ready "$@"
fi