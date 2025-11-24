# Build stage - download YOURLS from source
FROM alpine:latest AS builder
RUN apk add --no-cache git
WORKDIR /app
# Clone YOURLS repository (using latest stable release)
RUN git clone --depth 1 https://github.com/YOURLS/YOURLS.git . && \
    git fetch --tags && \
    git checkout $(git describe --tags `git rev-list --tags --max-count=1`)
# Runtime stage
FROM artifactory.dev.adskengineer.net/container-hardening/alpine-hardened-min:latest AS amd64
USER root
# Install PHP, Apache, and required PHP extensions
RUN apk update && apk upgrade && \
    apk add --no-cache \
    php84 \
    php84-apache2 \
    php84-mysqli \
    php84-pdo \
    php84-pdo_mysql \
    php84-opcache \
    php84-mbstring \
    php84-xml \
    php84-curl \
    php84-gd \
    php84-zip \
    php84-json \
    php84-intl \
    apache2 \
    curl
# Copy YOURLS files from builder stage
COPY --from=builder /app /var/www/html
# Create user directory and config directory with proper permissions
RUN mkdir -p /var/www/html/user /var/www/html && \
    cp /var/www/html/user/config-sample.php /var/www/html/user/config.php && \
    chown -R ctr-user:ctr-user /var/www/html && \
    chmod -R 755 /var/www/html
# Ensure .htaccess file exists for URL rewriting (YOURLS requires this)
RUN echo '# BEGIN YOURLS' > /var/www/html/.htaccess && \
    echo '<IfModule mod_rewrite.c>' >> /var/www/html/.htaccess && \
    echo 'RewriteEngine On' >> /var/www/html/.htaccess && \
    echo 'RewriteBase /' >> /var/www/html/.htaccess && \
    echo 'RewriteCond %{REQUEST_FILENAME} !-f' >> /var/www/html/.htaccess && \
    echo 'RewriteCond %{REQUEST_FILENAME} !-d' >> /var/www/html/.htaccess && \
    echo 'RewriteRule ^.*$ /yourls-loader.php [L]' >> /var/www/html/.htaccess && \
    echo '</IfModule>' >> /var/www/html/.htaccess && \
    echo '# END YOURLS' >> /var/www/html/.htaccess && \
    chown ctr-user:ctr-user /var/www/html/.htaccess && \
    chmod 644 /var/www/html/.htaccess
# Modify config.php to read from environment variables using getenv()
# PassEnv directive in Apache config will make these available to PHP
RUN sed -i 's|define( '\''YOURLS_DB_USER'\'', '\''your db user name'\'' );|define( '\''YOURLS_DB_USER'\'', getenv('\''YOURLS_DB_USER'\'') ?: '\''your db user name'\'' );|' /var/www/html/user/config.php && \
    sed -i 's|define( '\''YOURLS_DB_PASS'\'', '\''your db password'\'' );|define( '\''YOURLS_DB_PASS'\'', getenv('\''YOURLS_DB_PASS'\'') ?: '\''your db password'\'' );|' /var/www/html/user/config.php && \
    sed -i 's|define( '\''YOURLS_DB_NAME'\'', '\''yourls'\'' );|define( '\''YOURLS_DB_NAME'\'', getenv('\''YOURLS_DB_NAME'\'') ?: '\''yourls'\'' );|' /var/www/html/user/config.php && \
    sed -i 's|define( '\''YOURLS_DB_HOST'\'', '\''localhost'\'' );|define( '\''YOURLS_DB_HOST'\'', getenv('\''YOURLS_DB_HOST'\'') ?: '\''localhost'\'' );|' /var/www/html/user/config.php && \
    sed -i 's|define( '\''YOURLS_SITE'\'', '\''http://your-own-domain-here.com'\'' );|define( '\''YOURLS_SITE'\'', getenv('\''YOURLS_SITE'\'') ?: '\''http://your-own-domain-here.com'\'' );|' /var/www/html/user/config.php && \
    sed -i 's|define( '\''YOURLS_COOKIEKEY'\'', '\''modify this text with something random'\'' );|define( '\''YOURLS_COOKIEKEY'\'', getenv('\''YOURLS_COOKIEKEY'\'') ?: '\''modify this text with something random'\'' );|' /var/www/html/user/config.php
# Handle YOURLS_UNIQUE_URLS boolean - replace with env-aware version using a here-document
RUN sed -i '/define( '\''YOURLS_UNIQUE_URLS'\'', true );/c\
$unique = getenv('\''YOURLS_UNIQUE_URLS'\'');\
define( '\''YOURLS_UNIQUE_URLS'\'', ($unique === '\''false'\'' || $unique === '\''0'\'') ? false : (($unique !== false) ? (bool)$unique : true) );' /var/www/html/user/config.php
# Handle user passwords - add override at end that replaces the entire array
# YOURLS will auto-hash plain text passwords, so we can use getenv() directly
RUN echo '' >> /var/www/html/user/config.php && \
    echo '// Override user passwords from environment variables' >> /var/www/html/user/config.php && \
    echo 'if (getenv("YOURLS_USER") && getenv("YOURLS_PASS")) {' >> /var/www/html/user/config.php && \
    echo '    $yourls_user_passwords = [getenv("YOURLS_USER") => getenv("YOURLS_PASS")];' >> /var/www/html/user/config.php && \
    echo '}' >> /var/www/html/user/config.php
# Create SSL certificate directory
RUN mkdir -p /etc/ssl/mysql && \
    chown -R ctr-user:ctr-user /etc/ssl/mysql && \
    chmod 755 /etc/ssl/mysql
# Patch class-mysql.php to add SSL support directly (since plugins aren't loaded yet)
RUN sed -i '/\$driver_options = yourls_apply_filter( '\''db_connect_driver_option'\'', \[\] );/a\    // Add SSL options for MySQL connection\n    if (file_exists('\''/etc/ssl/mysql/ca.pem'\'')) {\n        $driver_options[PDO::MYSQL_ATTR_SSL_CA] = '\''/etc/ssl/mysql/ca.pem'\'';\n        $driver_options[PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT] = false;\n    }' /var/www/html/includes/class-mysql.php
# Configure Apache to write logs to stdout/stderr, listen on port 8080, set DocumentRoot, and run as ctr-user
RUN sed -i 's|^Listen 80|Listen 8080|' /etc/apache2/httpd.conf && \
    sed -i 's|^#ServerName.*|ServerName localhost:8080|' /etc/apache2/httpd.conf && \
    sed -i 's|^User apache|User ctr-user|' /etc/apache2/httpd.conf && \
    sed -i 's|^Group apache|Group ctr-user|' /etc/apache2/httpd.conf && \
    sed -i 's|DocumentRoot "/var/www/localhost/htdocs"|DocumentRoot "/var/www/html"|' /etc/apache2/httpd.conf && \
    sed -i 's|<Directory "/var/www/localhost/htdocs">|<Directory "/var/www/html">|' /etc/apache2/httpd.conf && \
    sed -i 's|ErrorLog.*|ErrorLog /dev/stderr|' /etc/apache2/httpd.conf && \
    sed -i 's|CustomLog.*|CustomLog /dev/stdout combined|' /etc/apache2/httpd.conf || true && \
    # Enable mod_rewrite for URL rewriting
    sed -i 's|^#LoadModule rewrite_module|LoadModule rewrite_module|' /etc/apache2/httpd.conf && \
    # Fix Options directive inconsistency - remove all Options in Directory block and add a single one with consistent format
    sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ { /^[[:space:]]*Options[[:space:]]/d }' /etc/apache2/httpd.conf && \
    sed -i '/<Directory "\/var\/www\/html">/a\    Options -Indexes +FollowSymLinks' /etc/apache2/httpd.conf && \
    # Enable .htaccess file processing (AllowOverride) for URL rewriting
    sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ { /^[[:space:]]*AllowOverride[[:space:]]/d }' /etc/apache2/httpd.conf && \
    sed -i '/<Directory "\/var\/www\/html">/a\    AllowOverride All' /etc/apache2/httpd.conf && \
    echo "LogLevel info" >> /etc/apache2/httpd.conf && \
    # Configure Apache to pass environment variables to PHP
    echo "PassEnv YOURLS_DB_HOST YOURLS_DB_USER YOURLS_DB_PASS YOURLS_DB_NAME YOURLS_SITE YOURLS_USER YOURLS_PASS YOURLS_UNIQUE_URLS YOURLS_COOKIEKEY" >> /etc/apache2/httpd.conf
# Configure PHP to write errors to stderr
RUN echo "memory_limit = 256M" >> /etc/php84/php.ini && \
    echo "upload_max_filesize = 10M" >> /etc/php84/php.ini && \
    echo "post_max_size = 10M" >> /etc/php84/php.ini && \
    echo "date.timezone = UTC" >> /etc/php84/php.ini && \
    echo "error_log = /dev/stderr" >> /etc/php84/php.ini && \
    echo "log_errors = On" >> /etc/php84/php.ini && \
    echo "display_errors = Off" >> /etc/php84/php.ini && \
    echo "display_startup_errors = Off" >> /etc/php84/php.ini
# Expose port 8080 (non-privileged port)
EXPOSE 8080
# Set working directory
WORKDIR /var/www/html
# Start Apache server (Apache will drop to ctr-user as configured)
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"] 