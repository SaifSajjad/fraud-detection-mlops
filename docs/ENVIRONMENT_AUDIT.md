# Environment Audit

Generated: 2026-06-05 22:45:37 +05:00

## python --version

```powershell
python --version
```

Exit Code: 0

```text
Python 3.14.5
```

## git --version

```powershell
git --version
```

Exit Code: 0

```text
git version 2.54.0.windows.1
```

## docker --version

```powershell
docker --version
```

Exit Code: 0

```text
Docker version 29.5.2, build 79eb04c
```

## docker info

```powershell
docker info
```

Exit Code: 0

```text
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
 Images: 5
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
  File Descriptors: 36
  Goroutines: 64
  System Time: 2026-06-05T17:45:54.144814142Z
  EventsListeners: 6
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

## minikube version

```powershell
minikube version
```

Exit Code: 0

```text
minikube version: v1.38.1
commit: c93a4cb9311efc66b90d33ea03f75f2c4120e9b0
```

## minikube status

```powershell
minikube status
```

Exit Code: 7

```text
minikube
type: Control Plane
host: Stopped
kubelet: Stopped
apiserver: Stopped
kubeconfig: Stopped
```

## kubectl version --client

```powershell
kubectl version --client
```

Exit Code: 0

```text
Client Version: v1.34.1
Kustomize Version: v5.7.1
```

## kubectl get nodes

```powershell
kubectl get nodes
```

Exit Code: 1

```text
kubectl.exe : E0605 22:45:57.755408   24560 memcache.go:265] "Unhandled Error" err="couldn't get current server API 
group list: Get \"https://127.0.0.1:60057/api?timeout=32s\": dial tcp 127.0.0.1:60057: connectex: No connection could 
be made because the target machine actively refused it."
At line:31 char:15
+     $output = & $exe @args 2>&1 | Out-String
+               ~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (E0605 22:45:57....ly refused it.":String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
E0605 22:45:57.769655   24560 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get 
\"https://127.0.0.1:60057/api?timeout=32s\": dial tcp 127.0.0.1:60057: connectex: No connection could be made because 
the target machine actively refused it."
E0605 22:45:57.771358   24560 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get 
\"https://127.0.0.1:60057/api?timeout=32s\": dial tcp 127.0.0.1:60057: connectex: No connection could be made because 
the target machine actively refused it."
E0605 22:45:57.773179   24560 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get 
\"https://127.0.0.1:60057/api?timeout=32s\": dial tcp 127.0.0.1:60057: connectex: No connection could be made because 
the target machine actively refused it."
E0605 22:45:57.776477   24560 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get 
\"https://127.0.0.1:60057/api?timeout=32s\": dial tcp 127.0.0.1:60057: connectex: No connection could be made because 
the target machine actively refused it."
Unable to connect to the server: dial tcp 127.0.0.1:60057: connectex: No connection could be made because the target 
machine actively refused it.
```

## terraform -version

```powershell
terraform -version
```

Exit Code: 0

```text
Terraform v1.15.5
on windows_amd64
```

