FROM mysql:8.0

# Create SSL directory
RUN mkdir -p /etc/mysql/ssl && \
    chown -R mysql:mysql /etc/mysql/ssl

# Copy SSL certificates (REQUIRED for SSL connections)
# ssl_ca.pem - Certificate Authority certificate (required for SSL)
COPY certs/ca.pem /etc/mysql/ssl/ssl_ca.pem
COPY certs/server-cert.pem /etc/mysql/ssl/server-cert.pem
COPY certs/server-key.pem /etc/mysql/ssl/server-key.pem

# Set correct permissions for SSL certificates
RUN chmod 644 /etc/mysql/ssl/ssl_ca.pem && \
    chmod 644 /etc/mysql/ssl/server-cert.pem && \
    chmod 600 /etc/mysql/ssl/server-key.pem && \
    chown mysql:mysql /etc/mysql/ssl/*

# Copy SSL configuration that enforces SSL for all connections
# This requires SSL and uses the ssl_ca.pem file
COPY ssl-required.cnf /etc/mysql/conf.d/ssl-required.cnf

# Set user to mysql for security
USER mysql

# Expose MySQL port
EXPOSE 3306

# Run MySQL with SSL enforcement
CMD ["mysqld"]
