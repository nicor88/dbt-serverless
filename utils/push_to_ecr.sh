#!/usr/bin/env bash

AWS_ACCOUNT_ID=$1

IMAGE_NAME="dbt-serverless"
COMMIT_HASH=$(hexdump -n 16 -v -e '/1 "%02X"' -e '/16 "\n"' /dev/urandom)

echo "Building image: $IMAGE_NAME:latest"

docker build --rm -t $IMAGE_NAME:latest .

eval $(aws ecr get-login --no-include-email) || EXIT_STATUS=$?

# tag the  built image with latest
docker tag $IMAGE_NAME $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_NAME:latest || EXIT_STATUS=$?
# push latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_NAME:latest || EXIT_STATUS=$?

# tag the built image with commit hash
docker tag $IMAGE_NAME $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_NAME:$COMMIT_HASH || EXIT_STATUS=$?

# push commit has image
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_NAME:$COMMIT_HASH || EXIT_STATUS=$?

exit $EXIT_STATUS
