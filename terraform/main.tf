provider "google" {
  project = "upgradlabs-1749732690621"
  region  = "us-east1"
  zone    = "us-east1-b"
}

resource "google_compute_instance" "web" {
  name         = "bookmyshow-vm"
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
    apt update
    apt install -y nginx git
    cd /var/www/html
    git clone https://github.com/anuragjnaik/bookmyshow-project.git .
    systemctl restart nginx
  EOF
}
