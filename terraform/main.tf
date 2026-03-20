# main.tf - creates 2 VMs + unmanaged instance group + global HTTP LB + health check + firewall

provider "google" {
  project = "upgradlabs-1749732690621"
  region  = "us-east1"
  zone    = "us-east1-b"
}

# -------------------------------
# VM 1
# -------------------------------
resource "google_compute_instance" "web1" {
  name         = "bookmyshow-vm-1"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e
    apt-get update
    apt-get install -y nginx git
    mkdir -p /var/www/html
    cd /var/www/html
    rm -rf *
    if git clone https://github.com/anuragjnaik/bookmyshow-project.git .; then
      echo "Repo cloned"
    else
      echo "<html><body><h1>BookMyShow fallback</h1></body></html>" > index.html
    fi
    echo "OK" > /var/www/html/healthz
    chmod 644 /var/www/html/healthz
    systemctl enable nginx
    systemctl restart nginx
  EOF
}

# -------------------------------
# VM 2
# -------------------------------
resource "google_compute_instance" "web2" {
  name         = "bookmyshow-vm-2"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e
    apt-get update
    apt-get install -y nginx git
    mkdir -p /var/www/html
    cd /var/www/html
    rm -rf *
    if git clone https://github.com/anuragjnaik/bookmyshow-project.git .; then
      echo "Repo cloned"
    else
      echo "<html><body><h1>BookMyShow fallback</h1></body></html>" > index.html
    fi
    echo "OK" > /var/www/html/healthz
    chmod 644 /var/www/html/healthz
    systemctl enable nginx
    systemctl restart nginx
  EOF
}

# -------------------------------
# Unmanaged instance group containing the two VMs
# -------------------------------
resource "google_compute_instance_group" "web_group" {
  name      = "bookmyshow-group"
  zone      = "us-east1-b"
  instances = [
    google_compute_instance.web1.self_link,
    google_compute_instance.web2.self_link
  ]
}

# -------------------------------
# Named port so backend service knows which port name maps to port 80
# -------------------------------
resource "google_compute_instance_group_named_port" "http_port" {
  group = google_compute_instance_group.web_group.self_link
  zone  = "us-east1-b"

  name = "http"
  port = 80
}

# -------------------------------
# Health check probing /healthz on port 80
# -------------------------------
resource "google_compute_health_check" "hc" {
  name                = "web-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port         = 80
    request_path = "/healthz"
  }
}

# -------------------------------
# Backend service referencing the unmanaged instance group
# -------------------------------
resource "google_compute_backend_service" "backend" {
  name                  = "web-backend"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 10
  load_balancing_scheme = "EXTERNAL"

  health_checks = [google_compute_health_check.hc.self_link]

  backend {
    group = google_compute_instance_group.web_group.self_link
  }
}

# -------------------------------
# URL map -> routes all requests to the backend service
# -------------------------------
resource "google_compute_url_map" "url_map" {
  name            = "web-url-map"
  default_service = google_compute_backend_service.backend.self_link
}

# -------------------------------
# Target HTTP proxy
# -------------------------------
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "web-http-proxy"
  url_map = google_compute_url_map.url_map.self_link
}

# -------------------------------
# Reserve a global external IP for the LB
# -------------------------------
resource "google_compute_global_address" "lb_ip" {
  name = "web-lb-ip"
}

# -------------------------------
# Global forwarding rule binding IP -> HTTP proxy on port 80
# -------------------------------
resource "google_compute_global_forwarding_rule" "http_forward" {
  name                  = "web-forwarding-rule"
  ip_address            = google_compute_global_address.lb_ip.address
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_proxy.self_link
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
}

# -------------------------------
# Firewall rules
# - allow external HTTP
# - allow Google health check IP ranges to probe instances
# -------------------------------
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-ingress"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_health_check" {
  name    = "allow-health-check"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
}

# -------------------------------
# Outputs
# -------------------------------
output "load_balancer_ip" {
  value = google_compute_global_address.lb_ip.address
}

output "instance_1_name" {
  value = google_compute_instance.web1.name
}

output "instance_2_name" {
  value = google_compute_instance.web2.name
}
