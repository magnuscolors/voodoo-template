#!/bin/env bash
#
# Script to make software deployments in running voodoo containers easier
#
#

IMAGE=$1
TAG=$2
VOLUMES="-v $(pwd)/.db/socket/:/var/run/postgresql/ -v $(pwd)/data:/home/odoo/data"
if [[ $1 = "" ]]
then
echo "Which Image should be altered for deploy?"
read IMAGE
echo "Which Tag?"
read TAG
fi


echo "Do you want to update the database from the command line? (y/n)"
read A
    if [ $A = "y" ]
    then
    docker run -it -u root ${VOLUMES} --name hoedoedeploy ${IMAGE}:${TAG} bash
    else
    docker run -it -u root --name hoedoedeploy ${IMAGE}:${TAG} bash
    fi
echo "Do you want to commit the changes you made to ${IMAGE}:${TAG}? (y/n)"
read B
    if [ $B = "y" ]
    then
    docker commit hoedoedeploy ${IMAGE}:${TAG}
    else
    echo "Do you want to commit to a different image? (y/n)"
    read D
        if [ $D = "y" ]
        then
        echo "Please specify the IMAGE:TAG you want to commit to"
        read E
        echo "Are you sure you want to commit to $E?"
        read F
            if [ $F = "y" ]
            then
            docker commit hoedoedeploy $E
            fi
        fi
    fi

echo "Updated container will now be deleted"
docker rm hoedoedeploy

if [ $B = "y" ]
        then
        echo "Do you want to push the changes you made to ${IMAGE}:${TAG}? (y/n)"
        read C
            if [ $C = "y" ]
            then
            docker push ${IMAGE}:${TAG}
            fi
fi
if [ $F = "y" ]
        then
        echo "Do you want to push the changes you made to ${E}? (y/n)"
        read C
            if [ $C = "y" ]
            then
            docker push $E
            fi
fi
