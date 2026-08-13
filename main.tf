# Main Infrastructure Definition: Service Account, Firewall, and GCE Instance

# 1. Service Account for the GCE Instance with Cloud Monitoring/Logging Permissions
resource "google_service_account" "redis_sa" {
  account_id   = "${var.instance_name}-sa"
  display_name = "Service Account for Redis GCE Instance"
}

resource "google_project_iam_member" "monitoring_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "service_account:${google_service_account.redis_sa.email}"
}

resource "google_project_iam_member" "logging_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "service_account:${google_service_account.redis_sa.email}"
}

# 2. Firewall Rule to Allow Ingress Traffic on Redis Port 6379 from Internal VPC
resource "google_compute_firewall" "allow_redis_internal" {
  name    = "allow-redis-internal-${var.instance_name}"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  source_ranges = var.allowed_ingress_cidrs
  target_tags   = ["redis-server"]
  description   = "Allow internal VPC traffic to Redis port 6379"
}

# 3. Google Compute Engine Instance (e2-micro in us-central1 for Free Tier)
resource "google_compute_instance" "redis_vm" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["redis-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = var.disk_size_gb
      type  = "pd-standard"
    }
  }

  network_interface {
    network = var.network_name
    access_config {
      # Allocate ephemeral external IP for initial SSH/setup package downloads
    }
  }

  service_account {
    email  = google_service_account.redis_sa.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -euo pipefail

    # Update system packages and install Redis
    apt-get update -y
    apt-get install -y curl gnupg lsb-release redis-server

    # Configure Redis for Production & Auto-Eviction Best Practices
    REDIS_CONF="/etc/redis/redis.conf"

    # Listen on all interfaces inside the VM
    sed -i 's/^bind .*/bind 0.0.0.0/' "$REDIS_CONF"
    sed -i 's/^protected-mode .*/protected-mode yes/' "$REDIS_CONF"

    # Set Max Memory Eviction Policy (Auto-cleanup of least recently used keys)
    if grep -q "^maxmemory " "$REDIS_CONF"; then
      sed -i 's/^maxmemory .*/maxmemory ${var.redis_maxmemory_mb}mb/' "$REDIS_CONF"
    else
      echo "maxmemory ${var.redis_maxmemory_mb}mb" >> "$REDIS_CONF"
    fi

    if grep -q "^maxmemory-policy " "$REDIS_CONF"; then
      sed -i 's/^maxmemory-policy .*/maxmemory-policy allkeys-lru/' "$REDIS_CONF"
    else
      echo "maxmemory-policy allkeys-lru" >> "$REDIS_CONF"
    fi

    # Set Password Authentication
    if grep -q "^requirepass " "$REDIS_CONF"; then
      sed -i 's/^requirepass .*/requirepass ${var.redis_password}/' "$REDIS_CONF"
    else
      echo "requirepass ${var.redis_password}" >> "$REDIS_CONF"
    fi

    # Restart Redis Service to apply configuration
    systemctl restart redis-server

    # Install Google Cloud Ops Agent for System and Redis Monitoring
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    bash add-google-cloud-ops-agent-repo.sh --also-install

    # Configure Google Cloud Ops Agent to ingest Redis metrics & logs
    cat <<OPSEOF > /etc/google-cloud-ops-agent/config.yaml
logging:
  receivers:
    redis_syslog:
      type: redis
  service:
    pipelines:
      redis_pipeline:
        receivers: [redis_syslog]
metrics:
  receivers:
    redis:
      type: redis
      endpoint: "127.0.0.1:6379"
      password: "${var.redis_password}"
  service:
    pipelines:
      redis:
        receivers: [redis]
OPSEOF

    # Restart Ops Agent to activate monitoring telemetry
    systemctl restart google-cloud-ops-agent
  EOF

  depends_on = [
    google_project_iam_member.monitoring_writer,
    google_project_iam_member.logging_writer
  ]
}
