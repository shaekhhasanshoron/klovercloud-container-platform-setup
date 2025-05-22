# Temporal

Temporal is a microservice orchestration platform which enables developers to build scalable applications without sacrificing productivity or reliability.
Temporal server executes units of application logic, Workflows, in a resilient manner that automatically handles intermittent failures, and retries failed operations.

## Setup
### Prerequisite
* Postgres
    * Postgres version: 17.4
    * Postgres credentials: `username` & `password`
    * Postgres connection address

### Step 1. Generate Manifest
Edit the `temporal-template.sh` file

Change the following (`CONNECT_ADDR`, `USER`, `PASSWORD`, `TEMPORAL_IMAGE`, `TEMPORAL_ADMIN_TOOLS_IMAGE`) accordingly,

```azure
DATABASE_NAME="temporal"
CONNECT_ADDR="svc_name_of_postgres.namespace.svc.cluster.local:5432" #postgres connection address
USER="temporal" # postgres user
PASSWORD="postgres_password"
TEMPORAL_IMAGE="quay.io/klovercloud/temporal-server:1.27.2"
TEMPORAL_ADMIN_TOOLS_IMAGE="quay.io/klovercloud/temporal-admin-tools:1.27.2-tctl-1.18.2-cli-1.3.0"
PLUGIN_NAME="postgres12"
DRIVER_NAME="postgres12"
```
After editing run the following command to generate the temporal manifest

```azure
bash temporal-template.sh
```
This will generate `temporal-v1.27.2.yaml` manifest file.

### Step 2. Apply the manifest

Apply the manifest. By default it will go to the default namespace. Add namespace param to apply in different namespace.

```azure
kubectl apply -f temporal-v1.27.2.yaml -n namespace-name
```

Check if the pods are running in the desired namespace. The following deployments and pods will be running.
```azure
temporal-admintools
temporal-frontend
temporal-history
temporal-matching
temporal-worker
```

### Step 3. Expose temporal-frontend service as load balancer

Edit the temporal-frontend service.


```azure
kubectl edit svc temporal-frontend -n namespace-name
```

**Change service type:** `ClusterIP` to `LoadBalancer`

### Step 4. Create temporal default namespace

Exec into the temporal-frontend pod.

```azure
kubectl exec -it temporal-frontend-pod -n namespace-name bash
```

Use `tctl` (temporal command line tool) to create and register the `default` namespace for temporal.

```azure
tctl --ns default n re
```

Use the following command to **verify** if the namespace is created. This should list out the temporal namespace list including the `default` one that was just created.

```azure
tctl namespace list
```