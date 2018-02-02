
DOCUMENTATION


0/ CREATION IMAGE S2I

oc new-build http://gitlab-cicd.13.69.24.39.nip.io/lbroudoux/eap-custom.git --context-dir=/6.4 --strategy=docker --to=custom-eap64-apm


1/ SANS TEMPLATE

oc new-build custom-eap64-apm~http://gitlab-cicd.13.69.24.39.nip.io/lbroudoux/openshift-tasks.git --to=tasks --name=tasks --build-e WAR_FILE_URL=http://...war
oc new-app --image-stream=tasks --name=tasks --allow-missing-imagestream-tags --env DB_PORT_3306_TCP_ADDR='database'
oc expose dc/tasks
oc expose svc/tasks

2/ AVEC TEMPLATE

oc process -f openshift-tasks-apm-template.yml -p WAR_FILE_URL=BAR | oc create -f -

3/ AVEC TEMPLATE pré-enregistré

oc create -f openshift-tasks-apm-template.yml
oc process -t openshift-tasks-apm -p WAR_FILE_URL=BAR | oc create -f -
