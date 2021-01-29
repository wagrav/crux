#!/bin/bash
validate_configuration() {
      local _mode="$1"
      local _arm_service_connection="$2"
      local _kubernetes_service_connection="$3"
      local _link="$4"
      local _check_arm_connection=false
      local _check_k8_connection=false
      local _check_dockerhub_connection=false

      echo "You have chosen to run CRUX in '$_mode' _mode."
      if [ "$_mode" == 'on_aks' ];then
        _check_k8_connection=true
      elif [ "$_mode" == 'on_aks_created_for_each_test_run' ];then
        _check_arm_connection=true
      elif [ "$_mode" == 'on_aks_pool_created_for_each_test_run' ];then
        _check_arm_connection=true
        _check_k8_connection=true
      elif [ "$_mode" == 'tests' ];then
        _check_dockerhub_connection=true
      elif [ "$_mode" == 'on_build_agent' ];then
        : #nothing required
      else
        echo "##[error] Unrecognized mode. Use one of jmeter|on_aks_created_for_each_test_run|tests. [$_link]"
        echo "##vso[task.complete result=Failed]current operation"
      fi
      if [ "$_check_arm_connection" == "true" ];then
          if [ "$_arm_service_connection" == "_" ];then
            message="ARM Connection is set to default '$_arm_service_connection'. Please create a correct ARM Connection to your resource group and update your pipeline."
            echo "##vso[task.logissue type=error]$message [$_link]"
            exit 1
          else
            echo "##[command] Required ARM Service Connection has been provided - OK"
          fi
      fi
      if [ "$_check_k8_connection" == "true" ];then
          if [ "$_kubernetes_service_connection" == "_" ];then
            message="Kubernetes Service Connection is set to default '$_kubernetes_service_connection'. Please create a correct connection to your cluster and update your pipeline."
            echo "##vso[task.logissue type=error]$message [$_link]"
            exit 1
          else
            echo "##[command] Required Kubernetes Service Connection has been provided - OK"
          fi
      fi

}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  validate_configuration "$@"
fi