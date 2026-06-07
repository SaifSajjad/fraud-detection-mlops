$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$Profile = "fraud-mlops-p4"
$Namespace = "fraud-mlops"
$ImageName = "fraud-detection-api:latest"
$StartMemory = 2400

function Add-ReportLine {
    param([string]$Text)
    Add-Content -LiteralPath (Join-Path $Root "docs\FINAL_REPORT.md") -Value $Text
}

function Invoke-NativeCapture {
    param(
        [string]$FilePath,
        [string[]]$Arguments
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $FilePath @Arguments 2>&1 | Out-String
        [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output   = $output
        }
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
}

function Invoke-NativeChecked {
    param(
        [string]$Label,
        [string]$FilePath,
        [string[]]$Arguments
    )

    Write-Host ""
    Write-Host "==> $Label"
    $result = Invoke-NativeCapture -FilePath $FilePath -Arguments $Arguments
    if (-not [string]::IsNullOrWhiteSpace($result.Output)) {
        Write-Host $result.Output.TrimEnd()
    }
    if ($result.ExitCode -ne 0) {
        throw "$Label failed with exit code $($result.ExitCode). Output: $($result.Output)"
    }
    return $result
}

Invoke-NativeChecked "Confirm Docker is available" "docker" @("info") | Out-Null

Write-Host ""
Write-Host "==> Check Project 4 Minikube status ($Profile)"
$statusResult = Invoke-NativeCapture -FilePath "minikube" -Arguments @("status", "-p", $Profile)
if (-not [string]::IsNullOrWhiteSpace($statusResult.Output)) {
    Write-Host $statusResult.Output.TrimEnd()
}

if ($statusResult.ExitCode -ne 0 -or $statusResult.Output -match "Stopped|Nonexistent|not found|Profile .* not found") {
    Write-Host "Starting isolated Project 4 Minikube profile: $Profile"
    Invoke-NativeChecked "Start Project 4 Minikube profile" "minikube" @(
        "start", "-p", $Profile, "--driver=docker", "--cpus=2", "--memory=$StartMemory", "--keep-context"
    ) | Out-Null
}

Invoke-NativeChecked "Verify Project 4 Minikube node is Ready" "kubectl" @(
    "--context=$Profile", "wait", "--for=condition=Ready", "node", "--all", "--timeout=180s"
) | Out-Null
Invoke-NativeChecked "Show Project 4 node" "kubectl" @("--context=$Profile", "get", "nodes") | Out-Null

Invoke-NativeChecked "Confirm local Docker image exists" "docker" @("image", "inspect", $ImageName) | Out-Null

Invoke-NativeChecked "Load Docker image into Project 4 Minikube profile" "minikube" @(
    "image", "load", "-p", $Profile, $ImageName
) | Out-Null

Invoke-NativeChecked "Apply namespace" "kubectl" @("--context=$Profile", "apply", "-f", "kubernetes/namespace.yaml") | Out-Null
Invoke-NativeChecked "Apply Deployment" "kubectl" @("--context=$Profile", "apply", "-f", "kubernetes/deployment.yaml") | Out-Null
Invoke-NativeChecked "Apply Service" "kubectl" @("--context=$Profile", "apply", "-f", "kubernetes/service.yaml") | Out-Null

Invoke-NativeChecked "Wait for deployment rollout" "kubectl" @(
    "--context=$Profile", "-n", $Namespace, "rollout", "status", "deployment/fraud-detection-api", "--timeout=180s"
) | Out-Null

Invoke-NativeChecked "Wait for API pods to become Ready" "kubectl" @(
    "--context=$Profile", "-n", $Namespace, "wait", "--for=condition=Ready", "pod", "-l", "app=fraud-detection-api", "--timeout=180s"
) | Out-Null

Invoke-NativeChecked "Show deployments" "kubectl" @("--context=$Profile", "-n", $Namespace, "get", "deployments") | Out-Null
Invoke-NativeChecked "Show ReplicaSets" "kubectl" @("--context=$Profile", "-n", $Namespace, "get", "replicasets") | Out-Null
Invoke-NativeChecked "Show pods" "kubectl" @("--context=$Profile", "-n", $Namespace, "get", "pods", "-o", "wide") | Out-Null
Invoke-NativeChecked "Show services" "kubectl" @("--context=$Profile", "-n", $Namespace, "get", "services") | Out-Null

Add-ReportLine ""
Add-ReportLine "## Phase 3 - Kubernetes Provisioning"
Add-ReportLine ""
Add-ReportLine "- Minikube provisioning script completed."
Add-ReportLine "- Project 4 Minikube profile: $Profile"
Add-ReportLine "- Project 4 profile memory target: ${StartMemory}MB"
Add-ReportLine "- Namespace: $Namespace"
Add-ReportLine "- Deployment: fraud-detection-api"
Add-ReportLine "- Replicas: 3"
Add-ReportLine "- Existing Project 3 profile `minikube` was not started, stopped, reset, deleted, or reused by this script."
