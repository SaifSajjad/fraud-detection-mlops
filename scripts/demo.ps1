Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root
$Profile = "fraud-mlops-p4"
$Namespace = "fraud-mlops"

Write-Host "1. Confirming model artifact..."
if (-not (Test-Path "artifacts\fraud_model.joblib")) { throw "Missing artifacts\fraud_model.joblib. Run .\scripts\train.ps1 first." }

Write-Host "2. Running tests..."
& ".\scripts\test.ps1"

Write-Host "3. Confirming Docker image..."
docker image inspect fraud-detection-api:latest *> $null
if ($LASTEXITCODE -ne 0) { & ".\scripts\build-docker.ps1" }

Write-Host "4. Running terraform apply..."
terraform -chdir=infra apply -auto-approve

Write-Host "5. Kubernetes objects..."
kubectl --context=$Profile -n $Namespace get pods -o wide
kubectl --context=$Profile -n $Namespace get replicasets
kubectl --context=$Profile -n $Namespace get services

Write-Host "6. Sending Kubernetes prediction..."
& ".\scripts\verify-api.ps1"

Write-Host "7. Monitoring pods..."
kubectl --context=$Profile -n $Namespace get pods -l 'app in (prometheus,grafana)'

Write-Host "8. Dashboard commands..."
& ".\scripts\port-forward-monitoring.ps1"
