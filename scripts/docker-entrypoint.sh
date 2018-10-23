#!/bin/bash

if [ "$1" = 'basic' ] || [ "$1" = 'all' ]; then
    
    echo "> Starting basic services"
    
    echo "> Starting postgres"
    service postgresql start

    echo "> Starting mosquitto"
    service mosquitto start
    sleep 5

    echo "> Starting uWSGI"
    touch /app/reload
    nohup bash -c "uwsgi --touch-reload=/app/reload --socket emstrack.sock --module emstrack.wsgi --uid www-data --gid www-data --chmod-socket=664 >/var/log/uwsgi.log 2>&1 &"

    echo "> Starting nginx"
    service nginx start

    echo "> Basic services up"

    if [ "$1" = 'all' ]; then

	echo "> Starting all services"
	
	echo "> Starting mqttseed"
	python manage.py mqttseed

	echo "> Starting mqttclient"
	service supervisor start

	echo "> All services up"

    fi

    echo "> Inspecting log"
    tail -f /var/log/uwsgi.log

else

    echo "> No services started" 
    echo "> Running '$@'"

    exec "$@"

fi
