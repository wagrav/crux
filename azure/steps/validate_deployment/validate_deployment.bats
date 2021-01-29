#!/usr/bin/env bash

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash

function setup(){
  source "$BATS_TEST_DIRNAME/validate_deployment.sh"
}
function teardown(){
  :
}

@test "UT:validate_deployment should NOT display warning when max  1 jmeter pod is scheduled on k8 node" {
  local _namespace=default
  kubectl (){
      cat << EOF
NAME                             READY   STATUS    RESTARTS   AGE   IP            NODE                                NOMINATED NODE   READINESS GATES
jmeter-master-56666bc748-xkhdh   1/1     Running   0          20h   10.244.2.21   aks-agentpool-86995916-vmss00000a   <none>           <none>
jmeter-slaves-849b8467b9-nc29g   1/1     Running   0          20h   10.244.1.15   aks-agentpool-86995916-vmss00000b   <none>           <none>
jmeter-slaves-849b8467b9-stwsh   1/1     Running   0          20h   10.244.0.21   aks-agentpool-86995916-vmss00000c   <none>           <none>
jmeter-slaves-849b8467b9-v42wv   1/1     Running   0          20h   10.244.2.22   aks-agentpool-86995916-vmss00000d   <none>           <none>
EOF
  }
  export -f kubectl
  run validate_deployment "$_namespace"
  refute_output --partial "##[warning]"
  unset kubectl
}

@test "UT:validate_deployment should display warning when more than 1 jmeter pod is scheduled on k8 node" {
  local _namespace=default
  kubectl (){
      cat << EOF
NAME                             READY   STATUS    RESTARTS   AGE   IP            NODE                                NOMINATED NODE   READINESS GATES
jmeter-master-56666bc748-xkhdh   1/1     Running   0          20h   10.244.2.21   aks-agentpool-86995916-vmss00000a   <none>           <none>
jmeter-slaves-849b8467b9-nc29g   1/1     Running   0          20h   10.244.1.15   aks-agentpool-86995916-vmss00000b   <none>           <none>
jmeter-slaves-849b8467b9-stwsh   1/1     Running   0          20h   10.244.0.21   aks-agentpool-86995916-vmss00000c   <none>           <none>
jmeter-slaves-849b8467b9-v42wv   1/1     Running   0          20h   10.244.2.22   aks-agentpool-86995916-vmss00000c   <none>           <none>
EOF
  }
  export -f kubectl
  run validate_deployment "$_namespace"
  assert_output --partial "##[warning]"
  unset kubectl
}
