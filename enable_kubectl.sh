#!/bin/bash

set -eux

KEY=testkey

terraform output instance_ips | cut -f 1 -d ',' |xargs -t -IHOST ssh -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i $KEY ubuntu@HOST source /tmp/enable_kubectl.sh

echo "##########################################"
echo "## Testing kubectl on all bastion hosts ##"
echo "##########################################"
terraform output instance_ips | cut -f 1 -d ',' |xargs -t -IHOST ssh -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i $KEY ubuntu@HOST kubectl get componentstatuses
