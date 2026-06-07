$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$Project3Profile = "minikube"
$Project4Profile = "fraud-mlops-p4"
$Namespace = "fraud-mlops"
$DockerDesktopExe = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
$DockerDesktopFallbackExe = Join-Path $env:LOCALAPPDATA "Programs\DockerDesktop\Docker Desktop.exe"

function Add-ReportLine {
    param([string]$Text)
    Add-Content -LiteralPath (Join-Path $Root "docs\FINAL_REPORT.md") -Value $Text
}

function Invoke-NativeCapture {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [int]$TimeoutSeconds = 120
    )

    $safe = ($FilePath + "-" + (($Arguments -join "-") -replace '[^A-Za-z0-9_.-]', '_'))
    $stdout = Join-Path $Root "artifacts\$safe.stdout.txt"
    $stderr = Join-Path $Root "artifacts\$safe.stderr.txt"
    Remove-Item -LiteralPath $stdout, $stderr -ErrorAction SilentlyContinue

    $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -WorkingDirectory $Root -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        Stop-Process -Id $process.Id -Force
        return [pscustomobject]@{
            ExitCode = 124
            Output   = "Timed out after $TimeoutSeconds seconds."
        }
    }
    $output = ((Get-Content -LiteralPath $stdout -ErrorAction SilentlyContinue | Out-String) + (Get-Content -LiteralPath $stderr -ErrorAction SilentlyContinue | Out-String)).Trim()
    [pscustomobject]@{
        ExitCode = $process.ExitCode
        Output   = $output
    }
}

function Invoke-NativeChecked {
    param(
        [string]$Label,
        [string]$FilePath,
        [string[]]$Arguments,
        [int]$TimeoutSeconds = 120
    )
    Write-Host ""
    Write-Host "==> $Label"
    $result = Invoke-NativeCapture -FilePath $FilePath -Arguments $Arguments -TimeoutSeconds $TimeoutSeconds
    if ($result.Output) { Write-Host $result.Output }
    if ($result.ExitCode -ne 0) {
        throw "$Label failed with exit code $($result.ExitCode). Output: $($result.Output)"
    }
    return $result.Output
}

function Test-DockerHealthy {
    $result = Invoke-NativeCapture -FilePath "docker" -Arguments @("info") -TimeoutSeconds 5
    return ($result.ExitCode -eq 0)
}

function Recover-DockerDesktop {
    if (Test-DockerHealthy) {
        Write-Host "Docker Desktop is healthy."
        return
    }

    Write-Host "Docker Desktop is not healthy; restarting Docker Desktop application processes only."
    Get-Process "Docker Desktop" -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process "com.docker.backend" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 10

    $dockerExeToStart = $DockerDesktopExe
    if (-not (Test-Path -LiteralPath $dockerExeToStart) -and (Test-Path -LiteralPath $DockerDesktopFallbackExe)) {
        $dockerExeToStart = $DockerDesktopFallbackExe
    }
    if (-not (Test-Path -LiteralPath $dockerExeToStart)) {
        throw "Docker Desktop executable not found at '$DockerDesktopExe' or '$DockerDesktopFallbackExe'."
    }
    Start-Process $dockerExeToStart

    for ($i = 0; $i -lt 12; $i++) {
        Start-Sleep -Seconds 10
        if (Test-DockerHealthy) {
            Write-Host "Docker Desktop recovered."
            return
        }
    }
    throw "Docker Desktop did not recover within 180 seconds."
}

function Stop-Project3IfRunning {
    $status = Invoke-NativeCapture -FilePath "minikube" -Arguments @("status", "-p", $Project3Profile) -TimeoutSeconds 60
    Add-ReportLine ""
    Add-ReportLine "## Project 3 Temporary Stop"
    Add-ReportLine ""
    Add-ReportLine "- `minikube status -p $Project3Profile` exit code: $($status.ExitCode)"
    $flatStatus = $status.Output -replace "(`r`n|`n|`r)", " | "
    Add-ReportLine "- Project 3 status output: $flatStatus"
    if ($status.Output -match "host:\s*Running|host: Running|Running") {
        Invoke-NativeChecked "Stop Project 3 profile temporarily" "minikube" @("stop", "-p", $Project3Profile) 180 | Out-Null
        Add-ReportLine "- Project 3 profile `minikube` was stopped temporarily to free Docker Desktop resources. It was not deleted, reset, or recreated."
    }
    else {
        Add-ReportLine "- Project 3 profile `minikube` was not running or not reachable; no destructive action was taken."
    }
}

function Remove-StaleProject4ContainerIfNeeded {
    $profiles = Invoke-NativeCapture -FilePath "minikube" -Arguments @("profile", "list") -TimeoutSeconds 60
    $profileExists = $profiles.Output -match [regex]::Escape($Project4Profile)
    $containers = Invoke-NativeCapture -FilePath "docker" -Arguments @("ps", "-a", "--format", "{{.Names}}") -TimeoutSeconds 60
    $staleContainerExists = @($containers.Output -split "`r?`n" | Where-Object { $_ -eq $Project4Profile }).Count -gt 0
    if (-not $profileExists -and $staleContainerExists) {
        Invoke-NativeChecked "Remove stale Project 4 Docker container only" "docker" @("rm", "-f", $Project4Profile) 120 | Out-Null
        Add-ReportLine "- Removed stale disposable Project 4 Docker container `$Project4Profile` because the Minikube profile was missing."
    }
}

function Run-TerraformProvisioning {
    Invoke-NativeChecked "Terraform init" "terraform" @("-chdir=infra", "init") 180 | Out-Null
    Invoke-NativeChecked "Terraform fmt" "terraform" @("-chdir=infra", "fmt") 120 | Out-Null
    Invoke-NativeChecked "Terraform validate" "terraform" @("-chdir=infra", "validate") 120 | Out-Null
    Invoke-NativeChecked "Terraform plan" "terraform" @("-chdir=infra", "plan") 180 | Out-Null
    $stateList = Invoke-NativeCapture -FilePath "terraform" -Arguments @("-chdir=infra", "state", "list") -TimeoutSeconds 120
    $nullResource = @($stateList.Output -split "`r?`n" | Where-Object { $_ -match "^null_resource\." } | Select-Object -First 1)
    if ($stateList.ExitCode -eq 0 -and $nullResource) {
        Invoke-NativeChecked "Terraform apply with explicit null_resource replacement" "terraform" @("-chdir=infra", "apply", "-replace=$nullResource", "-auto-approve") 900 | Out-Null
    }
    else {
        Invoke-NativeChecked "Terraform apply" "terraform" @("-chdir=infra", "apply", "-auto-approve") 900 | Out-Null
    }
}

function Save-Phase3Evidence {
    $evidence = @()
    $evidence += "PHASE 3 EVIDENCE"
    $evidence += ""
    $evidence += "kubectl --context=$Project4Profile get nodes"
    $evidence += Invoke-NativeChecked "Capture nodes" "kubectl" @("--context=$Project4Profile", "get", "nodes") 120
    $evidence += "kubectl --context=$Project4Profile -n $Namespace get deployments"
    $evidence += Invoke-NativeChecked "Capture deployments" "kubectl" @("--context=$Project4Profile", "-n", $Namespace, "get", "deployments") 120
    $evidence += "kubectl --context=$Project4Profile -n $Namespace get replicasets"
    $evidence += Invoke-NativeChecked "Capture replicasets" "kubectl" @("--context=$Project4Profile", "-n", $Namespace, "get", "replicasets") 120
    $evidence += "kubectl --context=$Project4Profile -n $Namespace get pods -o wide"
    $evidence += Invoke-NativeChecked "Capture pods" "kubectl" @("--context=$Project4Profile", "-n", $Namespace, "get", "pods", "-o", "wide") 120
    $evidence += "kubectl --context=$Project4Profile -n $Namespace get services"
    $evidence += Invoke-NativeChecked "Capture services" "kubectl" @("--context=$Project4Profile", "-n", $Namespace, "get", "services") 120
    if (Test-Path "docs\PHASE3_API_VERIFICATION.txt") {
        $evidence += ""
        $evidence += Get-Content -LiteralPath "docs\PHASE3_API_VERIFICATION.txt"
    }
    $evidence | Set-Content -LiteralPath "docs\PHASE3_EVIDENCE.txt" -Encoding UTF8
}

Stop-Project3IfRunning
Recover-DockerDesktop
Remove-StaleProject4ContainerIfNeeded
Run-TerraformProvisioning
& (Join-Path $Root "scripts\verify-api.ps1")
Save-Phase3Evidence
& (Join-Path $Root "scripts\deploy-monitoring.ps1")

Add-ReportLine ""
Add-ReportLine "## Project 4 Cluster State"
Add-ReportLine ""
Add-ReportLine "- Final desired cluster state: Project 4 profile `fraud-mlops-p4` running; Project 3 profile `minikube` stopped."
Add-ReportLine "- Restore Project 3 later with `.\scripts\restore-project3.ps1`."
