FROM openshift/jboss-amq-63:1.3

# Temporary switch to root
USER root

# Prometheus JMX exporter agent
RUN mkdir -p /opt/prometheus/etc \
    && curl http://central.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.10/jmx_prometheus_javaagent-0.10.jar \
        -o /opt/prometheus/jmx_prometheus_javaagent.jar
ADD prometheus-config.yml /opt/prometheus/prometheus-config.yml
RUN chmod 444 /opt/prometheus/jmx_prometheus_javaagent.jar \
    && chmod 444 /opt/prometheus/prometheus-config.yml \
    && chmod 775 /opt/prometheus/etc \
    && chgrp root /opt/prometheus/etc

EXPOSE 9779

# S2I customization and annotation
COPY ./s2i/ /opt/amq-custom/s2i
COPY launch.sh /opt/amq-custom
RUN chmod -R 777 /opt/amq-custom

LABEL io.openshift.s2i.scripts-url="image:///opt/amq-custom/s2i"

# Override default launch.
CMD [ "/opt/amq-custom/launch.sh" ]

# S2I requires a numeric, non-0 UID. This is the UID for the jboss user in the base image
USER 185