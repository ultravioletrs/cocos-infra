locals {
  cloud_init_config = filebase64("${path.module}/../cloud-init/base.yaml")
}

resource "google_compute_instance" "confidential" {
  name         = var.vm_name
  machine_type = "n2d-standard-2"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  confidential_instance_config {
    enable_confidential_compute = true
  }

  metadata = {
    user-data = local.cloud_init_config
  }
}
