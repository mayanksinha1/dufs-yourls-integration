# MySQL SSL Connection Test Commands

## SUCCESS - Connection WITH SSL Certificate

### 1. Connection with CA Certificate Verification (VERIFY_CA)
```bash
docker exec mysql-ssl-container mysql -uroot -prootpassword --ssl-mode=VERIFY_CA --ssl-ca=/etc/mysql/ssl/ssl_ca.pem -h 127.0.0.1 -P 3306 -e "SELECT 'SUCCESS: Connected with SSL certificate!' AS Status; SHOW STATUS LIKE 'Ssl_cipher';"
```

### 2. Connection with SSL Required (REQUIRED mode)
```bash
docker exec mysql-ssl-container mysql -uroot -prootpassword --ssl-mode=REQUIRED --ssl-ca=/etc/mysql/ssl/ssl_ca.pem -h 127.0.0.1 -P 3306 -e "SELECT 'SUCCESS: SSL connection established!' AS Status; SHOW STATUS LIKE 'Ssl_cipher';"
```

### 3. Check SSL Status
```bash
docker exec mysql-ssl-container mysql -uroot -prootpassword --ssl-mode=REQUIRED --ssl-ca=/etc/mysql/ssl/ssl_ca.pem -h 127.0.0.1 -P 3306 -e "SHOW STATUS LIKE 'Ssl%';"
```

### 4. Verify SSL is Required
```bash
docker exec mysql-ssl-container mysql -uroot -prootpassword --ssl-mode=REQUIRED --ssl-ca=/etc/mysql/ssl/ssl_ca.pem -h 127.0.0.1 -P 3306 -e "SHOW VARIABLES LIKE 'require_secure_transport';"
```

---

## FAILURE - Connection WITHOUT SSL Certificate

### 1. Connection with SSL Explicitly Disabled
```bash
docker exec mysql-ssl-container mysql -uroot -prootpassword --ssl-mode=DISABLED -h 127.0.0.1 -P 3306 -e "SELECT 1;"
```
**Expected Error:** `ERROR 3159 (HY000): Connections using insecure transport are prohibited while --require_secure_transport=ON.`

### 2. Connection without SSL options (Note: This actually uses SSL automatically)
```bash
docker exec mysql-ssl-container mysql -uroot -prootpassword -h 127.0.0.1 -P 3306 -e "SELECT 1;"
```
**Note:** This command works because MySQL 8.0 client automatically enables SSL by default when the server supports it. To verify SSL is being used, check:
```bash
docker exec mysql-ssl-container mysql -uroot -prootpassword -h 127.0.0.1 -P 3306 -e "SHOW STATUS LIKE 'Ssl_cipher';"
```
**Result:** Shows `TLS_AES_256_GCM_SHA384` - confirming SSL is active even without explicit `--ssl-mode` flag.

---

## Container Management Commands

### Build the Docker Image
```bash
docker build -t mysql:mysql .
```

### Create and Run Container
```bash
docker run -d --name mysql-ssl-container -e MYSQL_ROOT_PASSWORD=rootpassword -e MYSQL_DATABASE=mydb -p 3306:3306 -v "${PWD}/certs/ca.pem:/etc/mysql/ssl/ssl_ca.pem:ro" -v "${PWD}/certs/server-cert.pem:/etc/mysql/ssl/server-cert.pem:ro" -v "${PWD}/certs/server-key.pem:/etc/mysql/ssl/server-key.pem:ro" mysql:mysql
```

### Check Container Status
```bash
docker ps -a --filter name=mysql-ssl-container
```

### View Container Logs
```bash
docker logs mysql-ssl-container --tail 50
```

### Stop Container
```bash
docker stop mysql-ssl-container
```

### Remove Container
```bash
docker rm mysql-ssl-container
```

---

## SSL Configuration Verification

### Check SSL Variables
```bash
docker exec mysql-ssl-container mysql -uroot -prootpassword -e "SHOW VARIABLES LIKE '%ssl%';"
```

### Check SSL Status
```bash
docker exec mysql-ssl-container mysql -uroot -prootpassword -e "SHOW STATUS LIKE 'Ssl%';"
```

### Check if SSL is Required
```bash
docker exec mysql-ssl-container mysql -uroot -prootpassword -e "SHOW VARIABLES LIKE 'require_secure_transport';"
```

