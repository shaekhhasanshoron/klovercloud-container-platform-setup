# Gitlab

## Gitlab Self hosted on Kubernetes

This is document for setting Gitlab Private Server.

### Prerequisite
* Kubernetes Cluster
* Filesystem Storage Class

### System Requirements
* minimum 4 core CPU
* minimum 10 GB ram
* minimum 5 GB storage

### Installation Procedure

#### Create Namespace

```
kubectl create ns gitlab

kubectl label namespace gitlab role=klovercloud
```

#### Step One: Deploy resources (PVC, Service, Ingress)
First we need to deploy the gitlab descriptors below. 

Before applying,
* Update the `storageClassName` in `manifests/gitlab/descriptors/gitlab-pvc.yaml`
* Update the `ingressClassName` and `host` in `manifests/gitlab/descriptors/gitlab-ingress.yaml`

````
kubectl apply -f manifests/gitlab/descriptors/gitlab-pvc.yaml
kubectl apply -f manifests/gitlab/descriptors/gitlab-svc.yaml
kubectl apply -f manifests/gitlab/descriptors/gitlab-ingress.yaml
````

> Note: Here in pvc.yaml, the storage class will be filesystem because deployment will try to attach storage.


> Note: Here in ingress.yaml, there is not tls enabled because we will configure tls certificates
> from inide the gitlab server. Just set the domain and we will setup the wild-certificate secrets following steps.

#### Step Two: Install Deployment

Deploy the following deployment file

````
kubectl apply -f gitlab-deploy.yaml
````

There are certain components inside deployments:

* `spec.template.spec.serviceAccountName` (Optional) if your cluster is psp (Pod Security Policy) enabled,
  which means the descriptor needs permission to access the initiate then it requires. Here the value
  is `ns-privileged-sa`. To setup service account and bind roles to it deploy the following
  descriptors (if its not setup yet).

    * serviceAccount
    * clusterrole
    * clusterrolebinding

* `spec.template.spec.volumes[].name: cert-files` (Required) this value is required to set the existing certificates
  to gitlab. here the value `wild-certificate-secret` is the wildcard secret name which contains certicate and private key for a domain.
  for this example lets say the wildcard domain is `*.console.klovercloud.com` so that we can use `gitlab.console.klovercloud.com` as a subdomain


* `spec.template.spec.containers[].volumeMounts[].name: cert-files: cert-files` here we need to set the certificate and the private key to
  gitlab into path under `/etc/gitlab/ssl` for example`/etc/gitlab/ssl/gitlab.example.com.crt` and `/etc/gitlab/ssl/gitlab.example.com.key`. here  you
  can set any value in place of `/gitlab.example.com`, we can set the domain `gitlab.console.klovercloud.com` instead or any value.
  If the folder does not exists kubernetes will create it. **Remember that we need to set these to path to gitlab config file**

After deploying the deployment wait for pod to be running.

![](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/blob/master/static/gitlab/1.gitlab.PNG)

#### Step Three: Update the Gitlab Config and Restart Gitlab Server

Now we need to update the certificates and configurations to gitlab server.

First we need to `exec` into the gitlab pod.

```
kubectl exec -it <pod name> -n <namespace> bash 
```
![](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/blob/master/static/gitlab/2.gitlab.PNG)


Now after entering into the pod, open the config file ` /etc/gitlab/gitlab.rb`

```
 vi /etc/gitlab/gitlab.rb
```

![](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/blob/master/static/gitlab/3.gitlab.PNG)

Now we have to edit the following config to the file.

1. We need to set external url to our url. we need to set `https//<url>` since we want to secure the
   connection
```
external_url 'https://gitlab.console.klovercloud.com'
```
![](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/blob/master/static/gitlab/4.gitlab-config.PNG)

2. We need to set the certificate and private key path and enable nginx https. **The path must be match with whatever we have set in the deployment
   descriptor**.

````
nginx['enable'] = true
nginx['client_max_body_size'] = '100m'
nginx['redirect_http_to_https'] = true
nginx['ssl_certificate'] = "/etc/gitlab/ssl/gitlab.example.com.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/gitlab.example.com.key"
nginx['ssl_protocols'] = "TLSv1.2 TLSv1.3"
````


![](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/blob/master/static/gitlab/5.gitlab-config.PNG)

> Note: In vim Editor to search a text write `/<searched text>` and press enter

![](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/blob/master/static/gitlab/6.shortcut-vim.PNG)

3. Now save and exit the file from vim editor

```
<esc button>
:x
```

4. Restart the server by the following command and press enter.
```
 gitlab-ctl reconfigure
```

![](https://github.com/shaekhhasanshoron/klovercloud-container-platform-setup/blob/master/static/gitlab/7.gitlab-config.PNG)

5. Exit from the pod with the following command

```
exit
```

#### Step Four: Validate Url

Now check if `https://github.console.klovercloud.com` access the gitlab or not.
