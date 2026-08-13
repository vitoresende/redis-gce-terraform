# Variable definitions for Redis GCE Terraform deployment

variable "project_id" {
  description = "The GCP Project ID where resources will be deployed."
  type        = string
}

variable "region" {
  description = "GCP Region for the GCE instance and networking (Free Tier eligible: us-east1)."
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "GCP Zone for the GCE instance (Free Tier eligible: us-east1-b)."
  type        = string
  default     = "us-east1-b"
}

variable "instance_name" {
  description = "Name of the Google Compute Engine instance."
  type        = string
  default     = "redis-instance"
}

variable "machine_type" {
  description = "Machine type for the GCE instance (Free Tier eligible: e2-micro)."
  type        = string
  default     = "e2-micro"
}

variable "disk_size_gb" {
  description = "Size of the boot disk in GB (pd-standard, max 30GB for Free Tier)."
  type        = number
  default     = 15
}

variable "network_name" {
  description = "VPC network name to attach the GCE instance."
  type        = string
  default     = "default"
}

variable "allowed_ingress_cidrs" {
  description = "List of internal IPv4 CIDR blocks allowed to access Redis on port 6379."
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "redis_password" {
  description = "Password required to authenticate with Redis."
  type        = string
  sensitive   = true
}

variable "redis_maxmemory_mb" {
  description = "Maximum memory in MB allocated for Redis data eviction (recommended 500-600MB for e2-micro)."
  type        = number
  default     = 550
}

variable "alert_email_address" {
  description = "Email address to receive alerts when GCE RAM usage exceeds 80%."
  type        = string
}
