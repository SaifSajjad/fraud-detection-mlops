$ErrorActionPreference = "Stop"

$Context   = "fraud-mlops-p4"
$Namespace = "fraud-mlops"
$LocalPort = 8080

Write-Host "Port-forwarding fraud-detection-service → http://127.0.0.1:$LocalPort"
Write-Host "Press Ctrl+C to stop."
kubectl --context=$Context -n $Namespace port-forward svc/fraud-detection-service "${LocalPort}:8000"
