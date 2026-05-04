# ============================================
# Notification Channels
# ============================================

resource "google_monitoring_notification_channel" "email" {
  for_each = toset(var.notification_emails)

  display_name = "${var.company_name}-${var.environment} | ${each.value}"
  type         = "email"
  project      = var.project_id
  force_delete = true

  labels = {
    email_address = each.value
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================
# Log Archive — GCS Sink
# ============================================

resource "google_storage_bucket" "log_archive" {
  name     = "${var.project_id}-log-archive"
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = var.log_retention_days
    }
  }

  labels = {
    environment = var.environment
    company     = var.company_name
    purpose     = "log-archive"
    managed_by  = "terraform"
  }
}

resource "google_logging_project_sink" "log_archive" {
  name        = "${var.company_name}-${var.environment}-log-sink"
  project     = var.project_id
  destination = "storage.googleapis.com/${google_storage_bucket.log_archive.name}"
  filter      = "resource.type=\"gce_instance\""

  unique_writer_identity = true
}

resource "google_storage_bucket_iam_member" "log_sink_writer" {
  bucket = google_storage_bucket.log_archive.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.log_archive.writer_identity
}

# ============================================
# Disk Usage Alert
# ============================================

resource "google_monitoring_alert_policy" "disk_usage" {
  display_name = "${var.company_name}-${var.environment}-disk-usage-high"
  combiner     = "OR"
  project      = var.project_id

  conditions {
    display_name = "Disk usage above ${var.disk_alert_threshold}%"

    condition_threshold {
      filter                  = "resource.type=\"gce_instance\" AND metric.type=\"agent.googleapis.com/disk/percent_used\" AND metric.labels.state=\"used\""
      duration                = "300s"
      comparison              = "COMPARISON_GT"
      threshold_value         = var.disk_alert_threshold
      evaluation_missing_data = "EVALUATION_MISSING_DATA_NO_OP"

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["metric.labels.device"]
      }
    }
  }

  notification_channels = [
    for ch in google_monitoring_notification_channel.email : ch.name
  ]

  documentation {
    content = "Disk usage on ${var.company_name}-${var.environment}-vm has exceeded ${var.disk_alert_threshold}%. Check Docker logs and images: run `docker system df` and `docker system prune`."
  }
}

# ============================================
# Error Log Alert (prod only by default)
# ============================================

resource "google_monitoring_alert_policy" "error_logs" {
  count = var.enable_error_alerts ? 1 : 0

  display_name = "${var.company_name}-${var.environment}-application-errors"
  combiner     = "OR"
  project      = var.project_id

  conditions {
    display_name = "Application error logs detected"

    condition_matched_log {
      filter = var.use_severity_filter ? "logName=\"projects/${var.project_id}/logs/docker_containers\" severity>=ERROR" : "logName=\"projects/${var.project_id}/logs/docker_containers\" jsonPayload.log=~\"(?i)(error|exception|traceback|critical)\""
    }
  }

  alert_strategy {
    notification_rate_limit {
      period = "300s"
    }
  }

  notification_channels = [
    for ch in google_monitoring_notification_channel.email : ch.name
  ]

  documentation {
    content = var.use_severity_filter ? "Application ERROR severity logs in ${var.company_name}-${var.environment}. Check Cloud Logging: logName=\"projects/${var.project_id}/logs/docker_containers\" severity>=ERROR" : "Application errors detected in ${var.company_name}-${var.environment}. Check Cloud Logging: logName=\"projects/${var.project_id}/logs/docker_containers\""
  }
}
