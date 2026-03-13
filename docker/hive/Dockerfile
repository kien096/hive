FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ARG HIVE_VERSION=2.3.8
ARG HIVE_ARCHIVE=apache-hive-${HIVE_VERSION}-bin.tar.gz
ARG HIVE_MIRROR=http://repo.huaweicloud.com/apache/hive/hive-${HIVE_VERSION}
ARG HADOOP_VERSION=2.7.7
ARG HADOOP_ARCHIVE=hadoop-${HADOOP_VERSION}.tar.gz
ARG HADOOP_MIRROR=http://repo.huaweicloud.com/apache/hadoop/common/hadoop-${HADOOP_VERSION}
ARG MYSQL_CONNECTOR_VERSION=8.0.23

RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-8-jre-headless \
    wget \
    curl \
    ca-certificates \
    netcat-openbsd \
    procps \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV HIVE_HOME=/opt/hive
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV PATH=${PATH}:${HIVE_HOME}/bin:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin

WORKDIR /opt

RUN curl -fL --retry 15 --retry-delay 3 -C - \
      -o "${HIVE_ARCHIVE}" "${HIVE_MIRROR}/${HIVE_ARCHIVE}" \
    && tar -xzf "${HIVE_ARCHIVE}" \
    && mv "apache-hive-${HIVE_VERSION}-bin" hive \
    && rm -f "${HIVE_ARCHIVE}"

RUN set -eux; \
    url="${HADOOP_MIRROR}/${HADOOP_ARCHIVE}"; \
    i=1; \
    while [ "$i" -le 20 ]; do \
      if curl -fL -C - --retry 5 --retry-delay 3 \
        -o "${HADOOP_ARCHIVE}" "${url}"; then \
        break; \
      fi; \
      echo "Retry Hadoop download ($i/20)"; \
      i=$((i + 1)); \
      sleep 3; \
    done; \
    test -s "${HADOOP_ARCHIVE}"; \
    tar -xzf "${HADOOP_ARCHIVE}"; \
    mv "hadoop-${HADOOP_VERSION}" hadoop; \
    rm -f "${HADOOP_ARCHIVE}"

RUN wget -q -O "/opt/hive/lib/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar" \
    "https://repo1.maven.org/maven2/mysql/mysql-connector-java/${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar"

COPY entrypoint.sh /opt/entrypoint.sh

RUN chmod +x /opt/entrypoint.sh \
    && mkdir -p /opt/hive/data/warehouse

EXPOSE 9083 10000 10002

ENTRYPOINT ["/opt/entrypoint.sh"]
CMD ["hiveserver2"]
