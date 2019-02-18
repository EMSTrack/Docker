#!/bin/bash

echo "> Reading settings from /etc/emstrack.defaults..."
set -o allexport
source /etc/emstrack/emstrack.defaults
if [ -f /etc/emstrack/emstrack.init ]; then
    echo "> Reading settings from /etc/emstrack/emstrack.init..."
    source /etc/emstrack/emstrack.init
fi
set +o allexport

echo "APP_HOME=$APP_HOME"

INIT_FILE=/etc/emstrack/emstrack.initialized
if [ -f $INIT_FILE ]; then
    echo "> Container is already initialized"

    echo "> Linking settings"
    ln -sf /etc/emstrack/settings.py $APP_HOME/emstrack/settings.py

    echo "> Recovering static files"
    python manage.py collectstatic --no-input
    python manage.py compilemessages

    # exit
    exit 1
fi

echo "> Initializing container..."

# Setup mosquitto
sed -i'' \
    -e 's/\[ip\]/'"$MQTT_BROKER_HTTP_IP"'/g' \
    -e 's/\[port\]/'"$MQTT_BROKER_HTTP_PORT"'/g' \
    -e 's/\[with_tls\]/'"$MQTT_BROKER_HTTP_WITH_TLS"'/g' \
    -e 's/\[hostname\]/'"$MQTT_BROKER_HTTP_HOSTNAME"'/g' \
    -e 's/\[mqtt-username\]/'"$MQTT_USERNAME"'/g' \
    -e 's/\[mqtt-broker-port\]/'"$MQTT_BROKER_PORT"'/g' \
    -e 's/\[mqtt-broker-ssl-port\]/'"$MQTT_BROKER_SSL_PORT"'/g' \
    -e 's/\[mqtt-broker-websockets-port\]/'"$MQTT_BROKER_WEBSOCKETS_PORT"'/g' \
    /etc/mosquitto/conf.d/default.conf

# Setup nginx
sed -i'' \
    -e 's/\[port\]/'"$PORT"'/g' \
    -e 's/\[domain\]/'"$HOSTNAME"'/g' \
    /etc/nginx/sites-available/default

# Wait for postgres
timer="5"
until pg_isready -d postgres://postgres:$DB_PASSWORD@db; do
  >&2 echo "Postgres is unavailable - sleeping for $timer seconds"
  sleep $timer
done

# Setup Postgres
sed -i'' \
    -e 's/\[username\]/'"$DB_USERNAME"'/g' \
    -e 's/\[password\]/'"$DB_PASSWORD"'/g' \
    -e 's/\[database\]/'"$DB_DATABASE"'/g' \
    $APP_HOME/init/init.psql
psql -f $APP_HOME/init/init.psql -d postgres://postgres:$DB_PASSWORD@db
rm $APP_HOME/init/init.psql

# Setup Django
cd $APP_HOME
sed -i'' \
    -e 's/\[username\]/'"$DB_USERNAME"'/g' \
    -e 's/\[password\]/'"$DB_PASSWORD"'/g' \
    -e 's/\[database\]/'"$DB_DATABASE"'/g' \
    -e 's/\[host\]/'"$DB_HOST"'/g' \
    -e 's/\[secret-key\]/'"$DJANGO_SECRET_KEY"'/g' \
    -e 's/\[hostname\]/'"$DJANGO_HOSTNAMES"'/g' \
    -e 's/\[debug\]/'"$DJANGO_DEBUG"'/g' \
    -e 's/\[mqtt-password\]/'"$MQTT_PASSWORD"'/g' \
    -e 's/\[mqtt-username\]/'"$MQTT_USERNAME"'/g' \
    -e 's/\[mqtt-email\]/'"$MQTT_EMAIL"'/g' \
    -e 's/\[mqtt-clientid\]/'"$MQTT_CLIENTID"'/g' \
    -e 's/\[mqtt-broker-host\]/'"$MQTT_BROKER_HOST"'/g' \
    -e 's/\[mqtt-broker-port\]/'"$MQTT_BROKER_PORT"'/g' \
    -e 's/\[mqtt-broker-ssl-host\]/'"$MQTT_BROKER_SSL_HOST"'/g' \
    -e 's/\[mqtt-broker-ssl-port\]/'"$MQTT_BROKER_SSL_PORT"'/g' \
    -e 's/\[mqtt-broker-websockets-host\]/'"$MQTT_BROKER_WEBSOCKETS_HOST"'/g' \
    -e 's/\[mqtt-broker-websockets-port\]/'"$MQTT_BROKER_WEBSOCKETS_PORT"'/g' \
    /etc/emstrack/settings.py
ln -sf /etc/emstrack/settings.py $APP_HOME/emstrack/settings.py
python manage.py makemigrations ambulance login hospital equipment
python manage.py migrate

# Has backup?
if [ -e "/etc/emstrack/fixtures/backup.db" ] ;
then
    python manage.py loaddata /etc/emstrack/fixtures/backup.db
else
    python manage.py bootstrap
fi
python manage.py mqttpwfile
mv pwfile /etc/mosquitto/passwd
python manage.py collectstatic
python manage.py compilemessages

# Install certificates?
if [ -e "/etc/emstrack/letsencrypt/live/$HOSTNAME" ] ;
then
    echo "Letsencrypt certificates found"
    ln -fs /etc/ssl/certs/DST_Root_CA_X3.pem /etc/emstrack/certificates/ca.crt
    ln -fs /etc/emstrack/letsencrypt/live/$HOSTNAME/fullchain.pem /etc/emstrack/certificates/srv.crt
    ln -fs /etc/emstrack/letsencrypt/live/$HOSTNAME/privkey.pem /etc/emstrack/certificates/srv.key ;
    certbot --authenticator standalone --installer nginx --pre-hook "service nginx stop" --post-hook "service nginx start" -d $HOSTNAME --reinstall --redirect
else
    echo "No letsencrypt certificates found" ;
fi

# Mark as initialized
DATE=$(date +%Y-%m-%d)
cat << EOF > /etc/emstrack/emstrack.initialized
# Container initialized on $DATE
APP_HOME=$APP_HOME
APP_BRANCH=$APP_BRANCH
PORT=$PORT
SSL_PORT=$SSL_PORT
HOSTNAME=$HOSTNAME

DB_USERNAME=$DB_USERNAME
DB_PASSWORD=$DB_PASSWORD
DB_DATABASE=$DB_DATABASE
DB_HOST=$DB_HOST

DJANGO_SECRET_KEY=$DJANGO_SECRET_KEY
DJANGO_HOSTNAMES=$DJANGO_HOSTNAMES
DJANGO_DEBUG=$DJANGO_DEBUG

MQTT_USERNAME=$MQTT_USERNAME
MQTT_PASSWORD=$MQTT_PASSWORD
MQTT_EMAIL=$MQTT_EMAIL
MQTT_CLIENTID=$MQTT_CLIENTID

MQTT_BROKER_HTTP_IP=$MQTT_BROKER_HTTP_IP
MQTT_BROKER_HTTP_PORT=$MQTT_BROKER_HTTP_PORT
MQTT_BROKER_HTTP_WITH_TLS=$MQTT_BROKER_HTTP_WITH_TLS
MQTT_BROKER_HTTP_HOSTNAME=$MQTT_BROKER_HTTP_HOSTNAME

MQTT_BROKER_HOST=$MQTT_BROKER_HOST
MQTT_BROKER_PORT=$MQTT_BROKER_PORT
MQTT_BROKER_SSL_HOST=$MQTT_BROKER_SSL_HOST
MQTT_BROKER_SSL_PORT=$MQTT_BROKER_SSL_PORT
MQTT_BROKER_WEBSOCKETS_HOST=$MQTT_BROKER_WEBSOCKETS_HOST
MQTT_BROKER_WEBSOCKETS_PORT=$MQTT_BROKER_WEBSOCKETS_PORT
EOF

exit 0
