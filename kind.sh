#!/bin/bash

set -e

echo "========================================="
echo "        WSL SYSTEM CHECK"
echo "========================================="

uname -a

echo ""
echo "========================================="
echo "        DOCKER CHECK"
echo "========================================="

docker version
docker ps

echo ""
echo "========================================="
echo "        INSTALLING KIND"
echo "========================================="

KIND_VERSION="v0.32.0"

curl -Lo ./kind \
  "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"

chmod +x ./kind

sudo mv ./kind /usr/local/bin/kind

echo ""
echo "========================================="
echo "        KIND VERSION"
echo "========================================="

kind version

echo ""
echo "========================================="
echo "        CREATING KIND CLUSTER"
echo "========================================="

CLUSTER_NAME="devops-lab"

if kind get clusters | grep -qx "$CLUSTER_NAME"; then
    echo "KIND cluster '$CLUSTER_NAME' already exists."
else
    kind create cluster \
        --name "$CLUSTER_NAME" \
        --wait 5m
fi

echo ""
echo "========================================="
echo "        KUBERNETES CONTEXT"
echo "========================================="

kubectl config current-context

echo ""
echo "========================================="
echo "        KUBERNETES NODES"
echo "========================================="

kubectl get nodes -o wide

echo ""
echo "========================================="
echo "        KUBERNETES CLUSTER INFO"
echo "========================================="

kubectl cluster-info

echo ""
echo "========================================="
echo "        KIND CLUSTERS"
echo "========================================="

kind get clusters

echo ""
echo "========================================="
echo "        CLUSTER CREATED SUCCESSFULLY"
echo "========================================="

echo "Cluster Name: $CLUSTER_NAME"
echo "Context: kind-$CLUSTER_NAME"