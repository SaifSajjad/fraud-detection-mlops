variable "namespace" {
  description = "Dedicated Kubernetes namespace for the fraud detection project."
  type        = string
  default     = "fraud-mlops"
}

variable "minikube_profile" {
  description = "Dedicated Minikube profile for Project 4."
  type        = string
  default     = "fraud-mlops-p4"
}

variable "image_name" {
  description = "Local Docker image loaded into Minikube."
  type        = string
  default     = "fraud-detection-api:latest"
}

variable "replicas" {
  description = "Number of fraud API replicas."
  type        = number
  default     = 3
}
