# Fraud Detection MLOps

Real-time fraud detection MLOps MVP. A RandomForestClassifier is trained on a synthetic financial transaction dataset, served via FastAPI, containerised with Docker, provisioned on Kubernetes (Minikube) through Terraform, and monitored with Prometheus and Grafana.

## Status

| Phase | Description | Status |
|---|---|---|
| 1 | Model training + MLflow tracking | Complete |
| 2 | FastAPI service + Docker | Complete |
| 3 | Terraform + Kubernetes (3-replica API) | Complete |
| 4 | Prometheus + Grafana monitoring | Complete |
| 5 | Jenkinsfile + docs + local Git | Complete |

## Architecture

```
Synthetic dataset
      |
  model/train.py  ──► MLflow (mlflow.db + artifacts/)
      |
  artifacts/fraud_model.joblib
      |
  app/main.py  ──►  FastAPI (/ping  /health  /predict  /metrics)
      |
  Dockerfile  ──►  fraud-detection-api:latest
      |
  infra/main.tf  ──►  Terraform  ──►  Minikube (fraud-mlops-p4)
                                         |
                              kubernetes/namespace.yaml
                              kubernetes/deployment.yaml   (3 replicas)
                              kubernetes/service.yaml      (NodePort 8000)
                                         |
                              kubernetes/monitoring/
                                  prometheus-config.yaml   (scrape fraud-detection-service:8000/metrics)
                                  prometheus-deployment.yaml + service (ClusterIP :9090)
                                  grafana-deployment.yaml  + service  (ClusterIP :3000)
                                  grafana-datasource.yaml
                                  grafana-dashboard*.yaml
```

## Profile Safety

| Project | Minikube profile | Status |
|---|---|---|
| Project 3 | `minikube` | Stopped, protected — never touch |
| Project 4 | `fraud-mlops-p4` | Running for demo |

Every kubectl command for this project uses `--context=fraud-mlops-p4`.
Every minikube command uses `-p fraud-mlops-p4`.

## Prerequisites

- Python 3.11
- Docker Desktop
- Minikube v1.38+
- Terraform v1.x
- kubectl

## Local Run — Step by Step

### 1. Environment setup

```powershell
.\scripts\bootstrap.ps1
```

Creates `.venv`, upgrades pip, installs `requirements.txt`.

### 2. Train model

```powershell
.\scripts\train.ps1
```

Trains RandomForestClassifier, logs to MLflow (`mlflow.db`), writes:

- `artifacts/fraud_model.joblib`
- `artifacts/feature_names.json`
- `artifacts/metrics.json`
- `artifacts/sample_request.json`

View the MLflow UI:

```powershell
.venv\Scripts\python.exe -m mlflow ui --backend-store-uri mlflow.db
# open http://127.0.0.1:5000
```

### 3. Run tests

```powershell
.\scripts\test.ps1
# expected: 5 passed, 1 warning
```

### 4. Run the API locally

```powershell
.\scripts\run-local.ps1
# open http://127.0.0.1:8000/docs
```

Quick smoke test:

```powershell
curl.exe http://127.0.0.1:8000/ping
curl.exe -X POST http://127.0.0.1:8000/predict -H "Content-Type: application/json" -d (Get-Content artifacts\sample_request.json -Raw)
```

### 5. Build Docker image

```powershell
.\scripts\build-docker.ps1
docker images fraud-detection-api
```

### 6. Start Minikube (Project 4 only)

Start Docker Desktop first, then:

```powershell
minikube start -p fraud-mlops-p4 --driver=docker --cpus=2 --memory=2400 --keep-context
```

Do not start or modify the `minikube` profile (Project 3).

### 7. Provision with Terraform

```powershell
terraform -chdir=infra init
terraform -chdir=infra fmt
terraform -chdir=infra validate
terraform -chdir=infra plan
terraform -chdir=infra apply -auto-approve
```

### 8. Verify Kubernetes API

```powershell
kubectl --context=fraud-mlops-p4 get nodes
kubectl --context=fraud-mlops-p4 -n fraud-mlops get deployments
kubectl --context=fraud-mlops-p4 -n fraud-mlops get replicasets
kubectl --context=fraud-mlops-p4 -n fraud-mlops get pods -o wide
kubectl --context=fraud-mlops-p4 -n fraud-mlops get services
.\scripts\verify-api.ps1
```

Expected: 3 replica pods Running, NodePort service on port 32696.

### 9. Deploy monitoring

```powershell
.\scripts\deploy-monitoring.ps1
```

Deploys Prometheus (port 9090) and Grafana (port 3000) into the `fraud-mlops` namespace.

### 10. Open Prometheus

```powershell
kubectl --context=fraud-mlops-p4 -n fraud-mlops port-forward svc/prometheus-service 9090:9090
# open http://127.0.0.1:9090
# Targets → fraud-detection-api should show health = up
# Query: fraud_api_requests_total
```

### 11. Open Grafana

```powershell
kubectl --context=fraud-mlops-p4 -n fraud-mlops port-forward svc/grafana-service 3000:3000
# open http://127.0.0.1:3000
# login: admin / admin
```

Helper that prints the commands:

```powershell
.\scripts\open-monitoring.ps1
```

## Running Tests

```powershell
.\scripts\test.ps1
# or directly:
.venv\Scripts\python.exe -m pytest -v
```

Tests are in `tests/test_api.py` (5 tests covering ping, health, predict, metrics, docs).

## Restoring Project 3

Project 3 can be restored at any time:

```powershell
minikube start -p minikube
```

Only one profile should be running at a time to avoid Docker Desktop memory pressure.

## CI/CD

The `Jenkinsfile` defines a declarative pipeline:

1. Checkout
2. Setup (bootstrap.ps1 — creates .venv, installs requirements.txt)
3. Lint / Test (test.ps1 — runs the 5 pytest tests)
4. Docker Build (build-docker.ps1 — builds fraud-detection-api:latest)
5. Deploy — **gated by `DEPLOY=false`** (set to `true` to apply manifests to the cluster)

The Deploy stage is disabled by default so Jenkins never auto-modifies the live cluster during a demo.
