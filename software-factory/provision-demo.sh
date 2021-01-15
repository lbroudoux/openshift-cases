#!/bin/bash
################################################################################
# Provisioning script to deploy the demos on an OpenShift environment  #
################################################################################

function usage() {
    echo
    echo "Usage:"
    echo " $0 [command] [demo-name] [options]"
    echo " $0 --help"
    echo
    echo "Example:"
    echo " $0 deploy --maven-mirror-url http://nexus.repo.com/content/groups/public/ --project-suffix mydemo"
    echo
    echo "COMMANDS:"
    echo "   deploy                   Set up the demo projects and deploy demo apps"
    echo "   delete                   Clean up and remove demo projects and objects"
    echo "   idle                     Make all demo services idle"
    echo "   unidle                   Make all demo services unidle"
    echo
    echo "DEMOS:"
    echo "   ab-testing               A/B Testing deployment and router"
    echo "   bg-demo                  CI/CD with rolling update on PHP app"
    echo "   news-aggregator          Composite / microservices news-aggregator"
    echo
    echo "OPTIONS:"
    echo "   --user [username]         The admin user for the demo projects. mandatory if logged in as system:admin"
    echo "   --maven-mirror-url [url]  Use the given Maven repository for builds. If not specifid, a Nexus container is deployed in the demo"
    echo "   --project-suffix [suffix] Suffix to be added to demo project names e.g. ci-SUFFIX. If empty, user will be used as suffix"
    echo
}

ARG_COMMAND=
ARG_DEMO=

while :; do
    case $1 in
        deploy)
            ARG_COMMAND=deploy
            if [ -n "$2" ]; then
                ARG_DEMO=$2
                shift
            fi
            ;;
        delete)
            ARG_COMMAND=delete
            if [ -n "$2" ]; then
                ARG_DEMO=$2
                shift
            fi
            ;;
        idle)
            ARG_COMMAND=idle
            if [ -n "$2" ]; then
                ARG_DEMO=$2
                shift
            fi
            ;;
        unidle)
            ARG_COMMAND=unidle
            if [ -n "$2" ]; then
                ARG_DEMO=$2
                shift
            fi
            ;;
        --user)
            if [ -n "$2" ]; then
                ARG_USERNAME=$2
                shift
            else
                printf 'ERROR: "--user" requires a non-empty value.\n' >&2
                usage
                exit 255
            fi
            ;;
        --maven-mirror-url)
            if [ -n "$2" ]; then
                ARG_MAVEN_MIRROR_URL=$2
                shift
            else
                printf 'ERROR: "--maven-mirror-url" requires a non-empty value.\n' >&2
                usage
                exit 255
            fi
            ;;
        --project-suffix)
            if [ -n "$2" ]; then
                ARG_PROJECT_SUFFIX=$2
                shift
            else
                printf 'ERROR: "--project-suffix" requires a non-empty value.\n' >&2
                usage
                exit 255
            fi
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            shift
            ;;
        *) # Default case: If no more options then break out of the loop.
            break
    esac

    shift
done

################################################################################
# CONFIGURATION                                                                #
################################################################################

#DOMAIN="apps.bizotdc.tech"
#DOMAIN="apps.cluster-lemans-ff7f.lemans-ff7f.example.opentlc.com"
DOMAIN=$(oc get route console -o template --template='{{.spec.host}}' -n openshift-console | sed "s/console-openshift-console.//g")
PRJ_CI=("fabric" "CI/CD Fabric" "CI/CD Components (Jenkins, Gogs, etc)")
GOGS_ROUTE="gogs-${PRJ_CI[0]}.$DOMAIN"

GOGS_USER=developer
GOGS_PASSWORD=developer
GOGS_ADMIN_USER=team
GOGS_ADMIN_PASSWORD=team

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

function provision_ab_demo() {
  echo_header "Deploying A/B Testing demo..."

  # import GitHub repo
  read -r -d '' _DATA_JSON << EOM
{
  "name": "ab-testing",
  "private": false
}
EOM

  echo "Creating repository ab-testing on Gogs"
  _RETURN=$(curl -o /dev/null -sL -w "%{http_code}" -H "Content-Type: application/json" -d "$_DATA_JSON" -u $GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD -X POST http://$GOGS_ROUTE/api/v1/user/repos)
  if [ $_RETURN != "201" ] && [ $_RETURN != "200" ] ; then
    echo "WARNING: Failed (http code $_RETURN) to create repository"
  else
    echo "ab-testing repo created"
  fi
  sleep 2

  local _CUR_DIR=$PWD
  local _REPO_DIR=/tmp/$(date +%s)-ab-testing
  echo "Pushing local sources on Gogs ab-testing repository"
  pushd ~ >/dev/null && \
      rm -rf $_REPO_DIR && \
      mkdir $_REPO_DIR && \
      cd $_REPO_DIR && \
      git init && \
      cp -R $_CUR_DIR/../ab-testing/ . && \
      git remote add origin http://$GOGS_ROUTE/$GOGS_ADMIN_USER/ab-testing.git && \
      git add . --all && \
      git config user.email "lbroudou@redhat.com" && \
      git config user.name "Laurent Broudoux" && \
      git commit -m "Initial add" && \
      git push -f http://$GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD@$GOGS_ROUTE/$GOGS_ADMIN_USER/ab-testing.git master && \
      popd >/dev/null && \
      rm -rf $_REPO_DIR
  sleep 2

  oc new-project ab-testing --display-name="A/B Testing"
  oc new-app php:5.6~http://$GOGS_ROUTE/$GOGS_ADMIN_USER/ab-testing.git --name=app-a -n ab-testing

  echo "Now modifying sources on Gogs ab-testing repository"
  pushd ~ >/dev/null && \
      cd /tmp && \
      git clone http://$GOGS_ROUTE/$GOGS_ADMIN_USER/ab-testing.git && \
      cd ab-testing && \
      sed -i '' 's/VERSION A/VERSION B/g' index.php && \
      git config user.email "lbroudou@redhat.com" && \
      git config user.name "Laurent Broudoux" && \
      git commit -m "Modify to version B" && \
      git push origin master && \
      popd >/dev/null && \
      rm -rf /tmp/ab-testing
  sleep 2
  oc new-app php:5.6~http://$GOGS_ROUTE/$GOGS_ADMIN_USER/ab-testing.git --name=app-b -n ab-testing

  oc expose svc app-a --name=app-ab
  oc annotate route/app-ab haproxy.router.openshift.io/balance=roundrodbin
}

function provision_bg_demo() {
  echo_header "Deploying MyApp BG demo..."

  # import GitHub repo
  read -r -d '' _DATA_JSON << EOM
{
  "name": "bg-demo",
  "private": false
}
EOM

  echo "Creating repository bg-demo on Gogs"
  _RETURN=$(curl -o /dev/null -sL -w "%{http_code}" -H "Content-Type: application/json" -d "$_DATA_JSON" -u $GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD -X POST http://$GOGS_ROUTE/api/v1/user/repos)
  if [ $_RETURN != "201" ] && [ $_RETURN != "200" ] ; then
    echo "WARNING: Failed (http code $_RETURN) to create repository"
  else
    echo "bg-demo repo created"
  fi
  sleep 2

  local _CUR_DIR=$PWD
  local _REPO_DIR=/tmp/$(date +%s)-bg-demo
  echo "Pushing local sources on Gogs bg-demo repository"
  pushd ~ >/dev/null && \
      rm -rf $_REPO_DIR && \
      mkdir $_REPO_DIR && \
      cd $_REPO_DIR && \
      git init && \
      cp -R $_CUR_DIR/../bg-demo/ . && \
      git remote add origin http://$GOGS_ROUTE/$GOGS_ADMIN_USER/bg-demo.git && \
      git add . --all && \
      git config user.email "lbroudou@redhat.com" && \
      git config user.name "Laurent Broudoux" && \
      git commit -m "Initial add" && \
      git push -f http://$GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD@$GOGS_ROUTE/$GOGS_ADMIN_USER/bg-demo.git master && \
      popd >/dev/null && \
      rm -rf $_REPO_DIR
  sleep 2

  oc adm policy add-scc-to-group anyuid system:serviceaccounts:cicd

  # Create 3 projects
  oc new-project myapp-dev --display-name="MyApp BG Development"
  #oc new-app php:5.6~http://$GOGS_ROUTE/$GOGS_ADMIN_USER/bg-demo.git --name=myapp -n myapp-dev
  oc new-app php:7.3-ubi8~http://$GOGS_ROUTE/$GOGS_ADMIN_USER/bg-demo.git --name=myapp -n myapp-dev
  oc new-project myapp-test --display-name="MyApp BG Testing"
  oc new-project myapp-prod --display-name="MyApp BG Production"

  # Adjust project permissions
  oc adm policy add-role-to-user edit system:serviceaccount:${PRJ_CI[0]}:jenkins -n myapp-dev
  oc adm policy add-role-to-user edit system:serviceaccount:${PRJ_CI[0]}:jenkins -n myapp-test
  oc adm policy add-role-to-user edit system:serviceaccount:${PRJ_CI[0]}:jenkins -n myapp-prod

  # Allow test and prod to pull from dev
  oc adm policy add-role-to-group system:image-puller system:serviceaccounts:myapp-test -n myapp-dev
  oc adm policy add-role-to-group system:image-puller system:serviceaccounts:myapp-prod -n myapp-dev

  # After having created development bc, dc, svc, routes
  oc expose svc myapp -n myapp-dev

  #oc create deploymentconfig myapp --image=docker-registry.default.svc:5000/myapp-dev/myapp:promoteToTest -n myapp-test
  oc create deploymentconfig myapp --image=image-registry.openshift-image-registry.svc:5000/myapp-dev/myapp:promoteToTest -n myapp-test
  oc rollout cancel dc/myapp -n myapp-test
  oc get dc myapp -o json -n myapp-test | jq '.spec.triggers |= []' | oc replace -f -
  oc get dc myapp -o yaml -n myapp-test | sed 's/imagePullPolicy: IfNotPresent/imagePullPolicy: Always/g' | oc replace -f -
  oc expose dc myapp --port=8080 -n myapp-test
  oc expose svc myapp -n myapp-test

  #oc create deploymentconfig myapp --image=docker-registry.default.svc:5000/myapp-dev/myapp:promoteToProd -n myapp-prod
  oc create deploymentconfig myapp --image=image-registry.openshift-image-registry.svc:5000/myapp-dev/myapp:promoteToProd -n myapp-prod
  oc rollout cancel dc/myapp -n myapp-prod
  oc get dc myapp -o json -n myapp-prod | jq '.spec.triggers |= []' | oc replace -f -
  oc get dc myapp -o yaml -n myapp-prod | sed 's/imagePullPolicy: IfNotPresent/imagePullPolicy: Always/g' | oc replace -f -
  oc expose dc myapp --port=8080 -n myapp-prod
  oc expose svc myapp -n myapp-prod

  #oc create -f ../bg-demo/pipeline/pipeline.yml -n ${PRJ_CI[0]} 
  oc create -f ../bg-demo/pipeline/pipeline-ocp4.yml -n ${PRJ_CI[0]}
}

function provision_news_aggregator_demo() {
  echo_header "Deploying News Aggregator demo..."

  # import articles GitHub repo
  read -r -d '' _DATA_JSON << EOM
{
  "name": "articles",
  "private": false
}
EOM

  echo "Creating repository articles on Gogs"
  _RETURN=$(curl -o /dev/null -sL -w "%{http_code}" -H "Content-Type: application/json" -d "$_DATA_JSON" -u $GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD -X POST http://$GOGS_ROUTE/api/v1/user/repos)
  if [ $_RETURN != "201" ] && [ $_RETURN != "200" ] ; then
    echo "WARNING: Failed (http code $_RETURN) to create repository"
  else
    echo "articles repo created"
  fi
  sleep 2

  local _CUR_DIR=$PWD
  local _REPO_DIR=/tmp/$(date +%s)-articles
  echo "Pushing local sources on Gogs articles repository"
  pushd ~ >/dev/null && \
      rm -rf $_REPO_DIR && \
      mkdir $_REPO_DIR && \
      cd $_REPO_DIR && \
      git init && \
      cp -R $_CUR_DIR/../news-aggregator/articles/ . && \
      git remote add origin http://$GOGS_ROUTE/$GOGS_ADMIN_USER/articles.git && \
      git add . --all && \
      git config user.email "lbroudou@redhat.com" && \
      git config user.name "Laurent Broudoux" && \
      git commit -m "Initial add" && \
      git push -f http://$GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD@$GOGS_ROUTE/$GOGS_ADMIN_USER/articles.git master && \
      popd >/dev/null && \
      rm -rf $_REPO_DIR
  sleep 2

  # import articles GitHub repo
  read -r -d '' _DATA_JSON << EOM
{
  "name": "aggregator",
  "private": false
}
EOM

  echo "Creating repository aggregator on Gogs"
  _RETURN=$(curl -o /dev/null -sL -w "%{http_code}" -H "Content-Type: application/json" -d "$_DATA_JSON" -u $GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD -X POST http://$GOGS_ROUTE/api/v1/user/repos)
  if [ $_RETURN != "201" ] && [ $_RETURN != "200" ] ; then
    echo "WARNING: Failed (http code $_RETURN) to create repository"
  else
    echo "articles repo aggregator"
  fi
  sleep 2

  local _REPO_DIR=/tmp/$(date +%s)-aggregator
  echo "Pushing local sources on Gogs aggregator repository"
  pushd ~ >/dev/null && \
      rm -rf $_REPO_DIR && \
      mkdir $_REPO_DIR && \
      cd $_REPO_DIR && \
      git init && \
      cp -R $_CUR_DIR/../news-aggregator/aggregator/ . && \
      git remote add origin http://$GOGS_ROUTE/$GOGS_ADMIN_USER/aggregator.git && \
      git add . --all && \
      git config user.email "lbroudou@redhat.com" && \
      git config user.name "Laurent Broudoux" && \
      git commit -m "Initial add" && \
      git push -f http://$GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD@$GOGS_ROUTE/$GOGS_ADMIN_USER/aggregator.git master && \
      popd >/dev/null && \
      rm -rf $_REPO_DIR
  sleep 2

  # import spring-boot-hello GitHub repo
  read -r -d '' _DATA_JSON << EOM
{
  "name": "spring-boot-hello",
  "private": false
}
EOM

  echo "Creating repository spring-boot-hello on Gogs"
  _RETURN=$(curl -o /dev/null -sL -w "%{http_code}" -H "Content-Type: application/json" -d "$_DATA_JSON" -u $GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD -X POST http://$GOGS_ROUTE/api/v1/user/repos)
  if [ $_RETURN != "201" ] && [ $_RETURN != "200" ] ; then
    echo "WARNING: Failed (http code $_RETURN) to create repository"
  else
    echo "spring-boot-hello repo aggregator"
  fi
  sleep 2

  local _REPO_DIR=/tmp/$(date +%s)-spring-boot-hello
  echo "Pushing local sources on Gogs spring-boot-hello repository"
  pushd ~ >/dev/null && \
      rm -rf $_REPO_DIR && \
      mkdir $_REPO_DIR && \
      cd $_REPO_DIR && \
      git init && \
      cp -R $_CUR_DIR/../news-aggregator/spring-boot-hello/ . && \
      git remote add origin http://$GOGS_ROUTE/$GOGS_ADMIN_USER/spring-boot-hello.git && \
      git add . --all && \
      git config user.email "lbroudou@redhat.com" && \
      git config user.name "Laurent Broudoux" && \
      git commit -m "Initial add" && \
      git push -f http://$GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD@$GOGS_ROUTE/$GOGS_ADMIN_USER/spring-boot-hello.git master && \
      popd >/dev/null && \
      rm -rf $_REPO_DIR
  sleep 2

  # Register template within openshift namespace
  oc create -f ../news-aggregator/news-aggregator-template.json -n openshift
}

################################################################################
# MAIN: DEPLOY DEMOS                                                           #
################################################################################

case "$ARG_COMMAND" in
    deploy)
      if [ "$ARG_DEMO" = "ab-testing" ] ; then
        provision_ab_demo
      elif [ "$ARG_DEMO" = "bg-demo" ] ; then
        provision_bg_demo
      elif [ "$ARG_DEMO" = "news-aggregator" ] ; then
        provision_news_aggregator_demo
      fi
      ;;
    delete)
      ;;
    idle)
      ;;
    unidle)
      ;;
    *)
      echo "Invalid command specified: '$ARG_COMMAND'"
      usage
      ;;
esac
