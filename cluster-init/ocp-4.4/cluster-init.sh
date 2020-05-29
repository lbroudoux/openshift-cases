#!/bin/bash

################################################################################
# Prepare your cluster for App Dev demonstrations  #
################################################################################

# Prepare a specific namespace for CodeReady Workspaces and Fuse Online
oc new-project workspaces
oc new-project fuse-online

# Start installing all operators and needed custom resources.
oc create -f operators-subscriptions.yaml

# Prepare projects to allow recopy of operators before waiting.
oc new-project istio-system
oc new-project knative-serving

# Wait a moment to allow operators to startup.
echo "Waiting a moment before pursuing..."
sleep 60

# Installing the ServiceMesh and Knative.
oc create -f operator-servicemesh-cr.yaml -n istio-system
oc create -f operator-serverless-cr.yaml -n knative-serving

# Installing CodeReady Workspaces
oc create -f operator-crw-cr.yaml -n workspaces

# Installing Fuse Online
source fuse-online-docker-secret.sh
oc create -f operator-syndesis-subscription.yaml -n fuse-online
oc secrets link syndesis-operator syndesis-service-account-pull-secret --for=pull -n fuse-online
oc create -f operator-syndesis-cr.yaml -n fuse-online
