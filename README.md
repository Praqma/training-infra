This is a Terraform/GCP based infrastructure designed for the Praqma [Docker
katas](https://github.com/praqma-training/docker-katas) and the Praqma
[Kubernetes katas](https://github.com/praqma-training/kubernetes-katas/).

The Terraform code assumes an existing GCP project which should be specified
through the variables.  The project should have compute, container and IAM APIs
enabled - see also the script `project-bootstrap.sh`.

The file `variables.tf` contain all the variabes that can be tuned for the
infrastructure, however, the following variables are of particular importance
and should be reviewed before any deployment of the training infrastructure:

1. `source_ip_cidr` - the source CIDR from where the training network access
originates.  Typically the /32 external NAT address of the training network. IMPORTANT: Your project should not have any default firewall rules for this to work.  The default value implies no source IP address filtering, i.e. no firewall functionality.

2. `bastion_count` - the number of individual Docker nodes necessary for Docker training. Also functions as the bastion hosts for accessing the Kubernetes cluster.

3. `initial_worker_node_count` - the number of worker nodes in the Kubernetes cluster.

4. `gcp_service_account_key` - the service account used to create all resource. The service account should have the roles `Compute Admin`, `Compute Network Admin`, `Kubernetes Engine Admin`, `Service Account Admin`, `Service Account User` and `Project IAM Admin`.  You also need to ensure that you have the `IAM API`, `Kubernetes Engine API` and `Cloud Resource Manager API` enabled.

6. `global_prefix` - a nice prefix for the resources created by terraform

An easy way to provide custom values for these variables are to create a file called `terraform.tfvars`, e.g.:

```
gcp_service_account_key = "your-service-account-key-file.json"
gcp_project_id = "project-to-use-for-resources"
global_prefix = "yourname-"
source_ip_cidr = [ "11.22.33.44/32" ]
bastion_count = 14
bastion_ports = ["80-40000"]
cluster_initial_worker_node_count = 4
cluster_machine_type = "n1-standard-4"
```

Note that the default variables contain port access lists suitable for the
training katas - should you add more katas or decide to use other ports, you
need to set the port access variables accordingly.

An ssh key-pair must be available in the local directory for injection into the
bastion hosts. They can be created with `ssh-keygen` and the default name is
`testkey` and `testkey.pub`.

# Bootstrapping Infrastructure

To bootstrap the infrastructure use terraform as follows:

```
terraform init
terraform apply
```

# Testing and Post-configuration

After the infrastructure has been deployed, the startup script will install the
necessary components such as Docker and kubectl. To test ssh access availability
of all bastion hosts, use the folowing test script:

```
test-ssh-access.sh
```

and to test running containers and accessing them use:

```
test-docker-run.sh
```

When bastion hosts are ready, kubernetes cluster access can be tested with the
following scripts:

```
test-cluster-access.sh
test-k8s-nginx.sh
```

Should you need to get the list of bastion hosts it can be queried as follows:

```
terraform output instance_ips
```

# Destroying Infrastructure

The deployed infrastructure can be deleted using:

```
terraform destroy
```

Note that Load balancers and persistent volumes are not necessarily destroyed as [documented here](https://cloud.google.com/kubernetes-engine/docs/how-to/deleting-a-cluster).

# Add-ons

The bastions support `kubens` for switching default namespace, `kubeon`/`kubeoff` for enabling prompt with cluster scope and general auto-completion for kubectl.