# Testing SSL Requirements

## Important Note
MySQL 8.0 client **automatically negotiates SSL** when the server supports it. This means connections without explicit `--ssl-mode` will still use SSL automatically.

## Failure Test - Explicit SSL Disabled

To demonstrate that SSL is required, you must **explicitly disable SSL**:

```bash
docker exec mysql-ssl-container mysql -uroot -prootpassword --ssl-mode=DISABLED -h 127.0.0.1 -P 3306 -e "SELECT 1;"
```

**Expected Result:**
```
ERROR 3159 (HY000): Connections using insecure transport are prohibited while --require_secure_transport=ON.
```

## Success Test - With SSL (Automatic)

```bash
docker exec mysql-ssl-container mysql -uroot -prootpassword -h 127.0.0.1 -P 3306 -e "SELECT 1;"
```

**Result:** Works (SSL is automatically negotiated)

**To verify SSL is being used:**
```bash
docker exec mysql-ssl-container mysql -uroot -prootpassword -h 127.0.0.1 -P 3306 -e "SHOW STATUS LIKE 'Ssl_cipher';"
```

**Output:** `TLS_AES_256_GCM_SHA384` (confirms SSL is active)

## Success Test - With Explicit SSL Mode

```bash
docker exec mysql-ssl-container mysql -uroot -prootpassword --ssl-mode=REQUIRED --ssl-ca=/etc/mysql/ssl/ssl_ca.pem -h 127.0.0.1 -P 3306 -e "SELECT 'SUCCESS' AS Status;"
```

**Result:** Works with explicit SSL mode and CA certificate

## Testing from External Client (MySQL 5.7)

To test with a client that doesn't auto-negotiate SSL:

```bash
docker run --rm --network container:mysql-ssl-container mysql:5.7 mysql -uroot -prootpassword -h 127.0.0.1 -P 3306 --ssl=0 -e "SELECT 1;"
```

**Expected Result:**
```
ERROR 3159 (HY000): Connections using insecure transport are prohibited while --require_secure_transport=ON.
```

## Summary

- **Without `--ssl-mode`**: Works (MySQL 8.0 auto-negotiates SSL)
- **With `--ssl-mode=DISABLED`**: **FAILS** (SSL is explicitly disabled)
- **With `--ssl-mode=REQUIRED`**: Works (SSL explicitly enabled)

The server correctly enforces SSL. The connection fails when SSL is explicitly disabled, proving that `require_secure_transport=ON` is working.

