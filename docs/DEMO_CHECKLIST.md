# Demo Checklist

Target duration: 5–8 minutes. Run each command exactly as written — all Kubernetes
commands are scoped to the `fraud-mlops-p4` context.

---

## Pre-demo setup (before recording)

```powershell
# Confirm Docker is healthy
docker info --format "Server Version: {{.ServerVersion}}"

# Confirm Project 4 is running
minikube status -p fraud-mlops-p4

# Confirm Project 3 is stopped and protected
minikube status -p minikube
```

---

## 1. Project structure

Show the top-level layout in the terminal or file explorer. Highlight:

- `app/main.py` — FastAPI service
- `model/train.py` — training script
- `kubernetes/` — manifests
- `infra/` — Terraform
- `Jenkinsfile` — CI pipeline
- `docs/` — evidence and reports

---

## 2. Phase 1 — Model + MLflow

Show the metrics file:

```powershell
Get-Content artifacts\metrics.json
```

Expected output (approximately):

```json
{"accuracy": 0.9675, "precision": 0.8205, "recall": 0.7191, "f1": 0.7665}
```

Open MLflow UI (optional, for recording):

```powershell
.venv\Scripts\python.exe -m mlflow ui --backend-store-uri mlflow.db
# open http://127.0.0.1:5000 in browser
```

---

## 3. Phase 2 — FastAPI + Docker

Show tests passing:

```powershell
.\scripts\test.ps1
# expected: 5 passed, 1 warning
```

Show the Docker image:

```powershell
docker images fraud-detection-api
```

---

## 4. Phase 3 — Kubernetes (Project 4 only)

Show Project 3 is protected (not running):

```powershell
minikube status -p minikube
```

Show Project 4 node:

```powershell
kubectl --context=fraud-mlops-p4 get nodes
```

Show all pods (3 API replicas + Prometheus + Grafana):

```powershell
kubectl --context=fraud-mlops-p4 -n fraud-mlops get pods -o wide
```

Expected output:

```
NAME                                   READY   STATUS    RESTARTS
fraud-detection-api-...                1/1     Running   ...
fraud-detection-api-...                1/1     Running   ...
fraud-detection-api-...                1/1     Running   ...
grafana-...                            1/1     Running   ...
prometheus-...                         1/1     Running   ...
```

Show deployments:

```powershell
kubectl --context=fraud-mlops-p4 -n fraud-mlops get deployments
```

Show ReplicaSet:

```powershell
kubectl --context=fraud-mlops-p4 -n fraud-mlops get replicasets
```

Show services:

```powershell
kubectl --context=fraud-mlops-p4 -n fraud-mlops get services
```

Send a prediction through the Kubernetes service:

```powershell
.\scripts\verify-api.ps1
```

---

## 5. Phase 4 — Prometheus + Grafana

Open Prometheus (run in a separate terminal, kill after recording):

```powershell
kubectl --context=fraud-mlops-p4 -n fraud-mlops port-forward svc/prometheus-service 9090:9090
# open http://127.0.0.1:9090/targets
# fraud-detection-api target health should be "up"
```

Query a metric:

```
# In the Prometheus expression browser:
fraud_api_requests_total
```

Open Grafana (run in a separate terminal, kill after recording):

```powershell
kubectl --context=fraud-mlops-p4 -n fraud-mlops port-forward svc/grafana-service 3000:3000
# open http://127.0.0.1:3000
# login: admin / admin
# health check: http://127.0.0.1:3000/api/health → {"database":"ok"}
```

---

## 6. Phase 5 — CI Pipeline + Git

Show the Jenkinsfile stages:

```powershell
Get-Content Jenkinsfile
```

Show git log:

```powershell
git log --oneline -5
```

Show the README:

```powershell
Get-Content README.md
```

---

## Port-forward cleanup

After recording, kill all port-forwards:

```powershell
Get-Process kubectl -ErrorAction SilentlyContinue | Stop-Process -Force
```
