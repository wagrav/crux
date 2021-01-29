
# CRUX JMeter performance framework.

CRUX (pron. kruhks) is build around Kubernetes (AKS) and JMeter. It makes it easy to incorporate performance tests into your Azure CI/CD pipeline. Each performance build can create and destroy infrastructure necessary for the run, which makes it cost effective. 
CRUX deploys a distributed JMeter cluster on Kubernetes (AKS) with the size you need, runs tests, destroys infrastructure. If you do not have an AKS, be at ease, you can also run JMeter tests with CRUX directly on build agent with docker.


![pipeline](https://github.com/ObjectivityLtd/jmeter_azure_k8_boilerplate/blob/master/img/pipeline.png)

### Overview

![overview](https://github.com/ObjectivityLtd/jmeter_azure_k8_boilerplate/blob/master/img/overview.png)


## Features

* the purpose of crux is a self-service tool that makes it easy for DEV teams to incorporate performance testing in their continuous delivery pipelines 
* performance tests can run on AKS cluster or directly on build agent using JMeter Docker containers
* when using AKS it supports dynamic kubernetes cluster creation but works with a static cluster too, see [modes](https://github.com/ObjectivityLtd/crux/wiki/Modes) for details.
* CRUX is tested with [BATS](https://github.com/bats-core/bats-core/), [PESTER](https://pester.dev/) and [ARM-TTK](https://github.com/Azure/arm-ttk) giving you certainty that it all works when things change around you
* CRUX contains Chrome Headless and allows you to use Web Driver Sampler to browser-test "difficult" applications (e.g. Mendix-based apps)
* Simple Table Server is included and ready to use
* You can send Live Data to Azure Insights, Azure Backend listener is included
* JMeter pipeline publishes [JUNIT](https://github.com/ObjectivityLtd/crux/wiki/JMETER-tests-as-JUNIT) results and fails on errors
* CRUX can send data to Azure LogAnalytics that can be analyzed with pre-defined Workbook templates for performance trends and anomalies  

## Setup

See [Installation Page](https://github.com/ObjectivityLtd/crux/wiki/Installation) to get started with CRUX.



