# CoCoS Infrastructure

Infrastructure as Code (IaC) templates for deploying External Confidential Virtual Machines (CVMs) on Google Cloud Platform (GCP) and Microsoft Azure, integrated with the Prism AI confidential computing platform.

## Overview

This repository provides Terraform/OpenTofu templates for deploying user-managed confidential virtual machines with AMD SEV-SNP technology. These external CVMs can be used in two ways:

1. **With Prism AI**: Integrate seamlessly with [Prism AI](https://prism.ultraviolet.rs) for managed confidential computing workflows
2. **Standalone with Open-Source CoCoS**: Deploy and manage CVMs directly using the [open-source CoCoS platform](https://docs.cocos.ultraviolet.rs)

Both options give you complete control over your infrastructure, billing, and security configurations.

## Features

- 🔒 **Confidential Computing**: AMD SEV-SNP enabled virtual machines for hardware-level data protection
- 🌐 **Multi-Cloud Support**: Deploy on GCP and Azure with consistent configurations
- 🔑 **Key Management**: Integrated KMS setup for disk encryption
- 🤖 **Automated Agent Setup**: Cloud-init configurations for seamless Prism integration
- 📊 **Attestation Policy Generation**: Tools for validating CVM integrity
- 🏗️ **Infrastructure as Code**: Reproducible, version-controlled deployments

## Why External CVMs?

While Prism AI's managed CVMs offer simplicity, external CVMs provide:

- **Infrastructure Sovereignty**: Complete control over compute resources
- **Existing Investment Utilization**: Leverage existing cloud commitments and reserved capacity
- **Custom Security Policies**: Implement organization-specific controls
- **Hybrid Deployments**: Deploy across multiple clouds or integrate with on-premises infrastructure
- **Performance Optimization**: Fine-tune VM specifications for your workload
- **Compliance Requirements**: Meet specific regulatory requirements for data residency
- **Flexibility**: Use with Prism AI for managed workflows OR directly with open-source CoCoS for full control

## Prerequisites

### For Prism AI Integration

- **Cloud Provider Access**: Active accounts on GCP and/or Azure with appropriate permissions
- **Terraform/OpenTofu**: Latest version installed
- **Cocos CLI**: Download from [CoCoS releases](https://github.com/ultravioletrs/cocos/releases)
- **Prism Account**: Sign up at [https://prism.ultraviolet.rs](https://prism.ultraviolet.rs)

### For Standalone CoCoS Usage

- **Cloud Provider Access**: Active accounts on GCP and/or Azure with appropriate permissions
- **Terraform/OpenTofu**: Latest version installed
- **CoCoS Installation**: Clone and build from [CoCoS repository](https://github.com/ultravioletrs/cocos)
- **QEMU/KVM**: Required for local CVM management
- See the [CoCoS Getting Started Guide](https://docs.cocos.ultraviolet.rs/getting-started) for detailed setup instructions

## Repository Structure

```
cocos-infra/
├── gcp/
│   ├── kms/              # GCP Key Management Service setup
│   └── main.tf           # GCP CVM deployment
├── azure/
│   ├── kms/              # Azure Key Management Service setup
│   └── main.tf           # Azure CVM deployment
├── cloud-init/
│   └── base.yml          # CoCoS agent configuration
└── terraform.tfvars      # Your configuration variables
```

## Quick Start

### Option 1: Using with Prism AI

#### 1. Clone the Repository

```bash
git clone https://github.com/ultravioletrs/cocos-infra.git
cd cocos-infra
```

#### 2. Create External CVM on Prism

1. Navigate to [Prism AI](https://prism.ultraviolet.rs)
2. Create a new External CVM in your workspace
3. Download the authentication certificates (ca.pem, cert.pem, key.pem)

#### 3. Configure Terraform Variables

Create or update `terraform.tfvars` with your configuration:

```hcl
# Common
vm_name = "myapp-vm"

# For GCP
project_id = "your-gcp-project"
region = "us-central1"
min_cpu_platform = "AMD Milan"
confidential_instance_type = "SEV_SNP"
machine_type = "n2d-standard-2"

# For Azure
resource_group_name = "your-resource-group"
location = "westus"
subscription_id = "your-subscription-id"
machine_type = "Standard_DC2ads_v5"

# VM Configuration
cloud_init_config = "cloud-init/base.yml"
```

#### 4. Update Cloud-Init Configuration

Edit `cloud-init/base.yml` and paste your downloaded certificates:

```yaml
- path: /etc/cocos/environment
  content: |
    AGENT_CVM_GRPC_URL=prism.ultraviolet.rs:7018
    AGENT_CVM_GRPC_CLIENT_CERT=/etc/cocos/certs/cert.pem
    AGENT_CVM_GRPC_SERVER_CA_CERTS=/etc/cocos/certs/ca.pem
    AGENT_CVM_GRPC_CLIENT_KEY=/etc/cocos/certs/key.pem
    AGENT_LOG_LEVEL=info

- path: /etc/cocos/certs/ca.pem
  content: |
    -----BEGIN CERTIFICATE-----
    [Paste your ca.pem content here]
    -----END CERTIFICATE-----

- path: /etc/cocos/certs/cert.pem
  content: |
    -----BEGIN CERTIFICATE-----
    [Paste your cert.pem content here]
    -----END CERTIFICATE-----

- path: /etc/cocos/certs/key.pem
  content: |
    -----BEGIN PRIVATE KEY-----
    [Paste your key.pem content here]
    -----END PRIVATE KEY-----
```

### Option 2: Using with Open-Source CoCoS

For standalone usage without Prism AI:

#### 1. Deploy the CVM Infrastructure

Follow the same Terraform deployment steps as above (see [Deployment Instructions](#deployment-instructions))

#### 2. Set Up CoCoS Locally

```bash
# Clone and build CoCoS
git clone https://github.com/ultravioletrs/cocos.git
cd cocos
make cli

# Generate keys for secure communication
./build/cocos-cli keys
```

#### 3. Configure Agent Connection

Instead of connecting to Prism, configure your CVM agent to connect to your local CoCoS computation management server as in the [guide](https://docs.cocos.ultraviolet.rs/getting-started#starting-cvms-server) Update the cloud-init configuration to point to your computation management server endpoint:

```yaml
- path: /etc/cocos/environment
  content: |
    AGENT_CVM_GRPC_URL=<your-computation-server-ip>:7001
    AGENT_LOG_LEVEL=info
```

#### 4. Run Computations

Use the CoCoS CLI to interact directly with your CVM:

```bash
# Set agent URL
export AGENT_GRPC_URL=<cvm-ip>:7002

# Upload algorithm
./build/cocos-cli algo ./path/to/algorithm.py ./private.pem -a python

# Retrieve results
./build/cocos-cli result ./private.pem
```

For detailed instructions, see the [CoCoS Getting Started Guide](https://docs.cocos.ultraviolet.rs/getting-started).

## Deployment Instructions

### Google Cloud Platform (GCP)

#### Step 1: Deploy KMS Infrastructure

```bash
cd gcp/kms
tofu init
tofu plan -var-file="../../terraform.tfvars"
tofu apply -var-file="../../terraform.tfvars"
```

Note the `disk_encryption_id` from the output and add it to your `terraform.tfvars`.

#### Step 2: Deploy the CVM

```bash
cd ..
tofu init
tofu plan -var-file="../terraform.tfvars"
tofu apply -var-file="../terraform.tfvars"
```

#### Step 3: Generate Attestation Policy

Download the attestation report from your VM and generate the policy:

```bash
./cocos-cli policy gcp /path/to/attestation-report.json 2 -j
```

The second argument (2) represents your VM's vCPU count.

### Microsoft Azure

#### Step 1: Authenticate and Deploy KMS

```bash
cd azure/kms
az login
tofu init
tofu plan -var-file="../../terraform.tfvars"
tofu apply -var-file="../../terraform.tfvars"
```

Note the `disk_encryption_id` and add it to your `terraform.tfvars`.

#### Step 2: Deploy the CVM

```bash
cd ..
tofu init
tofu plan -var-file="../terraform.tfvars"
tofu apply -var-file="../terraform.tfvars"
```

#### Step 3: Generate Attestation Policy

Download the attestation token and generate the policy:

```bash
./cocos-cli policy azure /path/to/azure-attestation-token.json Milan
```

## Verification

After deployment, verify your CVM is online:

1. Check the Prism UI - the CVM status should change from "creating" to "online"
2. If issues occur, SSH into the VM and restart the agent:

```bash
sudo systemctl restart cocos-agent.service
```

## Troubleshooting

### Agent Won't Connect

- Verify network connectivity to `prism.ultraviolet.rs:7018` or your local computation management server ip.
- Check certificate validity and file paths
- Review agent logs: `sudo journalctl -u cocos-agent.service -f`

### Attestation Failures

- Ensure AMD processor with SEV-SNP support
- Verify attestation report is recent
- Check for infrastructure changes affecting measurements

### Performance Issues

- Choose appropriate machine types for your workload
- Monitor resource utilization
- Optimize network configurations

## Security Best Practices

- **Network Security**: Configure firewalls to allow only necessary traffic
- **Certificate Management**: Regularly rotate authentication certificates
- **Attestation Policies**: Keep policies updated as infrastructure evolves
- **Monitoring**: Implement comprehensive infrastructure monitoring
- **Version Control**: Store all configurations in version control

## Cost Management

External CVMs give you control over cloud costs:

- Choose machine types matching your workload
- Implement auto-scaling policies
- Use cloud provider cost monitoring tools
- Clean up unused resources: `tofu destroy`

## Contributing

Contributions are welcome! Please submit pull requests or open issues for bugs and feature requests.

## Resources

- [Prism AI Platform](https://prism.ultraviolet.rs)
- [CoCoS GitHub](https://github.com/ultravioletrs/cocos)
- [CoCoS Documentation](https://docs.cocos.ultraviolet.rs)
- [CoCoS Getting Started Guide](https://docs.cocos.ultraviolet.rs/getting-started)
- [Prism Documentation](https://docs.ultraviolet.rs)

## Support

For support and questions:
- Open an issue in this repository
- Contact the Prism AI team
- Join our community channels

---

**Ready to deploy confidential computing?** Visit [https://prism.ultraviolet.rs](https://prism.ultraviolet.rs) to get started.
