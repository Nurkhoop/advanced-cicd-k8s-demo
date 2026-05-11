# Lecture Notes: Advanced GitHub CI/CD and Kubernetes

## 1. Main idea

SRE is strongly connected with release reliability. A system may be well-designed, but a weak deployment process can still create incidents. Advanced CI/CD and Kubernetes reduce this risk by making delivery automated, traceable, and reversible.

## 2. CI/CD explained academically

Continuous Integration means that every code change is automatically validated. At minimum, this includes tests and image builds.

Continuous Deployment means that validated code can be automatically delivered to runtime infrastructure. In this project, Kubernetes is the runtime platform.

The pipeline is:

```text
Git push -> GitHub Actions -> test -> build images -> push registry -> kubectl apply -> rollout verification
```

The important point is that the pipeline does not SSH into a server and manually restart containers. It updates declarative Kubernetes manifests and lets Kubernetes reconcile the desired state.

## 3. Docker Compose role

Docker Compose is used for local reproducibility. It allows developers and students to run multiple services with one command.

The frontend Nginx container proxies `/api/` to `http://backend:3000/api/`. This works because Compose provides DNS resolution by service name.

## 4. Kubernetes explained

Kubernetes is a desired-state orchestration system.

Instead of running a container manually, we define the required state:

```text
Run two backend replicas and two frontend replicas.
Expose frontend externally.
Expose backend internally.
Restart unhealthy containers.
Do rolling updates safely.
```

Kubernetes objects used in this project:

- Pod: smallest deployable unit
- Deployment: manages Pods, replicas, rollouts, rollbacks
- Service: stable network endpoint for Pods
- Readiness probe: controls traffic eligibility
- Liveness probe: controls restart behavior

## 5. Rolling updates

The Deployment uses:

```yaml
maxUnavailable: 0
maxSurge: 1
```

This means Kubernetes will not reduce available replicas during update and may create one extra temporary Pod. This is an SRE-oriented deployment strategy because it reduces downtime risk.

## 6. Practical lecture flow

1. Show project structure.
2. Run `make compose-up` and explain local service discovery.
3. Run `make all` and explain Minikube deployment.
4. Show `kubectl get all`.
5. Scale backend: `kubectl scale deployment backend --replicas=4`.
6. Delete one Pod and show self-healing.
7. Explain GitHub Actions workflow.
8. Discuss how this pattern becomes production CI/CD.

## 7. Key conclusion

Docker packages the application.
Compose reproduces the local environment.
GitHub Actions automates build and deployment.
Kubernetes maintains desired state.
Together, they form a reliable delivery platform.
