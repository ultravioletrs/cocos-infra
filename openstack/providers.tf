terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

provider "openstack" {
  auth_url          = var.openstack_auth_url
  user_name         = var.openstack_user_name
  password          = var.openstack_password
  tenant_name       = var.openstack_tenant_name
  region            = var.openstack_region
  user_domain_name  = var.user_domain_name
  project_domain_name = var.project_domain_name

  endpoint_overrides = {
    network = "http://109.92.195.153:6123/networking/v2.0/"
  }
}
