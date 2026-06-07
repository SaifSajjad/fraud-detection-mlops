$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$Profile = "fraud-mlops-p4"
$Namespace = "fraud-mlops"
$ApiPort = 8080
$PrometheusPort = 9090
$GrafanaPort = 3000
$EvidencePath = Join-Path $Root "docs\PHASE4_EVIDENCE.txt"
$PortForwardStartupSeconds = 20

$script:Evidence = New-Object System.Collections.Generic.List[string]

function Add-Evidence {
    param([string]$Text)
    $script:Evidence.Add($Text) | Out-Null
}

function Add-EvidenceSection {
    param([string]$Title, [string]$Content)
    Add-Evidence ""
    Add-Evidence "## $Title"
    Add-Evidence ""
    if ([string]::IsNullOrWhiteSpace($Content)) {
        Add-Evidence "(no output)"
    }
    else {
        Add-Evidence $Content.TrimEnd()
    }
}

function Invoke-Checked {
    param([string]$FilePath, [string[]]$Arguments)

    $commandLine = "$FilePath $($Arguments -join ' ')"
    Write-Host ""
    Write-Host "> $commandLine"

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $outputObjects = & $FilePath @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    $output = ($outputObjects | Out-String).TrimEnd()
    if (-not [string]::IsNullOrWhiteSpace($output)) {
        Write-Host $output
    }

    Add-EvidenceSection $commandLine $output

    if ($exitCode -ne 0) {
        throw "$commandLine failed with exit code $exitCode."
    }

    return $output
}

function Assert-PortFree {
    param([int]$Port)

    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Parse("127.0.0.1"), $Port)
    try {
        $listener.Start()
    }
    catch {
        throw "Local port $Port is already in use. Stop the existing process before running Phase 4 validation."
    }
    finally {
        $listener.Stop()
    }
}

function Start-PortForward {
    param([string]$Name, [string]$Service, [int]$LocalPort, [int]$RemotePort)

    Assert-PortFree -Port $LocalPort

    $stdout = Join-Path $Root "artifacts\$Name-port-forward.stdout.log"
    $stderr = Join-Path $Root "artifacts\$Name-port-forward.stderr.log"
    Remove-Item -LiteralPath $stdout, $stderr -ErrorAction SilentlyContinue

    $arguments = @("--context=$Profile", "-n", $Namespace, "port-forward", "service/$Service", "${LocalPort}:$RemotePort")
    Write-Host ""
    Write-Host "> kubectl $($arguments -join ' ')"
    Add-EvidenceSection "kubectl $($arguments -join ' ')" "Started temporary port-forward for $Service on 127.0.0.1:$LocalPort."

    $process = Start-Process -FilePath "kubectl" `
        -ArgumentList $arguments `
        -WorkingDirectory $Root `
        -PassThru `
        -WindowStyle Hidden `
        -RedirectStandardOutput $stdout `
        -RedirectStandardError $stderr

    Start-Sleep -Milliseconds 500
    if ($process.HasExited) {
        $stdoutText = if (Test-Path -LiteralPath $stdout) { Get-Content -LiteralPath $stdout -Raw } else { "" }
        $stderrText = if (Test-Path -LiteralPath $stderr) { Get-Content -LiteralPath $stderr -Raw } else { "" }
        throw "Port-forward for $Service exited immediately. Stdout: $stdoutText Stderr: $stderrText"
    }

    return $process
}

function Stop-PortForward {
    param([System.Diagnostics.Process]$Process, [string]$Name)

    if ($Process -and -not $Process.HasExited) {
        Write-Host "Stopping temporary $Name port-forward (PID $($Process.Id))."
        Stop-Process -Id $Process.Id -Force
        Wait-Process -Id $Process.Id -Timeout 5 -ErrorAction SilentlyContinue
    }
}

function Wait-Http {
    param([string]$Uri, [int]$Seconds = $PortForwardStartupSeconds)

    $lastError = $null
    for ($i = 0; $i -lt $Seconds; $i++) {
        try {
            return Invoke-WebRequest -Method Get -Uri $Uri -TimeoutSec 5 -UseBasicParsing
        }
        catch {
            $lastError = $_.Exception.Message
            Start-Sleep -Seconds 1
        }
    }

    throw "Timed out after $Seconds seconds waiting for $Uri. Last error: $lastError"
}

function Wait-RestJson {
    param(
        [string]$Uri,
        [hashtable]$Headers = @{},
        [int]$Seconds = $PortForwardStartupSeconds
    )

    $lastError = $null
    for ($i = 0; $i -lt $Seconds; $i++) {
        try {
            return Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -TimeoutSec 5
        }
        catch {
            $lastError = $_.Exception.Message
            Start-Sleep -Seconds 1
        }
    }

    throw "Timed out after $Seconds seconds waiting for $Uri. Last error: $lastError"
}

function Wait-PrometheusTargetUp {
    param([int]$Seconds = 20)

    $lastHealth = "not found"
    for ($i = 0; $i -lt $Seconds; $i++) {
        $targets = Invoke-RestMethod -Method Get -Uri "http://127.0.0.1:$PrometheusPort/api/v1/targets" -TimeoutSec 5
        $target = @($targets.data.activeTargets | Where-Object { $_.labels.job -eq "fraud-detection-api" }) | Select-Object -First 1
        if ($target) {
            $lastHealth = $target.health
            if ($target.health -eq "up") {
                return $target
            }
        }
        Start-Sleep -Seconds 1
    }

    throw "fraud-detection-api Prometheus target did not become up within $Seconds seconds. Last health: $lastHealth"
}

function Wait-PrometheusMetric {
    param([int]$Seconds = 20)

    $query = [System.Uri]::EscapeDataString("sum(fraud_api_requests_total)")
    $lastResponse = $null
    for ($i = 0; $i -lt $Seconds; $i++) {
        $response = Invoke-RestMethod -Method Get -Uri "http://127.0.0.1:$PrometheusPort/api/v1/query?query=$query" -TimeoutSec 5
        $lastResponse = $response
        $results = @($response.data.result)
        if ($response.status -eq "success" -and $results.Count -gt 0 -and $results[0].value.Count -ge 2) {
            return $response
        }
        Start-Sleep -Seconds 1
    }

    throw "Prometheus query sum(fraud_api_requests_total) did not return a valid result within $Seconds seconds. Last response: $($lastResponse | ConvertTo-Json -Depth 10 -Compress)"
}

function Wait-GrafanaDashboard {
    param([hashtable]$Headers, [int]$Seconds = 20)

    $lastResponse = $null
    for ($i = 0; $i -lt $Seconds; $i++) {
        $response = Invoke-RestMethod -Method Get -Uri "http://127.0.0.1:$GrafanaPort/api/search?query=Fraud%20Detection%20MLOps%20Dashboard" -Headers $Headers -TimeoutSec 5
        $lastResponse = $response
        $match = @($response | Where-Object { $_.title -eq "Fraud Detection MLOps Dashboard" }) | Select-Object -First 1
        if ($match) {
            return $match
        }
        Start-Sleep -Seconds 1
    }

    throw "Grafana dashboard provisioning was not visible within $Seconds seconds. Last response: $($lastResponse | ConvertTo-Json -Depth 10 -Compress)"
}

$apiPortForward = $null
$prometheusPortForward = $null
$grafanaPortForward = $null

try {
    Add-Evidence "PHASE 4 MONITORING EVIDENCE"
    Add-Evidence "Generated: $(Get-Date -Format o)"
    Add-Evidence "Context: $Profile"
    Add-Evidence "Namespace: $Namespace"

    $apiDeployment = Invoke-Checked "kubectl" @("--context=$Profile", "-n", $Namespace, "get", "deployment", "fraud-detection-api")

    $applyFiles = @(
        "kubernetes/monitoring/prometheus-config.yaml",
        "kubernetes/monitoring/prometheus-deployment.yaml",
        "kubernetes/monitoring/prometheus-service.yaml",
        "kubernetes/monitoring/grafana-datasource.yaml",
        "kubernetes/monitoring/grafana-dashboard-provider.yaml",
        "kubernetes/monitoring/grafana-dashboard.yaml",
        "kubernetes/monitoring/grafana-deployment.yaml",
        "kubernetes/monitoring/grafana-service.yaml"
    )

    foreach ($file in $applyFiles) {
        Invoke-Checked "kubectl" @("--context=$Profile", "apply", "-f", $file) | Out-Null
    }

    $prometheusRollout = Invoke-Checked "kubectl" @("--context=$Profile", "-n", $Namespace, "rollout", "status", "deployment/prometheus", "--timeout=180s")
    $grafanaRollout = Invoke-Checked "kubectl" @("--context=$Profile", "-n", $Namespace, "rollout", "status", "deployment/grafana", "--timeout=180s")

    $pods = Invoke-Checked "kubectl" @("--context=$Profile", "-n", $Namespace, "get", "pods", "-o", "wide")
    $services = Invoke-Checked "kubectl" @("--context=$Profile", "-n", $Namespace, "get", "services")

    $apiPortForward = Start-PortForward -Name "api-monitoring-seed" -Service "fraud-detection-service" -LocalPort $ApiPort -RemotePort 8000
    try {
        Wait-Http -Uri "http://127.0.0.1:$ApiPort/ping" -Seconds $PortForwardStartupSeconds | Out-Null

        $sampleBody = Get-Content -LiteralPath "artifacts\sample_request.json" -Raw
        for ($i = 1; $i -le 10; $i++) {
            Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$ApiPort/predict" -ContentType "application/json" -Body $sampleBody -TimeoutSec 10 | Out-Null
        }
        Add-EvidenceSection "API traffic seed" "Sent 10 prediction requests to http://127.0.0.1:$ApiPort/predict using artifacts/sample_request.json."
    }
    finally {
        Stop-PortForward -Process $apiPortForward -Name "API"
        $apiPortForward = $null
    }

    $prometheusPortForward = Start-PortForward -Name "prometheus" -Service "prometheus-service" -LocalPort $PrometheusPort -RemotePort 9090
    $grafanaPortForward = Start-PortForward -Name "grafana" -Service "grafana-service" -LocalPort $GrafanaPort -RemotePort 3000

    $prometheusReady = Wait-Http -Uri "http://127.0.0.1:$PrometheusPort/-/ready" -Seconds $PortForwardStartupSeconds
    $grafanaHealth = Wait-RestJson -Uri "http://127.0.0.1:$GrafanaPort/api/health" -Seconds $PortForwardStartupSeconds
    $target = Wait-PrometheusTargetUp -Seconds 20
    $metricQuery = Wait-PrometheusMetric -Seconds 20

    $grafanaAuthBytes = [System.Text.Encoding]::ASCII.GetBytes("admin:admin")
    $grafanaHeaders = @{ Authorization = "Basic $([System.Convert]::ToBase64String($grafanaAuthBytes))" }
    $datasourceStatus = Wait-RestJson -Uri "http://127.0.0.1:$GrafanaPort/api/datasources/name/Prometheus" -Headers $grafanaHeaders -Seconds 20
    $dashboardStatus = Wait-GrafanaDashboard -Headers $grafanaHeaders -Seconds 20

    $metricValue = @($metricQuery.data.result)[0].value[1]

    Add-EvidenceSection "Prometheus readiness result" "HTTP $($prometheusReady.StatusCode): $($prometheusReady.Content.Trim())"
    Add-EvidenceSection "Grafana health result" ($grafanaHealth | ConvertTo-Json -Depth 10)
    Add-EvidenceSection "Prometheus target health" "job=fraud-detection-api health=$($target.health) scrapeUrl=$($target.scrapeUrl)"
    Add-EvidenceSection "Metric query result" ($metricQuery | ConvertTo-Json -Depth 10)
    Add-EvidenceSection "Grafana datasource status" ($datasourceStatus | ConvertTo-Json -Depth 10)
    Add-EvidenceSection "Grafana dashboard provisioning status" ($dashboardStatus | ConvertTo-Json -Depth 10)
    Add-EvidenceSection "Manifest checks" "Grafana datasource manifest exists: $(Test-Path -LiteralPath 'kubernetes\monitoring\grafana-datasource.yaml')`nGrafana dashboard manifest exists: $(Test-Path -LiteralPath 'kubernetes\monitoring\grafana-dashboard.yaml')"

    Set-Content -LiteralPath $EvidencePath -Value $script:Evidence -Encoding UTF8

    Write-Host ""
    Write-Host "Prometheus rollout status: $prometheusRollout"
    Write-Host "Grafana rollout status: $grafanaRollout"
    Write-Host "Prometheus readiness result: HTTP $($prometheusReady.StatusCode)"
    Write-Host "Grafana health result: $($grafanaHealth | ConvertTo-Json -Compress)"
    Write-Host "Prometheus target health: $($target.health)"
    Write-Host "Total API request metric: $metricValue"
    Write-Host "Grafana datasource status: name=$($datasourceStatus.name), url=$($datasourceStatus.url)"
    Write-Host "Grafana dashboard provisioning status: title=$($dashboardStatus.title)"
    Write-Host ""
    Write-Host "Monitoring pod list:"
    Write-Host $pods
    Write-Host ""
    Write-Host "Monitoring Service list:"
    Write-Host $services
    Write-Host ""
    Write-Host "Evidence saved to docs\PHASE4_EVIDENCE.txt"
}
finally {
    Stop-PortForward -Process $apiPortForward -Name "API"
    Stop-PortForward -Process $prometheusPortForward -Name "Prometheus"
    Stop-PortForward -Process $grafanaPortForward -Name "Grafana"
}
