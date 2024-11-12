# To Run application

## Start and SSH into Vagrant VM 

```
vagrant up
vagrant ssh servidorWeb
```

## The webapp is already deployed in Apache once it's started
# So simply go to https://192.168.60.3/ to see the app

## Run the webApp (Local)

```
cd /home/vagrant/webapp
export FLASK_APP=run.py
/usr/local/bin/flask run --host=0.0.0.0
```

## For Docker deployment

# Add a docker-compose.yml on /home/vagrant/ with this content:

version: '3.8'

services:
  webapp:
    build: ./webapp
    links:
      - db
    ports:
      - "80:80"
      - "443:443"
    restart: always
    # environment:
    #   - FLASK_APP=/var/www/webapp/run.py
    #   - FLASK_ENV=production
    #   - MYSQL_HOST=db
    #   - MYSQL_PORT=3306
    #   - MYSQL_USER=root
    #   - MYSQL_PASSWORD=root
    #   - MYSQL_DB=myflaskapp
    # volumes:
    #   - ./webapp:/var/www/webapp

  db:
    image: mysql:5.7
    ports:
      - "32000:3306"
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: root
      # MYSQL_DATABASE: myflaskapp
    volumes:
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro

# Then use:

```
sudo docker-compose up --build -d
```