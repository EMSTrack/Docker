APP_HOME="${APP_HOME:=/app}"
PORT="${PORT:=8000}"
SSL_PORT="${SSL_PORT:=8443}"

DB_USERNAME="${DB_USERNAME:=emstrack}"
DB_PASSWORD="${DB_PASSWORD:=password}"
DB_DATABASE="${DB_DATABASE:=emstrack}"
DB_HOST="${DB_HOST:=db}"

DJANGO_SECRET_KEY="${DJANGO_SECRET_KEY:=CH4NG3M3!}"
DJANGO_HOSTNAMES="${DJANGO_HOSTNAMES:=" 'localhost', '127.0.0.1' "}"
DJANGO_DEBUG="${DJANGO_DEBUG:=False}"

MQTT_USERNAME="${MQTT_USERNAME:=admin}"
MQTT_PASSWORD="${MQTT_PASSWORD:=cruzrojaadmin}"
MQTT_EMAIL="${MQTT_EMAIL:=webmaster@cruzroja.ucsd.edu}"
MQTT_CLIENTID="${MQTT_CLIENTID:=mqttclient}"

MQTT_BROKER_HTTP_IP="${MQTT_BROKER_HTTP_IP:=127.0.0.1}"
MQTT_BROKER_HTTP_PORT="${MQTT_BROKER_HTTP_PORT:=$PORT}"
MQTT_BROKER_HTTP_WITH_TLS="${MQTT_BROKER_HTTP_WITH_TLS:=false}"
MQTT_BROKER_HTTP_HOSTNAME="${MQTT_BROKER_HTTP_HOSTNAME:=localhost}"

MQTT_BROKER_HOST="${MQTT_BROKER_HOST:=localhost}"
MQTT_BROKER_PORT="${MQTT_BROKER_PORT:=1883}"
MQTT_BROKER_SSL_HOST="${MQTT_BROKER_SSL_HOST:=localhost}"
MQTT_BROKER_SSL_PORT="${MQTT_BROKER_SSL_PORT:=8883}"
MQTT_BROKER_WEBSOCKETS_HOST="${MQTT_BROKER_WEBSOCKETS_HOST:=localhost}"
MQTT_BROKER_WEBSOCKETS_PORT="${MQTT_BROKER_WEBSOCKETS_PORT:=8884}"

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
    emstrack/settings.py
DJANGO_ENABLE_MQTT_SIGNALS="False" python manage.py makemigrations
DJANGO_ENABLE_MQTT_SIGNALS="False" python manage.py makemigrations ambulance login hospital
DJANGO_ENABLE_MQTT_SIGNALS="False" python manage.py migrate
DJANGO_ENABLE_MQTT_SIGNALS="False" python manage.py collectstatic
DJANGO_ENABLE_MQTT_SIGNALS="False" python manage.py bootstrap
DJANGO_ENABLE_MQTT_SIGNALS="False" python manage.py mqttpwfile
mv pwfile /etc/mosquitto/passwd

# Change ownership of app to www-data
chown -R www-data:www-data $APP_HOME

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
fi
