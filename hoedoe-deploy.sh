#!/bin/env bash
#
# Script to make software deployments in running voodoo containers easier
#
#

IMAGE=$1
TAG=$2
VOLUMES="-v $(pwd)/.db/socket/:/var/run/postgresql/ -v $(pwd)/data:/home/odoo/data"
if [ $(1) = "" ]
then
echo "Which Image should be altered for deploy?"
read IMAGE
echo "Which Tag?"
read TAG
fi


# docker run --rm $DOCKER_RUN_OPTIONS $DOCKER_ADDR $COMPOSE_OPTIONS $VOLUMES -w "$(pwd)" $IMAGE "$@"
exec docker run -it -u root $(VOLUMES) --name hoedoedeploy $(IMAGE):$(TAG) bash
exec docker commit hoedoedeploy $(IMAGE):$(TAG)
exec docker rm hoedoedeploy
exec docker push $(IMAGE):$(TAG)
