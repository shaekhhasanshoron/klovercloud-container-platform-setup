# Setup Guide for Klovercloud Container Platform

## Table of Contents
1. [Introduction]()
2. [Prerequisites]()
3. [Installation Steps]()
   1. [Management Cluster Setup]()
   2. [Agent Cluster Setup]()
4. [Verification]()
5. [Troubleshooting]()
6. [Support]()

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


![]()