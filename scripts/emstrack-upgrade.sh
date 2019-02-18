#!/bin/bash

echo "> Starting upgrade..."

# stop services
echo "> Stoping services"
emstrack-down

# git pull to update
echo "> Pulling changes"
git pull

# run updates
echo "> Upgrading database"
python manage.py makemigrations
python manage.py migrate

echo "> Upgrading static files"
python manage.py collectstatic --no-input
python manage.py compilemessages

# start services
echo "> Restarting services"
emstrack-up all

echo "> Upgrade complete"
