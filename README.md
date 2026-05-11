# Advanced CI/CD + Kubernetes Demo

Frontend HTML + one backend microservice + Docker Compose + Kubernetes + GitHub Actions.

## Full deployment guide

Russian step-by-step guide for GitHub + Google Cloud VM + Kubernetes:

[docs/DEPLOY_GITHUB_GCP_RU.md](docs/DEPLOY_GITHUB_GCP_RU.md)

## One-command local run

```bash
make compose-up
```

Open: http://localhost:8080

Stop:

```bash
make compose-down
```

## One-command Kubernetes run

Requirements: Docker, kubectl, Minikube, make.

```bash
make all
make k8s-open
```

Clean:

```bash
make k8s-clean
```

## How it works

### Docker Compose
Compose creates a private network. The frontend proxies `/api/` to `http://backend:3000/api/` because `backend` is the service name.

### Kubernetes
Kubernetes uses Deployments and Services:

- Deployment keeps the desired number of Pods running.
- Service gives stable DNS/networking for Pods.
- `backend` is a ClusterIP service used by frontend Nginx.
- `frontend` is a NodePort service exposed on port 30080.

### GitHub Actions CI/CD
Pipeline flow:

```text
Push -> Test -> Build Docker images -> Push to GHCR -> Deploy to Kubernetes -> Verify rollout
```

For deployment, add a GitHub secret called `KUBE_CONFIG` with base64 kubeconfig.

```bash
cat ~/.kube/config | base64 -w 0
```

## Useful commands

```bash
kubectl get all
kubectl get pods -o wide
kubectl logs deployment/backend
kubectl logs deployment/frontend
kubectl describe deployment backend
kubectl rollout status deployment/backend
kubectl rollout restart deployment/backend
kubectl scale deployment backend --replicas=4
```

Internal cluster test:

```bash
kubectl run test-client --rm -it --image=curlimages/curl -- sh
curl http://backend:3000/api/health
curl http://backend:3000/api/message
exit
```
