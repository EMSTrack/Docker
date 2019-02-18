#!/bin/bash

echo "> ATTENTION: stop services before backing up database to preserve integrity"

echo "> Backing up database"
mkdir -p /etc/emstrack/fixtures
python manage.py dumpdata > /etc/emstrack/fixtures/backup.json

echo "> Done backing up database"
