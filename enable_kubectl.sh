#!/bin/bash

set -eu

KEY=testkey

for host in $(terraform output instance_ips | cut -f 1 -d ','); do
    echo "### Processing host $host"
    ssh -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i $KEY ubuntu@$host source /tmp/enable_kubectl.sh
done

echo "##########################################"
echo "## Testing kubectl on all bastion hosts ##"
echo "##########################################"
for host in $(terraform output instance_ips | cut -f 1 -d ','); do
    echo "### Testing kubectl on host $host"
    ssh -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i $KEY ubuntu@$host kubectl get componentstatuses
done
