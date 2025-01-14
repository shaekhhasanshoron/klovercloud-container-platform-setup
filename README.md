# Setup Guide for Klovercloud Container Platform

## Table of Contents
1. [Introduction](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/tree/master?tab=readme-ov-file#1-introduction)
2. [Prerequisites](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/tree/master?tab=readme-ov-file#2-prerequisites)
3. [Installation Steps](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/tree/master?tab=readme-ov-file#3-installation-steps)
4. [Verification](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/tree/master?tab=readme-ov-file#4-verification)
5. [Troubleshooting](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/tree/master?tab=readme-ov-file#5-troubleshooting)
6. [Support](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/tree/master?tab=readme-ov-file#6-support)
7. [Deletion Steps](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/tree/master?tab=readme-ov-file#6-deletion-steps)
## 1. Introduction
[Klovercloud](https://klovercloud.com/) container platform cost-effective Container Platform on top of Kubernetes with all cutting-edge technologies to help your applications scale.
For more details [click here](https://klovercloud.com/klovercloud-container-platform-on-kubernetes/).

This repository provides detailed instructions for the setup process, including the prerequisites required to configure the [klovercloud](https://klovercloud.com/) container platform.

The platform comprises two main clusters, both deployed on Kubernetes:

### a) Management Cluster:
The Klovercloud management cluster hosts all essential services to manage and monitor klovercloud agent clusters and user interface. The platform requires only a single management cluster.

### b) Agent Cluster:
The Klovercloud agent cluster deploys all the essential services to manage user applications and the cluster. 
Users can deploy multiple agent clusters and link them to the management console. 
Although it's possible to use the same Kubernetes cluster hosting the management cluster, this is not recommended.


![](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/blob/master/static/klovercloud-platform-overview.png)

## 2. Prerequisites
### 2.1 Infrastructure Requirements

Here are the requirements before installing the platform. 

#### 2.1.1 System Requirements:

**Management Cluster Requirements:**

| Resource      | Minimum | Recommended |
|:--------------|:--------|:-----------:|
| CPU           | 8 Core  |   8 Core    | 
| Memory        | 16 GB   |    16 GB    | 
| Node/VM Count | 1       |      3      |

**Agent Cluster Requirements:**

| Resource      | Minimum |     Recommended      |
|:--------------|:--------|:--------------------:|
| CPU           | 2 Core  | Based on user's need | 
| Memory        | 8 GB    | Based on user's need | 
| Node/VM Count | 1       | Based on user's need |

**Storage Machine Storage Requirements (Per VM):**

Path-specific storage is required.
* “/var/lib”: 150 GB (Kubernetes Storage will be mounted in this path)
* “/var/log”: 50 GB (Kubernetes logs will be mounted in this path)
* “Others”: 50 GB
* disabled swap

Total (each VM): 250 GB (SSD)

#### 2.1.2 VM/Cluster Node configuration:
* Linux (RedHat Enterprise Linux 8+ or Ubuntu 22+)
* Kernel Version >= 5
* NFSv4.2, NFSv4.1 support
* SELinux disabled (for RedHat Enterprise Linux)

#### 2.1.3 Kubernetes Requirements:
* Kubernetes version >= 1.25
* Helm version >= 3.0
* kubectl >= 1.23

#### 2.1.4 Kubernetes Components:
* Storage class access modes (ReadWriteOnly) for management cluster.
* Storage class access modes (ReadWriteOnly, ReadWriteMany) for agent cluster.
* [Cert-manager](https://cert-manager.io/) for managing certificates for your domain. (This is optional)

#### 2.1.5 Platform requirements:
* To access kloverCloud management console and agent clusters, we also need a domain/subdomain (TLS certificate recommended). **The domain must be wildcard supported**. That domain/subdomain needs to be routed to the Ingress Controller Gateway IP.

## 3. Installation Steps
This installation process involves setting up two components: the management console cluster and 
the agent cluster. The management cluster is set up first, followed by the agent cluster. 
If the agent cluster is installed on the same Kubernetes cluster as the management cluster, 
some installation steps can be skipped.

You will find all the manifests/configurations files for the installation process under [manifests](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/tree/master/manifests). 
You can clone the repository and apply these files.

### 3.1 Management Cluster Setup Steps

#### 3.1.1 Create namespace

Create a namespace in your kubernetes cluster named `klovercloud`
```
kubectl create namespace klovercloud
```

#### 3.1.2 Install Nginx Ingress Controller

Apply the configurations, this will create ingress controller in a namespace `ingress-nginx`
```
kubectl apply -f manifests/nginx-ingress-controller/deploy.yaml
```

#### 3.1.3 Create DNS record for the Wild Card Domain

Check the 'External-IP' of the cluster by running the following command.

```
kubectl get svc -n ingress-nginx
```

Now create a 'A-record' for your domain and point that to that IP.

> If you face any difficulties while creating A record, please contact [klovercloud support](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/tree/master?tab=readme-ov-file#6-support)


#### 3.1.4 Creating Certificate Secret

There are two ways to enable/create tls secret for your domain. 

**Way One - If you already have tls certificate and key for your domain:**

Create a Kubernetes secret to provide TLS certificates for the wildcard domain. 
First, create a Kubernetes secret file named `wild-cert-secret.yaml` and include the 
base64-decoded TLS certificate and certificate key for your domain. 
The secret must be created within the `klovercloud` namespace. 

Here is the secret file format. replace the certificate and key:

````
apiVersion: v1
data:
  tls.crt: <base64 encoded tls certificate>
  tls.key: <base64 encoded tls certificate key>
kind: Secret
metadata:
  name: wild-cert-secret
  namespace: klovercloud
type: kubernetes.io/tls
````

Now apply the certificate secret:
```
kubectl apply -f wild-cert-secret.yaml
```

**Way Two - If you want Kubernetes to generate and manage tls certificate secret for your domain:**

First setup [cert-manager](https://cert-manager.io/) on your cluster,

```
kubectl apply -f manifests/cert-manager/deploy.yaml
```

After running cert-manager, now apply the configuration, it will create a clusterissuer named `klovercloud-letsencrypt`.
```
kubectl apply -f manifests/cert-manager/cluster-issuer.yaml
```

> If you face any difficulties while generating certificate secret or cert-manager, please contact [klovercloud support](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/tree/master?tab=readme-ov-file#6-support)

#### 3.1.5 Pull Klovercloud Operator

[Klovercloud Operator](https://github.com/klovercloud/klovercloud-charts/blob/master/klovercloud-operator.md#klovercloud-operator) is a helm chart for installing
Management console into your kubernetes cluster. Run the following helm commands to fetch the klovercloud operator helm repository:

```
helm repo add klovercloud-charts https://klovercloud.github.io/klovercloud-charts/charts
helm repo update
```

#### 3.1.6 Install Klovercloud Operator

Follow the variables for here [Klovercloud Operator](https://github.com/klovercloud/klovercloud-charts/blob/master/klovercloud-operator.md#klovercloud-operator)

Update the variables and apply the helm command.
```  
helm install kc-operator --namespace klovercloud klovercloud-charts/klovercloud-operator --version 0.2.5 \
    --set operator.namespace=klovercloud \
    --set agentOperator.image.tag="v2.1" \
    --set agentOperator.chart.version="0.2.6" \
    --set cluster.volumes.storageType=BARE_METAL \
    --set cluster.volumes.storageClass.readWriteOnce=<storage class name RWO> \
    --set cluster.clusterissuer.name="" \
    --set platform.temporal.host="95.216.152.146:7233" \
    --set platform.temporal.namespace="default" \
    --set platform.namespace=klovercloud \
    --set platform.user.adminUser.enabled="true" \
    --set platform.service.multiClusterCoreEngine.addServiceDomainConfigInClusterOnboardHelmCommand="true" \
    --set platform.internalServiceRequestThroughExternalEndpoint="true" \
    --set platform.user.operatorUser.username="<any email address>" \
    --set platform.user.operatorUser.password="<any password>" \
    --set platform.service.domain.wildcard.tlsSecret="wild-cert-secret" \
    --set platform.service.domain.useClusterIssuerForGeneratingDomainTlsSecret="false" \
    --set platform.service.domain.wildcard.name="<wild card supported domain>"
```

Here, 
* Tls Certificate: 
  * If you have created tls secret following section [3.1.4](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/tree/master?tab=readme-ov-file#314-creating-certificate-secret), set the following values
    * `platform.service.domain.wildcard.tlsSecret=wild-cert-secret`.
  * If you did not create tls secret and instead deployed cert-manager and created clusterissuer following section [3.1.4](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/tree/master?tab=readme-ov-file#314-creating-certificate-secret), set the following values
    * `cluster.clusterissuer.name="klovercloud-letsencrypt"`
    * `platform.service.domain.wildcard.tlsSecret=""`
    * `platform.service.domain.useClusterIssuerForGeneratingDomainTlsSecret="true"`

#### 3.1.7 Verify the installation

Check if all the components for klovercloud management console has installed or not inside `klovercloud` namespace.

```
kubectl get po -n klovercloud
```

after the installation complete, you will see all pod are in running state. You will see something like the following. verify if
all pods are up and running or not. If not, wait for some-while and restart the `klovercloud-operator` pod and check then. 
If you face any issue regarding installation, please contact with  please contact [klovercloud support](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/tree/master?tab=readme-ov-file#6-support).

````
kc-kafka-0                                                 1/1     Running
kcprod-mongodb-0                                           2/2     Running
klovercloud-activity-log-b9bc6c4b-9qb5h                    1/1     Running
klovercloud-auth-server-65d7545bf5-n9dw5                   1/1     Running
klovercloud-cicd-queue-98fbb6465-jx4mt                     1/1     Running
klovercloud-control-plane-webapp-86f9ccf54-9zgqf           1/1     Running
klovercloud-dashboard-8dd68dbf7-xs4v7                      1/1     Running
klovercloud-dashboard-webapp-54f98f699-lvg6n               1/1     Running
klovercloud-external-endpoint-manager-5cc7c7ffbc-bpgdw     1/1     Running
klovercloud-facade-5ffc9796b7-kvqc4                        1/1     Running
klovercloud-general-publisher-8698fb44f-bg5m2              1/1     Running
klovercloud-helm-agent-gateway-657678ff68-v8xnv            1/1     Running
klovercloud-helm-generator-5f656b85c7-qt8bc                1/1     Running
klovercloud-helm-marketplace-56f69d8856-flqp5              1/1     Running
klovercloud-light-house-56f7476f6d-j5fhm                   1/1     Running
klovercloud-listener-554fc44dc4-lwrmb                      1/1     Running
klovercloud-logmanager-5c5f7946f-9r8pf                     1/1     Running
klovercloud-management-769f9dd5f7-m8z9v                    1/1     Running
klovercloud-message-publisher-7499dd6778-vtz4c             1/1     Running
klovercloud-metrics-7468b484f5-75t88                       1/1     Running
klovercloud-monitor-74df47b66c-vkcsd                       1/1     Running
klovercloud-multi-cluster-665cb9bb9b-s9db6                 1/1     Running
klovercloud-multicluster-console-gateway-c7679f66f-2l6vf   1/1     Running
klovercloud-multicluster-log-saver-6c8cb5ddf7-p9ckl        1/1     Running
klovercloud-pipeline-77d649b6cd-t2wgk                      1/1     Running
klovercloud-proxy-server-75f6cb46f9-h4825                  1/1     Running
klovercloud-queue-54469995b6-kxlmx                         1/1     Running
klovercloud-redis-0                                        2/2     Running
klovercloud-tally-8b6dc5d8f-8b6t7                          1/1     Running
klovercloud-vpc-6dbc546df5-gwdh5                           1/1     Running
klovercloud-webapp-cc555f449-2cszj                         1/1     Running
````

After the installation restart the `klovercloud-monitor` pod. 

Check the ingress in `klovercloud` namespace. You will find the url of the management console UI `klovercloud-webapp` Host. 

### 3.2 Agent Cluster Setup Steps

If you want to deploy the agent cluster on the same Kubernetes instance as the management cluster, 
use a namespace other than `klovercloud`, since the `klovercloud` namespace will contain management cluster services.

#### 3.2.1 Install Nginx Ingress Controller

Setup nginx ingress controller if not installed yet. Follow [instructions](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup?tab=readme-ov-file#311-install-nginx-ingress-controller).

#### 3.2.2 Install ArgoCD

ArgoCD is required for helm apps feature. Apply the configurations.

Create namespace and add the label.
```
kubectl create namespace argocd
kubectl label namespace argocd role=klovercloud
```

Now apply the manifest.

```
kubectl apply -f manifests/argocd/argocd.yaml -n argocd
```

Check all pods are up and running or not.

```
kubectl get po  -n argocd
```

Create an ingress to access argocd UI. Before applying the manifests, replace the host domain (host domain that points to the ExternalIP of Nginx Ingress Controller's LoadBalancer Service) or  in the ` <domain> ` section in `manifests/argocd/ingress.yaml` file.

```
kubectl apply -f manifests/argocd/ingress.yaml
```

Now get the initial admin password,

```
kubectl get secrets/argocd-initial-admin-secret -n argocd --template={{.data.password}} | base64 -d
```

#### 3.2.3 Install Prometheus and Grafana

Prometheus is required for visualizing application matrices. 

Now apply the manifests,  

```
kubectl create -f manifests/prometheus/crds/
kubectl apply -f manifests/prometheus/prometheus.yaml
```

Now create ingresses for prometheus and grafana. Before applying the manifests, replace the host domain (host domain that points to the ExternalIP of Nginx Ingress Controller's LoadBalancer Service) in the` <domain> ` section in `manifests/prometheus/prometheus-ingress.yaml` and `manifests/prometheus/grafana-ingress.yaml` files.

```
kubectl apply -f manifests/prometheus/prometheus-ingress.yaml
kubectl apply -f manifests/prometheus/grafana-ingress.yaml
```

Now get grafana username and password,
```
kubectl get secret -n k8-monitoring kube-prom-stack-grafana -o jsonpath="{.data.admin-user}" | base64 --decode
kubectl get secret -n k8-monitoring kube-prom-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```

#### 3.2.4 Install Loki

Loki is a log aggregation tool which is used to collect the application logs. Apply the following configurations.

Loki uses persistent volume, so before applying the loki manifest, need to replace the storage class name in ` <storageclassname> ` section in `manifests/loki/loki.yaml` file. 
You can update the storage resource according to your requirements. Also verify the resolver in the configmap named `loki-gateway` in `manifests/loki/loki.yaml` with your kubernetes cluster. 

Now apply the configuration manifest. this will create a namespace `loki`

```
kubectl apply -f manifests/loki/loki.yaml
```

Check the pods and wait for all the pods to go to running state,

```
kubectl get po -n loki
```

Apply running loki, apply promtail config

```
kubectl apply -f manifests/loki/promtail.yaml
```

Now create ingresses for loki. Before applying the manifests, replace the host domain (host domain that points to the ExternalIP of Nginx Ingress Controller's LoadBalancer Service) in the` <domain> ` section in `manifests/loki/loki-ingress.yaml` file.

```
kubectl apply -f manifests/loki/loki-ingress.yaml
```

#### 3.2.5 Install Service Mesh - Istio

[Istio](https://istio.io/) will enable to use service mesh features from klovercloud platform. 

> Istio setup configures a kubernetes service with
type `LoadBalancer`. Since your cluster already need a nginx ingress controller which uses a service with type `LoadBalancer`,
you will need to have another LoadBalancer.

Install istio base configuration. this will create a namespace `istio-system`
```
kubectl apply -f manifests/istio/istio-base.yaml
```

Install istiod
```
kubectl apply -f manifests/istio/istiod.yaml
```

Apply istio gateway

```
kubectl apply -f manifests/istio/istio-ingressgateway.yaml
```

Check for the 'ExternalIP' of istio gateway.
```
kubectl get svc -n istio-system
```

Update the hosts section and apply.
Now create istio gateway. Before applying the manifests, replace the host domain (host domain that points to the ExternalIP of Istio Ingress Controller's LoadBalancer Service) in the` <istio-domain> ` section in `manifests/istio/gateway.yaml` file.
This will create a istio gateway named `default-istio-gateway`.

```
kubectl apply -f manifests/istio/gateway.yaml
```

#### 3.2.6 Install Jaeger

[Jaeger](https://www.jaegertracing.io/) is a distributed tracing tool used to trace application data. 

Apply the configuration, you will find the details [here](https://istio.io/latest/docs/ops/integrations/jaeger/#installation).

```
kubectl apply -f manifests/kiali/jaeger.yaml
```

#### 3.2.7 Install Kiali

[Kiali](https://kiali.io/) is a visualization tool for Istio.

Apply the configuration, for details installation [click here](https://istio.io/latest/docs/ops/integrations/kiali/#installation)

```
kubectl apply -f manifests/kiali/kiali.yaml
```

Now create ingress to access Kiali UI. Before applying the manifests, replace the host domain (host domain that points to the ExternalIP of Nginx Ingress Controller's LoadBalancer Service) in the` <domain> ` section in `manifests/kiali/ingress.yaml` file.

```
kubectl apply -f manifests/kiali/ingress.yaml
```

To Collecting Kiali Token, Run following command
```
kubectl exec -it -n istio-system deploy/kiali -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

> Note: If there any issue occurs while getting the token, the exec into the pod and get it.
>
> `kubectl exec -it -n istio-system deploy/kiali -- bash`
>
> `cat /var/run/secrets/kubernetes.io/serviceaccount/token`


#### 3.2.8 Onboard Cluster using Klovercloud Agent Operator

Go to management console UI, follow the steps:
1. Go to management console UI.
2. Create a new company/account (if not exists) and login.
3. Go to cluster section.
4. Click on "On Board k8 Existing Cluster"
5. Provide all the necessary information and proceed, make sure to set the namespace name.
6. Click on "Generate helm command", 
7. A cluster will be created in the UI with 'Pending' state and will generate a helm chart command.

Now, after getting the helm chart command Go to the agent kubernetes server, and pull the helm repository (if not pulled yet)

```
helm repo add klovercloud-charts https://klovercloud.github.io/klovercloud-charts/charts
helm repo update
```

After fetching the repository, run the copied helm chart command from UI inside the kubernetes cluster.
This will deploy all the necessary components of agent cluster and connect it to the master cluster.

After the installation complete, you will see all pod are in running state. Check the pods under provided namespace.
You will see something like the following. Verify if
all pods are up and running or not. 
If not, wait for some-while and restart the `klovercloud-agent-operator` pod and check then.
If you face any issue regarding installation, please contact with  please contact [klovercloud support](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/tree/master?tab=readme-ov-file#6-support).

````
klovercloud-agent-monitor-869cdd9875-b9bkw      1/1     Running
klovercloud-agent-operator-5758fcc864-2h9fs     1/1     Running
klovercloud-cd-agent-66677b5494-rx9vk           1/1     Running
klovercloud-ci-agent-cf6974c7d-4xzl4            1/1     Running
klovercloud-helm-agent-566b6fdbf7-x9b4c         1/1     Running
klovercloud-light-house-agent-b77f5cf58-n9fcm   1/1     Running
klovercloud-light-house-logs-fb76d9b9f-dwqzb    1/1     Running
klovercloud-terminal-cf8d54b89-9vf4p            1/1     Running
````

#### 3.1.9 Verify the installation

Go to management console and create a namespace. Check if it is successfully initiated or not.

## 4. Verification

* Go to management console and create a namespace. Check if it is successfully initiated or not.
* Create an application, build and deploy the application.
* Create a helm application.

## 5. Troubleshooting

## 6. Support

Please contact klovercloud team,

Mail: [support@klovercloud.com](support@klovercloud.com)

## 7. Deletion Steps

#### 7.1 Management Cluster deletion steps

Go to the kubernetes cluster where you have installed the management operator. Run the commands

Check the operator 

```
helm list -n klovercloud
```
Now delete the operator
```
helm delete kc-operator -n klovercloud
```
Delete the created pvc
```
kubectl delete --all pvc -n klovercloud
```

If you have applied cert-manager and generated secret using cluster-issuer, then remove the secrets created by cert-manager with prefix `-ingress-tls-secret``,
```
kubectl delete secret -n klovercloud \
klovercloud-dashboard-webapp-ingress-tls-secret \
klovercloud-facade-ingress-tls-secret \
klovercloud-listener-ingress-tls-secret \
klovercloud-multicluster-console-gateway-ingress-tls-secret \
klovercloud-proxy-server-ingress-tls-secret \
klovercloud-webapp-ingress-tls-secret \
klovercloud-lighthouse-webapp-ingress-tls-secret
```

Delete the namespace
```
kubectl delete ns klovercloud
```

#### 7.2 Agent Cluster deletion steps

Go to the kubernetes cluster where you have installed the agent operator. Run the commands

Check the operator

```
helm list -n <deployed namespace>
```
Now delete the operator
```
helm delete kc-agent-operator -n <deployed namespace>
```
Delete the created pvc
```
kubectl delete --all pvc -n <deployed namespace>
```

Delete the created secrets
```
kubectl delete secret agent-crypto-key ci-agent-crypto-secret -n <deployed namespace>
```

Delete created namespace
```
kubectl delete ns <deployed namespace>
```