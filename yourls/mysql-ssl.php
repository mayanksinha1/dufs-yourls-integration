<?php
/**
 * Plugin Name: MySQL SSL Connection
 * Description: Configures MySQL SSL connection for YOURLS
 * Version: 1.0
 */

yourls_add_filter( 'db_connect_driver_option', 'yourls_mysql_ssl_options' );

function yourls_mysql_ssl_options( $options ) {
    if (file_exists('/etc/ssl/mysql/ca.pem')) {
        $options[PDO::MYSQL_ATTR_SSL_CA] = '/etc/ssl/mysql/ca.pem';
        $options[PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT] = false;
    }
    return $options;
}

