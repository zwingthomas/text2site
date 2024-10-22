# Optional: Create a storage bucket for log exports
resource "google_storage_bucket" "logs_bucket" {
  name     = "gke-logs-bucket-${var.project_id}"
  location = var.region

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 90  # Retain logs for 90 days
    }
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

# Log Sink to export logs to the storage bucket
resource "google_logging_project_sink" "gke_logs_sink" {
  name        = "gke-logs-sink"
  destination = var.log_sink_destination != "" ? var.log_sink_destination : "storage.googleapis.com/${google_storage_bucket.logs_bucket.name}"
  filter      = var.log_filter

  unique_writer_identity = true
}

# Grant write permissions to the sink's service account
resource "google_storage_bucket_iam_member" "sink_writer" {
  bucket = google_storage_bucket.logs_bucket.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.gke_logs_sink.writer_identity
}
