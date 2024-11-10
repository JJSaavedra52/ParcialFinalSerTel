#!/bin/bash

# Install MySQL
echo "Installing MySQL"

debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'

sudo apt update
sudo apt install mysql-server -y
sudo systemctl start mysql.service

#Create and fill Database
echo "Creating and filling database"
sudo mysql -h localhost -u root -proot < /home/vagrant/init.sql

#Adding permissions to remote access
echo "Adding permissions to remote access"
sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql.service

# Instal Python Flask and Flask-MySQLdb
sudo apt install python3-dev default-libmysqlclient-dev build-essential pkg-config mysql-client python3-pip -y
pip3 install Flask==2.3.3
pip3 install flask-cors
pip3 install Flask-MySQLdb
pip install Flask-SQLAlchemy

# Install Apache2 to deploy
echo "Installing Apache"
sudo apt install apache2 libapache2-mod-wsgi-py3 -y

# Install Docker
echo "Installing Docker"
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install Docker Compose
echo "Installing Docker Compose"
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

# Generate SSL keys
echo "Generating SSL keys"
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /home/vagrant/webapp/localhost.key -out /home/vagrant/webapp/localhost.crt -subj "/C=US/ST=YourState/L=YourCity/O=YourOrganization/CN=localhost"

# Copy SSL certificate and key to the appropriate locations
echo "Copying SSL certificate and key"
sudo cp /home/vagrant/webapp/localhost.crt /etc/ssl/certs/localhost.crt
sudo cp /home/vagrant/webapp/localhost.key /etc/ssl/private/localhost.key

# Enable mod_wsgi module
echo "Enabling mod_wsgi module"
sudo a2enmod wsgi

# Copy the custom Apache virtual host config
echo "Copying custom Apache virtual host config"
sudo cp /home/vagrant/webapp/my-httpd-vhosts.conf /etc/apache2/sites-available/my-ssl.conf

# Enable SSL module, configure Apache for PHP support, and enable our SSL site configuration
echo "Configuring Apache"
sudo a2enmod ssl
sudo a2enmod rewrite
sudo a2dissite 000-default default-ssl
sudo a2ensite my-ssl

# Restart Apache to apply changes
# echo "Restarting Apache"
# sudo systemctl restart apache2

# Copy webapp directory to /var/www
echo "Copying webapp to /var/www"
sudo cp -r /home/vagrant/webapp /var/www/webapp

# Create application.wsgi file
echo "Creating application.wsgi"
sudo bash -c 'cat > /var/www/webapp/application.wsgi <<EOF
#!/usr/bin/python
import sys
sys.path.insert(0,"/var/www/webapp/")
from run import app as application
EOF'

# Configure Apache
echo "Configuring Apache"
sudo bash -c 'cat > /etc/apache2/sites-available/000-default.conf <<EOF
WSGIScriptAlias / /var/www/webapp/application.wsgi
DocumentRoot /var/www/webapp
<VirtualHost *>
    <Directory /var/www/webapp/>
        Order deny,allow
        Allow from all
    </Directory>
</VirtualHost>
EOF'

# Install Prometheus
echo "Installing Prometheus"
sudo apt update
sudo groupadd --system prometheus
sudo useradd -s /sbin/nologin --system -g prometheus prometheus

sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus

cd /home/vagrant
wget https://github.com/prometheus/prometheus/releases/download/v2.43.0/prometheus-2.43.0.linux-amd64.tar.gz

tar vxf prometheus*.tar.gz

cd prometheus-2.43.0.linux-amd64

sudo mv prometheus /usr/local/bin
sudo mv promtool /usr/local/bin
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool

sudo mv consoles /etc/prometheus
sudo mv console_libraries /etc/prometheus
sudo mv prometheus.yml /etc/prometheus

sudo chown prometheus:prometheus /etc/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
sudo chown -R prometheus:prometheus /var/lib/prometheus

# Create Prometheus service file
echo "Creating Prometheus service file"
sudo bash -c 'cat <<EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF'

# Reload systemd and start Prometheus service
echo "Reloading systemd and starting Prometheus service"
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus
sudo ufw allow 9090/tcp
sudo systemctl status prometheus

# Enable the site and restart Apache
echo "Enabling site and restarting Apache"
sudo a2ensite 000-default.conf
sudo systemctl restart apache2

# Check Apache configuration syntax
echo "Checking Apache configuration syntax"
sudo apachectl -t

#Run application
#cd /home/vagrant/webapp
#export FLASK_APP=run.py
#/usr/local/bin/flask run --host=0.0.0.0
