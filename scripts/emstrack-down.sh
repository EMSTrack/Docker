#!/bin/bash

echo "> Stoping services"

echo "> Stop nginx"
service nginx stop

echo "> Stopping mqttclient"
# supervisorctl stop mqttclient
/etc/init.d/mqttclient stop

echo "> Stop mosquitto"
service mosquitto stop

echo "> All services down"
