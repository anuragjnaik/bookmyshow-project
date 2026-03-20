# 1. Deploy Cloud Run Service
resource "google_cloud_run_service" "bookmyshow_app" {
  name     = "bookmyshow-serverless"
  location = "us-east1"

  template {
    spec {
      containers {
        image = "us-east1-docker.pkg.dev/upgradlabs-1749732690621/bookmyshow-repo/frontend:v1"
        ports {
          container_port = 80
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# 2. Output the Service URL
output "serverless_url" {
  value = google_cloud_run_service.bookmyshow_app.status[0].url
}
