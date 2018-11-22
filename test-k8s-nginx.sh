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
    echo "### Pass 1 - Testing through bastion host $host"
    TNAME="nginx-$INST"
    ssh -q -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i $KEY ubuntu@$host kubectl create deploy $TNAME --image nginx
    ssh -q -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i $KEY ubuntu@$host kubectl expose deploy $TNAME --port 80 --type NodePort
    let INST=INST+1
done

INST=1
for host in $(terraform output instance_ips | cut -f 1 -d ','); do
    echo "###############################################"
    echo "### Pass 2 - Testing through bastion host $host"
    TNAME="nginx-$INST"
    NODES=$(ssh -q -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i $KEY ubuntu@$host kubectl get nodes -o jsonpath='"'{.items[*].status.addresses[?\(@.type=='\"'ExternalIP'\"'\)].address}'"')
    PORT=$(ssh -q -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i $KEY ubuntu@$host kubectl get svc $TNAME -o jsonpath='"'{@.spec.ports[0].nodePort}'"')
    echo "  Cluster nodes: $NODES"
    for node in $NODES; do
        echo "    Testing nodeport access through node $node, port $PORT"
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
    echo "### Pass 3 - Testing through bastion host $host"
    TNAME="nginx-$INST"
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
