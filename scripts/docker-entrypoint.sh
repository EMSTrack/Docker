#!/bin/bash

pid=0

# Cleanup
cleanup() {

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
    rm /etc/emstrack/emstrack.initialized
fi

if /usr/local/bin/docker-entrypoint-init.sh; then
    echo "> Initialization complete"
fi

# Run commands
if [ "$COMMAND" = 'basic' ] || [ "$COMMAND" = 'all' ] || [ "$COMMAND" = 'test' ]; then
    
    echo "> Starting basic services"
    
    # Trap SIGTERM
    trap 'kill ${!}; cleanup' SIGTERM

    echo "> Waiting for postgres"
    timer="5"
    until pg_isready -U postgres -h db --quiet; do
	>&2 echo "Postgres is unavailable - sleeping for $timer seconds"
	sleep $timer
    done

    echo "> Starting mosquitto"
    service mosquitto start
    sleep $timer

    echo "> Starting uWSGI"
    touch /app/reload
    nohup bash -c "uwsgi --touch-reload=/app/reload --socket emstrack.sock --module emstrack.wsgi --uid www-data --gid www-data --chmod-socket=664 >/var/log/uwsgi.log 2>&1 &"

    echo "> Starting nginx"
    service nginx start

    echo "> Basic services up"

    if [ "$COMMAND" = 'all' ]; then

	echo "> Starting all services"
	
	# echo "> Starting mqttseed"
	# python manage.py mqttseed

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

else

    echo "> No services started" 
    echo "> Running '$@'"

    exec "$@"

fi
