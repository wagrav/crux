
# CRUX JMeter peformance framework.

CRUX (pron. kruhks) is build around kubernetes. On Azure it requires a valid Kubernetes Service Connection to work. It can be easily adjusted to private Kubernetes Clusters or other Cloud Providers. 

### Overview

![overview](https://github.com/ObjectivityLtd/jmeter_azure_k8_boilerplate/blob/master/img/overview.png)

There are 3 pipelines provided to control your deployment. All require prior set-up of Kubernetes Service Connection.

### Pipelines

![pipelines](https://github.com/ObjectivityLtd/jmeter_azure_k8_boilerplate/blob/master/img/pipelines_1.png)

The "run" pipeline which is where your tests happen is easily extensible with Azure Pipeline Steps.

## Features

* based on kubernetes therefore can be implemented on majority of cloud providers and private clusters
* supports dynamic kubernetes cluster creation but works with provided cluster too, see for details.
* framework is tested with [BATS](https://github.com/bats-core/bats-core/) and [ARM-TTK](https://github.com/Azure/arm-ttk) giving you certainty that it all works when things change around you
* solution contains Chrome Headless and allows you to use Web Driver Sampler to browser-test "difficult" applications (e.g. Mendix-based apps)
* Simple Table Server is included and ready to use
* You can send Live Data to Azure Insights, Azure Backend listener is included
* JMeter pipeline publishes JUNIT result and fails on errors
* contains example pipelines you can use and extend  


## Setup

In the first step you need to create a k8 cluster if you do not have one already. Cluster for Jmeter should run no other services.
In the seconds step you create a kubernetes service connection to your cluster in your DevOps. 

### a) Creating brand new cluster via Azure CLI

Execute that in Azure CLI, changing parameters to your needs:

``` 
  #create cluster form CLI
  az group create -l westeurope -n jmeter-group 
  az aks create --resource-group jmeter-group --name k8 --kubernetes-version 1.16.10 --node-vm-size Standard_D3_v2 --node-count 4 --enable-addons monitoring --generate-ssh-keys 
  #show nodes and poded
  az aks get-credentials --resource-group jmeter-group --name k8 --overwrite-existing
  kubectl get no
  kubectl get po
```
Go to DevOps and set up a k8 connection to your cluster.

## b) Attaching to an existing cluster via DevOps k8 connection

To attach to an existing cluster you need a valid Service Connection in DevOps.
Edit the pipeline pipline/azure/attach.to.existing.kubernetes.yaml and set k8 connection name and cluster namespace (if different than default). Run the pipeline to create Jmeter deployment.

## Usage

JMeters test belong to software project they are written for. We recommend you store them in actual software repo. A sample repo to hold your tests can be found in here: https://github.com/ObjectivityLtd/jmeter_simple_test. Fork it, edit:
* run.jmeter.kubernetes.yaml - runs actual tests with selected version of CRUX.
and you are good to go.


There are 2 pipelines supplied in CRUX that you can use for admin activities:

* stop.jmeter.kubernetes.yaml - stops tests gracefully
* attach.to.existing.kubernetes.yaml - redeploys the solution on kubernetes

Edit these pipelines providing k8 connection prior to use.


Happy testing! :) 
