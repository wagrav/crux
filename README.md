
## Setup
You can either create your own cluster during set up or attach to an exisiting one.
Note: Cluster for jmeter should be fully dedicated to Jmeter tests and run no other services.
The commands in here should be executed from Azure CLI

### Creating brand new cluster during set-up:

1. Edit setup_cluster.sh/setVARS and set all required cluster parameters such as # of nodes, location, k8 version ....
2. In Azure CLI set secrets that are required to automatically create k8 connection in Devops e.g. (if you skip this, you will have to create the connection manually)

`vi .bash_profile`

        #!/bin/bash
        export pat=YOUR_PATH

3.Load secrets

  `source bash_profile`

4.Change 'jmeter_azure_k8_boilerplate' and 'jmeter-group' parameters to your own and execute the command

`repo=jmeter_azure_k8_boilerplate && cd ~ && rm -Rf $repo- && git clone  https://github.com/ObjectivityLtd/$repo  && cd $repo/pipelines/azure && bash setup_cluster.sh jmeter-group`

### Attaching to an existing cluster

1. Edit setup_cluster.sh/setVARS and set necessary parameters listed below e.g.:

  * cluster_name=k8
  * cluster_namespace=jmeter
  * kubernetes_version=1.15.10
  * node_count=3 #minimum 3 nodes are required for jmeter
  * git_path=jmeter_azure_k8_boilerplate


2.Change 'jmeter_azure_k8_boilerplate' and 'jmeter-group' parameters to your own and execute the command

`repo=jmeter_azure_k8_boilerplate && cd ~ && rm -Rf $repo- && git clone  https://github.com/ObjectivityLtd/$repo  && cd $repo/pipelines/azure && bash setup_cluster.sh jmeter-group attach_to_existing`
