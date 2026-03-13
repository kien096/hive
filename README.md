# Hive 2.3.8 + MySQL bang Docker

- MySQL 8 (metadata DB cho Hive)
- Hive Metastore
- HiveServer2

## 1) Chay nhanh

```bash
cp .env.example .env
docker compose up -d --build
docker compose ps
```

## 2) Kiem tra da len dung

```bash
docker compose exec -T hive-server2 /opt/hive/bin/hive --version
docker compose exec -T hive-server2 /opt/hive/bin/hive -e "show databases;"
```

Neu thay:

- `Hive 2.3.8`
- database `default`
  la thanh cong.

## 3) Port mac dinh

- MySQL: `3306`
- Hive Metastore Thrift: `9083`
- HiveServer2 Thrift: `10000`
- HiveServer2 Web UI: `10002`

Co the doi trong file `.env`.

## 4) Tai khoan mac dinh (lab)

- MySQL root: `admin@123`
- Hive DB: `hivedb`
- Hive user: `hivedb_user`
- Hive password: `Hive@123`

## 5) Lenh thuong dung

Xem log:

```bash
docker compose logs -f hive-metastore hive-server2
```

Tat he thong:

```bash
docker compose down
```

Tat va xoa toan bo data volume:

```bash
docker compose down -v
```
