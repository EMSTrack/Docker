#!/bin/bash

pid=0

# Cleanup
cleanup() {

    # Go verbose
    set -x
    
    echo "Container stopped, cleaning up..."

    # stop supervisor
    service supervisor stop

    # stop nginx
    service nginx stop

    # stop mosquitto
    service mosquitto stop

    # stop postgres
    service postgresql stop

    echo "Exiting..."

    if [ $pid -ne 0 ]; then
	kill -SIGTERM "$pid"
	wait "$pid"
    fi
    exit 143; # 128 + 15 -- SIGTERM

}

COMMAND=$1

# Initialized?
if [ "$COMMAND" = 'init' ]; then
    rm /tmp/initialized
fi

if /usr/local/bin/docker-entrypoint-init.sh; then
    echo "> Initialization complete"
fi

# Run commands
if [ "$COMMAND" = 'basic' ] || [ "$COMMAND" = 'all' ]; then
    
    echo "> Starting basic services"
    
    # Trap SIGTERM
    trap 'kill ${!}; cleanup' SIGTERM

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

    if [ "$COMMAND" = 'all' ]; then

	echo "> Starting all services"
	
	echo "> Starting mqttseed"
	python manage.py mqttseed

	echo "> Starting mqttclient"
	service supervisor start

	echo "> All services up"

    fi

    pid="$!"
    
    # Wait forever
    while true
    do
	tail -f /dev/null & wait ${!}
    done

    # Call cleanup
    cleanup

elif [ "$COMMAND" = 'test' ]; then

    echo "> Just testing..." 
    
else

    echo "> No services started" 
    echo "> Running '$@'"

    exec "$@"

fi
