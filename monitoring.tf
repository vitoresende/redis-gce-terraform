# Google Cloud Monitoring & Alerting Configuration

# 1. Notification Channel for Email Alerts
resource "google_monitoring_notification_channel" "email" {
  display_name = "Redis Admin Email Notification Channel"
  type         = "email"

  labels = {
    email_address = var.alert_email_address
  }
}

# 2. Alert Policy: Triggers when GCE Memory Utilization exceeds 80% for 5 minutes
resource "google_monitoring_alert_policy" "memory_high_alert" {
  display_name = "Redis GCE Memory Usage Exceeds 80%"
  combiner     = "OR"

  conditions {
    display_name = "GCE System RAM Utilization > 80%"

    condition_threshold {
      filter = "metric.type=\"agent.googleapis.com/memory/percent_used\" AND resource.type=\"gce_instance\" AND metric.label.state=\"used\" AND resource.label.instance_id=\"${google_compute_instance.redis_vm.instance_id}\""

      duration        = "300s" # Condition must hold true for 5 minutes
      comparison      = "COMPARISON_GT"
      threshold_value = 80.0 # 80% memory utilization threshold

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email.name
  ]

  alert_strategy {
    auto_close = "604800s" # Auto-close incident after 7 days if resolved
  }

  documentation {
    content   = "The Redis GCE instance (${var.instance_name}) RAM utilization has exceeded 80% for more than 5 minutes. Check active key eviction policy and connected clients."
    mime_type = "text/markdown"
  }
}

# 3. Custom Google Cloud Monitoring Dashboard for Redis GCE
resource "google_monitoring_dashboard" "redis_dashboard" {
  dashboard_json = jsonencode({
    displayName = "Redis GCE Performance Dashboard"
    gridLayout = {
      columns = "2"
      widgets = [
        {
          title = "1. RAM Memory Utilization (%)"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"agent.googleapis.com/memory/percent_used\" AND resource.type=\"gce_instance\" AND metric.label.state=\"used\" AND resource.label.instance_id=\"${google_compute_instance.redis_vm.instance_id}\""
                  }
                }
              }
            ]
          }
        },
        {
          title = "2. VM CPU Utilization (%)"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\" AND resource.label.instance_id=\"${google_compute_instance.redis_vm.instance_id}\""
                  }
                }
              }
            ]
          }
        },
        {
          title = "3. Active Connections / Connected Clients"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"workload.googleapis.com/redis.clients.connected\" AND resource.type=\"gce_instance\" AND resource.label.instance_id=\"${google_compute_instance.redis_vm.instance_id}\""
                  }
                }
              }
            ]
          }
        },
        {
          title = "4. Cache Hits vs Misses"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"workload.googleapis.com/redis.keyspace.hits\" AND resource.type=\"gce_instance\" AND resource.label.instance_id=\"${google_compute_instance.redis_vm.instance_id}\""
                  }
                }
              },
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"workload.googleapis.com/redis.keyspace.misses\" AND resource.type=\"gce_instance\" AND resource.label.instance_id=\"${google_compute_instance.redis_vm.instance_id}\""
                  }
                }
              }
            ]
          }
        },
        {
          title = "5. Active Keys Stored in DB0"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"workload.googleapis.com/redis.db.keys\" AND resource.type=\"gce_instance\" AND resource.label.instance_id=\"${google_compute_instance.redis_vm.instance_id}\""
                  }
                }
              }
            ]
          }
        },
        {
          title = "6. Expired Keys (Auto-Cleanup)"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"workload.googleapis.com/redis.keys.expired\" AND resource.type=\"gce_instance\" AND resource.label.instance_id=\"${google_compute_instance.redis_vm.instance_id}\""
                  }
                }
              }
            ]
          }
        }
      ]
    }
  })
}
