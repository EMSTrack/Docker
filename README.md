# Docker

Docker container for WebServerAndClient

## How to build and test the emstrack container

There are two ways to build and test the emstrack container. You can use the `docker` or `docker-compose` (recommended). The latter will take care of mounting volumes, handling options, etc.

### Using docker-compose

Type

    docker-compose build

to build the container. See below for details on the options available. Type

    docker-compose up

to run the container. You can log in a running container using

    docker-compose exec emstrack bash

This will open up a shell session. Once inside the container shell you can, for example, test your application using

    supervisorctl stop mqttclient
    ./manage.py test
    supervisorctl start mqttclient

or

    supervisorctl stop mqttclient
    ./manage.py test -s -v 2
    supervisorctl start mqttclient

if you need more details. If testing fails on your installation please report. Testing the MQTT functions is tricky and might require tunning some wait times in the test files. Don't forget to stop the mqttclient as it might interfere with certain tests.

The file [django/db.json](django/db.json) has a set of fixtures that can be used to populate the database with some test data. **Beware that this data should not be used in a production server**. Use:

    ./manage.py loaddata db.json

to install the fixtures.

### Using docker

Type

    docker build -t emstrack .

to build your container.

Arguments in the file `Dockerfile` can be modified at build time using `--build-arg`. Available arguments are:

1) Application
   - HOME
   - BRANCH

2) Postgres database
   - USERNAME
   - PASSWORD
   - DATABASE

3) Django
   - SECRET_KEY
   - HOSTNAME

4) MQTT client
   - USERNAME
   - MQTT_PASSWORD
   - MQTT_EMAIL
   - MQTT_CLIENTID

5) SSL Certificates
   - CA_CRT
   - SRV_CRT
   - SRV_KEY

For example to build the image from the `devel` branch of the project run:

    docker build --build-arg BRANCH=devel -t emstrack .

Type

    docker run -p 8000:8000 -p 8883:8883 -p 8884:8884 -ti emstrack

to run your container.

## Create self-signed certificates

As per:

https://mcuoneclipse.com/2017/04/14/enable-secure-communication-with-tls-and-the-mosquitto-broker

Make sure to add the certificates to your mqtt client and browser if
you do not want to run into browser and client security issues with the self-signed certificate.

## Other contents

1) directory `django` contains configuration files for django
2) directory `mosquitto` contains configuration files for mosquitto
3) directory `init.d` contains file for configuring the mosquitto service
4) directory `postgresql` contain files for configuring postgresql
5) directory `supervisor` contains files for configuring supervisord
6) directory `certificates` contains the ssl certificates to run your servers
