#!/bin/bash
################################################################################
# Provisioning script to deploy the monitoring infra of demos on an OpenShift environment  #
################################################################################

################################################################################
# CONFIGURATION                                                                #
################################################################################

DOMAIN=""
PRJ_CP=("cockpit" "Cockpit" "Monitoring Components (Prometheus, Grafana, etc)")

# Create Infra Project for Monitoring
function create_cp_project() {
  echo_header "Creating project..."

  echo "Creating project ${PRJ_CP[0]}"
  oc new-project ${PRJ_CP[0]} --display-name="${PRJ_CP[1]}" --description="${PRJ_CP[2]}" >/dev/null
  oc adm pod-network make-projects-global ${PRJ_CP[0]}
}

# Deploy Prometheus
function deploy_prometheus() {
  echo_header "Deploying Prometheus metrics engine..."

  oc process -f grafana-prometheus-storage.yaml --param=PVC_SIZE=5Gi | oc create -f - -n ${PRJ_CP[0]}
  sleep 5
  oc process -f grafana-prometheus.yaml --param=NAMESPACE=${PRJ_CP[0]} | oc create -f - -n ${PRJ_CP[0]}
}

# Deploy Grafana
function deploy_grafana() {
  echo_header "Deploying Grafana dashboard builder..."
  oc import-image -n openshift rhel7 --from registry.access.redhat.com/rhel7:latest --confirm
  oc process -f grafana-base.yaml --param=NAMESPACE=${PRJ_CP[0]} | oc create -f - -n ${PRJ_CP[0]}
}

# Deploy Jaeger
function deploy_jaeger() {
  echo_header "Deploying Jaeger tracing collector..."
  oc process -f https://raw.githubusercontent.com/jaegertracing/jaeger-openshift/master/all-in-one/jaeger-all-in-one-template.yml | oc create -f - -n ${PRJ_CP[0]}
}

function echo_header() {
  echo
  echo "########################################################################"
  echo $1
  echo "########################################################################"
}

# Waits while the condition is true until it becomes false or it times out
function wait_while_empty() {
  local _NAME=$1
  local _TIMEOUT=$(($2/5))
  local _CONDITION=$3

  echo "Waiting for $_NAME to be ready..."
  local x=1
  while [ -z "$(eval ${_CONDITION})" ]
  do
    echo "."
    sleep 5
    x=$(( $x + 1 ))
    if [ $x -gt $_TIMEOUT ]
    then
      echo "$_NAME still not ready, I GIVE UP!"
      exit 255
    fi
  done

  echo "$_NAME is ready."
}

################################################################################
# MAIN: DEPLOY INFRASTRUCTURE                                                  #
################################################################################

create_cp_project
deploy_prometheus
deploy_grafana
deploy_jaeger
