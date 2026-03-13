#!/usr/bin/env bash
set -euo pipefail

role="${1:-hiveserver2}"

: "${MYSQL_HOST:=mysql}"
: "${MYSQL_PORT:=3306}"
: "${MYSQL_DB:=hivedb}"
: "${MYSQL_USER:=hivedb_user}"
: "${MYSQL_PASSWORD:=Hive@123}"
: "${HIVE_METASTORE_URIS:=thrift://hive-metastore:9083}"
: "${HIVE_METASTORE_HOST:=hive-metastore}"
: "${HIVE_METASTORE_PORT:=9083}"
: "${HIVE_SERVER2_PORT:=10000}"
: "${HIVE_SERVER2_WEBUI_PORT:=10002}"
: "${HIVE_WAREHOUSE_DIR:=/opt/hive/data/warehouse}"

wait_for_port() {
  local host="$1"
  local port="$2"
  local max_try=90
  local i=1
  until nc -z "$host" "$port" >/dev/null 2>&1; do
    if [ "$i" -ge "$max_try" ]; then
      echo "Timeout waiting for $host:$port"
      return 1
    fi
    echo "Waiting for $host:$port ($i/$max_try)..."
    i=$((i + 1))
    sleep 2
  done
}

write_hive_site() {
  cat > "${HIVE_HOME}/conf/hive-site.xml" <<EOF
<?xml version='1.0' encoding='UTF-8'?>
<configuration>
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DB}?createDatabaseIfNotExist=true</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>com.mysql.jdbc.Driver</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>${MYSQL_USER}</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>${MYSQL_PASSWORD}</value>
  </property>
  <property>
    <name>datanucleus.autoCreateSchema</name>
    <value>false</value>
  </property>
  <property>
    <name>datanucleus.fixedDatastore</name>
    <value>true</value>
  </property>
  <property>
    <name>datanucleus.autoStartMechanism</name>
    <value>SchemaTable</value>
  </property>
  <property>
    <name>hive.metastore.uris</name>
    <value>${HIVE_METASTORE_URIS}</value>
  </property>
  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>${HIVE_WAREHOUSE_DIR}</value>
  </property>
</configuration>
EOF
}

init_schema_if_needed() {
  if "${HIVE_HOME}/bin/schematool" -dbType mysql -info >/tmp/schematool-info.log 2>&1; then
    echo "Hive schema already exists."
    return 0
  fi

  echo "Initializing Hive schema..."
  "${HIVE_HOME}/bin/schematool" -initSchema -dbType mysql
}

run_metastore_daemon() {
  "${HIVE_HOME}/bin/hive" --service metastore

  local pid=""
  local i=1
  while [ "$i" -le 30 ]; do
    pid="$(pgrep -f 'org.apache.hadoop.hive.metastore.HiveMetaStore' || true)"
    if [ -n "$pid" ]; then
      echo "Hive metastore is running with PID ${pid}"
      tail --pid="$pid" -f /dev/null
      return 0
    fi
    i=$((i + 1))
    sleep 1
  done

  echo "Hive metastore process did not start."
  return 1
}

mkdir -p "${HIVE_WAREHOUSE_DIR}"
chmod 777 "${HIVE_WAREHOUSE_DIR}"
write_hive_site

case "$role" in
  metastore)
    wait_for_port "${MYSQL_HOST}" "${MYSQL_PORT}"
    init_schema_if_needed
    run_metastore_daemon
    ;;
  hiveserver2)
    wait_for_port "${HIVE_METASTORE_HOST}" "${HIVE_METASTORE_PORT}"
    exec "${HIVE_HOME}/bin/hiveserver2" \
      --hiveconf hive.server2.thrift.port="${HIVE_SERVER2_PORT}" \
      --hiveconf hive.server2.webui.port="${HIVE_SERVER2_WEBUI_PORT}" \
      --hiveconf hive.server2.thrift.bind.host=0.0.0.0
    ;;
  *)
    exec "$@"
    ;;
esac
