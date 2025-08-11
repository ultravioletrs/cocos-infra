terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id = var.subscription_id
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subscription_id" {
  type = string
}

data "azurerm_client_config" "current" {}

locals {
  key_vault_name = "prism-enc-vault"
  key_name = "prism-enc-key"
  des_name = "des-${substr(var.resource_group_name, 0, 10)}"
}

resource "azurerm_key_vault" "encryption_vault" {
  name                        = local.key_vault_name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "premium"
  purge_protection_enabled    = true
  soft_delete_retention_days  = 7
  
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    
    key_permissions = [
      "Get", "List", "Create", "Delete", "Recover", "Backup", "Restore", "Update",
      "GetRotationPolicy", "SetRotationPolicy", "Rotate", "Purge"
    ]
    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
    ]
  }

  lifecycle {
    ignore_changes = [
      access_policy,
    ]
  }
}

resource "azurerm_key_vault_key" "encryption_key" {
  name         = local.key_name
  key_vault_id = azurerm_key_vault.encryption_vault.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  lifecycle {
    ignore_changes = [
      key_vault_id,
      key_opts,
    ]
  }
}

resource "azurerm_disk_encryption_set" "des" {
  name                = local.des_name
  resource_group_name = var.resource_group_name
  location            = var.location
  key_vault_key_id    = azurerm_key_vault_key.encryption_key.id

  identity {
    type = "SystemAssigned"
  }

  # This prevents recreation if already exists
  lifecycle {
    ignore_changes = [
      key_vault_key_id,
    ]
  }
}

resource "azurerm_key_vault_access_policy" "des_policy" {
  key_vault_id = azurerm_key_vault.encryption_vault.id
  tenant_id    = azurerm_disk_encryption_set.des.identity[0].tenant_id
  object_id    = azurerm_disk_encryption_set.des.identity[0].principal_id

  key_permissions = [
    "Get", "WrapKey", "UnwrapKey"
  ]

  lifecycle {
    ignore_changes = [
      key_vault_id,
      object_id,
    ]
  }
}

output "kms_key_vault_id" {
  value = azurerm_key_vault.encryption_vault.id
}

output "kms_key_id" {
  value = azurerm_key_vault_key.encryption_key.id
}

output "disk_encryption_id" {
  value = azurerm_disk_encryption_set.des.id
}

output "des_principal_id" {
  value = azurerm_disk_encryption_set.des.identity[0].principal_id
}
