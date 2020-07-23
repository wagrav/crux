#!/bin/bash
create_service_connection() {
  local org=$1
  local project=$2
  local user=$3
  local pat=$4
  local name=$5
  local cluster_name=$6
  local resource_group=$7

  url=$(az aks show --name $cluster_name --resource-group $resource_group | jq '.fqdn' | sed "s/\"//g") || :
  printf "Creating kubernetes connection $name for cluster: $cluster_name \n\t url: $url"
  source template.json.sh $name $url $cluster_name $resource_group> payload.json
  ls
  echo "Sending payload"
  cat payload.json
  #http_code=$(curl -s -o /dev/null -w "%{http_code}" --user $user:$pat -X POST -H "Content-Type: application/json" --data-binary  @$path/payload.json https://dev.azure.com/$org/$project/_apis/serviceendpoint/endpoints?api-version=5.0-preview.2)
  curl --user $user:$pat -X POST -H "Content-Type: application/json" --data-binary  @payload.json https://dev.azure.com/$org/$project/_apis/serviceendpoint/endpoints?api-version=5.0-preview.2
  echo "Http code: $http_code"
  if [ "$http_code" != "200" ]; then
    echo "Connection $name was not created"
  else
    echo "Connection $name was created. "
  fi
}
create_service_connection "$@"