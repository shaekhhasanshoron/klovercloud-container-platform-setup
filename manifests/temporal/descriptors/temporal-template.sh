#!/bin/bash
DATABASE_NAME="temporal"
CONNECT_ADDR="postgres-cluster-rw:5432"
USER="appuser"
PASSWORD="YXBwdXNlcnBhc3N3b3JkMTIz"
TEMPORAL_IMAGE="quay.io/klovercloud/temporal-server:1.27.2"
TEMPORAL_ADMIN_TOOLS_IMAGE="quay.io/klovercloud/temporal-admin-tools:1.27.2-tctl-1.18.2-cli-1.3.0"
PLUGIN_NAME="postgres12"
DRIVER_NAME="postgres12"

cat << EOF > temporal.yaml
# Source: temporal/templates/server-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: temporal-default-store
  labels:
    app.kubernetes.io/name: temporal
    app.kubernetes.io/version: "1.27.2"
type: Opaque
data:
  password: $PASSWORD
---
# Source: temporal/templates/server-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: temporal-visibility-store
  labels:
    app.kubernetes.io/name: temporal
    app.kubernetes.io/version: "1.27.2"
type: Opaque
data:
  password: $PASSWORD
---
# Source: temporal/templates/server-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: "temporal-config"
  labels:
    app.kubernetes.io/name: temporal
    app.kubernetes.io/version: "1.27.2"
data:
  config_template.yaml: |-
    log:
      stdout: true
      level: "debug,info"
    persistence:
      defaultStore: default
      visibilityStore: visibility
      numHistoryShards: 512
      datastores:
        default:
          sql:
            pluginName: $PLUGIN_NAME
            driverName: $DRIVER_NAME
            databaseName: $DATABASE_NAME
            connectAddr: $CONNECT_ADDR
            connectProtocol: "tcp"
            user: $USER
            password: "{{ .Env.TEMPORAL_STORE_PASSWORD }}"
            maxConnLifetime: 1h
            maxConns: 20
            maxIdleConns: 20
            secretName: ""
        visibility:
          sql:
            pluginName: $PLUGIN_NAME
            driverName: $DRIVER_NAME
            databaseName: "temporal_visibility"
            connectAddr: $CONNECT_ADDR
            connectProtocol: "tcp"
            user: $USER
            password: "{{ .Env.TEMPORAL_VISIBILITY_STORE_PASSWORD  }}"
            maxConnLifetime: 1h
            maxConns: 20
            maxIdleConns: 20
            secretName: ""
    global:
      membership:
        name: temporal
        maxJoinDuration: 30s
        broadcastAddress: {{ default .Env.POD_IP "0.0.0.0" }}
      pprof:
        port: 7936
    services:
      frontend:
        rpc:
          grpcPort: 7233
          httpPort: 7243
          membershipPort: 6933
          bindOnIP: "0.0.0.0"
      history:
        rpc:
          grpcPort: 7234
          membershipPort: 6934
          bindOnIP: "0.0.0.0"
      matching:
        rpc:
          grpcPort: 7235
          membershipPort: 6935
          bindOnIP: "0.0.0.0"
      worker:
        rpc:
          membershipPort: 6939
          bindOnIP: "0.0.0.0"
    clusterMetadata:
      enableGlobalDomain: false
      failoverVersionIncrement: 10
      masterClusterName: "active"
      currentClusterName: "active"
      clusterInformation:
        active:
          enabled: true
          initialFailoverVersion: 1
          rpcName: "temporal-frontend"
          rpcAddress: "127.0.0.1:7233"
          httpAddress: "127.0.0.1:7243"
    dcRedirectionPolicy:
      policy: "noop"
      toDC: ""
    archival:
      status: "disabled"
    publicClient:
      hostPort: "temporal-frontend:7233"
    dynamicConfigClient:
      filepath: "/etc/temporal/dynamic_config/dynamic_config.yaml"
      pollInterval: "10s"
---
# Source: temporal/templates/server-dynamicconfigmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: "temporal-dynamic-config"
  labels:
    app.kubernetes.io/name: temporal
    app.kubernetes.io/version: "1.27.2"
data:
  dynamic_config.yaml: |-
---
# Source: temporal/templates/server-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: temporal-frontend
  labels:
    app.kubernetes.io/component: frontend
    app.kubernetes.io/name: temporal
    app.kubernetes.io/version: "1.27.2"
spec:
  type: ClusterIP
  ports:
    - port: 7233
      targetPort: rpc
      protocol: TCP
      name: grpc-rpc
    - port: 7243
      targetPort: http
      protocol: TCP
      name: http
      # TODO: Allow customizing the node HTTP port
  selector:
    app.kubernetes.io/name: temporal
    app.kubernetes.io/component: frontend
---
# Source: temporal/templates/server-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: temporal-internal-frontend
  labels:
    app.kubernetes.io/component: internal-frontend
    app.kubernetes.io/name: temporal
    app.kubernetes.io/version: "1.27.2"
spec:
  type: ClusterIP
  ports:
    - port: 7236
      targetPort: rpc
      protocol: TCP
      name: grpc-rpc
    - port: 7246
      targetPort: http
      protocol: TCP
      name: http
      # TODO: Allow customizing the node HTTP port
  selector:
    app.kubernetes.io/name: temporal
    app.kubernetes.io/component: internal-frontend
---
# Source: temporal/templates/server-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: temporal-frontend-headless
  labels:
    app.kubernetes.io/component: frontend
    app.kubernetes.io/name: temporal
    app.kubernetes.io/version: "1.27.2"
    app.kubernetes.io/headless: 'true'
  annotations:
    service.alpha.kubernetes.io/tolerate-unready-endpoints: "true"
spec:
  type: ClusterIP
  clusterIP: None
  publishNotReadyAddresses: true
  ports:
    - port: 7233
      targetPort: rpc
      appProtocol: tcp
      protocol: TCP
      name: grpc-rpc
    - port: 6933
      targetPort: membership
      appProtocol: tcp
      protocol: TCP
      name: grpc-membership
    - port: 9090
      targetPort: metrics
      appProtocol: http
      protocol: TCP
      name: metrics
  selector:
    app.kubernetes.io/name: temporal
    app.kubernetes.io/component: frontend
---
# Source: temporal/templates/server-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: temporal-matching-headless
  labels:
    app.kubernetes.io/component: matching
    app.kubernetes.io/name: temporal
    app.kubernetes.io/version: "1.27.2"
    app.kubernetes.io/headless: 'true'
  annotations:
    service.alpha.kubernetes.io/tolerate-unready-endpoints: "true"
spec:
  type: ClusterIP
  clusterIP: None
  publishNotReadyAddresses: true
  ports:
    - port: 7235
      targetPort: rpc
      appProtocol: tcp
      protocol: TCP
      name: grpc-rpc
    - port: 6935
      targetPort: membership
      appProtocol: tcp
      protocol: TCP
      name: grpc-membership
    - port: 9090
      targetPort: metrics
      appProtocol: http
      protocol: TCP
      name: metrics
  selector:
    app.kubernetes.io/name: temporal
    app.kubernetes.io/component: matching
---
# Source: temporal/templates/server-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: temporal-history-headless
  labels:
    app.kubernetes.io/component: history
    app.kubernetes.io/name: temporal
    app.kubernetes.io/version: "1.27.2"
    app.kubernetes.io/headless: 'true'
  annotations:
    service.alpha.kubernetes.io/tolerate-unready-endpoints: "true"
spec:
  type: ClusterIP
  clusterIP: None
  publishNotReadyAddresses: true
  ports:
    - port: 7234
      targetPort: rpc
      appProtocol: tcp
      protocol: TCP
      name: grpc-rpc
    - port: 6934
      targetPort: membership
      appProtocol: tcp
      protocol: TCP
      name: grpc-membership
    - port: 9090
      targetPort: metrics
      appProtocol: http
      protocol: TCP
      name: metrics
  selector:
    app.kubernetes.io/name: temporal
    app.kubernetes.io/component: history
---
# Source: temporal/templates/server-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: temporal-worker-headless
  labels:
    app.kubernetes.io/component: worker
    app.kubernetes.io/name: temporal
    app.kubernetes.io/version: "1.27.2"
    app.kubernetes.io/headless: 'true'
  annotations:
    service.alpha.kubernetes.io/tolerate-unready-endpoints: "true"
spec:
  type: ClusterIP
  clusterIP: None
  publishNotReadyAddresses: true
  ports:
    - port: 7239
      targetPort: rpc
      appProtocol: tcp
      protocol: TCP
      name: grpc-rpc
    - port: 6939
      targetPort: membership
      appProtocol: tcp
      protocol: TCP
      name: grpc-membership
    - port: 9090
      targetPort: metrics
      appProtocol: http
      protocol: TCP
      name: metrics
  selector:
    app.kubernetes.io/name: temporal
    app.kubernetes.io/component: worker
---
# Source: temporal/templates/admintools-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: temporal-admintools
  labels:
    app.kubernetes.io/component: admintools
    app.kubernetes.io/name: temporal
    app.kubernetes.io/version: "1.27.2"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: temporal
      app.kubernetes.io/component: admintools
  template:
    metadata:
      labels:
        app.kubernetes.io/component: admintools
        app.kubernetes.io/name: temporal
        app.kubernetes.io/version: "1.27.2"
    spec:
      serviceAccountName: default
      containers:
        - name: admin-tools
          image: $TEMPORAL_ADMIN_TOOLS_IMAGE
          imagePullPolicy: IfNotPresent
          env:
            # TEMPORAL_CLI_ADDRESS is deprecated, use TEMPORAL_ADDRESS instead
            - name: TEMPORAL_CLI_ADDRESS
              value: temporal-frontend:7233
            - name: TEMPORAL_ADDRESS
              value: temporal-frontend:7233
          livenessProbe:
            exec:
              command:
                - ls
                - /
            initialDelaySeconds: 5
            periodSeconds: 5
---
# Source: temporal/templates/server-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: temporal-frontend
  labels:
    app.kubernetes.io/component: frontend
    app.kubernetes.io/name: temporal
    app.kubernetes.io/version: "1.27.2"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: temporal
      app.kubernetes.io/component: frontend
  template:
    metadata:
      labels:
        app.kubernetes.io/component: frontend
        app.kubernetes.io/name: temporal
        app.kubernetes.io/version: "1.27.2"
    spec:
      serviceAccountName: default
      securityContext:
        fsGroup: 1000
        runAsUser: 1000
      containers:
        - name: temporal-frontend
          image: $TEMPORAL_IMAGE
          imagePullPolicy: IfNotPresent
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
            - name: SERVICES
              value: frontend
            - name: TEMPORAL_STORE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: temporal-default-store
                  key: password
            - name: TEMPORAL_VISIBILITY_STORE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: temporal-visibility-store
                  key: password
          ports:
            - name: rpc
              containerPort: 7233
              protocol: TCP
            - name: membership
              containerPort: 6933
              protocol: TCP
            - name: http
              containerPort: 7243
              protocol: TCP
            - name: metrics
              containerPort: 9090
              protocol: TCP
          livenessProbe:
            initialDelaySeconds: 150
            tcpSocket:
              port: rpc
          volumeMounts:
            - name: config
              mountPath: /etc/temporal/config/config_template.yaml
              subPath: config_template.yaml
            - name: dynamic-config
              mountPath: /etc/temporal/dynamic_config
          resources:
            {}
      volumes:
        - name: config
          configMap:
            name: "temporal-config"
        - name: dynamic-config
          configMap:
            name: "temporal-dynamic-config"
            items:
              - key: dynamic_config.yaml
                path: dynamic_config.yaml
---
# Source: temporal/templates/server-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: temporal-history
  labels:
    app.kubernetes.io/component: history
    app.kubernetes.io/name: temporal
    app.kubernetes.io/version: "1.27.2"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: temporal
      app.kubernetes.io/component: history
  template:
    metadata:
      labels:
        app.kubernetes.io/component: history
        app.kubernetes.io/name: temporal
        app.kubernetes.io/version: "1.27.2"
    spec:
      serviceAccountName: default
      securityContext:
        fsGroup: 1000
        runAsUser: 1000
      containers:
        - name: temporal-history
          image: $TEMPORAL_IMAGE
          imagePullPolicy: IfNotPresent
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
            - name: SERVICES
              value: history
            - name: TEMPORAL_STORE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: temporal-default-store
                  key: password
            - name: TEMPORAL_VISIBILITY_STORE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: temporal-visibility-store
                  key: password
          ports:
            - name: rpc
              containerPort: 7234
              protocol: TCP
            - name: membership
              containerPort: 6934
              protocol: TCP
            - name: metrics
              containerPort: 9090
              protocol: TCP
          livenessProbe:
            initialDelaySeconds: 150
            tcpSocket:
              port: rpc
          volumeMounts:
            - name: config
              mountPath: /etc/temporal/config/config_template.yaml
              subPath: config_template.yaml
            - name: dynamic-config
              mountPath: /etc/temporal/dynamic_config
          resources:
            {}
      volumes:
        - name: config
          configMap:
            name: "temporal-config"
        - name: dynamic-config
          configMap:
            name: "temporal-dynamic-config"
            items:
              - key: dynamic_config.yaml
                path: dynamic_config.yaml
---
# Source: temporal/templates/server-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: temporal-matching
  labels:
    app.kubernetes.io/component: matching
    app.kubernetes.io/name: temporal
    app.kubernetes.io/version: "1.27.2"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: temporal
      app.kubernetes.io/component: matching
  template:
    metadata:
      labels:
        app.kubernetes.io/component: matching
        app.kubernetes.io/name: temporal
        app.kubernetes.io/version: "1.27.2"
    spec:
      serviceAccountName: default
      securityContext:
        fsGroup: 1000
        runAsUser: 1000
      containers:
        - name: temporal-matching
          image: $TEMPORAL_IMAGE
          imagePullPolicy: IfNotPresent
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
            - name: SERVICES
              value: matching
            - name: TEMPORAL_STORE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: temporal-default-store
                  key: password
            - name: TEMPORAL_VISIBILITY_STORE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: temporal-visibility-store
                  key: password
          ports:
            - name: rpc
              containerPort: 7235
              protocol: TCP
            - name: membership
              containerPort: 6935
              protocol: TCP
            - name: metrics
              containerPort: 9090
              protocol: TCP
          livenessProbe:
            initialDelaySeconds: 150
            tcpSocket:
              port: rpc
          volumeMounts:
            - name: config
              mountPath: /etc/temporal/config/config_template.yaml
              subPath: config_template.yaml
            - name: dynamic-config
              mountPath: /etc/temporal/dynamic_config
          resources:
            {}
      volumes:
        - name: config
          configMap:
            name: "temporal-config"
        - name: dynamic-config
          configMap:
            name: "temporal-dynamic-config"
            items:
              - key: dynamic_config.yaml
                path: dynamic_config.yaml
---
# Source: temporal/templates/server-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: temporal-worker
  labels:
    app.kubernetes.io/component: worker
    app.kubernetes.io/name: temporal
    app.kubernetes.io/version: "1.27.2"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: temporal
      app.kubernetes.io/component: worker
  template:
    metadata:
      labels:
        app.kubernetes.io/component: worker
        app.kubernetes.io/name: temporal
        app.kubernetes.io/version: "1.27.2"
    spec:
      serviceAccountName: default
      securityContext:
        fsGroup: 1000
        runAsUser: 1000
      containers:
        - name: temporal-worker
          image: $TEMPORAL_IMAGE
          imagePullPolicy: IfNotPresent
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
            - name: SERVICES
              value: worker
            - name: TEMPORAL_STORE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: temporal-default-store
                  key: password
            - name: TEMPORAL_VISIBILITY_STORE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: temporal-visibility-store
                  key: password
          ports:
            - name: membership
              containerPort: 6939
              protocol: TCP
            - name: metrics
              containerPort: 9090
              protocol: TCP
          volumeMounts:
            - name: config
              mountPath: /etc/temporal/config/config_template.yaml
              subPath: config_template.yaml
            - name: dynamic-config
              mountPath: /etc/temporal/dynamic_config
          resources:
            {}
      volumes:
        - name: config
          configMap:
            name: "temporal-config"
        - name: dynamic-config
          configMap:
            name: "temporal-dynamic-config"
            items:
              - key: dynamic_config.yaml
                path: dynamic_config.yaml
EOF
