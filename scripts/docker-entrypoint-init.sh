INIT_FILE=/tmp/emstrack.initialized
if [ -f $INIT_FILE ]; then
    echo "> Container is already initialized"
    exit 1
fi

echo "> Initializing container..."

echo "> Reading settings from /etc/emstrack.defaults..."
set -o allexport
source /etc/emstrack.defaults
if [ -f /etc/emstrack.init ]; then
    echo "> Reading settings from /etc/emstrack.init..."
    source /etc/emstrack.init
fi
set +o allexport

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

# Setup Django
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
    $APP_HOME/emstrack/settings.py
cd $APP_HOME
DJANGO_ENABLE_MQTT_SIGNALS="False" python manage.py makemigrations
DJANGO_ENABLE_MQTT_SIGNALS="False" python manage.py makemigrations ambulance login hospital
DJANGO_ENABLE_MQTT_SIGNALS="False" python manage.py migrate
DJANGO_ENABLE_MQTT_SIGNALS="False" python manage.py collectstatic
DJANGO_ENABLE_MQTT_SIGNALS="False" python manage.py bootstrap
DJANGO_ENABLE_MQTT_SIGNALS="False" python manage.py mqttpwfile
mv pwfile /etc/mosquitto/passwd

# Change ownership of app to www-data
chown -R www-data:www-data $APP_HOME

# Install certificates?
if [ -e "/etc/certificates/letsencrypt/live/$HOSTNAME" ] ;
then
    echo "Letsencrypt certificates found"
    pip install certbot-nginx
    ln -fs /etc/ssl/certs/DST_Root_CA_X3.pem /etc/certificates/ca.crt
    ln -fs /etc/certificates/letsencrypt/live/$HOSTNAME/fullchain.pem /etc/certificates/srv.crt
    ln -fs /etc/certificates/letsencrypt/live/$HOSTNAME/privkey.pem /etc/certificates/srv.key ;
    certbot --authenticator standalone --installer nginx --pre-hook "service nginx stop" --post-hook "service nginx start" -d $HOSTNAME --reinstall --redirect
else
    echo "No letsencrypt certificates found" ;
    # TODO: ask if wants to run certbot
fi

# Mark as initialized
DATE=$(date +%Y-%m-%d)
cat << EOF > /tmp/emstrack.initialized
> Container initialized on $DATE
EOF

exit 0
