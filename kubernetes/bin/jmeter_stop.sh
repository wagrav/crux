#!/usr/bin/env bash
#Script writtent to stop a running jmeter master test
#Kindly ensure you have the necessary kubeconfig

namespace=$1
working_dir=`pwd`

if [ -z "$namespace" ]; then
  #Get namesapce variable
  tenant=`awk '{print $NF}' $working_dir/../tmp/tenant_export`
else
  tenant=namespace
fi
master_pod=`kubectl get po -n $tenant | grep jmeter-master | awk '{print $1}'`

kubectl -n $tenant exec -ti $master_pod bash /jmeter/apache-jmeter-5.3/bin/stoptest.sh
