$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root
$Profile = "fraud-mlops-p4"
$Namespace = "fraud-mlops"

kubectl --context=$Profile apply -f kubernetes\namespace.yaml
docker image inspect fraud-detection-api:latest | Out-Null
minikube image load -p $Profile fraud-detection-api:latest
kubectl --context=$Profile apply -f kubernetes\deployment.yaml
kubectl --context=$Profile apply -f kubernetes\service.yaml
kubectl --context=$Profile -n $Namespace rollout status deployment/fraud-detection-api --timeout=180s
kubectl --context=$Profile -n $Namespace get deployments
kubectl --context=$Profile -n $Namespace get replicasets
kubectl --context=$Profile -n $Namespace get pods -o wide
kubectl --context=$Profile -n $Namespace get services
& (Join-Path $Root "scripts\verify-api.ps1")
