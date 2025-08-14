terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "vm_name" {
  type = string
}

variable "cloud_init_config" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "disk_encryption_id" {
  type = string
  description = "The self-link of the KMS key to encrypt the VM disk"
}

variable "vm_id" {
  type = string
  description = "Unique identifier for the VM"
}

variable "workspace_id" {
  type = string
  description = "Workspace identifier"
}

variable "min_cpu_platform" {
  type = string
  default = "AMD Milan"
}

variable "confidential_instance_type" {
  type = string
  default = "SEV_SNP"
}

data "cloudinit_config" "conf" {
  gzip = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = file(var.cloud_init_config)
    filename = "conf.yml"
  }
}


resource "google_compute_instance" "confidential" {
  name         = var.vm_name
  machine_type = var.machine_type
  min_cpu_platform = var.min_cpu_platform
  zone         = "${var.region}-a"
  tags = [var.vm_name]

  labels = {
    vm_id        = var.vm_id
    workspace_id = var.workspace_id
  }

  scheduling {
    on_host_maintenance = "TERMINATE"  
  }

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20250112"
      labels = {
        vm_id        = var.vm_id
        workspace_id = var.workspace_id
      }
    }
    kms_key_self_link = var.disk_encryption_id
  }

  network_interface {
    network = "default"
    access_config {}
  }

  confidential_instance_config {
    enable_confidential_compute = true
    confidential_instance_type = var.confidential_instance_type
  }

  metadata = {
    user-data = "${data.cloudinit_config.conf.rendered}"
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }
}

resource "google_compute_firewall" "allow-agent" {
  name    = "allow-agent-${var.vm_name}"
  network = "default"
  
  allow {
    protocol = "tcp"
    ports    = ["7002"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.vm_name]
}

output "vm_public_ip" {
  value = google_compute_instance.confidential.network_interface.0.access_config.0.nat_ip
}
