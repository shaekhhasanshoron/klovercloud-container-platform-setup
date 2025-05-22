# CloudNativePG Operator Manual Installation Guide (Temporal Namespace)

This guide explains how to manually install the CloudNativePG operator, configure it to use PostgreSQL 17.4, and deploy a PostgreSQL cluster with a temporal database and temporal user inside the temporal namespace.

## Prerequisites

- Kubernetes cluster access (`kubectl` configured)
- Git installed

## Step 1: Create the `temporal` Namespace

Create the namespace where Database will be deployed:

```bash
kubectl create namespace temporal
```

## Step 2: Install the Postgres Operator

Apply the operator manifests:

```bash
kubectl apply -f \
  https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.21/releases/cnpg-1.21.0.yaml

```

### Check the operator deployment
```bash
kubectl get deployments -n cnpg-system
```

### Check the operator pod
```bash
kubectl get pods -n cnpg-system
```

## Step 3: Create the secret postgres-secret with the credentials
```bash
kubectl create secret generic postgres-secret \
  --namespace temporal \
  --from-literal=username=appuser \
  --from-literal=password=appuserpassword123 \
  --from-literal=postgres-password=supersecret123 \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Step 4: Create the PostgreSQL cluster YAML

```bash
cat > postgres-cluster.yaml << EOF
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres-cluster
  namespace: temporal
spec:
  instances: 1
  imageName: ghcr.io/cloudnative-pg/postgresql:17.4

  storage:
    size: 5Gi
    storageClass: local-path

  bootstrap:
    initdb:
      database: temporal  # This creates the database first
      owner: appuser   # This creates the appuser with ownership of appdb
      secret:
        name: postgres-secret
      postInitApplicationSQL:  # Changed from postInitSQL to run after appdb exists
        - ALTER USER appuser CREATEDB;
        - GRANT ALL PRIVILEGES ON DATABASE temporal TO appuser;
        - GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO appuser;

  postgresql:
    parameters:
      max_connections: "200"
      shared_buffers: 256MB
      work_mem: 8MB

  primaryUpdateStrategy: unsupervised
EOF
```

## Step 5: Apply the configuration to create the PostgreSQL cluster
```bash
kubectl apply -f postgres-cluster.yaml
```

### Check the pods being created
```bash
kubectl get pods -l cnpg.io/cluster=postgres-cluster -n temporal
```


## Connect to the primary database through a temporary pod (To test the connection)
```bash
kubectl exec -it postgres-cluster-1 -n temporal -- env PGPASSWORD=appuserpassword123 psql -U appuser -d temporal -h localhost
```
