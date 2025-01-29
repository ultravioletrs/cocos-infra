resource "openstack_compute_flavor_v2" "sev_snp_flavor_1" {
  name  = "sev-snp.medium2"
  ram   = "4096"
  vcpus = "2"
  disk  = "20"

  extra_specs = {
    "hw:mem_encryption_context" = "sev"
    "trait:HW_CPU_X86_AMD_SEV" = "required"
  }
}

# Create network
resource "openstack_networking_network_v2" "private_net" {
  name           = "private-net"
  admin_state_up = "true"
}

# Create subnet
resource "openstack_networking_subnet_v2" "private_subnet" {
  name       = "private-subnet"
  network_id = openstack_networking_network_v2.private_net.id
  cidr       = "192.168.1.0/24"
  ip_version = 4
}

# Create router
resource "openstack_networking_router_v2" "router" {
  name                = "router1"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
}

# Attach subnet to router
resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.private_subnet.id
}

# Create keypair
resource "openstack_compute_keypair_v2" "sev_keypair" {
  name = "sev-keypair"
  # Replace with your public key
  public_key = file("~/.ssh/id_ed25519.pub")
}

# Create SEV-SNP instance
resource "openstack_compute_instance_v2" "sev_instance" {
  name            = "sev-instance"
  flavor_id       = "bbd2772e-6918-4142-ae3a-32b6baa7adf8"
  key_pair        = openstack_compute_keypair_v2.sev_keypair.name
  security_groups = ["default"]

  block_device {
    uuid                  = data.openstack_images_image_v2.ubuntu_sev.id
    source_type          = "image"
    destination_type     = "volume"
    volume_size          = 20
    boot_index          = 0
    delete_on_termination = true
  }

  network {
    uuid = openstack_networking_network_v2.private_net.id
  }
}

# Data source for external network
data "openstack_networking_network_v2" "external" {
  name = "public" # Replace with your external network name
}

# Data source for SEV-SNP image
data "openstack_images_image_v2" "ubuntu_sev" {
  name        = "ubuntu-sev-snp"
  most_recent = true

  properties = {
    hw_firmware_type = "uefi"
    hw_machine_type = "q35"
  }
}
