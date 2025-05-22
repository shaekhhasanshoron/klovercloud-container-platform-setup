# CloudNativePG Operator Manual Installation Guide (Temporal Namespace)

This guide explains how to manually install the CloudNativePG operator, configure it to use PostgreSQL 17.4, 
and deploy a PostgreSQL cluster with a temporal database and temporal user inside the temporal namespace.

## Prerequisites

- Kubernetes cluster access (`kubectl` configured)
- Git installed

## Step 1: Create the `temporal` Namespace

Here we will create CloudNativePG in `temporal` namespace, since we want to deploy the temporal in the same namespace.

Create the namespace where Database will be deployed (Create if namespace does not exists):

```
kubectl create namespace temporal
```

## Step 2: Install the Postgres Operator

Option 1: Apply the operator manifests:

You check the releases [https://github.com/cloudnative-pg/cloudnative-pg/releases](https://github.com/cloudnative-pg/cloudnative-pg/releases)
```
kubectl apply -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.21/releases/cnpg-1.21.0.yaml
```

Option 2: Direct apply the `operator.yaml`
```
kubectl apply -f /manifests/temporal-postgres/cloudnative-pg/descriptors/operator.yaml
```

This will create a namespace `cnpg-system` and deploy the postgres operator

### Check the operator deployment
```
kubectl get deployments -n cnpg-system
```

### Check the operator pod
```
kubectl get pods -n cnpg-system
```

## Step 3: Create the secret postgres-secret with the credentials

Now we will create a postgres user secret name `postgres-secret` in the `temporal` namespace. 
You can update the `password` which is `appuserpassword123` if you want. The `username` is `appuser`, you can also update it.

```
kubectl create secret generic postgres-secret \
  --namespace temporal \
  --from-literal=username=appuser \
  --from-literal=password=appuserpassword123 \
  --from-literal=postgres-password=supersecret123 \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Step 4: Create the PostgreSQL cluster YAML

Apply the `cn-postgres-cluster.yaml` to create the postgres cluster.

Before applying,
* Update the `storage.size` according to your requirements.
* Update the `storage.storageClass` based on your cluster storage system.
* Update the `metadata.name` if you want.

Now apply, it will create a pods with name `postgres-cluster` under `temporal` namespace.  
```
kubectl apply -f /manifests/temporal-postgres/cloudnative-pg/descriptors/cn-postgres-cluster.yaml
```

> Note: The cluster will create a database named `temporal`.

### Check the pods being created
```
kubectl get pods -l cnpg.io/cluster=postgres-cluster -n temporal
```

### Check the serive being created
```
kubectl get svc -n temporal
```

you will see the services,

```
kubectl get svc -n temporal

NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
postgres-cluster-r           ClusterIP   10.43.31.225    <none>        5432/TCP                     18d
postgres-cluster-ro          ClusterIP   10.43.128.137   <none>        5432/TCP                     18d
postgres-cluster-rw          ClusterIP   10.43.85.209    <none>        5432/TCP                     18d
```
We will use `postgres-cluster-rw` for temporal.

## Step 5: Check the connection to the primary database through a temporary pod (To test the connection)

Check the access and connection,
```
kubectl exec -it postgres-cluster-1 -n temporal -- env PGPASSWORD=appuserpassword123 psql -U appuser -d temporal -h localhost
```

Check databases,
```
\l
```
