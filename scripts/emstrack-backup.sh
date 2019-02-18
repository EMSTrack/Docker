#!/bin/bash

echo "> ATTENTION: stop services before backing up database to preserve integrity"

echo "> Backing up database"
python manage dumpdata > /etc/emstrack/fixtures/backup.db

echo "> Done backing up database"
