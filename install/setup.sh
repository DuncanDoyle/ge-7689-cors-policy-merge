#!/bin/sh

pushd ..

# Deploy the petstore application
printf "\nDeploy Petstore application ...\n"
kubectl apply -f apis/petstore.yaml

# Create gloo-deployments namespace if it does not yet exist
kubectl create namespace gloo-deployments --dry-run=client -o yaml | kubectl apply -f -

# Policies/Options
kubectl apply -f policies/cors-virtualhostoptions.yaml

# VirtualServices
printf "\nDeploy VirtualServices ...\n"
kubectl apply -f virtualservices/petstore-example-com-vs.yaml

popd