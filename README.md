# Setup Guide for Klovercloud Container Platform

## Table of Contents
1. [Introduction](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/tree/master?tab=readme-ov-file#1-introduction)
2. [Prerequisites](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/tree/master?tab=readme-ov-file#2-prerequisites)
3. [Installation Steps](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/tree/master?tab=readme-ov-file#2-installation-steps)
4. [Verification]()
5. [Troubleshooting]()
6. [Support](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/tree/master?tab=readme-ov-file#6-support)

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
| Memory        | 12 GB   |    16 GB    | 
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
* Storage class access modes (Read Write Only, Read Write Many)
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

#### 3.1.1 Install Nginx Ingress Controller

Apply the configurations, this will create ingress controller in a namespace `ingress-nginx`
```
kubectl apply -f manifests/nginx-ingress-controller/deploy.yaml
```

#### 3.1.2 Create namespace

Create a namespace in your kubernetes cluster named `klovercloud`
```
kubectl create namespace klovercloud
```

#### 3.1.2 Creating Certificate Secret

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

> Note: If you want kubernetes to manage and create certificate secrets for you, then you need to setup a [cert-manager](https://cert-manager.io/) and create 
> certificate for you domain. 
> 
> If you face any difficulties while setting certificate secret or cert-manager, please contact [support](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/tree/master?tab=readme-ov-file#6-support)


## 6. Support