# To Run application

## Start and SSH into Vagrant VM 

```
vagrant up
vagrant ssh servidorWeb
```

## Run the webApp

```
cd /home/vagrant/webapp
export FLASK_APP=run.py
/usr/local/bin/flask run --host=0.0.0.0
```
