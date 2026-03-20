# --- 4. CLOUD SPANNER (Global Scale) ---
resource "google_spanner_instance" "global_spanner" {
  name         = "bookmyshow-global-spanner"
  config       = "regional-us-east1" # Use 'nam3' for multi-region if quota allows
  display_name = "BookMyShow Global DB"
  num_nodes    = 1
  labels = {
    "env" = "production"
  }
}

resource "google_spanner_database" "spanner_db" {
  instance = google_spanner_instance.global_spanner.name
  name     = "tickets-global"
  
  # Prevent accidental deletion in production (set false for labs)
  deletion_protection = false
}

output "spanner_state" {
  value = google_spanner_instance.global_spanner.state
}

