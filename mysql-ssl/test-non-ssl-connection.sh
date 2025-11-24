#!/bin/bash
# Test script to demonstrate connection failure without explicit SSL mode

echo "=== Testing connection WITHOUT --ssl-mode (should fail) ==="
echo ""

# Test 1: Try connection with SSL explicitly disabled
echo "Test 1: Connection with --ssl-mode=DISABLED"
docker exec mysql-ssl-container mysql -uroot -prootpassword --ssl-mode=DISABLED -h 127.0.0.1 -P 3306 -e "SELECT 1;" 2>&1
echo ""

# Test 2: Try connection without any SSL options (MySQL 8.0 auto-negotiates SSL)
echo "Test 2: Connection without --ssl-mode (MySQL 8.0 auto-negotiates SSL)"
docker exec mysql-ssl-container mysql -uroot -prootpassword -h 127.0.0.1 -P 3306 -e "SHOW STATUS LIKE 'Ssl_cipher';" 2>&1
echo "Note: This works because MySQL 8.0 client automatically uses SSL"
echo ""

# Test 3: Connection with explicit SSL required
echo "Test 3: Connection with --ssl-mode=REQUIRED (should succeed)"
docker exec mysql-ssl-container mysql -uroot -prootpassword --ssl-mode=REQUIRED --ssl-ca=/etc/mysql/ssl/ssl_ca.pem -h 127.0.0.1 -P 3306 -e "SELECT 'SUCCESS' AS Status;" 2>&1

