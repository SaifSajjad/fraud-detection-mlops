# Architecture

This project is a local-first MLOps MVP for real-time financial transaction fraud detection.

```mermaid
flowchart LR
    Client[Client / Demo Request] --> API[FastAPI Fraud API]
    API --> Model[Random Forest Model]
    API --> Metrics[Prometheus Metrics Endpoint]
    Train[Training Script] --> Dataset[Synthetic Transactions]
    Dataset --> Model
    Train --> MLflow[MLflow SQLite Tracking]
    Train --> Artifacts[Model Artifacts]
    Artifacts --> Docker[Docker Image]
    Docker --> K8s[Kubernetes Deployment]
    Terraform[Terraform null_resource] --> K8s
    K8s --> ReplicaSet[ReplicaSet]
    ReplicaSet --> Pod1[Pod 1]
    ReplicaSet --> Pod2[Pod 2]
    ReplicaSet --> Pod3[Pod 3]
    Service[Kubernetes NodePort Service] --> Pod1
    Service --> Pod2
    Service --> Pod3
    Prometheus[Prometheus] --> Metrics
    Grafana[Grafana Dashboard] --> Prometheus
    Jenkins[Jenkins Pipeline] --> Train
    Jenkins --> Docker
    Jenkins --> Terraform
    GitHub[GitHub Repository] --> Jenkins
```

## Components

- `model/train.py` creates an imbalanced synthetic dataset with `make_classification`, trains `RandomForestClassifier`, logs metrics to MLflow, and saves model artifacts.
- `app/main.py` serves `/predict`, `/health`, `/ping`, `/metrics`, and Swagger documentation.
- Docker packages the FastAPI service and generated artifacts.
- Terraform calls the local PowerShell provisioning script to start Minikube, load the Docker image, and deploy Kubernetes resources.
- Prometheus scrapes `fraud-detection-service:8000/metrics`.
- Grafana provisions a default Prometheus datasource and fraud dashboard.
- Jenkinsfile documents a realistic Windows CI/CD pipeline.

