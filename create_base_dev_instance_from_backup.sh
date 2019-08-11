#!/bin/env bash

function check_exec_ok {
    if [[ $?  -eq 0 ]]; then
        echo "$1"
        else
        echo "$2"
    fi
}

read -p "Which base Directory/Instance?: " BASE
read -p "Which IMAGE? include TAG like "latest": " IMAGE
read -p "Which Host? " HOST
read -p "Which Instance?: " INSTANCE
read -p "Which base db(s)? If more than one, separate with comma and no spaces: " DBS
read -p "Which Port runs Postgres destination? (default 5432) " PG_PORT
read -p "Which Postgres Version? (default 9.6) " PG_VERSION
read -p "Which ssh-user has destination? (default core) " SSH_USER
read -p "Which location of filestore at source? \".filestore\" or \"data\"? (default \"data\") " FILESTORE

USER=voodoo
TOSERVER=172.128.1.226
PG_PORT="${PG_PORT:=5432}"
PG_VERSION="${PG_VERSION:=9.6}"
SSH_USER="${SSH_USER:=core}"
FILESTORE="${FILESTORE:=data}"


su $USER sh -c "mkdir -p /home/voodoo/filestore/base/${BASE}/filestore /home/voodoo/filestore/base/${BASE}/sessions /home/voodoo/filestore/base/${BASE}/addons /home/voodoo/odooconfig/${BASE}/etc/"
check_exec_ok ""${BASE}" added in ../filestore/base/" ""${BASE}" NOT added in ../filestore/base/"
IFS=","
for DB in $DBS
do
  ssh core@172.128.1.202 /opt/bin/backup/restore_unatt.sh ${HOST} ${INSTANCE} ${TOSERVER} ${DB} ${PG_PORT} ${PG_VERSION} ${SSH_USER} ${FILESTORE} /home/voodoo/filestore/base/${BASE}
done

docker pull ${IMAGE}
docker create -ti --name dummy ${IMAGE} bash
sudo docker cp -a dummy:/workspace/parts/ /home/voodoo/parts/base/${BASE}/
sudo chown -R $USER:$USER /home/voodoo/parts/base/${BASE}
sudo docker cp -a dummy:/workspace/etc/odoo.cfg /home/voodoo/odooconfig/${BASE}/etc/
sudo chown -R $USER:$USER /home/voodoo/odooconfig/${BASE}
sudo chmod 644 /home/voodoo/odooconfig/${BASE}/etc/odoo.cfg
docker rm dummy

