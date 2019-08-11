#!/bin/env bash

DEVELOPER=$1
ROLE_YN=$2
BASE=$3
BASEDBS=$4
DEVELOPER_PASSWD=$5
DEVELOPER_IP=$6
DB_FILTER=$7

if [[ $DEVELOPER = "" ]]
then
    read -p "Which developer? Abbreviation with two letters, like "wh": " DEVELOPER
    read -p "Which password? Not too complicated. Just to avoid mistake when updating db: " DEVELOPER_PASSWD
    read -p "Which IP-adres?: " DEVELOPER_IP
    read -p "Which base Directory/Instance?: " BASE
    read -p "Which base db(s)? If more than one, separate with comma and no spaces: " BASEDBS
    read -p "Does Postgres Role and passwd need to be created? y/n: " ROLE_YN=$"{ROLE_YN:=y}"
    read -p "Does Instance/db need to be created? y/n: " INST_YN=$"{INST_YN:=y}"
    read -p "Does odoo.cfg need to be updated? y/n: " CFG_YN=$"{CFG_YN:=y}"
    read -p "What dbfilter should be used in odoo.cfg? : " DB_FILTER=$"{DB_FILTER:=" .*"}"
    read -p "Does nfs-server need to be restarted? y/n: " NFS_RESTART_YN=$"{NFS_RESTART_YN:=y}"
fi

EMAIL=w.hulshof@magnus.nl
USER=voodoo
PG_VERSION=9.6
HOST_BASE=${DEVELOPER}/${BASE}
BASE_DEV=${BASE}-${DEVELOPER}
HOST=${BASE_DEV}.vd
BASEDB_DEV=echo $BASEDBS | sed -E "s/([^,]+)/\1wh/g"

# Instance/db creation
if [[ $INST_YN =~ [yY](es)* ]]
then
    sudo mkdir /home/voodoo/${BASE_DEV}
    sudo chown -R $USER:$USER /home/voodoo/${BASE_DEV}
    sudo rsync -av --exclude=.db/ /home/voodoo/base/ /home/voodoo/${BASE_DEV}
    sudo rm /home/voodoo/${BASE_DEV}/docker-compose.yml
    sudo mv /home/voodoo/${BASE_DEV}/odoo.docker-compose.yml /home/voodoo/${BASE_DEV}/docker-compose.yml

    sudo cp -ra /home/voodoo/filestore/${BASE}/ /home/voodoo/filestore/${HOST_BASE}/
    sudo cp -ra /home/voodoo/parts/${BASE}/ /home/voodoo/parts/${HOST_BASE}/
    sudo cp -ra /home/voodoo/odooconfig/${BASE}/ /home/voodoo/parts/${HOST_BASE}/

    IFS=","
    for DB in $BASEDBS
    do
        sudo mv  /home/voodoo/filestore/"${HOST_BASE}"/filestore/"$DB" /home/voodoo/filestore/"${HOST_BASE}"/filestore/"${DB}${DEVELOPER}"
        docker run  --rm -v /home/voodoo/base/.db/socket:/var/run/postgresql/ -e PGPASSWORD=magnuscolors postgres:${PG_VERSION} createdb -U postgres -T "${DB}" "${DB}${DEVELOPER}";
    done
fi

# postres user role add
if [[ $ROLE_YN =~ [yY](es)* ]]
then
    docker run  --rm -v /home/voodoo/base/.db/socket:/var/run/postgresql/ -e PGPASSWORD=magnuscolors postgres:${PG_VERSION} psql -U postgres -t -c "
    CREATE ROLE "odoo${DEVELOPER}" SUPERUSER CREATEDB CREATEROLE LOGIN REPLICATION BYPASSRLS PASSWORD '"${DEVELOPER_PASSWD}"';
    ALTER DATABASE "$BASEDB${DEVELOPER}" OWNER TO odoo"${DEVELOPER}";"
fi

# odoo.cfg
if [[ $CFG_YN =~ [yY](es)* ]]
then
    sudo sh -c "sed -i 's/\(db_name =\).*$/\1 "${BASEDB_DEV}"/' /home/voodoo/${HOST_BASE}/etc/odoo.cfg"
    sudo sh -c "sed -i 's/\(db_password =\).*$/\1 "${DEVELOPER_PASSWD}"/' /home/voodoo/${HOST_BASE}/etc/odoo.cfg"
    sudo sh -c "sed -i 's/\(db_user =\).*$/\1 "odoo${DEVELOPER}"/' /home/voodoo/${HOST_BASE}/etc/odoo.cfg"
    sudo sh -c "sed -i 's/\(dbfilter =\).*$/\1 "${DB_FILTER}"/' /home/voodoo/${HOST_BASE}/etc/odoo.cfg"
fi

# .env file always gets overwritten again
su $USER sh -c "printf 'HOST="${BASE_DEV}".vd\nHOST_BASE="${HOST_BASE}"' > /home/voodoo/"${BASE_DEV}"/.env"

# adapt exports.txt for nfs-server and restart it
if [[ $NFS_RESTART_YN =~ [yY](es)* ]]
then
    sudo sh -c "grep -q "^/data1/"${DEVELOPER}"" /opt/nfs-server/exportswh.txt && sed 's/^\/data1\/"${DEVELOPER}".*/\/data1\/"${DEVELOPER}" 10.147.18.118\(rw,anonuid=1000,anongid=1000,sync,all_squash\) 10.147.18.124\(rw,anonuid=1000,anongid=1000,sync,all_squash\) "$DEVELOPER_IP"\(rw,anonuid=1000,anongid=1000,sync,all_squash\)/' -i /opt/nfs-server/exportswh.txt ||
    sed '$ a\\/data1\/"${DEVELOPER}" 10.147.18.118\(rw,anonuid=1000,anongid=1000,sync,all_squash\) 10.147.18.124\(rw,anonuid=1000,anongid=1000,sync,all_squash\) "$DEVELOPER_IP"\(rw,anonuid=1000,anongid=1000,sync,all_squash\)' -i /opt/nfs-server/exportswh.txt"
    cd /opt/nfs-server
    docker-compose restart
fi