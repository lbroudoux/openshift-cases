#!/bin/bash
################################################################################
# Provisioning script to deploy the infrastructure of demos on an OpenShift environment  #
################################################################################

################################################################################
# CONFIGURATION                                                                #
################################################################################

DOMAIN=""
PRJ_CI=("fabric" "CI/CD Fabric" "CI/CD Components (Jenkins, Gogs, etc)")
GOGS_ROUTE="gogs-${PRJ_CI[0]}.$DOMAIN"

GOGS_USER=developer
GOGS_PASSWORD=developer
GOGS_ADMIN_USER=team
GOGS_ADMIN_PASSWORD=team


# Create Infra Project for CI/CD
function create_cicd_project() {
  echo_header "Creating project..."

  echo "Creating project ${PRJ_CI[0]}"
  oc new-project ${PRJ_CI[0]} --display-name="${PRJ_CI[1]}" --description="${PRJ_CI[2]}" >/dev/null
}

# Deploy Gogs
function deploy_gogs() {
  echo_header "Deploying Gogs git server..."

  local _DB_USER=gogs
  local _DB_PASSWORD=gogs
  local _DB_NAME=gogs

  # hack for getting default domain for routes.
  if [ "x$DOMAIN" = "x" ]; then
    #DOMAIN=$(oc get route docker-registry -o template --template='{{.spec.host}}' -n default | sed "s/docker-registry-default.//g")
    DOMAIN=$(oc get route console -o template --template='{{.spec.host}}' -n openshift-console | sed "s/console-openshift-console.//g")
    GOGS_ROUTE="gogs-${PRJ_CI[0]}.$DOMAIN"
  fi

  #oc process -f gogs-persistent-template.yaml --param=HOSTNAME=$GOGS_ROUTE --param=GOGS_VERSION=0.9.113 --param=DATABASE_USER=$_DB_USER --param=DATABASE_PASSWORD=$_DB_PASSWORD --param=DATABASE_NAME=$_DB_NAME --param=SKIP_TLS_VERIFY=true -n ${PRJ_CI[0]} | oc create -f - -n ${PRJ_CI[0]}
  oc process -f gogs-persistent-template-ocp4.yaml --param=HOSTNAME=$GOGS_ROUTE --param=GOGS_VERSION=0.9.113 --param=DATABASE_USER=$_DB_USER --param=DATABASE_PASSWORD=$_DB_PASSWORD --param=DATABASE_NAME=$_DB_NAME --param=SKIP_TLS_VERIFY=true -n ${PRJ_CI[0]} | oc create -f - -n ${PRJ_CI[0]}
  sleep 10

  # wait for Gogs to be ready
  wait_while_empty "Gogs PostgreSQL" 600 "oc get ep gogs-postgresql -o yaml -n ${PRJ_CI[0]} | grep '\- addresses:'"
  wait_while_empty "Gogs" 600 "oc get ep gogs -o yaml -n ${PRJ_CI[0]} | grep '\- addresses:'"
  sleep 10

  # add admin user
  _RETURN=$(curl -o /dev/null -sL --post302 -w "%{http_code}" http://$GOGS_ROUTE/user/sign_up \
    --form user_name=$GOGS_ADMIN_USER \
    --form password=$GOGS_ADMIN_PASSWORD \
    --form retype=$GOGS_ADMIN_PASSWORD \
    --form email=$GOGS_ADMIN_USER@gogs.com)
  sleep 5
}

# Deploy Nexus
function deploy_nexus() {
  echo_header "Deploying Sonatype Nexus repository manager..."
  oc process -f nexus2-persistent-template.yaml -n ${PRJ_CI[0]} | oc create -f - -n ${PRJ_CI[0]}
  sleep 10
  oc set resources dc/nexus --limits=cpu=1,memory=2Gi --requests=cpu=200m,memory=1Gi -n ${PRJ_CI[0]}
}

# Deploy Jenkins
function deploy_jenkins() {
  echo_header "Deploying Jenkins..."
  oc new-app jenkins-persistent -l app=jenkins -p MEMORY_LIMIT=1Gi -n ${PRJ_CI[0]}
  sleep 5
  oc set resources dc/jenkins --limits=cpu=1,memory=2Gi --requests=cpu=200m,memory=1Gi -n ${PRJ_CI[0]}
  oc adm pod-network make-projects-global ${PRJ_CI[0]}
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

create_cicd_project
deploy_gogs
#deploy_nexus
deploy_jenkins
