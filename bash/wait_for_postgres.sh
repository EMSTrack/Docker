#!/bin/bash
# wait-for-postgres.sh

set -e

host="$1"
shift
user="$1"
shift
cmd="$@"

echo psql -h "$host" -U "$user" -c '\q'

until psql -h "$host" -U "$user" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

if [ -z "$cmd" ]
then
>&2 echo "Proceeding"
else
>&2 echo "Postgres is up - executing command"
exec $cmd
fi
