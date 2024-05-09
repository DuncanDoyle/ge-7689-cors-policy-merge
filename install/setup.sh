#!/bin/sh

pushd ..

# Create httpbin namespace if it does not yet exist
kubectl create namespace httpbin --dry-run=client -o yaml | kubectl apply -f -

printf "\nDeploy HTTPBin service ...\n"
kubectl apply -f apis/httpbin.yaml

printf "\nDeploy Petstore application ...\n"
kubectl apply -f apis/petstore.yaml

# Create gloo-deployments namespace if it does not yet exist
kubectl create namespace gloo-deployments --dry-run=client -o yaml | kubectl apply -f -

# Policies/Options
kubectl apply -f policies/cors-virtualhostoptions.yaml

# VirtualServices
printf "\nDeploy VirtualServices ...\n"
kubectl apply -f virtualservices/api-example-com-vs.yaml
kubectl apply -f virtualservices/petstore-example-com-vs.yaml

popd