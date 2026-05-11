SHELL := /bin/bash
.PHONY: help compose-up compose-down k8s-start k8s-build k8s-deploy k8s-open k8s-status k8s-clean all
help:
	@echo "Available commands:"
	@echo "  make compose-up     Build and run locally with Docker Compose"
	@echo "  make compose-down   Stop local Docker Compose app"
	@echo "  make all            Start Minikube, build images, deploy to Kubernetes"
	@echo "  make k8s-open       Open frontend service from Minikube"
	@echo "  make k8s-status     Show Kubernetes resources"
	@echo "  make k8s-clean      Delete Kubernetes resources"
compose-up:
	docker compose up --build
compose-down:
	docker compose down
k8s-start:
	minikube start --driver=docker
k8s-build:
	eval $$(minikube docker-env) && docker build -t sre-backend:v1 ./backend
	eval $$(minikube docker-env) && docker build -t sre-frontend:v1 ./frontend
k8s-deploy:
	kubectl apply -f k8s/
k8s-open:
	minikube service frontend
k8s-status:
	kubectl get all
	kubectl get pods -o wide
k8s-clean:
	kubectl delete -f k8s/ --ignore-not-found=true
all: k8s-start k8s-build k8s-deploy k8s-status
	@echo "Application deployed. Run: make k8s-open"
