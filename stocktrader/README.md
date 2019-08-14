# IBM StockTrader Application Version 2

1.  [Introduction](#introduction)
2.  [Installation](#installation)
    - [Get The Code](#get-the-code)
    - [Platform](#platform)
    - [Middleware](#middleware)
      - [IBM DB2](#ibm-db2)
      - [IBM MQ](#ibm-mq)
      - [IBM ODM](#ibm-odm)
      - [Redis](#redis)
    - [Application](#application)
      - [Configure](#configure)
      - [Install](#install)
3.  [Verification](#verification)
4.  [Uninstallation](#uninstallation)
5.  [Files](#files)
6.  [Links](#links)

## Introduction

This branch contains the IBM StockTrader Application Version 2 Helm chart which integrates with the IBM Operational Decision Manager (ODM) as well as with other IBM Cloud Public and third parties services.

The overall architecture looks like the following diagram:

<p align="center">
<img alt="st-v2" src="images/stocktrader_v2_no_numbers.png"/>
</p>

Where you can find StockTrader specific microservices in blue and IBM middleware in purple all running on IBM Cloud Private (ICP), IBM Cloud Public services in green and other third party applications in other different colours.

## Installation

As shown in the IBM StockTrader Application architecture diagram above, the IBM StockTrader Application environment within IBM Cloud Private (ICP) is made up of IBM middleware such as **IBM DB2**, **IBM MQ** and **IBM ODM**, third party applications like **Redis** and the IBM StockTrader Application microservices **Trader**, **Tradr**, **Portfolio**, **Stock-quote**, **Messaging**, **Notification-Twitter** and **Notification-Slack** (last two being, unfortunately, mutually exclusive for now).

In this section, we will outline the steps needed in order to get the aforementioned components installed into IBM Cloud Private (ICP) so that we have a complete functioning IBM StockTrader Application to carry out our test on. We will try to use as much automation as possible as well as Helm charts for installing as many components as possible. Most of this components require a post-installation configuration and tuning too.

**IMPORTANT:** The below installation steps will create Kubernetes resources with names and configurations that the IBM StockTrader Helm chart expects. Therefore, if any of these is changed, the IBM StockTrader Helm installation configuration/details will need to be modified accordingly.

Finally, most of the installation process will be carried out by using the IBM Cloud Private (ICP) CLI. Follow this [link](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0.3/manage_cluster/icp_cli.html) for the installation instructions.

### Get The Code

Before anything else, we need to **clone this Github repository** onto our workstations in order to be able to use the scripts, files and tools mentioned throughout this readme. To do so, clone this GitHub repository to a convenient location for you:

```
$ git clone https://github.com/ibm-cloud-architecture/stocktrader-app.git
Cloning into 'stocktrader-app'...
remote: Counting objects: 163, done.
remote: Compressing objects: 100% (120/120), done.
remote: Total 163 (delta 73), reused 116 (delta 38), pack-reused 0
Receiving objects: 100% (163/163), 8.94 MiB | 1.06 MiB/s, done.
Resolving deltas: 100% (73/73), done.
```

Afterwards, change directory to `stocktrader-app` and checkout the stocktrader-app github repository v2 branch:

```
$ git checkout v2
Switched to branch 'v2'
Your branch is up to date with 'origin/v2'.
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

As previously said, IBM middleware will be installed using Helm charts as much as possible. Therefore, we need to add the IBM Helm chart repository to our local Helm chart repositories:

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

User must be subscribed to [Db2 Developer-C Edition on Docker Hub](https://hub.docker.com/_/db2-developer-c-edition) in order to access the image.

This way, the IBM Db2 Developer-C Edition Helm chart will be able to pull down the IBM Db2 Developer-C Edition Docker image by using your Docker Hub credentials. We need to store your Docker Hub credentials into a Kubernetes secret which the IBM Db2 Developer-C Edition Helm chart will read at installation time.

1. Create a secret that holds your Docker Hub credentials & Db2 Developer-C Edition API key to retrieve the Db2 Developer-C Edition docker image:

```
$ kubectl create secret docker-registry st-docker-registry --docker-username=<userid> --docker-password=<password> --docker-email=<email> --namespace=stocktrader
secret "st-docker-registry" created
$ kubectl get secrets   
NAME                  TYPE                                  DATA      AGE
default-token-t92bq   kubernetes.io/service-account-token   3         51d
st-docker-registry    kubernetes.io/dockercfg               1         28s
```

2. Install IBM Db2 Developer-C Edition using the [db2_values.yaml](installation/middleware/db2_values.yaml) file:

```
$ helm install -n st-db2 --namespace stocktrader --tls ibm-charts/ibm-db2oltp-dev -f installation/middleware/db2_values.yaml
NAME:   st-db2
LAST DEPLOYED: Wed Jun 27 18:49:04 2018
NAMESPACE: stocktrader
STATUS: DEPLOYED

RESOURCES:
==> v1/Secret
NAME                    TYPE    DATA  AGE
st-db2-ibm-db2oltp-dev  Opaque  1     5s

==> v1/PersistentVolumeClaim
NAME               STATUS   VOLUME     CAPACITY  ACCESS MODES  STORAGECLASS  AGE
st-db2-st-db2-pvc  Pending  glusterfs  5s

==> v1/Service
NAME                        TYPE       CLUSTER-IP   EXTERNAL-IP  PORT(S)                                  AGE
st-db2-ibm-db2oltp-dev-db2  NodePort   10.10.10.83  <none>       50000:32329/TCP,55000:31565/TCP          5s
st-db2-ibm-db2oltp-dev      ClusterIP  None         <none>       50000/TCP,55000/TCP,60006/TCP,60007/TCP  5s

==> v1beta2/StatefulSet
NAME                    DESIRED  CURRENT  AGE
st-db2-ibm-db2oltp-dev  1        1        5s

==> v1/Pod(related)
NAME                      READY  STATUS   RESTARTS  AGE
st-db2-ibm-db2oltp-dev-0  0/1    Pending  0         4s


NOTES:
1. Get the database URL by running these commands:
  export NODE_PORT=$(kubectl get --namespace stocktrader -o jsonpath="{.spec.ports[0].nodePort}" services st-db2-ibm-db2oltp-dev)
  export NODE_IP=$(kubectl get nodes --namespace stocktrader -o jsonpath="{.items[0].status.addresses[0].address}")
  echo jdbc:db2://$NODE_IP:$NODE_PORT/sample
```

**Important:** This will install the non HA version of IBM Db2 Developer-C Edition with persistent storage using GlusterFS. If you don't have GlusterFS you can always install IBM DB2 without persistent storage by setting the persistence flag to false: `$ helm install -n st-db2 --namespace stocktrader --tls ibm-charts/ibm-db2oltp-dev -f db2_values.yaml --set persistence.enabled=false`

The command above will take few minutes at least. Monitor the recently created Db2 Developer-C Edition pod, which in our case is called `st-db2-ibm-db2oltp-dev-0`, until you see the following messages:

```
(*) All databases are now active.
(*) Setup has completed.
```
At this point we can be sure the IBM Db2 Developer-C Edition and the **STOCKTRD** database have successfully been installed and created respectively.

3. Now, we need to create the appropriate structure in the **STOCKTRD** database that the IBM StockTrader Application needs. We do so by initialising the database with the [initialise_stocktrader_db_v2.yaml](installation/middleware/initialise_stocktrader_db_v2.yaml) file:

```
$ kubectl apply -f installation/middleware/initialise_stocktrader_db_v2.yaml
job "initialise-stocktrader-db" created
```

The command above created a Kubernetes job which spun up a simple db2express-c container that contains the IBM DB2 tools to execute an sql file against a DB2 database on a remote host. The sql file that gets executed against a DB2 database on a remote host is actually the one that initialises the database with appropriate structures the IBM StockTrader Application needs. The sql file is [initialise_stocktrader_db_v2.sql](installation/middleware/initialise_stocktrader_db_v2.sql).

Check the Kubernetes job to make sure it has finished before moving on:

```
$ kubectl get jobs
NAME                        DESIRED   SUCCESSFUL   AGE
initialise-stocktrader-db   1         1            4m
```

_(\*)The following step is optional. It only makes sense if the IBM StockTrader Application is being installed due to the IBM Cloud Private (ICP) application resiliency work in [here](https://github.com/ibm-cloud-architecture/stocktrader-resiliency)_

4. Finally, we are going to download few util scripts into the IBM Db2 Developer-C recently created container that our resiliency test scripts will make use of as explained in the [test section](https://github.com/ibm-cloud-architecture/stocktrader-resiliency#test) of the IBM StockTrader Application resiliency GitHub repo:

```
$ kubectl exec `kubectl get pods | grep ibm-db2oltp-dev | awk '{print $1}'` \
        -- bash -c "yum -y install wget && cd /tmp && wget https://raw.githubusercontent.com/ibm-cloud-architecture/stocktrader-resiliency/master/test/export.sh \
        && wget https://raw.githubusercontent.com/ibm-cloud-architecture/stocktrader-resiliency/master/test/users.sh && chmod 777 export.sh users.sh"
```

Make sure the scripts have been successfully download:

```
$ kubectl exec `kubectl get pods | grep ibm-db2oltp-dev | awk '{print $1}'` -- bash -c "ls -all /tmp | grep sh"
-rwxrwxrwx. 1 root     root         139 Jun 27 17:48 export.sh
-rwxrwxrwx. 1 root     root          98 Jun 27 17:48 users.sh
```

#### IBM MQ

1. Install MQ using the [mq_values.yaml](installation/middleware/mq_values.yaml) file:

```
$ helm install -n st-mq --namespace stocktrader --tls ibm-charts/ibm-mqadvanced-server-dev -f installation/middleware/mq_values.yaml
NAME:   st-mq
LAST DEPLOYED: Thu Jun 28 16:38:22 2018
NAMESPACE: stocktrader
STATUS: DEPLOYED

RESOURCES:
==> v1/Secret
NAME          TYPE    DATA  AGE
st-mq-ibm-mq  Opaque  1     4s

==> v1/Service
NAME          TYPE      CLUSTER-IP    EXTERNAL-IP  PORT(S)                        AGE
st-mq-ibm-mq  NodePort  10.10.10.133  <none>       9443:31184/TCP,1414:32366/TCP  4s

==> v1beta2/StatefulSet
NAME          DESIRED  CURRENT  AGE
st-mq-ibm-mq  1        1        4s

==> v1/Pod(related)
NAME            READY  STATUS   RESTARTS  AGE
st-mq-ibm-mq-0  0/1    Running  0         4s


NOTES:
MQ can be accessed via port 1414 on the following DNS name from within your cluster:
st-mq-ibm-mq.stocktrader.svc.cluster.local

To get your admin password run:

    MQ_ADMIN_PASSWORD=$(kubectl get secret --namespace stocktrader st-mq-ibm-mq -o jsonpath="{.data.adminPassword}" | base64 --decode; echo)

If you set an app password, you can retrieve it by running the following:

    MQ_APP_PASSWORD=$(kubectl get secret --namespace stocktrader st-mq-ibm-mq -o jsonpath="{.data.appPassword}" | base64 --decode; echo)
```

**IMPORTANT:** The `mq_values.yaml` file used to install the IBM Message Queue Helm chart into our IBM Cloud Private (ICP) cluster is configured to install a non-persistent IBM Message Queue due to some problems between IBM MQ and GlusterFS.

2. We now need to create the **NotificationQ** message queue and the **app** message queue user (with the appropriate permissions). For doing so we need to interact with our IBM Message Queue instance we just deployed above through its web console.

For accessing the IBM MQ web console, we need to

- Grab our IBM Cloud Private (ICP) proxy's IP:

```
$ kubectl get nodes -l proxy=true             
NAME            STATUS    AGE       VERSION
172.16.40.176   Ready     57d       v1.9.1+icp-ee
172.16.40.177   Ready     57d       v1.9.1+icp-ee
172.16.40.178   Ready     57d       v1.9.1+icp-ee
```
In this case, we have three proxy nodes in our IBM Cloud Private (ICP) highly available cluster. We are going to use the first proxy node with IP `172.16.40.176` to access any resource we need within our ICP cluster (bearing in mind we could use any of the others and the result would be the same).

- Grab the NodePort for our recently installed IBM Message Queue instance. We can see that NodePort from the output we obtain when we executed the Helm install command under the services section and right beside the internal **9443** port:

```
==> v1/Service
NAME          TYPE      CLUSTER-IP    EXTERNAL-IP  PORT(S)                        AGE
st-mq-ibm-mq  NodePort  10.10.10.133  <none>       9443:31184/TCP,1414:32366/TCP  4s
```

That is, the NodePort for accessing our IBM MQ deployment from the outside is **31184**

- Access the IBM MQ web console pointing your browser to https://<proxy_ip>:<mq_nodeport>/ibmmq/console

![mq-web-console](images/resiliency1.png)

and using `admin` as the user and `passw0rd` as its password (Anyway, you could also find out what the password is by following the instructions the Helm install command for IBM MQ displayed).

- Once you log into the IBM MQ web console, find out the **Queues on trader** widget/portlet and clieck on `Create` on the top right corner:

<p align="center">
<img alt="create-queue" src="images/resiliency2.png" width="600"/>
</p>

- Enter **NotificationQ** on the dialog that pops up and click create:

<p align="center">
<img alt="queue-name" src="images/resiliency3.png" width="600"/>
</p>

- On the Queues on trader widget/portlet again, click on the dashes icon and then on the **Manage authority records...** option within the dropdown menu:

<p align="center">
<img alt="authority" src="images/resiliency4.png" width="600"/>
</p>

- On the new dialog that opens up, click on **Create** on the top right corner. This will also open up a new dialog to introduce the **Entity name**. Enter **app** as the Entity name and click on create

<p align="center">
<img alt="entity-name" src="images/resiliency5.png" width="600"/>
</p>

- Back to the first dialog that opened up, verify the new app entity appears listed, click on it and select **Browse, Inquire, Get and Put** on the right bottom corner as the MQI permissions for the app entity and click on Save:

<p align="center">
<img alt="mqi-permissions" src="images/resiliency6.png" width="600"/>
</p>

#### Redis

1. Install Redis using the [redis_values.yaml](installation/middleware/redis_values.yaml) file:

**Note:** Make sure to [add an image policy](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.1/manage_images/image_security.html) in ICP console (Manage->Resource Security->Image Policies) to allow pulling images from `docker.io/bitnami/redis:*` registry.

```
$ helm install -n st-redis --namespace stocktrader --tls stable/redis -f installation/middleware/redis_values.yaml
NAME:   st-redis
E0628 18:14:21.431010   11573 portforward.go:303] error copying from remote stream to local connection: readfrom tcp4 127.0.0.1:55225->127.0.0.1:55228: write tcp4 127.0.0.1:55225->127.0.0.1:55228: write: broken pipe
LAST DEPLOYED: Thu Jun 28 18:14:19 2018
NAMESPACE: stocktrader
STATUS: DEPLOYED

RESOURCES:
==> v1/Secret
NAME      TYPE    DATA  AGE
st-redis  Opaque  1     3s

==> v1/Service
NAME             TYPE       CLUSTER-IP    EXTERNAL-IP  PORT(S)   AGE
st-redis-master  ClusterIP  10.10.10.4    <none>       6379/TCP  3s
st-redis-slave   ClusterIP  10.10.10.191  <none>       6379/TCP  3s

==> v1beta1/Deployment
NAME            DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
st-redis-slave  1        1        1           0          3s

==> v1beta2/StatefulSet
NAME             DESIRED  CURRENT  AGE
st-redis-master  1        1        3s

==> v1/Pod(related)
NAME                             READY  STATUS             RESTARTS  AGE
st-redis-slave-5866f6f889-5c2cc  0/1    ContainerCreating  0         3s
st-redis-master-0                0/1    Pending            0         3s


NOTES:
** Please be patient while the chart is being deployed **
Redis can be accessed via port 6379 on the following DNS names from within your cluster:

st-redis-master.stocktrader.svc.cluster.local for read/write operations
st-redis-slave.stocktrader.svc.cluster.local for read-only operations


To get your password run:

    export REDIS_PASSWORD=$(kubectl get secret --namespace stocktrader st-redis -o jsonpath="{.data.redis-password}" | base64 --decode)

To connect to your Redis server:

1. Run a Redis pod that you can use as a client:

   kubectl run --namespace stocktrader st-redis-client --rm --tty -i --restart='Never' \
    --env REDIS_PASSWORD=$REDIS_PASSWORD \
   --image docker.io/bitnami/redis:4.0.12 -- bash

2. Connect using the Redis CLI:
   redis-cli -h st-redis-master -a $REDIS_PASSWORD
   redis-cli -h st-redis-slave -a $REDIS_PASSWORD

To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace stocktrader svc/st-redis 6379:6379 &
    redis-cli -h 127.0.0.1 -p 6379 -a $REDIS_PASSWORD
```

**IMPORTANT:** The Redis instance installed is a non-persistent non-HA Redis Redis deployment

#### IBM ODM

1. Install IBM Operational Decision Manager (ODM) using the [odm_values.yaml](installation/middleware/odm_values.yaml) file:

```
$ helm install -n st-odm --namespace stocktrader --tls ibm-charts/ibm-odm-dev -f installation/middleware/odm_values.yaml
NAME:   st-odm
LAST DEPLOYED: Thu Jun 28 18:53:45 2018
NAMESPACE: stocktrader
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME                       DATA  AGE
st-odm-odm-test-configmap  2     3s

==> v1/Service
NAME                TYPE      CLUSTER-IP   EXTERNAL-IP  PORT(S)         AGE
st-odm-ibm-odm-dev  NodePort  10.10.10.39  <none>       9060:32265/TCP  3s

==> v1beta1/Deployment
NAME                DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
st-odm-ibm-odm-dev  1        1        1           1          3s

==> v1/Pod(related)
NAME                                 READY  STATUS   RESTARTS  AGE
st-odm-ibm-odm-dev-6699d55df5-fv9lv  1/1    Running  0         3s


NOTES:
st-odm is ready to use. st-odm is an instance of the ibm-odm-dev chart.

st-odm uses version 8.10.0.0 of the IBM® Operational Decision Manager (ODM) components.

ODM Information
----------------

Username/Password :
  - For Decision Center : odmAdmin/odmAdmin
  - For Decision Server Console: odmAdmin/odmAdmin
  - For Decision Server Runtime: odmAdmin/odmAdmin
  - For Decision Runner: odmAdmin/odmAdmin

Get the application URLs by running these commands:

  export NODE_PORT=$(kubectl get --namespace stocktrader -o jsonpath="{.spec.ports[0].nodePort}" services st-odm-ibm-odm-dev)
  export NODE_IP=$(kubectl get nodes --namespace stocktrader -o jsonpath="{.items[0].status.addresses[0].address}")

  -- Decision Center Business Console
  echo http://$NODE_IP:$NODE_PORT/decisioncenter

  -- Decision Center Enterprise Server
  echo http://$NODE_IP:$NODE_PORT/teamserver

  -- Decision Server Console
  echo http://$NODE_IP:$NODE_PORT/res

  -- Decision Server Runtime
  echo http://$NODE_IP:$NODE_PORT/DecisionService

  -- Decision Runner
  echo http://$NODE_IP:$NODE_PORT/DecisionRunner

To learn more about the st-odm release, try:

  $ helm status st-odm
  $ helm get st-odm
```

**IMPORTANT:** The IBM Operational Decision Manager (ODM) installed is a non-persistent IBM ODM deployment.

2. We now need to import the already developed loyalty level IBM ODM project which our IBM StockTrader Application will use. To import the such project:

- Download the project from this [link](https://github.com/IBMStockTrader/portfolio/blob/master/stock-trader-loyalty-decision-service.zip)

- Open the IBM Operational Decision Manager by pointing your browser to http://<proxy_ip>:<odm_nodeport> where the `<proxy_ip>` can be obtained as explained in the [IBM MQ installation](#ibm-mq) previous section above and the `<odm_nodeport>` can be obtained under the service section from the output of the Helm install command for IBM ODM above in this section. More precisely, we can see above that in our case `<odm_nodeport>` is **32265**.

![odm](images/resiliency7.png)

- Click on **Decision Center Business Console** and log into it using the credentials from the Helm install command output above (`odmAdmin/odmAdmin`).

- Once you are logged in, click on the arrow on the left top corner to import a new project.

<p align="center">
<img alt="odm-import" src="images/resiliency8.png" width="600"/>
</p>

- On the dialog that pops up, click on `Choose...` and select the **stock-trader-loyalty-decision-service.zip** file you downloaded above. Click on Import.

<p align="center">
<img alt="odm-choose" src="images/resiliency9.png" width="500"/>
</p>

- Once the stock-trader-loyalty-decision-service project is imported, you should be redirected into that project within the **Library section** of the Decision Center Business Console. You should see there an icon that says **main**. Click on it.

![odm-library](images/resiliency10.png)

- The above should have opened the **main** workflow of the stock-trader-loyalty-decision-service project. Now, click on **Deploy** at the top to actually deploy the stock-trader-loyalty-decision-service into the IBM Operational Decision server.

![odm-deploy](images/resiliency11.png)

- A new dialog will pop up with the **specifics** on how to deploy the main branch for the stock-trader-loyalty-decision-service. Leave it as it is and click on Deploy.

<p align="center">
<img alt="odm-deploy-specifics" src="images/resiliency12.png" width="600"/>
</p>

- Finally, you should see a **Deployment status** dialog confirming that the deployment of the stock-trader-loyalty-decision-service project (actually called ICP-Trader-Dev-1) has started. Click OK to close the dialog.

<p align="center">
<img alt="odm-status" src="images/resiliency13.png" width="600"/>
</p>

At this point we should have an instance of the IBM Operation Decision Manager deployed into out IBM Cloud Private (ICP) cluster, the stock-trader-loyalty-decision-service project (actually called ICP-Trader-Dev-1) imported into it and deployed to the Operation Decision server for the IBM StockTrader Application to use it for calculating the loyalty of the portfolios.

In order to make sure of the aforementioned, we are going to poke the IBM ODM endpoint for our loyalty service to see what it returns. To poke the endpoint, execute

```
$ curl -X POST -d '{ "theLoyaltyDecision": { "tradeTotal": 75000 } }' -H "Content-Type: application/json" http://<proxy_ip>:<odm_nodeport>/DecisionService/rest/ICP_Trader_Dev_1/determineLoyalty
```
where we have already explained how to obtain `<proxy_ip>` and `<odm_nodepot>` few steps above.

The `curl` request should return a **SILVER** loyalty on a JSON obsect similar to the following:

```
{"__DecisionID__":"3d18f834-0095-4821-8e1b-157f41ee1ee80","theLoyaltyDecision":{"tradeTotal":75000,"loyalty":"SILVER","message":null}}
```

**We have finally installed all the middleware** the IBM StockTrader Application depends on in order to function properly. Let's now move on to install the IBM StockTrader Application.

### Application

The IBM StockTrader Application can be deployed to IBM Cloud Private (ICP) using Helm charts. All the microservices that make up the application have been packaged into a Helm chart. They could be deployed individually using their Helm chart or they all can be deployed at once using the main umbrella IBM StockTrader Application Helm chart which is stored in this repository under the **chart/stocktrader-app** folder. This Helm chart, along with each IBM StockTrader Application microservice's Helm chart, is latter packaged and stored in the IBM StockTrader Helm chart repository at https://github.com/ibm-cloud-architecture/stocktrader-helm-repo/

As we have done for the middleware pieces installed on the previous section, the IBM StockTrader Application installation will be done by passing the desired values/configuration for some its components through a values file called [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml). This way, the IBM StockTrader Application Helm chart is the template/structure/recipe of what components and Kubernetes resources the IBM StockTrader Application is made up of while the [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml) file specifies the configuration these need to take based on your credentials, environments, needs, etc.

As a result, we need to look at the [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml) file to make sure the middleware configuration matches how we have deployed such middleware in the previous section and **provide the appropriate configuration and credentials for the services the IBM StockTrader Application integrates with**.

#### Configure

The following picture shows the points where we need to provide configuration/credentials for in the [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml) file to successfully install the IBM StockTrader Application:

<p align="center">
<img alt="st-integration" src="images/stocktrader_integration.png"/>
</p>

Now we look at each of the above points in the [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml) file to see what we need to provide.

**IMPORTANT:** The **values for the variables belonging to secrets** in the [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml) file **must be base64 encoded**. As a result, whatever the value you want to set the following **secret variables** with, they first need to be encoded using this command:

```
echo -n "<the_value_you_want_to_encode>" | base64
```

1. **IBMid:** IBMid is the authentication and authorisation provider for the `latest` version (docker image tag) of the Tradr BFF or Trader BFF microservices (there is a `basicregistry` version of the Trader BFF microservice that uses `stock/trader` user/password to gain access to the IBM StockTrader Application which we will talk more about it later in this section).

Here we need to provide our IBMid SSO configuration and credentials which our two Backend For Frontend (BFF) microservices Trader and Tradr will use to authenticate and authorise users through the Open ID Connect (OIDC) protocol. Follow this [link](https://w3-connections.ibm.com/wikis/home?lang=en-us#!/wiki/BlueID%20Single%20Sign-On%20%28SSO%29%20Self-Boarding%20Process/page/SSO%20with%20blueID%20%28IBM%20ID%29) to set your IBMid service instance up. **IMPORTANT:** Please, choose the **blueID PreProduction** identity provider since that is the one to use for testing and also does not require any approval. Also, provide the redirect URIs for the Trader and Tradr BFF microservices as follows respectively:

```
https://stocktrader.ibm.com/ibm/api/social-login/redirect/IBMid
https://stocktrader.ibm.com/tradr/auth/sso/callback
```

where `stocktrader.ibm.com` **must be added to your hosts file** to point to your ICP Proxy node IP (or one of them). In order to find out what are your ICP proxy node(s) IP address(es):

```
$ kubectl get nodes -l proxy=true
NAME            STATUS    AGE       VERSION
172.16.50.173   Ready     18d       v1.10.0+icp-ee
172.16.50.174   Ready     18d       v1.10.0+icp-ee
172.16.50.175   Ready     18d       v1.10.0+icp-ee
```

we are going to use the first one: `172.16.50.173` in our hosts file:

```
$ cat /etc/hosts
##
# Host Database
#
# localhost is used to configure the loopback interface
# when the system is booting.  Do not change this entry.
##
127.0.0.1	localhost
255.255.255.255	broadcasthost
::1             localhost
172.16.50.173   stocktrader.ibm.com
```
(\*) If you don't know how to edit your hosts file, google is plenty of guidance such as this [link](https://www.howtogeek.com/howto/27350/beginner-geek-how-to-edit-your-hosts-file/).

In the [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml) file complete the following configuration/credentials:

```
oidc:
  # Your IBMid SSO ClientId
  id:
  # Your IBMid SSO clientSecret
  secret:
```

Once again, the IBMid provider and the corresponding `oidc` section within the [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml) file needs to be configured if we plan to use the `latest` version of the Tradr BFF or Trader BFF microservices. There is a `basicregistry` version of the Trader BFF microservice that uses `stock/trader` user/password to gain access to the IBM StockTrader Application bypassing IBMid Open ID connect authentication and authorisation mechanism. **Either way, you must configure your hosts file.**

2. **IBM Watson:** One of the use cases the IBM StockTrader Application implements in its version 2 is a feedback mechanism whereby it adjusts the stock quote fee based on users feedback tone analysis. For doing so, the feedback is analysed with the [IBM Watson Tone Analyzer service](https://www.ibm.com/watson/services/tone-analyzer/) wich we need to sign up for. You can sign up and get your credentials to use the IBM Watson Tone Analyzer in this [link](https://console.bluemix.net/catalog/services/tone-analyzer).

In the [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml) file complete the following configuration/credentials:

```
watson:
    id:
    pwd:
```

3. **IBM Functions:** We are using IBM Functions in the IBM StockTrader Application to trigger a loyalty level change notification to the Slack messenger application. As a result, you need to set up a rest callable sequence (PostStatusToSlack) that contains two actions:

<p align="center">
<img alt="ibm-functions" src="images/IBM_Functions.png"/>
</p>

- A NodeJS action (Notify), which will receive the JSON (from the messaging microservice) with the values to output the message we want to post to slack

<p align="center">
<img alt="notify" src="images/notify.png"/>
</p>

- A binding action to Slack that will get configured with the [Slack Incoming WebHook](https://api.slack.com/incoming-webhooks) for the Slack channel the notification will get posted to.

<p align="center">
<img alt="post" src="images/post.png"/>
</p>

For more information on how to create the above, follow this [blog](https://www.ibm.com/developerworks/community/blogs/5092bd93-e659-4f89-8de2-a7ac980487f0/entry/Serverless_computing_and_OpenWhisk?lang=en).

Once you have your IBM Functions flow implemented, complete the following configuration/credentials in the [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml) file:

```
openwhisk:
  url:
  id:
  pwd:
```
4. **Twitter:** The IBM StockTrader Application can also use Twitter to notify portfolio loyalty level changes. In order to get notified in Twitter, you must have a [Twitter account](https://help.twitter.com/en/create-twitter-account) and register/create a [Twitter application](https://developer.twitter.com/en/docs/basics/getting-started) on it which is the one that will tweet on your behalf and the one that the IBM StockTrader application will talk to.

Once you have your Twitter account and Twitter application set up, complete the following configuration/credentials in the [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml) file:

```
twitter:
  consumerKey:
  consumerSecret:
  accessToken:
  accessTokenSecret:
```

5. **Trader:** As previously mentioned in the **IBMid** first point, if we don't want to use the IBMid provider service to authenticate and authorise users through the Open ID Connect protocol, we must specify that the version of the trader BFF that we want to get deployed is the `basicregistry` version. This has to be the value for the **tag** attribute within the [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml) file:

```
trader:
  image:
    tag:
```

(\*) **tag** is set to `basicregistry` by default since we already have the NodeJS Tradr BFF set up to use the IBMid provider service out of the box.

6. **Notification Route:** Finally, we must set the notification route we want the IBM StockTrader Application to use as the endpoints for the portfolio loyalty level change notifications. It can be either **Slack or Twitter**. For selecting one or the other turn the appropriate option to true in the [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml) file:

```
route:
  slack:
    enabled: false
  twitter:
    enabled: false
```
**IMPORTANT:** Unfortunately, the Slack and Twitter notification routes are **mutually exclusive** and **only one can be set to true**.

**TIP:** The above configuration/values in the [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml) file are overwritten by the **--set variable=value** flag if used during the **helm install** command. This way, you don't need to open, modify, save and close the [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml) file everytime you want to install the IBM StockTrader Application. Instead, you could pass the desired values to certain variables using the **--set variable=value** flag as we are now going to see for the IBM StockTrader Application notification route during the install section down below.

#### Install

Now that we are sure our configuration [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml) file looks good for both the middleware, IBM Cloud services and third party integrations, **let's deploy the IBM StockTrader Application!**

1. Add the IBM StockTrader Helm repository:

**Note:** Make sure to [add an image policy](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.1/manage_images/image_security.html) in ICP console (Manage->Resource Security->Image Policies) to allow pulling images from `docker.io/ibmstocktrader/*` registry.

```
$ helm repo add stocktrader https://raw.githubusercontent.com/ibm-cloud-architecture/stocktrader-helm-repo/master/docs/charts
$ helm repo list
NAME                    	URL                                                                                                      
stable                  	https://kubernetes-charts.storage.googleapis.com                                                         
local                   	http://127.0.0.1:8879/charts                                                                             
stocktrader                      	https://raw.githubusercontent.com/ibm-cloud-architecture/stocktrader-helm-repo/master/docs/charts                      
ibm-charts              	https://raw.githubusercontent.com/IBM/charts/master/repo/stable/  
```

2. Deploy the IBM StockTrader Application using the [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml) file:

**TIP:** Remember you can use the **--set variable=value** to overwrite values within the [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml) file.

```
$ helm install -n test --tls --namespace stocktrader -f installation/application/st_app_values_v2.yaml stocktrader/stocktrader-app --version "0.2.0" --set route.twitter.enabled=true --set trader.image.tag=basicregistry
NAME:   test
LAST DEPLOYED: Mon Jul  2 13:39:28 2018
NAMESPACE: stocktrader
STATUS: DEPLOYED

RESOURCES:
==> v1/Secret
NAME                       TYPE    DATA  AGE
stocktrader-db2            Opaque  5     4s
strocktrader-ingress-host  Opaque  1     4s
stocktrader-jwt            Opaque  2     4s
stocktrader-mq             Opaque  7     4s
stocktrader-odm            Opaque  1     4s
stocktrader-oidc           Opaque  8     4s
stocktrader-redis          Opaque  2     4s
stocktrader-twitter        Opaque  4     4s
stocktrader-watson         Opaque  3     4s

==> v1/Service
NAME                  TYPE       CLUSTER-IP    EXTERNAL-IP  PORT(S)                        AGE
notification-service  ClusterIP  10.10.10.171  <none>       9080/TCP,9443/TCP              4s
portfolio-service     ClusterIP  10.10.10.105  <none>       9080/TCP,9443/TCP              4s
stock-quote-service   ClusterIP  10.10.10.210  <none>       9080/TCP,9443/TCP              4s
trader-service        NodePort   10.10.10.22   <none>       9080:31507/TCP,9443:32370/TCP  4s
tradr-service         NodePort   10.10.10.58   <none>       3000:31007/TCP                 4s

==> v1beta1/Deployment
NAME                       DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
test-messaging             1        1        1           0          4s
test-notification-twitter  1        1        1           0          4s
test-portfolio             1        1        1           0          4s
test-stock-quote           1        1        1           0          4s
test-trader                1        1        1           1          4s
test-tradr                 1        1        1           1          4s

==> v1beta1/Ingress
NAME            HOSTS  ADDRESS  PORTS  AGE
test-portfolio  *      80       4s
test-trader     *      80       4s
test-tradr      *      80       4s

==> v1/Pod(related)
NAME                                        READY  STATUS             RESTARTS  AGE
test-messaging-644ccbcd95-mwkjh             0/1    ContainerCreating  0         4s
test-notification-twitter-6dd5f9d7dc-bsfs7  0/1    ContainerCreating  0         4s
test-portfolio-75b4dbd485-k6rq4             0/1    ContainerCreating  0         4s
test-stock-quote-7679899d76-rgkwr           0/1    ContainerCreating  0         4s
test-trader-5446499c5b-ldkjk                1/1    Running            0         4s
test-tradr-548b58bc55-jjr4c                 1/1    Running            0         4s
```

(\*) As you can figure by the install command and the IBM StockTrader Application components we've got deployed, we chose the Twitter notification route. Hence, we've got deployed a secret called `stocktrader-twitter` and a deployment plus its corresponding pod(s) called `test-notification-twitter` as opposed to a secret called `stocktrader-openwhisk` and a deployment plus its corresponding pod(s) called `test-notification-slack`.

## Verification

Here we are going to explain how to quickly verify our IBM StockTrader Application has been successfully deployed and it is working. This verification will not cover any potential issue occurred during the installation process above as we understand it is out of the scope of this work. We sort of assume the "happy path" applies.

1. Check your Helm releases are installed:

```
$ helm list --namespace stocktrader --tls
NAME      REVISION  UPDATED                   STATUS    CHART                           NAMESPACE  
st-db2    1         Tue Jan 22 10:47:36 2019  DEPLOYED  ibm-db2oltp-dev-3.2.0           stocktrader
st-mq     1         Tue Jan 22 11:16:26 2019  DEPLOYED  ibm-mqadvanced-server-dev-2.2.0 stocktrader
st-odm    1         Tue Jan 22 14:10:33 2019  DEPLOYED  ibm-odm-dev-2.0.0               stocktrader
st-redis  1         Tue Jan 22 20:43:52 2019  DEPLOYED  redis-5.3.0                     stocktrader
test      1         Tue Jan 22 20:36:34 2019  DEPLOYED  stocktrader-app-0.2.0           stocktrader
```

2. Check all the Kubernetes resources created and deployed by the Helm charts from the Helm releases above, specially the Kubernetes pods, are all `Running` and looking good:

```
$ kubectl get all
NAME                                            READY     STATUS    RESTARTS   AGE
po/st-db2-ibm-db2oltp-dev-0                     1/1       Running   0          4d
po/st-mq-ibm-mq-0                               1/1       Running   0          3d
po/st-odm-ibm-odm-dev-6699d55df5-fv9lv          1/1       Running   0          3d
po/st-redis-master-0                            1/1       Running   0          3d
po/st-redis-slave-5866f6f889-fkstr              1/1       Running   0          3d
po/test-messaging-644ccbcd95-mwkjh              1/1       Running   0          10m
po/test-notification-twitter-6dd5f9d7dc-bsfs7   1/1       Running   0          10m
po/test-portfolio-75b4dbd485-k6rq4              1/1       Running   0          10m
po/test-stock-quote-7679899d76-rgkwr            1/1       Running   0          10m
po/test-trader-5446499c5b-ldkjk                 1/1       Running   0          10m
po/test-tradr-548b58bc55-jjr4c                  1/1       Running   0          10m

NAME                                      CLUSTER-IP     EXTERNAL-IP   PORT(S)                                   AGE
svc/glusterfs-dynamic-st-db2-st-db2-pvc   10.10.10.6     <none>        1/TCP                                     20d
svc/notification-service                  10.10.10.171   <none>        9080/TCP,9443/TCP                         10m
svc/portfolio-service                     10.10.10.105   <none>        9080/TCP,9443/TCP                         10m
svc/st-db2-ibm-db2oltp-dev                None           <none>        50000/TCP,55000/TCP,60006/TCP,60007/TCP   4d
svc/st-db2-ibm-db2oltp-dev-db2            10.10.10.83    <nodes>       50000:32329/TCP,55000:31565/TCP           4d
svc/st-mq-ibm-mq                          10.10.10.133   <nodes>       9443:31184/TCP,1414:32366/TCP             3d
svc/st-odm-ibm-odm-dev                    10.10.10.39    <nodes>       9060:31101/TCP                            3d
svc/st-redis-master                       10.10.10.208   <none>        6379/TCP                                  3d
svc/st-redis-slave                        10.10.10.195   <none>        6379/TCP                                  3d
svc/stock-quote-service                   10.10.10.210   <none>        9080/TCP,9443/TCP                         10m
svc/trader-service                        10.10.10.22    <nodes>       9080:31507/TCP,9443:32370/TCP             10m
svc/tradr-service                         10.10.10.58    <nodes>       3000:31007/TCP                            10m

NAME                                  KIND
statefulsets/st-db2-ibm-db2oltp-dev   StatefulSet.v1.apps
statefulsets/st-mq-ibm-mq             StatefulSet.v1.apps
statefulsets/st-redis-master          StatefulSet.v1.apps

NAME                             DESIRED   SUCCESSFUL   AGE
jobs/initialise-stocktrader-db   1         1            4d

NAME                               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/st-odm-ibm-odm-dev          1         1         1            1           3d
deploy/st-redis-slave              1         1         1            1           3d
deploy/test-messaging              1         1         1            1           10m
deploy/test-notification-twitter   1         1         1            1           10m
deploy/test-portfolio              1         1         1            1           10m
deploy/test-stock-quote            1         1         1            1           10m
deploy/test-trader                 1         1         1            1           10m
deploy/test-tradr                  1         1         1            1           10m

NAME                                      DESIRED   CURRENT   READY     AGE
rs/st-odm-ibm-odm-dev-6699d55df5          1         1         1         3d
rs/st-redis-slave-5866f6f889              1         1         1         3d
rs/test-messaging-644ccbcd95              1         1         1         10m
rs/test-notification-twitter-6dd5f9d7dc   1         1         1         10m
rs/test-portfolio-75b4dbd485              1         1         1         10m
rs/test-stock-quote-7679899d76            1         1         1         10m
rs/test-trader-5446499c5b                 1         1         1         10m
rs/test-tradr-548b58bc55                  1         1         1         10m
```

(\*) Again, we chose the Twitter notification route. Hence, we've got deployed a secret called `stocktrader-twitter` and a deployment plus its corresponding pod(s) called `test-notification-twitter` as opposed to a secret called `stocktrader-openwhisk` and a deployment plus its corresponding pod(s) called `test-notification-slack` if we had chosen the Slack notification route.

3. Open the IBM StockTrader Application by pointing your browser to `https://stocktrader.ibm.com/trader/login`

<p align="center">
<img alt="st-login" src="images/resiliency14.png" width="500"/>
</p>

**IMPORTANT:** Depending on what version of the **Trader** microservice (`basicregistry` or `latest`) you have deployed, the login screen will look differently. In the image above, we are showing the "simplest" path which is using the `basicregistry` version.

4. Log into the IBM StockTrader Application using User ID `stock` and Password `trader`:

<p align="center">
<img alt="st-app" src="images/resiliency15.png" width="500"/>
</p>

**IMPORTANT:** Again, based on the **Trader** BFF microservice version you deploy, you will use the aforementioned credentials or your IBMid credentials.

5. Click on Create a new portfolio and submit in order to create a test portfolio. Introduce the name for the portfolio you like the most and click on submit:

<p align="center">
<img alt="st-create" src="images/resiliency16.png" width="500"/>
</p>

6. With your newly created portfolio selected, click on Update selected portfolio (add stock) and submit. Then, introduce `IBM` and `400` for the Stock Symbol and Number of Shares fields respectively and click submit:

<p align="center">
<img alt="st-add" src="images/resiliency17.png" width="500"/>
</p>

7. Your IBM StockTrader application should now have a portfolio with 400 IBM shares:

<p align="center">
<img alt="st-summary" src="images/resiliency18.png" width="500"/>
</p>

8. Since we have added enough stock to advance our portfolio to a higher Loyalty Level (SILVER), we should have got a new tweet on our twitter account to notify us of such a change:

<p align="center">
<img alt="st-twitter" src="images/resiliency19.png" width="500"/>
</p>

If we had chosen the Slack notification route, we would have got a Slack message on the Slack channel we had configured it for similar to:

<p align="center">
<img alt="verification-slack" src="images/verification-slack.png" width="500"/>
</p>

9. If we had configured the IBMid provider service appropriately, we should see the most modern NodeJS based version of the IBM StockTrader Application by pointing our web browser to https://stocktrader.ibm.com/tradr and logging into the IBMid provider service:

<p align="center">
<img alt="st-tradr" src="images/resiliency20.png"/>
</p>

## Uninstallation

Since we have used `Helm` to install both the IBM StockTrader Application and the IBM (and third party) middleware the application needs, we then only need to issue the `helm delete <release_name> --purge --tls ` command to get all the pieces installed by a Helm release `<release_name>` uninstalled:

As an example, in order to delete all the IBM StockTrader Application pieces installed by its Helm chart when we installed them as the `test` Helm release:

```
$ helm delete test --purge --tls
release "test" deleted
```

If we now look at what we have running on our `stocktrader` namespace within our IBM Cloud Private (ICP) cluster, we should not see any of the pieces belonging to the IBM StockTrader Application Helm chart:

```
$ kubectl get all
NAME                                     READY     STATUS    RESTARTS   AGE
po/st-db2-ibm-db2oltp-dev-0              1/1       Running   0          4d
po/st-mq-ibm-mq-0                        1/1       Running   0          3d
po/st-odm-ibm-odm-dev-6699d55df5-fv9lv   1/1       Running   0          3d
po/st-redis-master-0                     1/1       Running   0          3d
po/st-redis-slave-5866f6f889-fkstr       1/1       Running   0          3d

NAME                                      CLUSTER-IP     EXTERNAL-IP   PORT(S)                                   AGE
svc/glusterfs-dynamic-st-db2-st-db2-pvc   10.10.10.6     <none>        1/TCP                                     20d
svc/st-db2-ibm-db2oltp-dev                None           <none>        50000/TCP,55000/TCP,60006/TCP,60007/TCP   4d
svc/st-db2-ibm-db2oltp-dev-db2            10.10.10.83    <nodes>       50000:32329/TCP,55000:31565/TCP           4d
svc/st-mq-ibm-mq                          10.10.10.133   <nodes>       9443:31184/TCP,1414:32366/TCP             3d
svc/st-odm-ibm-odm-dev                    10.10.10.39    <nodes>       9060:31101/TCP                            3d
svc/st-redis-master                       10.10.10.208   <none>        6379/TCP                                  3d
svc/st-redis-slave                        10.10.10.195   <none>        6379/TCP                                  3d

NAME                                  KIND
statefulsets/st-db2-ibm-db2oltp-dev   StatefulSet.v1.apps
statefulsets/st-mq-ibm-mq             StatefulSet.v1.apps
statefulsets/st-redis-master          StatefulSet.v1.apps

NAME                             DESIRED   SUCCESSFUL   AGE
jobs/initialise-stocktrader-db   1         1            4d

NAME                        DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/st-odm-ibm-odm-dev   1         1         1            1           3d
deploy/st-redis-slave       1         1         1            1           3d

NAME                               DESIRED   CURRENT   READY     AGE
rs/st-odm-ibm-odm-dev-6699d55df5   1         1         1         3d
rs/st-redis-slave-5866f6f889       1         1         1         3d
```

and, of course, the Helm release should not be listed either:

```
$ helm list --namespace stocktrader --tls
NAME          	REVISION	UPDATED                 	STATUS  	CHART                          	NAMESPACE     
st-db2        	1       	Wed Jun 27 18:49:04 2018	DEPLOYED	ibm-db2oltp-dev-3.0.0          	stocktrader
st-mq         	1       	Thu Jun 28 16:38:22 2018	DEPLOYED	ibm-mqadvanced-server-dev-1.3.0	stocktrader
st-odm        	1       	Thu Jun 28 18:53:45 2018	DEPLOYED	ibm-odm-dev-1.0.0              	stocktrader
st-redis      	1       	Thu Jun 28 18:20:55 2018	DEPLOYED	redis-3.3.6                    	stocktrader
```

If you wanted to clean your entire `stocktrader` namespace, you would need to delete the other Helm releases too: `st-mq`, `st-db2`, `st-odm` and `st-redis`.

## Files

This section will describe each of the files presented in this repository.

#### chart/stocktrader-app

This folder contains the IBM StockTrader Application version 2 Helm chart. In here, you can find the usual [Helm chart folder structure and yaml files](https://docs.helm.sh/developing_charts/).

#### images

This folder contains the images used for this README file.

#### installation - application

- [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml): Default IBM StockTrader version 2 Helm chart values file.

#### installation - middleware

- [db2_values.yaml](installation/middleware/db2_values.yaml): tailored IBM DB2 Helm chart values file with the default values that the IBM StockTrader Helm chart expects.
- [initialise_stocktrader_db_v2.sql](installation/middleware/initialise_stocktrader_db_v2.sql): initialises the IBM StockTrader version 2 database with the appropriate structure for the application to work properly.
- [initialise_stocktrader_db_v2.yaml](installation/middleware/initialise_stocktrader_db_v2.yaml): Kubernetes job that pulls [initialise_stocktrader_db_v2.sql](installation/middleware/initialise_stocktrader_db_v2.sql) to initialise the IBM StockTrader version 2 database.
- [mq_values.yaml](installation/middleware/mq_values.yaml): tailored IBM MQ Helm chart values file with the default values that the IBM StockTrader Helm chart expects.
- [redis_values.yaml](installation/middleware/master/redis_values.yaml): tailored Redis Helm chart values file with the default values that the IBM StockTrader Helm chart expects.
- [odm_values.yaml](installation/middleware/odm_values.yaml): tailored IBM Operation Decision Manager (ODM) Helm chart values file with the default values that the IBM StockTrader Helm chart expects.

## Links

This section gathers all links to IBM StockTrader application sort of documentation.

- [Building Stock Trader in IBM Cloud Private 2.1 using Production Services](https://www.ibm.com/developerworks/community/blogs/5092bd93-e659-4f89-8de2-a7ac980487f0/entry/Building_Stock_Trader_in_IBM_Cloud_Private_2_1_using_Production_Services?lang=en)

- [Official IBM StockTrader Application GitHub repository](https://github.com/IBMStockTrader)

- [IBM Cloud private: Continuously Deliver Java Apps with IBM Cloud private and Middleware Services (video)](https://www.youtube.com/watch?v=ctuUTDIClms&feature=youtu.be)

- [Introducing IBM Cloud Private](https://www.ibm.com/developerworks/community/blogs/5092bd93-e659-4f89-8de2-a7ac980487f0/entry/Introducing_IBM_Cloud_private?lang=en)

- [Build and Continuously Deliver a Java Microservices App in IBM Cloud private](https://www.ibm.com/developerworks/community/blogs/5092bd93-e659-4f89-8de2-a7ac980487f0/entry/Build_and_Continuously_Deliver_a_Java_Microservices_App_in_IBM_Cloud_private?lang=en)

- [Developing Microservices for IBM Cloud Private](https://www.ibm.com/developerworks/community/blogs/5092bd93-e659-4f89-8de2-a7ac980487f0/entry/Developing_microservices_for_IBM_Cloud_private?lang=en)

- [Use Kubernetes Secrets to Make Your App Portable Across Clouds](https://developer.ibm.com/recipes/tutorials/use-kubernetes-secrets-to-make-your-app-portable-across-clouds/)

- [Deploy MQ-Dev into IBM Cloud Private 2.1](https://developer.ibm.com/recipes/tutorials/deploy-mq-into-ibm-cloud-private/)

- [Db2 Integration into IBM Cloud Private](https://developer.ibm.com/recipes/tutorials/db2-integration-into-ibm-cloud-private/)
