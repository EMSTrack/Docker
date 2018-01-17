# Use the official python 3.6 running on debian
FROM python:3.6

# Getting rid of debconf messages
ARG DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update -y
RUN apt-get install -y apt-utils git
RUN apt-get install -y postgresql postgresql-contrib
RUN apt-get install -y postgis
RUN apt-get install -y gdal-bin libgdal-dev python3-gdal
RUN apt-get install -y openssl cmake
RUN apt-get install -y supervisor
RUN apt-get install -y vim sudo

# Install uwsgi and nginx
RUN apt-get install -y nginx
RUN pip install uwsgi

ARG HOME=/app

# Build libraries
WORKDIR /src

# Download source code for libwebsockets
# THIS MIGHT NOT BE NECESSARY IN THE FUTURE!
# CURRENT VERSION OF LIBWEBSOCKET GENERATES
# ERROR IN MOSQUITTO-AUTH-PLUG
RUN git clone https://github.com/warmcat/libwebsockets

# Download source code for mosquitto
RUN git clone https://github.com/eclipse/mosquitto

# Download source code for mosquitto-auth-plug
RUN git clone https://github.com/jpmens/mosquitto-auth-plug

# Build libwebsockets
WORKDIR /src/libwebsockets/build
RUN cmake ..
RUN make install

# Configure and build mosquitto
WORKDIR /src/mosquitto
RUN cp config.mk config.mk.in
RUN sed -e 's/WITH_SRV:=yes/WITH_SRV:=no/' \
        -e 's/WITH_WEBSOCKETS:=no/WITH_WEBSOCKETS:=yes/' \
	-e 's/WITH_DOCS:=yes/WITH_DOCS:=no/' \
	config.mk.in > config.mk
RUN make binary install

# Configure and build mosquitto-auth-plug
WORKDIR /src/mosquitto-auth-plug
RUN sed -e 's/BACKEND_MYSQL ?= yes/BACKEND_MYSQL ?= no/' \
        -e 's/BACKEND_FILES ?= no/BACKEND_FILES ?= yes/' \
	-e 's/BACKEND_HTTP ?= no/BACKEND_HTTP ?= yes/' \
	-e 's,MOSQUITTO_SRC =,MOSQUITTO_SRC =/src/mosquitto,' \
	-e 's,OPENSSLDIR = /usr,OPENSSLDIR = /usr/bin,' \
	config.mk.in > config.mk
RUN make; cp auth-plug.so /usr/local/lib

# Run ldconfig
RUN ldconfig

ARG CA_CRT=certificates/example-com.ca.crt
ARG SRV_CRT=certificates/example-com.srv.crt
ARG SRV_KEY=certificates/example-com.srv.key

# Install certificates
COPY $CA_CRT /etc/certificates/ca.crt
COPY $SRV_CRT /etc/certificates/srv.crt
COPY $SRV_KEY /etc/certificates/srv.key

# Clone and build application

ARG BRANCH=master
ARG USERNAME=emstrack
ARG PASSWORD=password
ARG DATABASE=emstrack

ARG SECRET_KEY=CH4NG3M3!
ARG HOSTNAME=" 'localhost', '127.0.0.1' "
ARG DEBUG=False

ARG MQTT_USERNAME=admin
ARG MQTT_PASSWORD=cruzrojaadmin
ARG MQTT_EMAIL=webmaster@cruzroja.ucsd.edu
ARG MQTT_CLIENTID=mqttclient

# Clone main repository and switch to branch
WORKDIR /src
RUN git clone https://github.com/EMSTrack/WebServerAndClient
RUN rm -fr $HOME
RUN mv WebServerAndClient $HOME

# Checkout branch
WORKDIR $HOME
RUN git checkout $BRANCH

# Install python requirements
RUN pip install -r requirements.txt

# Setup Postgres
COPY postgresql/init.psql init.psql
RUN sed -i'' \
        -e 's/\[username\]/'"$USERNAME"'/g' \
        -e 's/\[password\]/'"$PASSWORD"'/g' \
        -e 's/\[database\]/'"$DATABASE"'/g' \
	init.psql
USER postgres
RUN service postgresql start &&\
    sleep 5 &&\
    psql -f init.psql &&\
    service postgresql stop
USER root
RUN rm init.psql

# Setup Django
RUN echo 1
RUN git pull
COPY django/settings.py emstrack/settings.py
RUN sed -i'' \
        -e 's/\[username\]/'"$USERNAME"'/g' \
        -e 's/\[password\]/'"$PASSWORD"'/g' \
        -e 's/\[database\]/'"$DATABASE"'/g' \
        -e 's/\[secret-key\]/'"$SECRET_KEY"'/g' \
        -e 's/\[hostname\]/'"$HOSTNAME"'/g' \
        -e 's/\[debug\]/'"$DEBUG"'/g' \
        -e 's/\[mqtt-password\]/'"$MQTT_PASSWORD"'/g' \
        -e 's/\[mqtt-username\]/'"$MQTT_USERNAME"'/g' \
        -e 's/\[mqtt-email\]/'"$MQTT_EMAIL"'/g' \
        -e 's/\[mqtt-clientid\]/'"$MQTT_CLIENTID"'/g' \
	emstrack/settings.py
RUN service postgresql start &&\
    sleep 10 &&\
    DJANGO_ENABLE_MQTT_SIGNALS="False" python manage.py makemigrations &&\
    DJANGO_ENABLE_MQTT_SIGNALS="False" python manage.py makemigrations ambulance login hospital &&\
    DJANGO_ENABLE_MQTT_SIGNALS="False" python manage.py migrate &&\
    service postgresql stop

# Setup mosquitto
RUN useradd -M mosquitto
RUN usermod -L mosquitto
COPY mosquitto/mosquitto.conf /etc/mosquitto/mosquitto.conf
COPY mosquitto/conf.d /etc/mosquitto/conf.d
RUN sed -i'' \
        -e 's/\[mqtt-username\]/'"$MQTT_USERNAME"'/g' \
	/etc/mosquitto/conf.d/default.conf
COPY init.d/mosquitto /etc/init.d/mosquitto
RUN chmod +x /etc/init.d/mosquitto
RUN update-rc.d mosquitto defaults
RUN mkdir /var/log/mosquitto
RUN chown -R mosquitto:mosquitto /var/log/mosquitto
RUN mkdir /var/lib/mosquitto
RUN chown -R mosquitto:mosquitto /var/lib/mosquitto

# Setup mqttclient
COPY supervisor/mqttclient.conf /etc/supervisor/conf.d/mqttclient.conf

# Expose the mosquitto ports
EXPOSE 1883
EXPOSE 8883
EXPOSE 8884

EXPOSE 8000

# Collect static
RUN DJANGO_ENABLE_MQTT_SIGNALS="False" python manage.py collectstatic

# Configure nginx
COPY nginx/nginx.conf /etc/nginx/sites-enabled/default
COPY nginx/uwsgi_params emstrack/uwsgi_params

# Enable nginx service
RUN update-rc.d nginx enable

# Change ownership of app to www-data
RUN cd /; chown -R www-data:www-data app

# Initialize django application
RUN service postgresql start &&\
    sleep 5 &&\
    DJANGO_ENABLE_MQTT_SIGNALS="False" python manage.py bootstrap &&\
    DJANGO_ENABLE_MQTT_SIGNALS="False" python manage.py mqttpwfile &&\
    sleep 5 &&\
    service postgresql stop
RUN mv pwfile /etc/mosquitto/passwd

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql", \
        "/etc/mosquitto", "/var/log/mosquitto", "/var/lib/mosquitto", \
	"/var/log/django", \
        "/etc/certificates" ]

CMD echo "> Starting postgres" &&\
    service postgresql start &&\
    echo "> Starting mosquitto" &&\
    service mosquitto start &&\
    sleep 5 &&\
    echo "> Starting uWSGI" &&\
    nohup bash -c "uwsgi --socket emstrack.sock --module emstrack.wsgi --uid www-data --gid www-data --chmod-socket=664 >/var/log/uwsgi.log 2>&1 &" &&\
    echo "> Starting nginx" &&\
    service nginx start &&\
    echo "> Starting mqttseed" &&\
    python manage.py mqttseed &&\
    echo "> Starting mqttclient" &&\
    service supervisor start &&\
    echo "> All services up" &&\
    tail -f /var/log/uwsgi.log

# CMD echo "> Starting postgres" &&\
#     service postgresql start &&\
#     echo "> Starting mosquitto" &&\
#     service mosquitto start &&\
#     echo "> All services up" &&\
#     python manage.py runserver 0.0.0.0:8000
