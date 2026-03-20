provider "google" {
  project = "upgradlabs-1749732690621"
  region  = "us-east1"
}

# --- 1. PRIMARY INSTANCE (Write Node) ---
resource "google_sql_database_instance" "primary" {
  name             = "bookmyshow-primary-db"
  database_version = "MYSQL_8_0"
  region           = "us-east1"
  deletion_protection = false # Disable for lab environment

  settings {
    tier = "db-f1-micro" # Lab-friendly tier
    
    # Enable Backups & Point-in-Time Recovery (PITR)
    backup_configuration {
      enabled            = true
      binary_log_enabled = true # Required for Replicas
      start_time         = "04:00" # Run backups at 4 AM
    }
  }
}

# --- 2. READ REPLICA (Read Node - Horizontal Scaling) ---
resource "google_sql_database_instance" "read_replica" {
  name                 = "bookmyshow-replica-us-west"
  database_version     = "MYSQL_8_0"
  region               = "us-west1" # CROSS-REGION for Disaster Recovery
  master_instance_name = google_sql_database_instance.primary.name
  deletion_protection  = false

  settings {
    tier = "db-f1-micro"
  }
}

# --- 3. DATABASE & USER ---
resource "google_sql_database" "database" {
  name     = "bookmyshow_db"
  instance = google_sql_database_instance.primary.name
}

resource "google_sql_user" "users" {
  name     = "admin"
  instance = google_sql_database_instance.primary.name
  password = "password123"
}

output "sql_primary_ip" {
  value = google_sql_database_instance.primary.public_ip_address
}

