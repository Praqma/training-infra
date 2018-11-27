#!/bin/bash

#set -eu
set -u

KEY=testkey

SUCCESSES=0
ERRORS=0

echo "##############################################"
echo "## Test running nginx on Kubernetes cluster ##"
echo "##############################################"

INST=1
for host in $(terraform output instance_ips | cut -f 1 -d ','); do
    echo "###############################################"
    echo "### Step 1 - Create test resource through bastion host $host"
    TNAME="autotest-nginx-$INST"
    ssh -q -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i $KEY ubuntu@$host kubectl create deploy $TNAME --image nginx
    # This is also a capacity test, i.e. do we have sufficient cluster resources for all users
    ssh -q -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i $KEY ubuntu@$host kubectl scale --replicas 5 deploy $TNAME
    ssh -q -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i $KEY ubuntu@$host kubectl expose deploy $TNAME --port 80 --type NodePort
    let INST=INST+1
done

INST=1
# The loop here is mostly to get the 'per bastion' instance count and 'do things' through all bastions
for host in $(terraform output instance_ips | cut -f 1 -d ','); do
    echo "###############################################"
    echo "### Step 2 - Testing through global access"
    TNAME="autotest-nginx-$INST"
    NODES=$(ssh -q -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i $KEY ubuntu@$host kubectl get nodes -o jsonpath='"'{.items[*].status.addresses[?\(@.type=='\"'ExternalIP'\"'\)].address}'"')
    PORT=$(ssh -q -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i $KEY ubuntu@$host kubectl get svc $TNAME -o jsonpath='"'{@.spec.ports[0].nodePort}'"')
    echo "  Cluster nodes (external-ip): $NODES"
    for node in $NODES; do
        echo "    Testing nodeport access through cluster node $node, port $PORT"
	# Note, curl is running locally, i.e. we assume this is 'internet access'
        curl --connect-timeout 60 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 40 --retry-connrefused -s $node:$PORT | grep -q 'Welcome to nginx!'
        if [ $? -eq 0 ]; then
            #echo "    - Got expected result from Nginx (bastion host $host, node $node, port $PORT)"
	    let SUCCESSES=SUCCESSES+1
        else
            echo "*** ERROR - did not get expected result from Nginx (bastion host $host, node $node, port $PORT)"
            let ERRORS=ERRORS+1
        fi
    done
    let INST=INST+1
done

INST=1
for host in $(terraform output instance_ips | cut -f 1 -d ','); do
    echo "###############################################"
    echo "### Step 3 - Testing through bastion host $host"
    TNAME="autotest-nginx-$INST"
    NODES=$(ssh -q -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i $KEY ubuntu@$host kubectl get nodes -o jsonpath='"'{.items[*].status.addresses[?\(@.type=='\"'InternalIP'\"'\)].address}'"')
    PORT=$(ssh -q -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i $KEY ubuntu@$host kubectl get svc $TNAME -o jsonpath='"'{@.spec.ports[0].nodePort}'"')
    echo "  Cluster nodes (internal-ip): $NODES"
    for node in $NODES; do
        echo "    Testing nodeport access through cluster node $node, port $PORT @ bastion host $host"
        ssh -q -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i $KEY ubuntu@$host curl -s $node:$PORT | grep -q 'Welcome to nginx!'
        if [ $? -eq 0 ]; then
            #echo "    - Got expected result from Nginx (bastion host $host, node $node, port $PORT)"
	    let SUCCESSES=SUCCESSES+1
        else
            echo "*** ERROR - did not get expected result from Nginx (bastion host $host, node $node, port $PORT)"
            let ERRORS=ERRORS+1
        fi
    done
    let INST=INST+1
done

INST=1
for host in $(terraform output instance_ips | cut -f 1 -d ','); do
    echo "###############################################"
    echo "### Step 4 - Deleting test resources using bastion host $host"
    TNAME="autotest-nginx-$INST"
    ssh -q -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i $KEY ubuntu@$host kubectl delete svc $TNAME
    ssh -q -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i $KEY ubuntu@$host kubectl delete deploy $TNAME
    let INST=INST+1
done

echo "-----------------------------------"
if [ $ERRORS -eq 0 ]; then
    echo "Success - no errors detected ($SUCCESSES successes)"
else
    echo "*** Failed - $ERRORS error(s) found ($SUCCESSES successes)"
fi
echo "-----------------------------------"
