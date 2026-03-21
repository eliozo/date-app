# Date App using Python Flask via Minikube

This repository contains a simple Python Flask web application that displays the current date/time in format `YYYY-MM-DD HH:mm:ss` and Kubernetes manifests to deploy it to a local cluster.

## Prerequisites

### Tools
- `kubectl`
- A Kubernetes cluster: **Minikube**
- Docker image for the app

### Manifests
Kubernetes resources included:
- `Deployment` (`deployment.yaml`)
- `Service` (`service.yaml`)
- `Ingress` (`ingress.yaml`)

The container listens on **port 5000**. The Service exposes it on **port 80** inside the cluster. Ingress routes HTTP traffic to the Service.

---

## Deploy on Minikube

### 1) Start Minikube

```
minikube start
```

### 2) Check Minikube profile (figure out on which driver it is running)

```
minikube profile list
```

### 3) Enable ingress controller

```
minikube addons enable ingress
kubectl -n ingress-nginx get pods
```
Have to wait for a bit until ingress-nginx controller pod is Running

### 4) Build and load the image into Minikube

If the image is only on your local machine, then Kubernetes inside Minikube won't have it, so you have to load it into Minikube:

```
docker build -t date-app:rootless .
minikube image load date-app:rootless
```


### 5) Create and apply deployment, service and ingress

```
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress
```

### 6) Check if those resources are up and running

```
kubectl get pods
kubectl get svc
kubectl get ingress
```

### 7) Get minikube ip

```
minikube ip
```

### 8) Changing /etc/hosts file by adding line

```
sudo vim /etc/hosts
<minikube-ip-address> date-app.local
```

### Additional troubleshooting 

1) Can't open http://date-app.local (this was the issue I had)

I realized the app is not opening via http://date-app.local/, it was loading for a long time and nothing changed

At first I tried to debug it by trying to access it via curl request, but it failed to connect.

```
curl -H "Host: date-app.local" http://<minikube-ip-address>/
```

Then I read some documentation that it is a common issue on macOS with Docker drivers, and I mapped date-app.local to 127.0.0.1 in /etc/hosts file and ran `minikube tunnel` and it finally was reachable via http://date-app.local/

I mapped the host in /etc/hosts to localhost like this:

```
sudo sh -c 'echo "127.0.0.1 date-app.local" >> /etc/hosts'
```

Some additional commands that would help debug this issue:

```
# Check if Ingress controller is running
kubectl -n ingress-gninx get pods
# Check if Ingress exists and has rules 
kubectl describe ingress date-app
kubectl get ingress -o wide 
```

2) Pods are not starting

This can happen when the cluster can't fetch your image

Trobleshoot:
```
# Check the pods events
kubectl describe pod -l app=date-app
```

Fix:
```
# If using Minikube and a local image, run:
minikube image load date-app:rootless
```
Also check if deployment.yaml contains `imagePullPolicy: IfNotPresent` is set for local testing

3) Service has no endpoints 

```
# Check endpoints:
kubectl get endpoints date-app
# Check labels on pods:
kubectl get pods --show-labels
```
In this case you have to ensure that in service.yaml spec.selector matches Pod labels (app: date-app) and ensure pods are ready with `kubectl get pods`

4) Ingress exists but returns 404

This can be because of the wrong hostname or wrong path or backend service/port

You need to inspect the Ingress:

```
kubectl describe ingress date-app
```

Make sure you are accessing the correct URL (it should be same as in ingress.yaml) and service name and port match your Service.

5) Readiness/Liveness probes failing

```
# Check pod status and events:
kubectl describe pod -l app=date-app
kubectl logs -l app=date-app
```
If app route changes, then you need to update probes in deployment.yaml to the correct path.

6) Other good debug commands

```
# See everything, each resource
kubectl get all
# Pod logs
kubectl logs -l app=date-app --tail=200 (Will show latest 200 lines of logs)
# Describe resources for events
kubectl describe deployment date-app
kubectl describe svc date-app
kubectl describe ingress date-app
# Ingress controller logs
kubectl -n ingress-nginx logs -l app.kubernetes.io/component=controller --tail=200
```

7) After work is done, you should perform cleanup to remove resources, stop minikube and if using tunnel, stop it by pressing `Ctrl+C` in the terminal

```
kubectl delete -f ingress.yaml
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
minikube stop
```
