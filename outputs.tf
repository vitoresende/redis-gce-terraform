# Terraform Outputs

output "instance_name" {
  description = "Name of the created GCE instance."
  value       = google_compute_instance.redis_vm.name
}

output "redis_internal_ip" {
  description = "Internal IPv4 address of the Redis GCE instance (use this in Cloud Run)."
  value       = google_compute_instance.redis_vm.network_interface[0].network_ip
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
  value       = "redis://:${var.redis_password}@${google_compute_instance.redis_vm.network_interface[0].network_ip}:6379"
  sensitive   = true
}
