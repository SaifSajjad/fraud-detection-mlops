terraform {
  required_version = ">= 1.0.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

resource "null_resource" "provision_fraud_mlops" {
  triggers = {
    namespace_manifest  = filesha256("${path.module}/../kubernetes/namespace.yaml")
    deployment_manifest = filesha256("${path.module}/../kubernetes/deployment.yaml")
    service_manifest    = filesha256("${path.module}/../kubernetes/service.yaml")
    provisioning_script = filesha256("${path.module}/../scripts/provision-minikube.ps1")
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = "& '.\\scripts\\provision-minikube.ps1'"
    working_dir = "${path.module}/.."
  }
}
