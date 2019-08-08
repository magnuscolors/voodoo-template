#!/bin/env bash

DEVELOPER=$1
DEVELOPER_PASSWD=$2
DEVELOPER_IP=$3
BASE=$4
BASEDBS=$5

if [[ $DEVELOPER = "" ]]
then
    read -p "Welke developer? Afkorting van twee kleine letters, zoals "wh": " DEVELOPER
    read -p "Welk wachtwoord? Niet ingewikkeld. Alleen om vergissing in db tijdens updaten te voorkomen: " DEVELOPER_PASSWD
    read -p "Welk IP-adres? : " DEVELOPER_IP
    read -p "Welke basis Directory/Instance?: " BASE
    read -p "Welke basis db(s)? If more than one, separate with comma: " BASEDBS
fi

EMAIL=w.hulshof@magnus.nl
USER=voodoo
PG_VERSION=9.6

HOST_BASE=${DEVELOPER}/${BASE}
BASE_DEV=${BASE}-${DEVELOPER}
HOST=${BASE_DEV}.vd

sudo mkdir /home/voodoo/${BASE_DEV}
sudo chown -R $USER:$USER /home/voodoo/${BASE_DEV}
sudo rsync -av --exclude=.db/ /home/voodoo/base/ /home/voodoo/${BASE_DEV}
sudo cp -ra /home/voodoo/filestore/${BASE}/ /home/voodoo/filestore/${HOST_BASE}/
sudo cp -ra /home/voodoo/parts/${BASE}/ /home/voodoo/parts/${HOST_BASE}/

IFS=","
for DB in $BASEDBS
do
sudo mv  /home/voodoo/filestore/${HOST_BASE}/filestore/$DB /home/voodoo/filestore/${HOST_BASE}/filestore/${DB}${DEVELOPER}
done

sudo rm /home/voodoo/${BASE_DEV}/docker-compose.yml
sudo mv /home/voodoo/${BASE_DEV}/odoo.docker-compose.yml /home/voodoo/${BASE_DEV}/docker-compose.yml

# postres user role add
docker run  --rm -v /home/voodoo/base/.db/socket:/var/run/postgresql/ -e PGPASSWORD=magnuscolors postgres:${PG_VERSION} createdb -U postgres -T "${BASEDB}" "${BASEDB}${DEVELOPER}";
docker run  --rm -v /home/voodoo/base/.db/socket:/var/run/postgresql/ -e PGPASSWORD=magnuscolors postgres:${PG_VERSION} psql -U postgres -t -c "CREATE ROLE "odoo${DEVELOPER}" SUPERUSER CREATEDB CREATEROLE LOGIN REPLICATION BYPASSRLS PASSWORD '"${DEVELOPER_PASSWD}"';ALTER DATABASE "$BASEDB${DEVELOPER}" OWNER TO odoo"${DEVELOPER}";"

# odoo.cfg
sudo sh -c "sed -i 's/\(db_name =\).*$/\1 "${BASEDB}${DEVELOPER}"/' /home/voodoo/${HOST_BASE}/etc/odoo.cfg"
sudo sh -c "sed -i 's/\(db_password =\).*$/\1 "${DEVELOPER_PASSWD}"/' /home/voodoo/${HOST_BASE}/etc/odoo.cfg"
sudo sh -c "sed -i 's/\(db_user =\).*$/\1 "odoo${DEVELOPER}"/' /home/voodoo/${HOST_BASE}/etc/odoo.cfg"

# nfs export definition: to do: sed if exists overwrite else add
sudo sh -c "echo '/data1/"${DEVELOPER}" 10.147.18.118(rw,anonuid=1000,anongid=1000,sync,all_squash) 10.147.18.124(rw,anonuid=1000,anongid=1000,sync,all_squash) "$DEVELOPER_IP"(rw,anonuid=1000,anongid=1000,sync,all_squash)' >> /opt/nfs-server/exports.txt"

# .env file
su $USER sh -c "printf 'HOST="${BASE_DEV}".vd\nHOST_BASE="${HOST_BASE}"' >> /home/voodoo/"${BASE_DEV}"/.env"

docker-compose -f /opt/nfs-server/docker-compose.yml restart
