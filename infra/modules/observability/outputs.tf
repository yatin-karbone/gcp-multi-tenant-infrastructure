output "log_archive_bucket" {
  description = "GCS bucket name for log archive"
  value       = google_storage_bucket.log_archive.name
}

output "log_sink_name" {
  description = "Log sink name"
  value       = google_logging_project_sink.log_archive.name
}

output "notification_channel_ids" {
  description = "Notification channel IDs"
  value       = [for ch in google_monitoring_notification_channel.email : ch.name]
}
