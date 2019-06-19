#!/bin/bash

set -eu

KEY=testkey

echo "######################################"
echo "## Testing ssh to all bastion hosts ##"
echo "######################################"
for host in $(terraform output -json instance_ips | jq -r '.[][]'); do
    echo "### Testing access and uptime of host $host"
    ssh -q -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i $KEY ubuntu@$host uptime
done

echo "-----------------------------------"
echo "Success - all hosts responded"
echo "-----------------------------------"
