# Terraform Outputs

output "instance_name" {
  description = "Name of the created GCE instance."
  value       = google_compute_instance.redis_vm.name
}

output "redis_internal_ip" {
  description = "Static internal IPv4 address reserved for Redis (Fixed forever, 100% Free)."
  value       = google_compute_address.redis_static_internal_ip.address
}

output "redis_port" {
  description = "Port number on which Redis is listening."
  value       = 6379
}

output "redis_maxmemory_mb" {
  description = "Configured Redis MaxMemory limit in MB."
  value       = var.redis_maxmemory_mb
}

output "alert_policy_id" {
  description = "Google Cloud Monitoring Alert Policy ID."
  value       = google_monitoring_alert_policy.memory_high_alert.id
}

output "connection_uri_example" {
  description = "Example internal connection URI for applications."
  value       = "redis://:${var.redis_password}@${google_compute_address.redis_static_internal_ip.address}:6379"
  sensitive   = true
}
