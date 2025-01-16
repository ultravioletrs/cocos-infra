locals {
  cloud_init_config = filebase64("${path.module}/../cloud-init/base.yml")
}

resource "google_compute_instance" "confidential" {
  name         = var.vm_name
  machine_type = "n2d-standard-2"
  min_cpu_platform = "AMD Milan"
  zone         = "${var.region}-a"

  scheduling {
    on_host_maintenance = "TERMINATE"  
  }

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20250112"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  confidential_instance_config {
    enable_confidential_compute = true
    confidential_instance_type = "SEV_SNP"
  }

  metadata = {
    user-data = local.cloud_init_config
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }
  
}