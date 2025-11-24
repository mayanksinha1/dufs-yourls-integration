#!/bin/sh
set -e

CONFIG_FILE="/var/www/html/user/config.php"
SSL_CONFIG_MARKER="Configure MySQL SSL connection"

# Check if SSL configuration already exists
if ! grep -q "$SSL_CONFIG_MARKER" "$CONFIG_FILE" 2>/dev/null; then
    echo "Adding SSL configuration to config.php..."
    
    # Add SSL configuration to config.php
    cat >> "$CONFIG_FILE" << 'EOF'

// Configure MySQL SSL connection
yourls_add_filter( 'db_connect_driver_option', function( $options ) {
    if (file_exists('/etc/ssl/mysql/ca.pem')) {
        $options[PDO::MYSQL_ATTR_SSL_CA] = '/etc/ssl/mysql/ca.pem';
        $options[PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT] = false;
    }
    return $options;
} );
EOF
    
    echo "SSL configuration added successfully."
else
    echo "SSL configuration already exists in config.php."
fi

# Execute the main command (Apache)
exec "$@"

