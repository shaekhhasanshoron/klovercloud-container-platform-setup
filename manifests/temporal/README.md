# Temporal

Temporal is a microservice orchestration platform which enables developers to build scalable applications without sacrificing productivity or reliability.
Temporal server executes units of application logic, Workflows, in a resilient manner that automatically handles intermittent failures, and retries failed operations.

## Setup

In this setup we will install the temporal (version: `v1.27.2`). We will be creating temporal inside `temporal` namespace.
You can update the namespace whatever you want.

### Step 1. Generate Manifest
Update the `manifests/temporal/descriptors/temporal-template.sh` bash file and update the following based on your cluster configurations and setup,

Change the following (`CONNECT_ADDR`, `USER`, `PASSWORD`, `TEMPORAL_IMAGE`, `TEMPORAL_ADMIN_TOOLS_IMAGE`) accordingly in the bash file,
```
DATABASE_NAME="<database name>" # for example, 'temporal'
CONNECT_ADDR="<svc_name_of_postgres>.<namespace>.svc.cluster.local:5432" #postgres connection address
USER="<postgres username>" # postgres username, for example 'appuser'
PASSWORD="<postgres_password_base64_encoded>" # baseword base64 encoded
TEMPORAL_IMAGE="quay.io/klovercloud/temporal-server:1.27.2"
TEMPORAL_ADMIN_TOOLS_IMAGE="quay.io/klovercloud/temporal-admin-tools:1.27.2-tctl-1.18.2-cli-1.3.0"
PLUGIN_NAME="postgres12"
DRIVER_NAME="postgres12"
```

After editing run the following command to generate the temporal manifest,
```
cd manifests/temporal/descriptors/

./temporal-template.sh
```
This will generate `temporal.yaml` manifest file under `manifests/temporal/descriptors/` directory.

### Step 2. Apply the manifest

Apply the manifest. By default, it will go to the default namespace. Add namespace param to apply in different namespace. 
For example, creating temporal in `temporal` namespace.

```
kubectl apply -f manifests/temporal/descriptors/temporal.yaml -n temporal
```

Check if the pods are running in the desired namespace. The following deployments and pods will be running.
```
temporal-admintools
temporal-frontend
temporal-history
temporal-matching
temporal-worker
```

### Step 3. Expose temporal-frontend service as load balancer

We have to use `temporal-frontend` service for connecting to the temporal. For, example Temporal connection string `temporal-frontend.<namespace>:7233`.

> **IMPORTANT:** By default, `temporal-frontend` is a ClusterIP type service. You can connect it internally within the cluster. For connecting temporal from
> outside the cluster, you need to set loadbalancer ip to `temporal-frontend` service, since Temporal communication happens with gRPC protocol.

If you want to connect the temporal outside of the cluster, you need to update the service type from `ClusterIP` to `LoadBalancer`. Edit the temporal-frontend service.
```
kubectl edit svc temporal-frontend -n temporal
```

### Step 4. Create `default` namespace in Temporal

Exec into the temporal-frontend pod.

```
kubectl exec -it <temporal-frontend-pod> -n temporal -- bash
```

Use `tctl` (temporal command line tool) to create and register the `default` namespace for temporal.

```
tctl --ns default n re
```

Use the following command to **verify** if the namespace is created. This should list out the temporal namespace list including the `default` one that was just created.

```
tctl namespace list
```