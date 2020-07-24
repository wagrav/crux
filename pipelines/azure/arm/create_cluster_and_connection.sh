#!/bin/bash
create_cluster_and_connection() {
  local deployment_name=$1
  local resource_group=$2
  local template_file=$3
  local node_size=$4
  local node_count=$5
  local cluster_name_prefix=$6
  local output_variable=$7

  local org=$8
  local project=$9
  local user=${10}
  local pat=${11}
  local connection_name=${12}
  local path=${13}


  source "$path"/create_cluster.sh
  create_cluster "$deployment_name" "$resource_group" "$template_file" "$node_size" "$node_count" "$cluster_name_prefix" "$output_variable"

  source "$path"/create_service_connection.sh
  echo "Creating connection for: ${!output_variable}"
  create_service_connection "$org" "$project" "$user" "$pat" "$connection_name" "${!output_variable}" "$resource_group" "$path"

}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  create_cluster_and_connection "$@"
fi