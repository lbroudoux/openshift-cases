```
$ oc process -f https://raw.githubusercontent.com/jaegertracing/jaeger-openshift/master/all-in-one/jaeger-all-in-one-template.yml | oc create -f - -n cockpit
$ oc process -f prometheus-app-311.yaml --param=NAMESPACE=cockpit | oc create -f - -n cockpit
$ oc process -f grafana-app-311.yaml --param=NAMESPACE=cockpit --param=GRAFANA_RELEASE=stable | oc create -f - -n cockpit
```