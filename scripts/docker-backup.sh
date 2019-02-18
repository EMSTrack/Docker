#!/bin/bash

echo "> Copying fixtures"
docker cp -a emstrack:/etc/emstrack/fixtures etc/emstrack/

echo "> Copying letsencrypt certificates"
docker cp -a emstrack:/etc/emstrack/letsencrypt etc/emstrack/
