FROM ubuntu/apache2

WORKDIR /webapp

# Copy application files
COPY . .

# Install Vim (optional)
RUN apt-get update && \
    apt-get install -y vim && \
    rm -rf /var/lib/apt/lists/*

# Install necessary packages
RUN echo "Installing necessary packages" && \
    apt update && \
    apt install -y openssl python3-dev default-libmysqlclient-dev build-essential pkg-config mysql-client python3-pip && \
    pip3 install Flask==2.3.3 flask-cors Flask-MySQLdb Flask-SQLAlchemy --break-system-packages

# Copy SSL certificate and key
RUN echo "Copying SSL certificate and key" && \
    cp localhost.crt /etc/ssl/certs/localhost.crt && \
    cp localhost.key /etc/ssl/private/localhost.key

# Copy Apache configuration files
COPY ./my-httpd-vhosts.conf /etc/apache2/sites-available/my-ssl.conf

# Modify 000-default.conf to use WSGI and SSL
RUN echo "Modifying 000-default.conf" && \
    echo "WSGIScriptAlias / /var/www/webapp/application.wsgi\n\
DocumentRoot /var/www/webapp\n\
<VirtualHost *:80>\n\
    <Directory /var/www/webapp/>\n\
        Order deny,allow\n\
        Allow from all\n\
    </Directory>\n\
</VirtualHost>" > /etc/apache2/sites-available/000-default.conf

# Install and configure Apache modules
RUN echo "Configuring Apache" && \
    apt install -y libapache2-mod-wsgi-py3 && \
    a2enmod ssl && \
    a2enmod wsgi && \
    a2enmod rewrite && \
    a2dissite 000-default default-ssl && \
    a2ensite my-ssl

# Copy application files to /var/www/webapp
RUN echo "Copying application files to /var/www/webapp" && \
    cp -r . /var/www/webapp

# Set permissions and ownership
RUN echo "Setting permissions and ownership" && \
    chown -R www-data:www-data /var/www/webapp && \
    chmod -R 755 /var/www/webapp && \
    chmod 644 /etc/ssl/certs/localhost.crt && \
    chmod 600 /etc/ssl/private/localhost.key

# Expose ports
EXPOSE 80 443

# Start Apache in the foreground
CMD ["apachectl", "-D", "FOREGROUND"]