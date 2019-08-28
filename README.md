# IBM StockTrader Application

1.  [Introduction](#introduction)
2.  [Prerequisites](#Prerequisites)
3.  [Installation](#installation)
    - [Get The Code](#get-the-code)
    - [Platform](#platform)
    - [Middleware](#middleware) 
      - [Helm](#helm)
      - [IBM DB2](#ibm-db2)
      - [IBM ODM](#ibm-odm)
      - [Redis](#redis)
    - [Application](#application)
      - [Configure](#configure)
4.  [Verification](#verification)
5.  [Uninstallation](#uninstallation)


## Introduction

The IBM Stock Trader application is a simple stock trading sample where you can create various stock portfolios and add shares of stock to each for a commission. It keeps track of each porfolio's total value and its loyalty level which affects the commission charged per transaction. It sends notifications of changes in loyalty level. It also lets you submit feedback on the application which can result in earning free (zero commission) trades, based on the tone of the feedback.

The overall architecture looks like the following diagram:

<p align="center">
<img alt="st-v2" src="images/stocktrader_v2_no_numbers.png"/>
</p>

Where you can find StockTrader specific microservices in blue and IBM middleware in purple all running on OpenStack Container Platform (OCP).

## Prerequisites

* OpenShift Containr Platform installed

The following installation instructions guide you through installing the dependent software (DB2, Redis, etc) and configuring it for use by the stocktrader application. 


## Installation
### Get The Code

Before anything else, we need to **clone this Github repository** onto our workstations in order to be able to use the scripts, files and tools mentioned throughout this readme. To do so, clone this GitHub repository to a convenient location for you:

```
$ git clone https://github.com/vmware-ibm-jil/stocktrader-jil.git
Cloning into 'stocktrader-jil'...
remote: Enumerating objects: 25, done.
remote: Counting objects: 100% (25/25), done.
remote: Compressing objects: 100% (14/14), done.
remote: Total 142 (delta 3), reused 17 (delta 3), pack-reused 117
Receiving objects: 100% (142/142), 116.13 KiB | 0 bytes/s, done.
Resolving deltas: 100% (23/23), done.
Checking connectivity... done.
```

Afterwards, change directory to `stocktrader-jil` and checkout the stocktrader-jil github repository v1.o branch:

```
$ git checkout v1.0
Switched to branch 'v1.0'
Your branch is up to date with 'origin/v1.0'.
```

### Platform

1. Create a namespace called **stocktrader**. If you don't know how to do so, follow this [link](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0.3/user_management/create_project.html).

2. Change your kubernetes CLI context to work against your **stocktrader** namespace:

```
$ kubectl config set-context cluster.local-context --user=admin --namespace=stocktrader
Context "cluster.local-context" modified.
```
_Use the appropriate user in the above command_

3. Give privileged permissions to your recently created namespace as some the IBM middleware need them to function:

```
$ kubectl create rolebinding -n stocktrader st-rolebinding --clusterrole=privileged  --serviceaccount=stocktrader:default
rolebinding "st-rolebinding" created
$ kubectl get rolebindings                 
NAME             KIND                                       SUBJECTS
st-rolebinding   RoleBinding.v1.rbac.authorization.k8s.io   1 item(s)
```

### Middleware
IBM middleware will be installed using Helm charts as much as possible. Therefore, we need to install the helm first:

#### Helm
Here are the steps to configure the v2.14.1 version helm with Openshift Container Platform:

```
$ oc new-project $TILLER_NAMESPACE
$ export TILLER_NAMESPACE=$TILLER_NAMESPACE
$ oc project $TILLER_NAMESPACE
$ curl -s https://storage.googleapis.com/kubernetes-helm/helm-v2.14.1-linux-amd64.tar.gz | tar xz
$ cd linux-amd64
$ ./helm init --client-only
$ oc process -f https://github.com/openshift/origin/raw/master/examples/helm/tiller-template.yaml -p TILLER_NAMESPACE="${TILLER_NAMESPACE}" -p HELM_VERSION=v2.14.1 | oc create -f -
$ oc rollout status deployment tiller
$ ./helm version
$ oc policy add-role-to-user edit "system:serviceaccount:${TILLER_NAMESPACE}:tiller"
$ oc adm policy add-scc-to-user privileged -n stocktrader -z default
```

Refer this link [Steps to set up the Helm CLI to work with Openshift Container Platform.](https://blog.openshift.com/getting-started-helm-openshift/)

We need to add the IBM Helm chart repository to our local Helm chart repositories:

```
$ helm repo add ibm-charts https://raw.githubusercontent.com/IBM/charts/master/repo/stable/
"ibm-charts" has been added to your repositories
$ helm repo list
NAME                    	URL                                                                                                      
stable                  	https://kubernetes-charts.storage.googleapis.com                                                         
local                   	http://127.0.0.1:8879/charts                                                                             
ibm-charts              	https://raw.githubusercontent.com/IBM/charts/master/repo/stable/
```

(\*) If you don't have a **stable** Helm repo pointing to https://kubernetes-charts.storage.googleapis.com, please add it too using:

```
$ helm repo add stable https://kubernetes-charts.storage.googleapis.com
```

#### IBM DB2

Create a secret that holds your Docker Hub credentials.

```
$ kubectl create secret docker-registry st-docker-registry --docker-username=<userid> --docker-password=<password> --docker-email=<email> --namespace=stocktrader
secret "st-docker-registry" created
```

Here we are going to use the external db2 server.
1. Provision one ubuntu-16.04 VM.
2. Setup docker on this VM. [Steps to setup docker on ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04)
3. Run the following command to setup the containerised DB2:

```
$ sudo docker pull stocktraders/st-db2
$ sudo docker run -itd --name mydb2 --privileged=true -p 50000:50000 -e LICENSE=accept -e DB2INST1_PASSWORD=db2inst1 -e DBNAME=STOCKTRD -v /data:/database stocktraders/st-db2
$ sudo docker exec -ti mydb2 bash -c "su - db2inst1"
```
4. Update this [st_app_values_v2.yaml](installation/st_app_values_v2.yaml) file, replace the value of host to DB2 Server IP in db2 section.

We are set to use external db2 server.

#### Redis

1. Install Redis using the [redis_values.yaml](installation/redis_values.yaml) file:

```
$ helm install -n st-redis --namespace stocktrader stable/redis -f installation/redis_values.yaml
```

**IMPORTANT:** The Redis instance installed is a non-persistent non-HA Redis deployment

#### IBM ODM

1. Install IBM Operational Decision Manager (ODM) using the [odm_values.yaml](installation/odm_values.yaml) file:

```
$ helm install -n st-odm --namespace stocktrader ibm-charts/ibm-odm-dev -f installation/middleware/odm_values.yaml
```

**Note:** For more details to configure the IBM ODM refer this [link](https://github.com/ibm-cloud-architecture/stocktrader-app/tree/v2#ibm-odm)


### Application

The IBM StockTrader Application can be deployed to OpenShift Container Platform (OCP) using Helm charts. All the microservices that make up the application have been packaged into a Helm chart. They could be deployed individually using their Helm chart or they all can be deployed at once using the main umbrella IBM StockTrader Application Helm chart which is stored in this repository under the **chart/stocktrader-app** folder. This Helm chart, along with each IBM StockTrader Application microservice's Helm chart, is latter packaged and stored in the IBM StockTrader Helm chart repository at https://github.com/ibm-cloud-architecture/stocktrader-helm-repo/

As we have done for the middleware pieces installed on the previous section, the IBM StockTrader Application installation will be done by passing the desired values/configuration for some its components through a values file called [st_app_values_v2.yaml](installation/st_app_values_v2.yaml). This way, the IBM StockTrader Application Helm chart is the template/structure/recipe of what components and Kubernetes resources the IBM StockTrader Application is made up of while the [st_app_values_v2.yaml](installation/st_app_values_v2.yaml) file specifies the configuration these need to take based on your credentials, environments, needs, etc.

As a result, we need to look at the [st_app_values_v2.yaml](installation/st_app_values_v2.yaml) file to make sure the middleware configuration matches how we have deployed such middleware in the previous section and **provide the appropriate configuration and credentials for the services the IBM StockTrader Application integrates with**.

Now we look at each of the above points in the [st_app_values_v2.yaml](installation/st_app_values_v2.yaml) file to see what we need to provide.

**IMPORTANT:** The **values for the variables belonging to secrets** in the [st_app_values_v2.yaml](installation/st_app_values_v2.yaml) file **must be base64 encoded**. As a result, whatever the value you want to set the following **secret variables** with, they first need to be encoded using this command:

```
echo -n "<the_value_you_want_to_encode>" | base64
```

`stocktrader.ibm.com` **must be added to your hosts file** to point to your OCP Master node IP.

1. Add the IBM StockTrader Helm repository:

```
$ helm repo add stocktrader https://raw.githubusercontent.com/ibm-cloud-architecture/stocktrader-helm-repo/master/docs/charts
$ helm repo list
NAME                    	URL                                                                                                      
stable                  	https://kubernetes-charts.storage.googleapis.com                                                         
local                   	http://127.0.0.1:8879/charts                                                                             
stocktrader                 https://raw.githubusercontent.com/ibm-cloud-architecture/stocktrader-helm-repo/master/docs/charts                      
ibm-charts              	https://raw.githubusercontent.com/IBM/charts/master/repo/stable/  
```

2. Deploy the IBM StockTrader Application using the [st_app_values_v2.yaml](installation/st_app_values_v2.yaml) file:

**TIP:** Remember you can use the **--set variable=value** to overwrite values within the [st_app_values_v2.yaml](installation/st_app_values_v2.yaml) file.

```
$ helm install -n test --namespace stocktrader -f installation/st_app_values_v2.yaml stocktrader/stocktrader-app --version "0.2.0" --set trader.image.tag=basicregistry
```

## Verification

Here we are going to explain how to quickly verify our IBM StockTrader Application has been successfully deployed and it is working.

1. Check your Helm releases are installed:

```
$ helm list --namespace stocktrader
NAME      REVISION  UPDATED                   STATUS    CHART                           NAMESPACE  
st-odm    1         Tue Jan 22 14:10:33 2019  DEPLOYED  ibm-odm-dev-2.0.0               stocktrader
st-redis  1         Tue Jan 22 20:43:52 2019  DEPLOYED  redis-5.3.0                     stocktrader
test      1         Tue Jan 22 20:36:34 2019  DEPLOYED  stocktrader-app-0.2.0
```

export NODE_PORT=$(kubectl get --namespace stocktrader -o jsonpath="{.spec.ports[1].nodePort}" services trader-service)
export NODE_IP=$(kubectl get nodes --namespace stocktrader -o jsonpath="{.items[0].status.addresses[0].address}")

-- Get the application console link --

```
echo https://$NODE_IP:$NODE_PORT/trader/login
```

## Uninstallation

Since we have used `Helm` to install both the IBM StockTrader Application and the IBM (and third party) middleware the application needs, we then only need to issue the `helm delete <release_name> --purge --tls ` command to get all the pieces installed by a Helm release `<release_name>` uninstalled:

As an example, in order to delete all the IBM StockTrader Application pieces installed by its Helm chart when we installed them as the `test` Helm release:

```
$ helm delete test --purge --tls
release "test" deleted
```