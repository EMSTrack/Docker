# Docker

Docker container for WebServerAndClient

## Build container

    docker build -t cruzroja .

Arguments can be modified at build time using `--build-arg`. Available
arguments are:

1) Postgres database
   - USERNAME
   - PASSWORD
   - DATABASE

2) Django
   - SECRET_KEY
   - HOSTNAME

3) MQTT client

   - USERNAME
   - MQTT_PASSWORD
   - MQTT_EMAIL
   - MQTT_CLIENTID

## Run container

    docker run -p 8000:8000 -p 8883:8883 -p 8884:8884 -ti cruzroja

## Create self-signed certificates

### as per https://stackoverflow.com/questions/10175812/how-to-create-a-self-signed-certificate-with-openssl:

    cd certificates
    openssl req -config example-com.conf -new -x509 -sha256 -newkey rsa:2048 -nodes -keyout example-com.key.pem -days 365 -out example-com.cert.pem

## Other contents

1) directory `django` contains configuration files for django
2) directory `mosquitto` contains configuration files for mosquitto
3) directory `init.d` contains file for configuring the mosquitto service
4) directory `postgresql` contain files for configuring postgresql

