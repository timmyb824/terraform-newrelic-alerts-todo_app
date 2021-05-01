# Summary
Provision New Relic alerting using Terraform.

## Installation

Install terraform:

https://learn.hashicorp.com/tutorials/terraform/install-cli

https://www.terraform.io/downloads.html

Install New Relic Provider:
```bash
terraform {
  required_providers {
    newrelic = {
      source = "newrelic/newrelic"
      version = "2.19.0"
    }
  }
}

provider "newrelic" {
  # Configuration options
}
```

Initilize the configuration:
```bash
terraform init
```

## Notes
A .tfvars file is needed for this code to work. 

