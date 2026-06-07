$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$Profile = "fraud-mlops-p4"
$Namespace = "fraud-mlops"
$PortForwardPort = 8080

function Add-ReportLine {
    param([string]$Text)
    Add-Content -LiteralPath (Join-Path $Root "docs\FINAL_REPORT.md") -Value $Text
}

function Invoke-NativeChecked {
    param(
        [string]$FilePath,
        [string[]]$Arguments
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $FilePath @Arguments 2>&1 | Out-String
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($exitCode -ne 0) {
        throw "$FilePath $($Arguments -join ' ') failed with exit code $exitCode. Output: $output"
    }
    return $output
}

function Get-ReadyApiPodCount {
    $podJson = Invoke-NativeChecked "kubectl" @("--context=$Profile", "-n", $Namespace, "get", "pods", "-l", "app=fraud-detection-api", "-o", "json") | ConvertFrom-Json
    @(
        $podJson.items | Where-Object {
            $_.status.phase -eq "Running" -and
            @($_.status.containerStatuses | Where-Object { $_.ready -eq $true }).Count -gt 0
        }
    ).Count
}

function Start-ScopedPortForward {
    $stdout = Join-Path $Root "artifacts\api-port-forward.stdout.log"
    $stderr = Join-Path $Root "artifacts\api-port-forward.stderr.log"
    Remove-Item -LiteralPath $stdout, $stderr -ErrorAction SilentlyContinue

    Start-Process -FilePath "kubectl" `
        -ArgumentList @("--context=$Profile", "-n", $Namespace, "port-forward", "service/fraud-detection-service", "${PortForwardPort}:8000") `
        -WorkingDirectory $Root `
        -PassThru `
        -WindowStyle Hidden `
        -RedirectStandardOutput $stdout `
        -RedirectStandardError $stderr
}

function Invoke-Json {
    param(
        [string]$Method,
        [string]$Uri,
        [string]$Body = $null
    )

    $params = @{
        Method     = $Method
        Uri        = $Uri
        TimeoutSec = 10
    }
    if ($Body) {
        $params["ContentType"] = "application/json"
        $params["Body"] = $Body
    }
    Invoke-RestMethod @params
}

$readyPodCount = Get-ReadyApiPodCount
if ($readyPodCount -ne 3) {
    Invoke-NativeChecked "kubectl" @("--context=$Profile", "-n", $Namespace, "get", "pods") | Write-Host
    throw "Expected exactly 3 ready API pods, found $readyPodCount."
}

$portForward = Start-ScopedPortForward
$baseUrl = "http://127.0.0.1:$PortForwardPort"
$accessMethod = "temporary scoped port-forward"

try {
    $portReady = $false
    for ($i = 0; $i -lt 30; $i++) {
        try {
            Invoke-Json -Method "GET" -Uri "$baseUrl/ping" | Out-Null
            $portReady = $true
            break
        }
        catch {
            Start-Sleep -Seconds 1
        }
    }
    if (-not $portReady) {
        throw "Scoped API port-forward did not become ready on $baseUrl."
    }

    $ping = Invoke-Json -Method "GET" -Uri "$baseUrl/ping"
    $health = Invoke-Json -Method "GET" -Uri "$baseUrl/health"
    $sample = Get-Content -LiteralPath "artifacts\sample_request.json" -Raw
    $prediction = Invoke-Json -Method "POST" -Uri "$baseUrl/predict" -Body $sample
    $metricsResponse = Invoke-WebRequest -Method Get -Uri "$baseUrl/metrics" -TimeoutSec 10 -UseBasicParsing
    $metricsVisible = $metricsResponse.Content -match "fraud_api_requests_total"

    Write-Host "Context: $Profile"
    Write-Host "Namespace: $Namespace"
    Write-Host "Ready pod count: $readyPodCount"
    Write-Host "Access method: $accessMethod"
    Write-Host "Service URL: $baseUrl"
    Write-Host "Ping response:"
    $ping | ConvertTo-Json -Depth 5
    Write-Host "Health response:"
    $health | ConvertTo-Json -Depth 5
    Write-Host "Prediction JSON:"
    $prediction | ConvertTo-Json -Depth 5
    Write-Host "Metrics visibility: $metricsVisible"

    $evidence = @()
    $evidence += "PHASE 3 API VERIFICATION"
    $evidence += "Context: $Profile"
    $evidence += "Namespace: $Namespace"
    $evidence += "Ready pod count: $readyPodCount"
    $evidence += "Access method: $accessMethod"
    $evidence += "Service URL: $baseUrl"
    $evidence += "Ping: $($ping | ConvertTo-Json -Compress)"
    $evidence += "Health: $($health | ConvertTo-Json -Compress)"
    $evidence += "Prediction: $($prediction | ConvertTo-Json -Compress)"
    $evidence += "Metrics visible: $metricsVisible"
    $evidence | Set-Content -LiteralPath "docs\PHASE3_API_VERIFICATION.txt" -Encoding UTF8

    Add-ReportLine ""
    Add-ReportLine "## Phase 3 - Kubernetes API Verification"
    Add-ReportLine ""
    Add-ReportLine "- Context: $Profile"
    Add-ReportLine "- Namespace: $Namespace"
    Add-ReportLine "- Ready API pod count: $readyPodCount"
    Add-ReportLine "- Access method: $accessMethod"
    Add-ReportLine "- Service URL: $baseUrl"
    Add-ReportLine "- Ping response: $($ping | ConvertTo-Json -Compress)"
    Add-ReportLine "- Health response: $($health | ConvertTo-Json -Compress)"
    Add-ReportLine "- Kubernetes prediction JSON: $($prediction | ConvertTo-Json -Compress)"
    Add-ReportLine "- Metrics endpoint contains fraud_api_requests_total: $metricsVisible"
}
finally {
    if ($portForward -and -not $portForward.HasExited) {
        Stop-Process -Id $portForward.Id -Force
    }
}
