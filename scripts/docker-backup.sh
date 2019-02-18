#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "Please provide the name of the container"
fi

echo "> Copying fixtures"
docker cp -a $1:/etc/emstrack/fixtures etc/emstrack/

echo "> Copying letsencrypt certificates"
docker cp -a $1:/etc/emstrack/letsencrypt etc/emstrack/
