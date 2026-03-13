## 1) Yeu cau truoc khi bat dau

- May Windows
- Co Internet
- Mo PowerShell bang quyen Administrator

## 2) Cai Ubuntu tren WSL

Chay tren PowerShell:

```powershell
wsl --install Ubuntu-20.04
wsl --set-default Ubuntu-20.04
wsl -l -v
```

Neu da co `Ubuntu-20.04` thi bo qua buoc nay.

## 3) Mo Ubuntu va vao root

```powershell
wsl -d Ubuntu-20.04 -u root
```

Tu day tro di, chay trong cua so Ubuntu.

## 4) Cai MySQL

```bash
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
service mysql start
```

Dat mat khau + tao DB/user cho Hive:

```bash
mysql -uroot <<'SQL'
INSTALL COMPONENT 'file://component_validate_password';
SET GLOBAL validate_password.policy = MEDIUM;
SET PERSIST validate_password.mixed_case_count = 0;
SET GLOBAL validate_password.mixed_case_count = 0;
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'admin@123';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'admin@123';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;

CREATE DATABASE IF NOT EXISTS hivedb;
CREATE USER IF NOT EXISTS 'hivedb_user'@'%' IDENTIFIED WITH mysql_native_password BY 'Hive@123';
GRANT ALL PRIVILEGES ON hivedb.* TO 'hivedb_user'@'%';
DELETE FROM mysql.user WHERE User='';
FLUSH PRIVILEGES;
SQL
```

Cho MySQL nghe theo IP hien tai cua WSL:

```bash
WSL_IP=$(hostname -I | awk '{print $1}')
sed -i "s/^bind-address.*/bind-address = $WSL_IP/" /etc/mysql/mysql.conf.d/mysqld.cnf
service mysql restart
echo "WSL IP hien tai: $WSL_IP"
```

## 5) Cai Java + Hadoop + Hive

```bash
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-8-jdk wget curl tar

cd /usr/local
wget -c https://mirrors.huaweicloud.com/apache/hadoop/common/hadoop-3.3.1/hadoop-3.3.1.tar.gz
tar -xzf hadoop-3.3.1.tar.gz
mv hadoop-3.3.1 hadoop

wget -c https://mirrors.huaweicloud.com/apache/hive/hive-2.3.8/apache-hive-2.3.8-bin.tar.gz
tar -xzf apache-hive-2.3.8-bin.tar.gz
mv apache-hive-2.3.8-bin hive
```

## 6) Cai bien moi truong

```bash
cat >> /root/.bashrc <<'EOF'

# HIVE_ENV_START
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/usr/local/hadoop
export HIVE_HOME=/usr/local/hive
export HCAT_HOME=$HIVE_HOME/hcatalog
export PATH="$PATH:$HIVE_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin"
# HIVE_ENV_END
EOF

source /root/.bashrc
```

## 7) Cau hinh Hive

```bash
cp -f /usr/local/hive/conf/hive-env.sh.template /usr/local/hive/conf/hive-env.sh
cat >> /usr/local/hive/conf/hive-env.sh <<'EOF'
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/usr/local/hadoop
export HIVE_CONF_DIR=/usr/local/hive/conf
EOF
```

Tao `hive-site.xml` (tu dong lay IP WSL hien tai):

```bash
WSL_IP=$(hostname -I | awk '{print $1}')
cat > /usr/local/hive/conf/hive-site.xml <<EOF
<?xml version='1.0' encoding='UTF-8'?>
<configuration>
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:mysql://$WSL_IP/hivedb</value>
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
EOF
```

Them MySQL connector + sua guava:

```bash
curl -L --fail -o /usr/local/hive/lib/mysql-connector-java-8.0.23.jar \
  https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.23/mysql-connector-java-8.0.23.jar

rm -f /usr/local/hive/lib/guava-14.0.1.jar
cp /usr/local/hadoop/share/hadoop/hdfs/lib/guava-27.0-jre.jar /usr/local/hive/lib/
```

Tao thu muc warehouse:

```bash
mkdir -p /hive/warehouse
chmod 777 /hive/warehouse
```

## 8) Khoi tao schema va chay Hive

```bash
/usr/local/hive/bin/schematool -initSchema -dbType mysql
/usr/local/hive/bin/hive --version
/usr/local/hive/bin/hive -e "show databases;"
```

Neu thay `Hive 2.3.8` va co database `default` la thanh cong.

## 9) Loi hay gap (fix nhanh)

1. Loi timeout khi download  
   Dung mirror da ghi trong huong dan (`mirrors.huaweicloud.com`) va them `wget -c` de resume.

2. `schematool` fail vi khong ket noi MySQL  
   Chay lai:

```bash
service mysql start
```

3. Sau reboot, Hive ket noi MySQL loi  
   Ly do: IP WSL thay doi. Lam lai 2 lenh:

```bash
WSL_IP=$(hostname -I | awk '{print $1}')
sed -i "s#jdbc:mysql://[^/]*/hivedb#jdbc:mysql://$WSL_IP/hivedb#g" /usr/local/hive/conf/hive-site.xml
```

4. `hive: command not found`  
   Chay truc tiep:

```bash
/usr/local/hive/bin/hive --version
```

## 10) Mat khau hien dang dung trong lab

- MySQL root: `admin@123`
- Hive metastore user: `hivedb_user`
- Hive metastore password: `Hive@123`
