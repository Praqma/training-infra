This is a Terraform/GCP based infrastructure designed for the Praqma [Docker
katas](https://github.com/praqma-training/docker-katas) and the Praqma
[Kubernetes katas](https://github.com/praqma-training/kubernetes-katas/).

A GCP project should exists and specified through the variables. Optionally the
GCP zone and region can also be specified through the variables. The project
should have compute and container APIs enabled - see also the script
`project-bootstrap.sh`.

The following variables should be reviewed before any deployment of the training infrastructure:

1. `source_ip_cidr` - the source CIDR from where the training network access
originates.  Typically the /32 external NAT address of the training network.
2. `bastion_count` - the number of individual nodes necessary for Docker training
3. `initial_worker_node_count` - the number of worker nodes in the Kubernetes cluster
4. `gce_service_account_key` - the service account used to access the Kubernetes cluster.

An ssh key-pair must be available in the local directory for injection into the
bastion hosts. They can be created with `ssh-keygen` and the default name is
`testkey` and `testkey.pub`.

To bootstrap the infrastructure use terraform as follows:

```
terraform init
terraform apply
```

After the infrastructure has been deployed and the startup-script has installed
the necessary components (hint, wait a few minutes), kubectl can be enabled
using the script `enable_kubectl.sh`.

Should you need to get the list of bastion hosts it can be queried as follows:

```
terraform output instance_ips
```
