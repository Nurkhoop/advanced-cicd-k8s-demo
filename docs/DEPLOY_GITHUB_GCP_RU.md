# Полная инструкция: GitHub + Google Cloud VM + Kubernetes

Эта инструкция подходит для текущего проекта: frontend на Nginx, backend на Node.js, Docker images в GHCR и деплой через GitHub Actions в Kubernetes на сервере Google Cloud.

## 1. Что должно быть готово

Локально:

```bash
git --version
docker --version
kubectl version --client
```

На Google Cloud:

- Compute Engine VM с Ubuntu 22.04/24.04.
- Открыт SSH.
- Открыт TCP порт `30080` для доступа к frontend.
- Открыт TCP порт `6443` для Kubernetes API, чтобы GitHub Actions мог делать deploy.
- На сервере установлен Kubernetes. Самый простой вариант для одной VM: `k3s`.

## 2. Залить проект на GitHub

В корне проекта:

```bash
git init
git branch -M main
git add .
git commit -m "Initial CI/CD Kubernetes demo"
git remote add origin https://github.com/YOUR_USERNAME/advanced-cicd-k8s-demo.git
git push -u origin main
```

Замени `YOUR_USERNAME` на свой GitHub username. Репозиторий на GitHub создай пустым, без README, чтобы не было конфликта.

## 3. Подготовить сервер Google Cloud

Зайди на VM:

```bash
ssh USER@SERVER_EXTERNAL_IP
```

Установи Docker:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Установи k3s. Важно добавить внешний IP сервера в TLS SAN, иначе kubeconfig с внешним IP может не пройти проверку сертификата:

```bash
SERVER_IP=$(curl -s ifconfig.me)
curl -sfL https://get.k3s.io | sh -s - server --tls-san "$SERVER_IP" --write-kubeconfig-mode 644
sudo kubectl get nodes
```

Сделай kubeconfig, который GitHub Actions сможет использовать:

```bash
cp /etc/rancher/k3s/k3s.yaml ~/kubeconfig
sed -i "s/127.0.0.1/$SERVER_IP/g" ~/kubeconfig
cat ~/kubeconfig | base64 -w 0
```

Скопируй длинную base64 строку. Она нужна для GitHub Secret.

## 4. Добавить GitHub Secret

В GitHub репозитории:

`Settings -> Secrets and variables -> Actions -> New repository secret`

Создай secret:

```text
Name: KUBE_CONFIG
Value: строка base64 из предыдущего шага
```

## 5. Доступ Kubernetes к GHCR images

После первого push GitHub Actions соберёт images и отправит их в GitHub Container Registry.

Самый простой вариант для учебного проекта:

1. Открой GitHub profile/org.
2. Перейди в `Packages`.
3. Найди `advanced-demo-backend` и `advanced-demo-frontend`.
4. В настройках package сделай visibility `Public`.

Если хочешь оставить images private, создай Personal Access Token с правом `read:packages`, затем на сервере выполни:

```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_GITHUB_TOKEN \
  --docker-email=YOUR_EMAIL
```

После этого в deployment нужно добавить `imagePullSecrets`. Для учебного варианта проще сделать packages public.

## 6. Открыть порты в Google Cloud firewall

Нужно открыть frontend порт `30080` и Kubernetes API порт `6443`.

В Google Cloud Console для frontend:

`VPC network -> Firewall -> Create firewall rule`

Параметры:

```text
Name: allow-frontend-30080
Targets: All instances in the network
Source IPv4 ranges: 0.0.0.0/0
Protocols and ports: tcp:30080
```

Для Kubernetes API создай второе правило:

```text
Name: allow-k8s-api-6443
Targets: All instances in the network
Source IPv4 ranges: 0.0.0.0/0
Protocols and ports: tcp:6443
```

Для учебного проекта это самый простой вариант. Для более безопасной настройки лучше ограничить `6443` конкретными IP или использовать self-hosted GitHub runner прямо на этой VM.

Если используешь network tags, добавь tag к VM и укажи его в firewall rule.

## 7. Запустить CI/CD

Сделай любое изменение и push:

```bash
git add .
git commit -m "Configure deployment docs"
git push
```

Открой:

`GitHub -> repository -> Actions -> Advanced CI/CD to Kubernetes`

Pipeline должен пройти этапы:

```text
Test backend
Build backend image
Build frontend image
Push images to GHCR
Deploy manifests
Rollout backend/frontend
```

## 8. Проверить на сервере

На Google Cloud VM:

```bash
kubectl get pods
kubectl get svc
kubectl rollout status deployment/backend
kubectl rollout status deployment/frontend
kubectl logs deployment/backend
```

Открой в браузере:

```text
http://SERVER_EXTERNAL_IP:30080
```

Проверь кнопки `Call Backend` и `Check Health`.

## 9. Локальная проверка перед push

```bash
cd backend
npm test
cd ..
docker compose config
docker compose up --build
```

Открой локально:

```text
http://localhost:8080
```

Остановить:

```bash
docker compose down
```

## 10. Частые проблемы

Если Pods в статусе `ImagePullBackOff`, значит Kubernetes не может скачать images из GHCR. Сделай packages public или настрой `ghcr-secret`.

Если сайт не открывается по `:30080`, проверь firewall rule в Google Cloud и service:

```bash
kubectl get svc frontend
```

Если GitHub Actions пропускает deploy, значит secret `KUBE_CONFIG` не создан или пустой.

Если rollout завис, смотри события:

```bash
kubectl describe pod POD_NAME
kubectl get events --sort-by=.lastTimestamp
```
