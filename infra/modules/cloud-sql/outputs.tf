output "instance_name" {
  value       = google_sql_database_instance.instance.name
  description = "Cloud SQL instance name"
}

output "instance_connection_name" {
  value       = google_sql_database_instance.instance.connection_name
  description = "Cloud SQL connection name (project:region:instance)"
}

output "private_ip" {
  value       = google_sql_database_instance.instance.private_ip_address
  description = "Private IP address of the Cloud SQL instance"
}

output "database_name" {
  value       = google_sql_database.database.name
  description = "Database name"
}

output "user_name" {
  value       = google_sql_user.user.name
  description = "Database user name"
}
