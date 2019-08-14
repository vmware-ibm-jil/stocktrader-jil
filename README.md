# IBM StockTrader Application

## Introduction

The IBM Stock Trader application is a simple stock trading sample where you can create various stock portfolios and add shares of stock to each for a commission. It keeps track of each porfolio's total value and its loyalty level which affects the commission charged per transaction. It sends notifications of changes in loyalty level. It also lets you submit feedback on the application which can result in earning free (zero commission) trades, based on the tone of the feedback.


## Prerequisites

* IBM Cloud Private or OpenShift Containr Platform installed
* IBM Cloud public account (trial account can be used)

The following installation instructions guide you through installing the dependent software (DB2, MQ, etc) and configuring it for use by the stocktrader application. 

## Install stocktrader Helm chart

1. [Set up the Helm CLI to work with IBM Cloud Private.](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0.3/app_center/create_helm_cli.html)
2. Review the values.yaml file.  By default the tradr (node.js application), notification-slack, notification-twitter and trade-history projects are not deployed.
If you want to deploy any of those projects, you will need to request it via command-line option or via your own values yaml file.
3. Install the chart.
Here is a sample helm install command.

    ```console
    helm install stocktrader --tls --name stocktrader --namespace stocktrader --set notificationSlack.enabled=true
    ```

    This command creates a Helm release named `stocktrader`.  The Kubernetes resources are created in a namespace called `stocktrader`.
    The ``--set`` argument shows how to deploy an optional project, in this case notification-slack.

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


**We have finally installed all the middleware** the IBM StockTrader Application depends on in order to function properly. Let's now move on to install the IBM StockTrader Application.

### Application

The IBM StockTrader Application can be deployed to IBM Cloud Private (ICP) using Helm charts. All the microservices that make up the application have been packaged into a Helm chart. They could be deployed individually using their Helm chart or they all can be deployed at once using the main umbrella IBM StockTrader Application Helm chart which is stored in this repository under the **chart/stocktrader-app** folder. This Helm chart, along with each IBM StockTrader Application microservice's Helm chart, is latter packaged and stored in the IBM StockTrader Helm chart repository at https://github.com/ibm-cloud-architecture/stocktrader-helm-repo/

As we have done for the middleware pieces installed on the previous section, the IBM StockTrader Application installation will be done by passing the desired values/configuration for some its components through a values file called [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml). This way, the IBM StockTrader Application Helm chart is the template/structure/recipe of what components and Kubernetes resources the IBM StockTrader Application is made up of while the [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml) file specifies the configuration these need to take based on your credentials, environments, needs, etc.

As a result, we need to look at the [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml) file to make sure the middleware configuration matches how we have deployed such middleware in the previous section and **provide the appropriate configuration and credentials for the services the IBM StockTrader Application integrates with**.


## Files

This section will describe each of the files presented in this repository.

#### chart/stocktrader-app

This folder contains the IBM StockTrader Application Helm chart. In here, you can find the usual [Helm chart folder structure and yaml files](https://docs.helm.sh/developing_charts/).

#### images

This folder contains the images used for this README file.

#### installation - application

- [st_app_values_v2.yaml](installation/application/st_app_values_v2.yaml): Default IBM StockTrader Helm chart values file.

#### installation - middleware

- [db2_values.yaml](installation/middleware/db2_values.yaml): tailored IBM DB2 Helm chart values file with the default values that the IBM StockTrader Helm chart expects.
- [initialise_stocktrader_db_v2.sql](installation/middleware/initialise_stocktrader_db_v2.sql): initialises the IBM StockTrader version 2 database with the appropriate structure for the application to work properly.
- [initialise_stocktrader_db_v2.yaml](installation/middleware/initialise_stocktrader_db_v2.yaml): Kubernetes job that pulls [initialise_stocktrader_db_v2.sql](installation/middleware/initialise_stocktrader_db_v2.sql) to initialise the IBM StockTrader version 2 database.
- [mq_values.yaml](installation/middleware/mq_values.yaml): tailored IBM MQ Helm chart values file with the default values that the IBM StockTrader Helm chart expects.
- [redis_values.yaml](installation/middleware/master/redis_values.yaml): tailored Redis Helm chart values file with the default values that the IBM StockTrader Helm chart expects.
- [odm_values.yaml](installation/middleware/odm_values.yaml): tailored IBM Operation Decision Manager (ODM) Helm chart values file with the default values that the IBM StockTrader Helm chart expects.
