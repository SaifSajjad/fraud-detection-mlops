# Screenshot Checklist

Capture each screen during the demo recording. All kubectl commands use
`--context=fraud-mlops-p4`. Suggested order matches the demo flow.

---

## Phase 1 — Model + MLflow

- [ ] `Get-Content artifacts\metrics.json` — accuracy 0.9675, f1 0.7665
- [ ] MLflow UI at `http://127.0.0.1:5000` — experiment list
- [ ] MLflow run detail — metrics tab showing accuracy, precision, recall, f1

## Phase 2 — API + Docker

- [ ] `.\scripts\test.ps1` output — **5 passed, 1 warning**
- [ ] FastAPI Swagger at `http://127.0.0.1:8000/docs` (local run)
- [ ] Local `/predict` response — `{"prediction":1,"label":"Fraudulent","fraud_probability":1.0}`
- [ ] `docker images fraud-detection-api` — image present, tag `latest`

## Phase 3 — Kubernetes

- [ ] `minikube status -p minikube` — Project 3 **Stopped** (protected)
- [ ] `minikube status -p fraud-mlops-p4` — Project 4 **Running**
- [ ] `terraform -chdir=infra apply -auto-approve` — apply success output
- [ ] `kubectl --context=fraud-mlops-p4 get nodes` — node **Ready**
- [ ] `kubectl --context=fraud-mlops-p4 -n fraud-mlops get deployments` — fraud-detection-api **3/3**, prometheus **1/1**, grafana **1/1**
- [ ] `kubectl --context=fraud-mlops-p4 -n fraud-mlops get replicasets` — desired/ready match
- [ ] `kubectl --context=fraud-mlops-p4 -n fraud-mlops get pods -o wide` — all 5 pods **Running**
- [ ] `kubectl --context=fraud-mlops-p4 -n fraud-mlops get services` — fraud-detection-service (NodePort), prometheus-service (ClusterIP), grafana-service (ClusterIP)
- [ ] `.\scripts\verify-api.ps1` — Kubernetes prediction `{"prediction":1,"label":"Fraudulent","fraud_probability":1.0}`

## Phase 4 — Prometheus + Grafana

- [ ] `http://127.0.0.1:9090/targets` — fraud-detection-api target health = **up**
- [ ] Prometheus query `fraud_api_requests_total` — non-zero value returned
- [ ] Grafana login page at `http://127.0.0.1:3000`
- [ ] Grafana dashboard showing request metrics
- [ ] `http://127.0.0.1:3000/api/health` response — `{"database":"ok"}`

## Phase 5 — Jenkins + Git

- [ ] `Jenkinsfile` open in editor — 5 stages visible, DEPLOY=false comment visible
- [ ] `git log --oneline` — commit present
- [ ] `README.md` — project overview visible
