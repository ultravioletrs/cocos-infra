variable "openstack_auth_url" {
  description = "OpenStack authentication URL"
  type        = string
}

variable "openstack_user_name" {
  description = "OpenStack username"
  type        = string
}

variable "openstack_password" {
  description = "OpenStack password"
  type        = string
  sensitive   = true
}

variable "openstack_tenant_name" {
  description = "OpenStack project/tenant name"
  type        = string
}

variable "openstack_region" {
  description = "OpenStack region"
  type        = string
}

variable "user_domain_name" {
  description = "OpenStack user domain name"
  type        = string
  default     = "Default"
}

variable "project_domain_name" {
  description = "OpenStack project domain name"
  type        = string
  default     = "Default"
}
