# Huong dan chi tiet cai moi truong MySQL de thuc hanh Hive (WSL Ubuntu 20.04)

## 1. Muc tieu

- Cai Ubuntu 20.04 tren WSL2.
- Cai MySQL Server tren Ubuntu.
- Hardening MySQL (tuong duong `mysql_secure_installation`).
- Bat truy cap tu xa vao MySQL.
- Tao database `metastore` va user `hive` cho Hive.

## 2. Dieu kien tien quyet

- Windows da bat WSL2.
- Mo PowerShell voi quyen Administrator.
- Co ket noi Internet de tai package.

Kiem tra nhanh:

```powershell
wsl --status
wsl -l -v
```

## 3. Cai Ubuntu 20.04 tren WSL

Xem distro co san:

```powershell
wsl --list --online
```

Cai Ubuntu 20.04:

```powershell
wsl --install Ubuntu-20.04
```

Dat Ubuntu 20.04 lam mac dinh:

```powershell
wsl --set-default Ubuntu-20.04
```

Kiem tra lai:

```powershell
wsl -l -v
wsl -d Ubuntu-20.04 -u root -- lsb_release -a
```

## 4. Cai MySQL Server trong Ubuntu 20.04

Cap nhat package index:

```powershell
wsl -d Ubuntu-20.04 -u root -- bash -lc "apt-get update"
```

Cai MySQL:

```powershell
wsl -d Ubuntu-20.04 -u root -- bash -lc "DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server"
```

Khoi dong va kiem tra:

```powershell
wsl -d Ubuntu-20.04 -u root -- service mysql start
wsl -d Ubuntu-20.04 -u root -- bash -lc "service mysql status | head -n 15"
```

## 5. Hardening MySQL (tuong duong mysql_secure_installation)

### Cach A (tuong tac nhu slide)

Chay:

```powershell
wsl -d Ubuntu-20.04 -u root -- mysql_secure_installation
```

Goi y tra loi theo slide:

- Setup VALIDATE PASSWORD component: `y`
- Password policy level: `1` (MEDIUM)
- Dat root password: `admin@123`
- Remove anonymous users: `y`
- Disallow root login remotely: `n` (theo slide)
- Remove test database: `n` (theo slide)
- Reload privilege tables: `y`

### Cach B (chay nhanh bang SQL)

Neu ban muon tu dong hoa, dung cac lenh sau:

```powershell
wsl -d Ubuntu-20.04 -u root -- mysql -uroot -e "INSTALL COMPONENT 'file://component_validate_password';"
wsl -d Ubuntu-20.04 -u root -- mysql -uroot -e "SET GLOBAL validate_password.policy = MEDIUM; SET PERSIST validate_password.mixed_case_count = 0; SET GLOBAL validate_password.mixed_case_count = 0;"
wsl -d Ubuntu-20.04 -u root -- mysql -uroot -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'admin@123'; DELETE FROM mysql.user WHERE User=''; FLUSH PRIVILEGES;"
```

Kiem tra dang nhap bang password moi:

```powershell
wsl -d Ubuntu-20.04 -u root -- mysql -uroot -padmin@123 -Nse "SELECT VERSION();"
```

## 6. Cau hinh MySQL cho phep truy cap tu xa

Lay IP hien tai cua Ubuntu WSL:

```powershell
wsl -d Ubuntu-20.04 -u root -- hostname -I
```

Vi du IP la `172.24.50.250`, sua `bind-address`:

```powershell
wsl -d Ubuntu-20.04 -u root -- sed -i "s/^bind-address.*/bind-address = 172.24.50.250/" /etc/mysql/mysql.conf.d/mysqld.cnf
```

Restart MySQL:

```powershell
wsl -d Ubuntu-20.04 -u root -- service mysql restart
```

Tao/quyen root remote (neu can):

```powershell
wsl -d Ubuntu-20.04 -u root -- mysql -uroot -padmin@123 -e "CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'admin@123'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"
```

Kiem tra MySQL dang listen cong 3306:

```powershell
wsl -d Ubuntu-20.04 -u root -- bash -lc "ss -ltnp | grep 3306"
```

Test tu Windows vao WSL:

```powershell
Test-NetConnection -ComputerName 172.24.50.250 -Port 3306
```

## 7. Tao DB metastore cho Hive

Tao database + user `hive`:

```powershell
wsl -d Ubuntu-20.04 -u root -- mysql -uroot -padmin@123 -e "CREATE DATABASE IF NOT EXISTS metastore CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; CREATE USER IF NOT EXISTS 'hive'@'%' IDENTIFIED WITH mysql_native_password BY 'H1ve@123'; GRANT ALL PRIVILEGES ON metastore.* TO 'hive'@'%'; FLUSH PRIVILEGES;"
```

Kiem tra:

```powershell
wsl -d Ubuntu-20.04 -u root -- mysql -uroot -padmin@123 -Nse "SHOW DATABASES LIKE 'metastore'; SHOW GRANTS FOR 'hive'@'%';"
```

## 8. Cac lenh kiem tra tong hop

```powershell
wsl -d Ubuntu-20.04 -u root -- service mysql status
wsl -d Ubuntu-20.04 -u root -- mysql -uroot -padmin@123 -e "SHOW DATABASES;"
wsl -d Ubuntu-20.04 -u root -- mysql -uroot -padmin@123 -Nse "SHOW VARIABLES LIKE 'bind_address';"
```

## 9. Loi thuong gap va cach xu ly

### 9.1 Cai WSL rat lau

Nguyen nhan:

- Dang tai image Ubuntu va setup lan dau (rat ton thoi gian).
- Mang cham hoac gioi han bang thong.

Xu ly:

- Cho lenh chay them.
- Neu dung giua chung, chay lai `wsl -l -v` de kiem tra distro da co chua.

### 9.2 Khong ket noi duoc MySQL local

Kiem tra service:

```powershell
wsl -d Ubuntu-20.04 -u root -- service mysql start
```

### 9.3 Password bi bao khong dat policy

Ban co 2 huong:

- Dat password manh hon.
- Hoac giam 1 vai rule validate nhu da lam o muc 5 Cach B (`validate_password.mixed_case_count = 0`).

### 9.4 IP WSL thay doi sau reboot

WSL thuong cap IP dong. Khi IP doi:

- Chay lai `hostname -I`.
- Sua lai `bind-address`.
- `service mysql restart`.

## 10. Khuyen nghi bao mat

- Khong nen dung `root` cho ung dung thuc te.
- Dung user rieng (`hive`) voi quyen toi thieu can thiet.
- Doi password mac dinh ngay sau khi test xong.

---

Neu ban can, co the tao tiep 1 file `.md` thu 2 cho phan ket noi Hive -> MySQL metastore (jdbc driver, `hive-site.xml`, schema tool, verify bang `beeline`).
