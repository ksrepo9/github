-- Additional database setup
CREATE DATABASE IF NOT EXISTS mydb_test;

-- Create additional user
CREATE USER IF NOT EXISTS 'app_user'@'%' IDENTIFIED BY 'app_password';
GRANT ALL PRIVILEGES ON mydb_test.* TO 'app_user'@'%';
FLUSH PRIVILEGES;
