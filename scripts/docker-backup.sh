#!/bin/bash

echo "> Copying fixtures"
docker cp -a docker_emstrack_1:/etc/emstrack/fixtures etc/emstrack/

echo "> Copying letsencrypt certificates"
docker cp -a docker_emstrack_1:/etc/emstrack/letsencrypt etc/emstrack/
