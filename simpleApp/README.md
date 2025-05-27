
# Horizontal Scroll Site Deployment

This guide walks you through the steps to:

1. Build a Docker image for the Horizontal Scroll Site
2. Push the Docker image to Docker Hub
3. Deploy the image on a Kubernetes cluster under the `dev` namespace using a combined manifest
4. Expose the application via a NodePort service
5. Add health probes for better pod management

---

## Prerequisites

- Docker installed on your local machine
- Access to Docker Hub account (`psawant05`)
- Kubernetes cluster with `kubectl` configured to access it
- Permissions to create namespaces, deployments, and services on the cluster

---

## Step 1: Build Docker Image

Navigate to your project directory containing the Dockerfile, then run:

```bash
docker build -t psawant05/horizontal-scroll-site:latest .
```

---

## Step 2: Push Docker Image to Docker Hub

Login to Docker Hub:

```bash
docker login -u psawant05
```

Enter your password or access token when prompted.

Push the image:

```bash
docker push psawant05/horizontal-scroll-site:latest
```

---

## Step 3: Deploy on Kubernetes

The following combined manifest creates the `dev` namespace, deployment, and service.

Save this manifest as `horizontal-site-dev.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: horizontal-site
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: horizontal-site
  template:
    metadata:
      labels:
        app: horizontal-site
    spec:
      containers:
      - name: horizontal-site
        image: psawant05/horizontal-scroll-site:latest
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 3
---
apiVersion: v1
kind: Service
metadata:
  name: horizontal-site-service
  namespace: dev
spec:
  type: NodePort
  selector:
    app: horizontal-site
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30080
```

Apply the manifest:

```bash
kubectl apply -f horizontal-site-dev.yaml
```

---

## Step 4: Access the Application

Get the IP address of any Kubernetes node:

```bash
kubectl get nodes -o wide
```

Visit the app at:

```
http://<NODE-IP>:30080
```

---

## Additional Notes

- You can customize the health check endpoint by modifying the probes in the manifest.
- For production, consider using Ingress instead of NodePort for better routing and TLS termination.
- Scale your deployment by updating the replicas count.

---

## Troubleshooting

- If you get permission errors with Docker commands, ensure your user is added to the `docker` group.
- If Kubernetes pods do not become ready, check pod logs with:

```bash
kubectl logs -n dev <pod-name>
```

---

Feel free to reach out if you need help customizing or extending this setup!
