#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Please specify a model to run"
    exit 1
fi

echo "Building the container Image dbt:latest"

docker build . -t dbt_locally:latest

echo "Running model " $1

docker run -e DB_HOST=$DB_HOST \
					 -e DB_PORT=$DB_PORT \
					 -e DB_USER=$DB_USER \
					 -e DB_PASSWORD=$DB_PASSWORD \
					 -e DB_NAME=$DB_NAME \
					 -e DB_SCHEMA=DB_SCHEMA \
           -it -v $(pwd)/models:/dbt/models dbt_locally:latest dbt run --models $1 --target dev
