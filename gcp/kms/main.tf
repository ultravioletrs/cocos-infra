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

variable "kms_location" {
  type        = string
  default     = "global"
  description = "Location for the KMS key ring"
}

# Set local name variables for consistency
locals {
  keyring_name = "vm-encryption-keyring"
  key_name     = "vm-encryption-key"
}

# Create a KMS Key Ring if it doesn't exist
resource "google_kms_key_ring" "vm_encryption_keyring" {
  count    = 1
  name     = local.keyring_name
  location = var.kms_location
  project  = var.project_id
}

# Create a KMS Key if it doesn't exist
resource "google_kms_crypto_key" "vm_encryption_key" {
  count           = 1
  name            = local.key_name
  key_ring        = google_kms_key_ring.vm_encryption_keyring[0].id
  rotation_period = "7776000s" # 90 days
}

# Output the KMS Key ID
output "disk_encryption_id" {
  value = google_kms_crypto_key.vm_encryption_key[0].id
}

# Output the key ring ID as well for reference
output "kms_keyring_id" {
  value = google_kms_key_ring.vm_encryption_keyring[0].id
}
