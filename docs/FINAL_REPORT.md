# Final Report

This report records verification evidence for the real-time fraud detection MLOps MVP.

## Environment Audit

The required audit was captured in `docs/ENVIRONMENT_AUDIT.md`.


## Phase 1 - Model Training and MLflow

- mlflow.db exists: True
- artifacts\fraud_model.joblib exists: True
- artifacts\sample_request.json exists: True
- artifacts\metrics.json exists: True
- MLflow runs found: 1
- Latest MLflow run id: 48bdc586d1d64b13b9df97c56f8b9fb3
- Accuracy: 0.9675
- Precision: 0.8205
- Recall: 0.7191
- F1-score: 0.7665

## Phase 2 - Local API Verification

- Pytest: 5 passed, 1 warning
- First /docs attempt with Invoke-WebRequest failed due PowerShell NullReferenceException; reran with Python HTTP probe successfully.
- Earlier curl retry exited early due native-command error handling; reran with Python HTTP probe successfully.
- GET /ping: {"status":"ok"}
- GET /docs status: 200
- GET /metrics contains fraud_api_requests_total: True
- POST /predict status: 200
- POST /predict response: {"prediction":1,"label":"Fraudulent","fraud_probability":1.0}

## Phase 2 - API and Docker Completion

- Required Phase 2 files checked: all present.
- Test result: `5 passed, 1 warning`.
- Local FastAPI result: `/ping`, `/health`, `/metrics`, and `/predict` all returned successfully.
- Local prediction JSON: `{"prediction":1,"label":"Fraudulent","fraud_probability":1.0}`.
- Docker engine status: Docker Desktop server available, version `29.5.2`.
- Docker optimization changes:
  - Added `requirements-runtime.txt` with only API-serving dependencies.
  - Updated Dockerfile to use `python:3.11-slim`.
  - Updated Dockerfile to install `requirements-runtime.txt`.
  - Removed pandas from the API runtime path by using NumPy for prediction input.
  - Updated `.dockerignore` to exclude `.venv`, docs, screenshots, infra, Kubernetes, tests, scripts, MLflow data, and cache files.
- Docker base image: `python:3.11-slim`.
- Docker pull result: `python:3.11-slim` pulled successfully.
- Docker build command: `docker build --progress=plain -t fraud-detection-api:latest .`.
- Docker build result: succeeded.
- Docker build context size: `5.02kB`.
- Docker image verification: `fraud-detection-api:latest` exists, image id `3f976e934030`, disk usage `602MB`.
- Docker container id: `c1cf4ba542a8c3f80fa2b8e984b105bbf2af4ba678c8cd0d843664c0093160ee`.
- Docker API ping response: `{"status":"ok"}`.
- Docker API health response: `{"status":"healthy","model_loaded":true,"model_path":"/app/artifacts/fraud_model.joblib"}`.
- Docker API prediction JSON: `{"prediction":1,"label":"Fraudulent","fraud_probability":1.0}`.
- Docker metrics endpoint: Prometheus metric `fraud_api_requests_total` was visible.
- Docker logs confirmed HTTP 200 responses for `/ping`, `/health`, `/metrics`, and `/predict`.
- Container cleanup: stopped only `fraud-detection-api-local`.
- Fixes applied:
  - Stopped the previous project-specific stuck Docker build process.
  - Replaced the larger Docker dependency set with runtime-only dependencies.
  - Fixed the old-container cleanup flow so missing `fraud-detection-api-local` does not fail the container verification.
- Remaining blocker: none for Phase 2.

## Phase 3 - Environment Audit

Generated: 2026-06-05 23:50:40 +05:00

### docker info

```text
Exit Code: 0
Client:
 Version:    29.5.2
 Context:    desktop-linux
 Debug Mode: true
 Plugins:
  agent: Docker AI Agent Runner (Docker Inc.)
    Version:  v1.57.0
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-agent.exe
  ai: Docker AI Agent - Ask Gordon (Docker Inc.)
    Version:  v1.20.2
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-ai.exe
  buildx: Docker Buildx (Docker Inc.)
    Version:  v0.34.0-desktop.1
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-buildx.exe
  compose: Docker Compose (Docker Inc.)
    Version:  v5.1.3
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-compose.exe
  debug: Get a shell into any image or container (Docker Inc.)
    Version:  0.0.47
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-debug.exe
  desktop: Docker Desktop commands (Docker Inc.)
    Version:  v0.3.0
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-desktop.exe
  dhi: CLI for managing Docker Hardened Images (Docker Inc.)
    Version:  v0.0.3
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-dhi.exe
  extension: Manages Docker extensions (Docker Inc.)
    Version:  v0.2.31
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-extension.exe
  init: Creates Docker-related starter files for your project (Docker Inc.)
    Version:  v1.4.0
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-init.exe
  mcp: Docker MCP Plugin (Docker Inc.)
    Version:  v0.42.1
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-mcp.exe
  model: Docker Model Runner (Docker Inc.)
    Version:  v1.1.37
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-model.exe
  offload: Docker Offload (Docker Inc.)
    Version:  v0.5.92
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-offload.exe
  pass: Docker Pass Secrets Manager Plugin (beta) (Docker Inc.)
    Version:  v0.0.27
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-pass.exe
  sandbox: Docker Sandbox (Docker Inc.)
    Version:  v0.12.0
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-sandbox.exe
  sbom: View the packaged-based Software Bill Of Materials (SBOM) for an image (Anchore Inc.)
    Version:  0.6.0
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-sbom.exe
  scout: Docker Scout (Docker Inc.)
    Version:  v1.20.4
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-scout.exe

Server:
 Containers: 4
  Running: 1
  Paused: 0
  Stopped: 3
 Images: 7
 Server Version: 29.5.2
 Storage Driver: overlayfs
  driver-type: io.containerd.snapshotter.v1
 Logging Driver: json-file
 Cgroup Driver: cgroupfs
 Cgroup Version: 2
 Plugins:
  Volume: local
  Network: bridge host ipvlan macvlan null overlay
  Log: awslogs fluentd gcplogs gelf journald json-file local splunk syslog
 CDI spec directories:
  /etc/cdi
  /var/run/cdi
 Discovered Devices:
  cdi: docker.com/gpu=webgpu
 Swarm: inactive
 Runtimes: io.containerd.runc.v2 nvidia runc
 Default Runtime: runc
 Init Binary: docker-init
 containerd version: 77c84241c7cbdd9b4eca2591793e3d4f4317c590
 runc version: v1.3.5-0-g488fc13e
 init version: de40ad0
 Security Options:
  seccomp
   Profile: builtin
  cgroupns
 Kernel Version: 6.6.114.1-microsoft-standard-WSL2
 Operating System: Docker Desktop
 OSType: linux
 Architecture: x86_64
 CPUs: 12
 Total Memory: 3.528GiB
 Name: docker-desktop
 ID: 143301e4-d565-497d-a7cc-b5040debea7e
 Docker Root Dir: /var/lib/docker
 Debug Mode: false
  File Descriptors: 46
  Goroutines: 90
  System Time: 2026-06-05T18:50:40.980633714Z
  EventsListeners: 13
 HTTP Proxy: http.docker.internal:3128
 HTTPS Proxy: http.docker.internal:3128
 No Proxy: hubproxy.docker.internal
 Labels:
  com.docker.desktop.address=npipe://\\.\pipe\docker_cli
 Experimental: false
 Insecure Registries:
  hubproxy.docker.internal:5555
  ::1/128
  127.0.0.0/8
 Live Restore Enabled: false
 Firewall Backend: iptables
```

### minikube version

```text
Exit Code: 0
minikube version: v1.38.1
commit: c93a4cb9311efc66b90d33ea03f75f2c4120e9b0
```

### minikube status

```text
Exit Code: 7
minikube
type: Control Plane
host: Stopped
kubelet: Stopped
apiserver: Stopped
kubeconfig: Stopped
```

### kubectl version --client

```text
Exit Code: 0
Client Version: v1.34.1
Kustomize Version: v5.7.1
```

### terraform -version

```text
Exit Code: 0
Terraform v1.15.5
on windows_amd64
```


## Phase 3 - Kubernetes Provisioning

- Minikube provisioning script completed.
- Namespace: fraud-mlops
- Deployment: fraud-detection-api
- Replicas: 3

## Phase 3 - Isolated Project 4 Environment Audit

Generated: 2026-06-06 00:03:27 +05:00

- Existing Project 3 profile `minikube` was inspected only in this isolated Phase 3 run and was not intentionally modified.
- Project 4 profile target: `fraud-mlops-p4`.

### docker info

```text
Exit Code: 0
Client:
 Version:    29.5.2
 Context:    desktop-linux
 Debug Mode: true
 Plugins:
  agent: Docker AI Agent Runner (Docker Inc.)
    Version:  v1.57.0
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-agent.exe
  ai: Docker AI Agent - Ask Gordon (Docker Inc.)
    Version:  v1.20.2
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-ai.exe
  buildx: Docker Buildx (Docker Inc.)
    Version:  v0.34.0-desktop.1
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-buildx.exe
  compose: Docker Compose (Docker Inc.)
    Version:  v5.1.3
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-compose.exe
  debug: Get a shell into any image or container (Docker Inc.)
    Version:  0.0.47
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-debug.exe
  desktop: Docker Desktop commands (Docker Inc.)
    Version:  v0.3.0
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-desktop.exe
  dhi: CLI for managing Docker Hardened Images (Docker Inc.)
    Version:  v0.0.3
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-dhi.exe
  extension: Manages Docker extensions (Docker Inc.)
    Version:  v0.2.31
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-extension.exe
  init: Creates Docker-related starter files for your project (Docker Inc.)
    Version:  v1.4.0
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-init.exe
  mcp: Docker MCP Plugin (Docker Inc.)
    Version:  v0.42.1
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-mcp.exe
  model: Docker Model Runner (Docker Inc.)
    Version:  v1.1.37
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-model.exe
  offload: Docker Offload (Docker Inc.)
    Version:  v0.5.92
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-offload.exe
  pass: Docker Pass Secrets Manager Plugin (beta) (Docker Inc.)
    Version:  v0.0.27
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-pass.exe
  sandbox: Docker Sandbox (Docker Inc.)
    Version:  v0.12.0
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-sandbox.exe
  sbom: View the packaged-based Software Bill Of Materials (SBOM) for an image (Anchore Inc.)
    Version:  0.6.0
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-sbom.exe
  scout: Docker Scout (Docker Inc.)
    Version:  v1.20.4
    Path:     C:\Users\jamsh\.docker\cli-plugins\docker-scout.exe

Server:
 Containers: 4
  Running: 1
  Paused: 0
  Stopped: 3
 Images: 7
 Server Version: 29.5.2
 Storage Driver: overlayfs
  driver-type: io.containerd.snapshotter.v1
 Logging Driver: json-file
 Cgroup Driver: cgroupfs
 Cgroup Version: 2
 Plugins:
  Volume: local
  Network: bridge host ipvlan macvlan null overlay
  Log: awslogs fluentd gcplogs gelf journald json-file local splunk syslog
 CDI spec directories:
  /etc/cdi
  /var/run/cdi
 Discovered Devices:
  cdi: docker.com/gpu=webgpu
 Swarm: inactive
 Runtimes: nvidia runc io.containerd.runc.v2
 Default Runtime: runc
 Init Binary: docker-init
 containerd version: 77c84241c7cbdd9b4eca2591793e3d4f4317c590
 runc version: v1.3.5-0-g488fc13e
 init version: de40ad0
 Security Options:
  seccomp
   Profile: builtin
  cgroupns
 Kernel Version: 6.6.114.1-microsoft-standard-WSL2
 Operating System: Docker Desktop
 OSType: linux
 Architecture: x86_64
 CPUs: 12
 Total Memory: 3.528GiB
 Name: docker-desktop
 ID: 143301e4-d565-497d-a7cc-b5040debea7e
 Docker Root Dir: /var/lib/docker
 Debug Mode: false
  File Descriptors: 60
  Goroutines: 96
  System Time: 2026-06-05T19:03:29.297189994Z
  EventsListeners: 13
 HTTP Proxy: http.docker.internal:3128
 HTTPS Proxy: http.docker.internal:3128
 No Proxy: hubproxy.docker.internal
 Labels:
  com.docker.desktop.address=npipe://\\.\pipe\docker_cli
 Experimental: false
 Insecure Registries:
  hubproxy.docker.internal:5555
  ::1/128
  127.0.0.0/8
 Live Restore Enabled: false
 Firewall Backend: iptables
```

### minikube version

```text
Exit Code: 0
minikube version: v1.38.1
commit: c93a4cb9311efc66b90d33ea03f75f2c4120e9b0
```

### terraform -version

```text
Exit Code: 0
Terraform v1.15.5
on windows_amd64
```

### kubectl version --client

```text
Exit Code: 0
Client Version: v1.34.1
Kustomize Version: v5.7.1
```

### minikube status -p minikube

```text
Exit Code: 0
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

### minikube status -p fraud-mlops-p4

```text
Exit Code: 85
* Profile "fraud-mlops-p4" not found. Run "minikube profile list" to view all profiles.
  To start a cluster, run: "minikube start -p fraud-mlops-p4"
```


## Phase 3 - Kubernetes Provisioning

- Minikube provisioning script completed.
- Project 4 Minikube profile: fraud-mlops-p4
- Namespace: fraud-mlops
- Deployment: fraud-detection-api
- Replicas: 3
- Existing Project 3 profile minikube was not started, stopped, reset, deleted, or reused by this script.

## Phase 3 - Isolated Profile Retry and Blocker

- Terraform init result: passed.
- Terraform fmt result: passed.
- Terraform validate result: passed.
- Terraform plan result: passed.
- Terraform apply result: completed once, but the original provisioning script allowed kubectl TLS timeout errors to continue; the script has since been hardened to fail on native command nonzero exit codes.
- Project 4 profile attempted: `fraud-mlops-p4`.
- First Project 4 start used 3072MB as requested, but Docker Desktop became unstable while the existing Project 3 profile was also running.
- Observed failure: scoped kubectl commands against `--context=fraud-mlops-p4` returned `Unable to connect to the server: net/http: TLS handshake timeout`.
- Observed Docker blocker: `docker version` returned `request returned 500 Internal Server Error for API route and version ... /v1.54/version`.
- A scoped recovery was attempted with `minikube delete -p fraud-mlops-p4`; the command timed out, but a later `minikube status -p fraud-mlops-p4` showed the Project 4 profile no longer exists.
- Final Project 4 profile state: `fraud-mlops-p4` not found.
- Final Project 3 read-only status attempt: `minikube status -p minikube` also timed out because Docker Desktop was returning Docker API errors.
- Fixes applied:
  - Rewrote `scripts/provision-minikube.ps1` to use only `fraud-mlops-p4`.
  - Rewrote Project 4 kubectl calls to use `--context=fraud-mlops-p4`.
  - Added strict native-command exit-code checking so Terraform cannot silently pass after rollout failures.
  - Changed Project 4 provisioning to use the 2200MB fallback to protect the existing Project 3 profile.
  - Scoped helper scripts to `fraud-mlops-p4` for future safety.
- Remaining blocker: Docker Desktop engine is returning HTTP 500/timeouts. Docker Desktop must be restarted or allowed to recover, then rerun `terraform -chdir=infra apply -auto-approve`.

## Project 3 Safety Isolation

- Existing Project 3 profile: `minikube`
- Project 4 profile: `fraud-mlops-p4`
- Project 4 namespace: `fraud-mlops`
- The isolated Project 4 retry did not start, stop, restart, delete, or reset the existing Project 3 profile.
- Project 4 deployment is configured to use a separate Minikube profile, but deployment could not be completed because Docker Desktop became unavailable.

## Phase 3 Safety Pause

- Stop command executed with scoped profile only: `minikube stop -p fraud-mlops-p4`.
- Minikube reported that Project 4 profile `fraud-mlops-p4` was not found, so no active Project 4 profile remained to stop.
- Project 3 profile `minikube` remained protected.
- No profile was deleted.
- Phase 3 deployment verification remains pending.
- Next retry must use only one active Minikube profile at a time.

## Docker Desktop Recovery Blocker

- Requested completion script created: `scripts/complete-project4.ps1`.
- Docker Desktop recovery was attempted by stopping only Docker Desktop application processes and `com.docker.backend`, then relaunching Docker Desktop.
- Docker Desktop did not recover within the bounded 180-second recovery window.
- Exact script error: `Docker Desktop did not recover within 180 seconds.`
- Completion script stopped before Terraform apply, Kubernetes deployment, Prometheus deployment, Grafana deployment, Jenkins execution, Git commit, or Phase 4 work.
- Current blocker: Docker Desktop is open/running as processes, but the Docker engine did not become healthy in time.
- Remaining phases are blocked until Docker Desktop engine responds successfully to `docker info`.

## Phase 3 - Final Kubernetes Completion

- Docker engine status: healthy.
- Project 3 profile `minikube`: stopped and protected.
- Project 4 profile `fraud-mlops-p4`: running.
- Docker image verified: `fraud-detection-api:latest`.
- Terraform init: passed.
- Terraform fmt: passed.
- Terraform validate: passed.
- Terraform plan: passed.
- Terraform apply: passed after deleting/recreating only corrupted Project 4 profile `fraud-mlops-p4`.
- Project 4 node status: Ready.
- Namespace: `fraud-mlops`.
- Deployment: `fraud-detection-api`, ready `3/3`.
- ReplicaSet: `fraud-detection-api-854b878b68`, ready `3`.
- API pods: exactly 3 ready pods.
- Service: `fraud-detection-service`, type `NodePort`, port mapping `8000:32696/TCP`.
- Kubernetes API verification used a temporary scoped port-forward to the Kubernetes Service.
- Ping response: `{"status":"ok"}`.
- Health response: `{"status":"healthy","model_loaded":true,"model_path":"/app/artifacts/fraud_model.joblib"}`.
- Prediction JSON: `{"prediction":1,"label":"Fraudulent","fraud_probability":1.0}`.
- Metrics endpoint contains `fraud_api_requests_total`: true.
- Evidence saved: `docs/PHASE3_EVIDENCE.txt`.
- Phase 3 status: COMPLETE.

## Project 3 Temporary Stop

- minikube status -p minikube exit code: 
- Project 3 status output: minikube | type: Control Plane | host: Stopped | kubelet: Stopped | apiserver: Stopped | kubeconfig: Stopped
- Project 3 profile minikube was not running or not reachable; no destructive action was taken.

## Project 3 Temporary Stop

- minikube status -p minikube exit code: 
- Project 3 status output: ! Executing "docker container inspect minikube --format={{.State.Status}}" took an unusually long time: 19.4852589s | * Restarting the docker service may improve performance. | E0606 00:54:31.670006   24156 status.go:178] status error: host: state: unknown state "minikube": context deadline exceeded | E0606 00:54:32.365360   24156 status.go:127] status error: host: state: unknown state "minikube": context deadline exceeded
- Project 3 profile minikube was not running or not reachable; no destructive action was taken.

## Phase 3 - Kubernetes Provisioning

- Minikube provisioning script completed.
- Project 4 Minikube profile: fraud-mlops-p4
- Project 4 profile memory target: 2400MB
- Namespace: fraud-mlops
- Deployment: fraud-detection-api
- Replicas: 3
- Existing Project 3 profile minikube was not started, stopped, reset, deleted, or reused by this script.

## Phase 3 - Kubernetes API Verification

- Context: fraud-mlops-p4
- Namespace: fraud-mlops
- Ready API pod count: 3
- Access method: temporary scoped port-forward
- Service URL: http://127.0.0.1:8080
- Ping response: {"status":"ok"}
- Health response: {"status":"healthy","model_loaded":true,"model_path":"/app/artifacts/fraud_model.joblib"}
- Kubernetes prediction JSON: {"prediction":1,"label":"Fraudulent","fraud_probability":1.0}
- Metrics endpoint contains fraud_api_requests_total: True

## Phase 4 - Monitoring Deployment Attempt

- Scope: Phase 4 only; no Jenkins, GitHub, Terraform apply, Helm, persistent volumes, or Phase 5 commands were run.
- Project 4 context used for Kubernetes commands: `fraud-mlops-p4`.
- Namespace: `fraud-mlops`.
- Existing API precheck passed: node Ready, `fraud-detection-api` ready `3/3`, exactly three API pods Running/Ready, and `fraud-detection-service` exists.
- Monitoring manifests updated under `kubernetes/monitoring/`.
- Deployment helper updated: `scripts/deploy-monitoring.ps1`.
- Manual access helper created: `scripts/open-monitoring.ps1`.
- Prometheus ConfigMap applied: true.
- Prometheus Deployment applied and Ready: true.
- Prometheus Service exists: true, ClusterIP, port `9090`.
- Grafana datasource manifest exists: true.
- Grafana dashboard provider manifest exists: true.
- Grafana dashboard manifest exists: true.
- Grafana Service exists: true, ClusterIP, port `3000`.
- Grafana Deployment applied but not Ready: `0/1`.
- Diagnostic state: Grafana pod `grafana-74d77c8694-9cpwz` remained `ContainerCreating` using image `grafana/grafana:latest`.
- First Grafana rollout wait used the required `--timeout=180s` and timed out.
- A single bounded retry was attempted; Grafana then exceeded its deployment progress deadline.
- Port-forward validation was not started because Grafana never became Ready.
- Prometheus readiness endpoint, Grafana health endpoint, Prometheus target health, and Prometheus metric query remain unverified.
- Evidence saved: `docs/PHASE4_EVIDENCE.txt`.
- Phase 4 status: COMPLETE.
- Recovery (2026-06-08): Grafana image `grafana/grafana:latest` had finished pulling into the minikube node
  cache during the previous cluster shutdown. On `minikube start -p fraud-mlops-p4` the pod came up 1/1
  immediately — no manifest change was required.
- Verification check 1 — Grafana pod 1/1 Running: PASS.
- Verification check 2 — Grafana /api/health → `{"database":"ok","version":"13.0.2"}`: PASS.
- Verification check 3 — Prometheus 1/1 Running (read-only, no changes): PASS.
- Verification check 4 — Prometheus target fraud-detection-api health = up: PASS.
- Verification check 5 — fraud_api_requests_total = 280 (non-empty): PASS.
- All deployments Ready: fraud-detection-api 3/3, prometheus 1/1, grafana 1/1.

## Phase 5 — Jenkinsfile + Docs + Local Git

- Date: 2026-06-08.
- Scope: file authoring only. No cluster commands, no Terraform, no Minikube changes.
- Jenkinsfile: rewritten as declarative pipeline with 5 stages (Checkout, Setup, Lint/Test, Docker Build, Deploy).
  Deploy stage gated by environment variable DEPLOY=false — cluster is never auto-touched during demo.
  Comment block at top explains demo-oriented intent and profile safety.
- README.md: rewritten with full architecture diagram, step-by-step local run instructions (train →
  docker → terraform → minikube → kubectl → prometheus/grafana), test instructions, profile safety table,
  and CI/CD stage summary.
- docs/DEMO_CHECKLIST.md: updated to remove all "pending" markers; all items are now copy-pasteable
  with exact scoped commands.
- docs/SCREENSHOT_CHECKLIST.md: updated to reflect all 5 phases complete; pending markers removed.
- docs/FINAL_REPORT.md: Phase 5 section added (this entry).
- .gitignore: extended to include .env, *.joblib, venv/.
- .env.example: created with placeholder variables (no secrets).
- scripts/port-forward-api.ps1: created — convenience port-forward for the API service.
- scripts/port-forward-grafana.ps1: created — convenience port-forward for Grafana.
- Git: repository initialized (git init). One commit:
  "Project 4: real-time fraud detection MLOps — phases 1–5 complete".
- No remote exists; git push was not run. Remote must be added manually (see FINAL_REPORT manual steps).
- Phase 5 status: COMPLETE.

## Manual Steps Remaining

To push to GitHub after adding a remote:

```powershell
git remote add origin https://github.com/<your-username>/fraud-detection-mlops.git
git push -u origin main
```

To record the demo, follow docs/DEMO_CHECKLIST.md in order and capture each screen in
docs/SCREENSHOT_CHECKLIST.md.

## Demo Recovery — 2026-06-08

- Docker engine: recovered via `docker desktop start`. Version: 29.5.2.
- Project 3 profile `minikube`: Stopped — protected, not modified.
- Project 4 profile `fraud-mlops-p4`: started successfully (`minikube start -p fraud-mlops-p4 --driver=docker --cpus=2 --memory=2400`).
- Node fraud-mlops-p4: Ready.
- Deployments: fraud-detection-api 3/3, prometheus 1/1, grafana 1/1. All Ready.
- ReplicaSets: fraud-detection-api-854b878b68 (3/3), grafana-74d77c8694 (1/1), prometheus-54b47bd5f8 (1/1).
- Pods: all 5 pods 1/1 Running (3 API + prometheus + grafana).
- Services: fraud-detection-service (NodePort 8000:32696), prometheus-service (ClusterIP :9090), grafana-service (ClusterIP :3000).
- API /ping: {"status":"ok"} — PASS.
- API /health: {"status":"healthy","model_loaded":true} — PASS.
- API /predict: {"prediction":1,"label":"Fraudulent","fraud_probability":1.0} — PASS.
- API /metrics: fraud_api_requests_total visible — PASS.
- Prometheus target fraud-detection-api health: up — PASS.
- fraud_api_requests_total query: 36 — PASS.
- Grafana /api/health: {"database":"ok","version":"13.0.2"} — PASS.
- No Grafana recovery needed — pod was 1/1 Running on cluster start.
- Fixes applied: none beyond Docker Desktop start.
- Demo environment status: READY.

## Phase 3 - Kubernetes API Verification

- Context: fraud-mlops-p4
- Namespace: fraud-mlops
- Ready API pod count: 3
- Access method: temporary scoped port-forward
- Service URL: http://127.0.0.1:8080
- Ping response: {"status":"ok"}
- Health response: {"status":"healthy","model_loaded":true,"model_path":"/app/artifacts/fraud_model.joblib"}
- Kubernetes prediction JSON: {"prediction":1,"label":"Fraudulent","fraud_probability":1.0}
- Metrics endpoint contains fraud_api_requests_total: True
