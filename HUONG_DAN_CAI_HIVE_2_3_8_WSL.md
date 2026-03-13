# Huong dan cai Apache Hive 2.3.8 tren WSL Ubuntu 20.04

## 1. Thong tin moi truong

- OS: Ubuntu 20.04.6 LTS (WSL2)
- Java: OpenJDK 8
- Hadoop: 3.3.1
- Hive: 2.3.8
- MySQL metastore DB: `hivedb`
- Metastore user: `hivedb_user` / `Hive@123`

## 2. Cai phu thuoc

```bash
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-8-jdk wget curl tar
```

Kiem tra Java:

```bash
java -version
```

## 3. Download va cai Hadoop + Hive

- Hadoop: `https://mirrors.huaweicloud.com/apache/hadoop/common/hadoop-3.3.1/hadoop-3.3.1.tar.gz`
- Hive: `https://mirrors.huaweicloud.com/apache/hive/hive-2.3.8/apache-hive-2.3.8-bin.tar.gz`

Lenh cai:

```bash
cd /usr/local

# Hadoop
wget -c https://mirrors.huaweicloud.com/apache/hadoop/common/hadoop-3.3.1/hadoop-3.3.1.tar.gz
tar -xzf hadoop-3.3.1.tar.gz
mv hadoop-3.3.1 hadoop

# Hive
wget -c https://mirrors.huaweicloud.com/apache/hive/hive-2.3.8/apache-hive-2.3.8-bin.tar.gz
tar -xzf apache-hive-2.3.8-bin.tar.gz
mv apache-hive-2.3.8-bin hive
```

## 4. Thiet lap bien moi truong

Them vao cuoi `~/.bashrc`:

```bash
# HIVE_ENV_START
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/usr/local/hadoop
export HIVE_HOME=/usr/local/hive
export HCAT_HOME=$HIVE_HOME/hcatalog
export PATH="$PATH:$HIVE_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin"
# HIVE_ENV_END
```

Nap lai shell:

```bash
source ~/.bashrc
```

## 5. Cau hinh hive-env.sh

```bash
cd /usr/local/hive
cp conf/hive-env.sh.template conf/hive-env.sh
```

Them vao `conf/hive-env.sh`:

```bash
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/usr/local/hadoop
export HIVE_CONF_DIR=/usr/local/hive/conf
```

## 6. Tao metastore DB/user trong MySQL

Khoi dong MySQL (neu chua chay):

```bash
sudo service mysql start
```

Tao DB + user:

```sql
CREATE DATABASE IF NOT EXISTS hivedb;
CREATE USER IF NOT EXISTS 'hivedb_user'@'%' IDENTIFIED WITH mysql_native_password BY 'Hive@123';
GRANT ALL PRIVILEGES ON hivedb.* TO 'hivedb_user'@'%';
FLUSH PRIVILEGES;
```

Kiem tra:

```bash
mysql -uhivedb_user -p -h <MYSQL_IP_WSL> -e "SHOW DATABASES LIKE 'hivedb';"
```

## 7. Cau hinh hive-site.xml

Tao file `/usr/local/hive/conf/hive-site.xml`:

```xml
<?xml version='1.0' encoding='UTF-8'?>
<configuration>
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:mysql://172.24.50.250/hivedb</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>com.mysql.jdbc.Driver</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>hivedb_user</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>Hive@123</value>
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
    <name>hive.metastore.warehouse.dir</name>
    <value>/hive/warehouse</value>
  </property>
</configuration>
```

Tao thu muc warehouse local:

```bash
sudo mkdir -p /hive/warehouse
sudo chmod 777 /hive/warehouse
```

## 8. Them MySQL connector

Tai connector 8.0.23 va copy vao lib cua Hive:

```bash
curl -L --fail -o /usr/local/hive/lib/mysql-connector-java-8.0.23.jar \
  https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.23/mysql-connector-java-8.0.23.jar
```

## 9. Cap nhat guava theo slide

```bash
rm -f /usr/local/hive/lib/guava-14.0.1.jar
cp /usr/local/hadoop/share/hadoop/hdfs/lib/guava-27.0-jre.jar /usr/local/hive/lib/
```

## 10. Khoi tao schema va test Hive

Khoi tao metastore schema:

```bash
/usr/local/hive/bin/schematool -initSchema -dbType mysql
```

Ky vong thanh cong:

- `Initialization script completed`
- `schemaTool completed`

Test Hive:

```bash
hive --version
hive -e "show databases;"
```

Ky vong co output:

- `Hive 2.3.8`
- database `default`

## 11. Luu y quan trong

1. `ConnectionURL` dang de `172.24.50.250` (IP WSL tai thoi diem cai). Neu reboot Windows, IP WSL co the doi -> cap nhat lai trong `hive-site.xml`.
2. Warning `com.mysql.jdbc.Driver is deprecated` khong gay fail, van chay duoc.
3. Warning `SLF4J: Class path contains multiple bindings` la warning pho bien voi bo thu vien Hive/Hadoop, khong chan viec khoi dong Hive.
4. Neu MySQL chua chay thi `schematool` se fail, can `sudo service mysql start` truoc.
