# Rocky Linux 9 Azure Deployment with Terraform

Hard-codes lots of things that should be parameterised,
but demonstrates how to deploy a Rocky Linux 9 VM in Azure using a
[Terraform module](https://github.com/simonbrady/azure-vm-tf-module).

Requires an existing SSH RSA key, and you'll have to set
your local IP in the `allowed_cidr` variable.
