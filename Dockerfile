# Using ubuntu as a base image
FROM ubuntu:18.04

# Getting rid of debconf messages
ARG DEBIAN_FRONTEND=noninteractive

# Arguments
ARG APP_HOME=/app

# Install dependencies
RUN apt-get update -y
RUN apt-get install -y apt-utils git

# Install python
RUN apt-get install -y python3-pip python3-dev 

# Install postgres and postgis
RUN apt-get install -y postgresql-client-10
RUN apt-get install -y gdal-bin libgdal-dev python3-gdal

# Install opensll
RUN apt-get install -y openssl

# Install utilities
RUN apt-get install -y vim sudo less
RUN apt-get install -y uuid-dev
RUN apt-get install -y libcurl4-openssl-dev

# Install libwebsockets
RUN apt-get install -y libwebsockets-dev

# Install nginx
RUN apt-get install -y nginx

# Make python3 default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1
RUN ln -s /usr/bin/pip3 /usr/bin/pip
RUN pip install --upgrade pip

# Install uwsgi
RUN pip install uwsgi

# Install supervisor (make sure it runs on python2)
RUN apt-get install -y supervisor
RUN sed -i'' \
        -e 's/bin\/python/bin\/python2/' \
	/usr/bin/supervisord
RUN sed -i'' \
        -e 's/bin\/python/bin\/python2/' \
	/usr/bin/supervisorctl

# Install certbot
RUN pip install --upgrade cryptography
RUN pip install certbot-nginx

# Build libraries

# Download source code for mosquitto
WORKDIR /src
RUN git clone https://github.com/eclipse/mosquitto
WORKDIR /src/mosquitto
RUN git checkout 8025f5a29b78551e1d5e9ea13ae9dacabb6830da

# Configure and build mosquitto
WORKDIR /src/mosquitto
RUN cp config.mk config.mk.in
RUN sed -e 's/WITH_SRV:=yes/WITH_SRV:=no/' \
        -e 's/WITH_WEBSOCKETS:=no/WITH_WEBSOCKETS:=yes/' \
	-e 's/WITH_DOCS:=yes/WITH_DOCS:=no/' \
	config.mk.in > config.mk
RUN make binary install
RUN useradd -M mosquitto
RUN usermod -L mosquitto
COPY mosquitto/mosquitto.conf /etc/mosquitto/mosquitto.conf
COPY mosquitto/conf.d /etc/mosquitto/conf.d
COPY init.d/mosquitto /etc/init.d/mosquitto
RUN chmod +x /etc/init.d/mosquitto
RUN update-rc.d mosquitto defaults
RUN mkdir /var/log/mosquitto
RUN chown -R mosquitto:mosquitto /var/log/mosquitto
RUN mkdir /var/lib/mosquitto
RUN chown -R mosquitto:mosquitto /var/lib/mosquitto

# Download source code for mosquitto-auth-plug
#RUN git clone https://github.com/EMSTrack/mosquitto-auth-plug
WORKDIR /src
RUN git clone https://github.com/jpmens/mosquitto-auth-plug
WORKDIR /src/mosquitto-auth-plug
RUN git checkout 481331fa57760bfe5934164c69784df70692bd65

# Configure and build mosquitto-auth-plug
WORKDIR /src/mosquitto-auth-plug
RUN sed -e 's/BACKEND_MYSQL ?= yes/BACKEND_MYSQL ?= no/' \
        -e 's/BACKEND_FILES ?= no/BACKEND_FILES ?= yes/' \
	-e 's/BACKEND_HTTP ?= no/BACKEND_HTTP ?= yes/' \
	-e 's,MOSQUITTO_SRC =,MOSQUITTO_SRC =/src/mosquitto,' \
	-e 's,OPENSSLDIR = /usr,OPENSSLDIR = /usr/bin,' \
	config.mk.in > config.mk
RUN make; cp auth-plug.so /usr/local/lib

# Clone application

# Clone main repository and switch to branch
WORKDIR /src
RUN git clone https://github.com/EMSTrack/WebServerAndClient
RUN rm -fr $APP_HOME
RUN mv WebServerAndClient $APP_HOME

# Install python requirements
WORKDIR $APP_HOME
RUN pip install -r requirements.txt

# Persistent settings
# Certificates are ready for letsencrypt
# Just put current keys in /etc/emstrack/letsencrypt and you will be done
COPY etc /etc
RUN mkdir -p /etc/emstrack/letsencrypt
RUN ln -s /etc/emstrack/letsencrypt /etc/letsencrypt
RUN ln -s /etc/emstrack/settings.py $APP_HOME/emstrack/settings.py

# Setup mqttclient
COPY supervisor/mqttclient.conf /etc/supervisor/conf.d/mqttclient.conf

# Configure nginx
COPY nginx/uwsgi_params emstrack/uwsgi_params
COPY nginx/nginx.conf /etc/nginx/sites-available/default
RUN update-rc.d nginx enable

# Run ldconfig
RUN ldconfig

# Init files
COPY postgresql/init.psql $APP_HOME/init/init.psql

# Init script
COPY scripts/docker-entrypoint-init.sh /usr/local/bin/docker-entrypoint-init.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-init.sh
COPY scripts/docker-test.sh /usr/local/bin/emstrack-test
RUN chmod +x /usr/local/bin/emstrack-test
COPY scripts/docker-upgrade.sh /usr/local/bin/emstrack-upgrade
RUN chmod +x /usr/local/bin/emstrack-upgrade
COPY scripts/docker-up.sh /usr/local/bin/emstrack-up
RUN chmod +x /usr/local/bin/emstrack-up
COPY scripts/docker-down.sh /usr/local/bin/emstrack-down
RUN chmod +x /usr/local/bin/emstrack-down

# Entrypoint script
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME ["/etc/emstrack"]

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["all"]
