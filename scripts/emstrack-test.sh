#!/bin/bash

echo "> Starting test..."

# stop mqttclient
#supervisorctl stop mqttclient
/etc/init.d/mqttclient stop

# run tests
python manage.py test $*

# start mqttclient
#supervisorctl start mqttclient
/etc/init.d/mqttclient start
