
Build a new custom image into your OpenShift namespace :

```
$ oc new-build openshift/amq-broker-72-openshift:1.2~https://github.com/lbroudoux/openshift-cases --name=custom-amq-broker-72-openshift --context-dir=jboss-amq7-custom/custom-amq
```

Wait for the build to complete...

After having deployed a broker using Red Hat provided templates, replace the official image by the custom one that you just built.

```
$ oc set triggers dc/broker-amq --containers=broker-amq --from-image=custom-amq-broker-72-openshift:latest
```

A redeployment should occur. In order to activate the `jmx_exporter_prometheus_agent`, you'll have to tweek the Java startup command line by adding a new environment variable to Deployment configuration:

```
$ oc set env dc/broker-amq JAVA_OPTS="-Dcom.sun.management.jmxremote=true -Djava.rmi.server.hostname=127.0.0.1 -Dcom.sun.management.jmxremote.port=1099 -Dcom.sun.management.jmxremote.ssl=true -Dcom.sun.management.jmxremote.registry.ssl=true -Dcom.sun.management.jmxremote.ssl.need.client.auth=true -Dcom.sun.management.jmxremote.authenticate=false -javaagent:/opt/amq/lib/optional/jmx_prometheus_javaagent-0.11.0.jar=9779:/opt/amq/conf/prometheus-config.yml"
```

All the `com.sun.management` related properties are necessary if you want to have all the Artemis metrics exposed. Otherwise you'll just get the JVM metrics.

Now in order to get this metrics scraped by your Prometheus instance, you may need to add some expositions and/or annotations. This depend on how your Prometheus rules were configured. My personal instance only scrape Services that are annotate that way and is looking for information on port and path. Though, I have to add a port to my container, expose it as a service and then annotate that service so that it can be discovered. Here's the corresponding CLI commands below:

```
$ oc patch dc/broker-amq --type=json -p '[{"op":"add", "path":"/spec/template/spec/containers/0/ports/-", "value": {"containerPort": 9779, "name": "prometheus", "protocol": "TCP"}}]'
$ oc expose dc/broker-amq --name=broker-amq-prometheus --port=9779 --target-port=9779 --protocol="TCP"
$ oc annotate svc/broker-amq-prometheus prometheus.io/scrape='true' prometheus.io/port='9779' prometheus.io/path='/'
```
