#!/bin/bash
#edit CONFIG part of this file in your repo, commit. You will need PAT from your devop org. Makeit available as ENV variable $pat
#echo "export pat=your_devops_org_pat" > .bash_profile && source .bash_profile
#execute this in Azure CLI:
#cd ~ && rm -Rf ${git_path} && git clone https://github.com/ObjectivityLtd/${git_path} && cd ${git_path}/pipelines/azure && clear && chmod +x *.sh && ./azure-pipelines.1.azure.agent.kubernetes.sh jmeter-group2

setVARS() {
  #K8 cluster params
  group_name=
  location=uksouth #use location close to your app
  cluster_name=k8
  cluster_namespace=jmeter
  kubernetes_version=1.15.10
  node_size=Standard_D3_v2 #Standard_D2_v2
  node_count=5 #for real test use 5

  #JMeter test params
  test_jmx="test/test.jmx"
  data_file_to_copy=test_data/sample_data.csv #copy to /test on master
  jmeter_user_params="-Gthreads=2"

  #AZURE DEVOPS org details
  devops_org=gstarczewski
  devops_project=jmeter
  devops_service_connection_name=k8con
  devops_user=gstarczewski
  git_path=jmeter_azure_k8_boilerplate

  #formats
  t="\n########################################################################################################\n"
  short="\t\n##### "
}
OK(){
  if [ "$?" == "0" ];then echo " - OK"; else echo " - FAIL"; fi
}
OK_ORFAIL(){
  if [ "$?" == "0" ];then echo " - OK"; else echo " - FAIL";exit 1; fi
}
checkUserProvidedVARS() {
  checkExists(){
    local what=$1
    local describe=$2
    local example_value=$3
    if [ -z "$what" ]; then
    echo "You need to provide your $describe before running this script."
    echo "Run: echo "export $describe=$example_value" > .bash_profile && source .bash_profile"
    exit 1
  fi
  }
  #checking resource_group
  if [ -z "$group_name" ]; then
    echo "Group name not set in script. Trying to fetch from commandline."
    if [ -z "$1" ]; then
      echo "Group name not provided on commandline. Setting to default: jmeter-group"
      group_name=jmeter-group
    else
      group_name=$1
    fi
  fi
  #checking PAT exists
  checkExists "$pat" "pat" "YOUR DEVOPS PAT"
  #checkExists "$git_token" "git_token" "YOUR GIT TOKEN"
}

deleteExistingKubernetesServiceConnection() {
  # Delete service connection if exists
  printf "\n1 Deleting k8 service connection $devops_service_connection_name if exists"
  source bin/delete_service_connection.sh $devops_org $devops_project $devops_user $pat $devops_service_connection_name > /dev/null 2>&1
  OK
}
deleteExistingResourceGroup() {
  # Delete entire resource group if exist:
  printf "2 Deleting group $group_name if exists"
  az group delete -n "$group_name" --yes > /dev/null 2>&1
  OK
}
createResourceGroup(){
  # Create resource group in desired location (it might take a while), use: az account list-locations to list locations
  printf "3 Creating group $group_name in location $location"
  az group create -l "$location" -n "$group_name" > /dev/null 2>&1
  OK
}
createAKSCluster(){
  # Create aks cluster
  printf "4 Creating cluster $group_name/$cluster_name with k8 $kubernetes_version and $node_count nodes of size $node_size"
  az aks create --resource-group "$group_name" --name "$cluster_name" --kubernetes-version "$kubernetes_version" --node-vm-size "$node_size" --node-count "$node_count" --enable-addons monitoring --generate-ssh-keys
  OK_ORFAIL
  # Display nodes
  printf "4 Listing your cluster nodes"
  az aks get-credentials --resource-group "$group_name" --name "$cluster_name" --overwrite-existing > /dev/null 2>&1
  OK
  printf "\n$(kubectl get nodes)\n"
}
createDevOpsKubernetesServiceConnection(){
  # Create service connection in devops org
  printf "\n5 Creating service connection"
  source bin/create_service_connection.sh $devops_org $devops_project $devops_user $pat $devops_service_connection_name $cluster_name $group_name > /dev/null 2>&1
  OK
}
askToContinue(){
  local text=$1
  # Ask if we continue
  printf "$t"
  echo "$text"
  read answer
  echo
}
deployServicesToAKS(){
  # Deploy services
  printf "6 Deploy services to AKS\n"

  local version=$1
  echo $version | egrep "^1.15."
  if [ "$?" != "1" ]; then #v1.15
      cd $HOME/${git_path}/kubernetes/bin && chmod +x *.sh && ./jmeter_cluster_create.sh "$cluster_namespace"
  else #v > 1.15
      cd $HOME/${git_path}/kubernetes/bin && chmod +x *.sh && ./jmeter_cluster_create_v17.sh "$cluster_namespace"
  fi

  OK
  # Wait for all pods to get deployed
  printf "7 Waiting for services to scale\n"
  cd $HOME/${git_path}/pipelines/azure && source bin/wait_for_pods.sh jmeter 1 20 jmeter-master
  OK
}

runVerifcationTest(){
  printf "$t"
  printf "8 Run simple test\n"
  cd $HOME/${git_path}/kubernetes/bin && ./start_test_from_script_params.sh $cluster_namespace $test_jmx $data_file_to_copy "$jmeter_user_params"
  OK
}

displayInfo(){
  local $attach_to_existing_cluster=$1
  printf "$t"
  echo "Congratulations!! It works!"
  printf "$t"
  printf "9  Use this pipeline for start: ${git_path}/pipelines/azure/run.jmeter.kubernetes.yaml"
  if [ -z "$attach_to_existing_cluster" ]; then
    printf "10  You service connection fro DEVOPS portal is $devops_service_connection_name \t\n"
  else
    printf "10 You should now create manually k8 connection in DevOps and use it in pipeline"
  fi
}

run_main(){
  local resource_group=$1
  local attach_to_existing_cluster=$2

  setVARS

  if [ -z "$attach_to_existing_cluster" ]; then #we need to create our own cluster
    echo "Creating our own cluster"
    checkUserProvidedVARS "$resource_group"
    deleteExistingKubernetesServiceConnection
    deleteExistingResourceGroup
    createResourceGroup
    createAKSCluster
    createDevOpsKubernetesServiceConnection
  else
    echo "Attaching to an existing cluster"
  fi
  deployServicesToAKS $kubernetes_version
  runVerifcationTest
  displayInfo "$attach_to_existing_cluster"

}

#script wont fire when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_main "$1" "$2"
fi



