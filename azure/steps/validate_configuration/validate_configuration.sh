#!/bin/bash
validate_configuration() {
      local mode="$1"
      local armServiceConnection="$2"
      local kubernetesServiceConnection="$3"
      local link="$4"
      check_arm_connection=false
      check_k8_connection=false
      check_dockerhub_connection=false

      echo "You have chosen to run CRUX in '$mode' mode."
      if [ "$mode" == 'on_aks' ];then
        check_k8_connection=true
      elif [ "$mode" == 'on_aks_created_for_each_test_run' ];then
        check_arm_connection=true
      elif [ "$mode" == 'on_aks_pool_created_for_each_test_run' ];then
        check_arm_connection=true
        check_k8_connection=true
      elif [ "$mode" == 'tests' ];then
        check_dockerhub_connection=true
      elif [ "$mode" == 'on_build_agent' ];then
        : #nothing required
      else
        echo "##[error] Unrecognized mode. Use one of jmeter|on_aks_created_for_each_test_run|tests. [$link]"
        echo "##vso[task.complete result=Failed]current operation"
      fi
      if [ "$check_arm_connection" == "true" ];then
          if [ "$armServiceConnection" == "_" ];then
            message="ARM Connection is set to default '$armServiceConnection'. Please create a correct ARM Connection to your resource group and update your pipeline."
            echo "##vso[task.logissue type=error]$message [$link]"
            exit 1
          else
            echo "##[command] Required ARM Service Connection has been provided - OK"
          fi
      fi
      if [ "$check_k8_connection" == "true" ];then
          if [ "$kubernetesServiceConnection" == "_" ];then
            message="Kubernetes Service Connection is set to default '$kubernetesServiceConnection'. Please create a correct connection to your cluster and update your pipeline."
            echo "##vso[task.logissue type=error]$message [$link]"
            exit 1
          else
            echo "##[command] Required Kubernetes Service Connection has been provided - OK"
          fi
      fi

}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  validate_configuration "$@"
fi