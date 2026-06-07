output "namespace" {
  value = "fraud-mlops"
}

output "minikube_profile" {
  value = "fraud-mlops-p4"
}

output "deployment_name" {
  value = "fraud-detection-api"
}

output "service_name" {
  value = "fraud-detection-service"
}

output "service_url_command" {
  value = "minikube service -p fraud-mlops-p4 fraud-detection-service -n fraud-mlops --url"
}
