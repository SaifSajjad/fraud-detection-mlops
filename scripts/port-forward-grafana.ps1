$ErrorActionPreference = "Stop"

$Context   = "fraud-mlops-p4"
$Namespace = "fraud-mlops"
$LocalPort = 3000

Write-Host "Port-forwarding grafana-service → http://127.0.0.1:$LocalPort"
Write-Host "Login: admin / admin"
Write-Host "Health: http://127.0.0.1:$LocalPort/api/health"
Write-Host "Press Ctrl+C to stop."
kubectl --context=$Context -n $Namespace port-forward svc/grafana-service "${LocalPort}:3000"
