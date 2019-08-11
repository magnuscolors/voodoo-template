#!/bin/env bash

DEVELOPERS=$1
ROLE_YN=$2
BASE=$3
BASEDBS=$4
DEVELOPER_PASSWD=$5
DEVELOPER_IP=$6
DB_FILTER=$7

if [[ $DEVELOPERS = "" ]]
then
    read -p "Which base Directory/Instance?: " BASE
    read -p "Which developers? Abbreviation with two letters, like "wh". If more than one, separate with comma and no spaces: " DEVELOPERS
    read -p "Which passwords? Same order as developers. Not too complicated. Just to avoid mistake when updating db. If more than one, separate with comma and no spaces: " DEVELOPER_PASSWDS
    read -p "Which IP-adresses? If more than one, separate with comma and no spaces: " DEVELOPER_IPS
    read -p "Which base db(s)? If more than one, separate with comma and no spaces: " BASEDBS
    read -p "What dbfilter should be used in odoo.cfg? : " DB_FILTER
    read -p "Does Instance/db need to be created? y/n: " INST_YN
    read -p "Does odoo.cfg need to be updated? y/n: " CFG_YN
    read -p "Does nfs-server need to be restarted? y/n: " NFS_RESTART_YN
fi

function check_exec_ok {
    if [[ $?  -eq 0 ]]; then
        echo "$1"
        else
        echo "$2"
    fi
}

INST_YN="${INST_YN:=y}"
CFG_YN="${CFG_YN:=y}"
DB_FILTER="${DB_FILTER:= .*}"
NFS_RESTART_YN="${NFS_RESTART_YN:=y}"
EMAIL="${EMAIL:=w.hulshof@magnus.nl}"
USER="${USER:=voodoo}"
PG_VERSION="${PG_VERSION:=9.6}"

IFS=","
COUNTERDEV=0
COUNTERPASS=0
COUNTERIP=0
for DEVELOPER in $DEVELOPERS
do
  COUNTERDEV=$((COUNTER + 1))
  for DEVELOPER_PASSWD in $DEVELOPER_PASSWDS
  do
    COUNTERPASS=$((COUNTERPASS + 1))
    for DEVELOPER_IP in $DEVELOPER_IPS
    do
      COUNTERIP=$((COUNTERPASS + 1))
## START OF LOOP
HOST_BASE=${DEVELOPER}/${BASE}
BASE_DEV=${BASE}-${DEVELOPER}
HOST=${BASE_DEV}.vd
BASEDB_DEV=`echo "$BASEDBS" | sed -E 's/([^,]+)/\1\'${DEVELOPER}'/g'`

# postres user role add
  # check if ROLE is already present in postgres
RESULT=$(docker run  --rm -v /home/voodoo/base/.db/socket:/var/run/postgresql/ -e PGPASSWORD=magnuscolors postgres:${PG_VERSION} psql -U postgres -t -c "SELECT usename
 FROM pg_user
 where usename = 'odoo"${DEVELOPER}"';"
)
if [[ $RESULT = "" ]]
then
  docker run  --rm -v /home/voodoo/base/.db/socket:/var/run/postgresql/ -e PGPASSWORD=magnuscolors postgres:${PG_VERSION} psql -U postgres -t -c "CREATE ROLE odoo"${DEVELOPER}" SUPERUSER CREATEDB CREATEROLE LOGIN REPLICATION BYPASSRLS PASSWORD '"${DEVELOPER_PASSWD}"';"
  check_exec_ok "odoo"${DEVELOPER}" added as ROLE" "odoo"${DEVELOPER}" NOT added as ROLE"
else
  echo "ROLE odoo"${DEVELOPER}" already exists. Nothing done"
fi

# Instance/db creation
if [[ $INST_YN =~ [yY](es)* ]]
then
    su $USER sh -c "mkdir -p /home/voodoo/${BASE_DEV} /home/voodoo/filestore/${HOST_BASE}/ /home/voodoo/parts/${HOST_BASE}/"
    sudo rsync -a --exclude=.db/ /home/voodoo/base/ /home/voodoo/${BASE_DEV}
    check_exec_ok "${BASE_DEV} copied" "${BASE_DEV} NOT copied"
    sudo rm /home/voodoo/${BASE_DEV}/docker-compose.yml
    sudo mv /home/voodoo/${BASE_DEV}/odoo.docker-compose.yml /home/voodoo/${BASE_DEV}/docker-compose.yml
    check_exec_ok "docker-compose.yml copied" "docker-compose.yml NOT copied"
    sudo rsync -a /home/voodoo/filestore/base/${BASE}/ /home/voodoo/filestore/${HOST_BASE}
    check_exec_ok "/home/voodoo/filestore/${HOST_BASE} copied" "/home/voodoo/filestore/${HOST_BASE} NOT copied"
    sudo rsync -a /home/voodoo/parts/base/${BASE}/ /home/voodoo/parts/${HOST_BASE}
    check_exec_ok "/home/voodoo/parts/${HOST_BASE} copied" "/home/voodoo/parts/${HOST_BASE} NOT copied"
    sudo rsync -a /home/voodoo/odooconfig/${BASE}/etc /home/voodoo/${BASE_DEV}/
    check_exec_ok "${BASE}/etc/odoo.cfg gekopieerd naar /home/voodoo/${BASE_DEV}/etc/odoo.cfg" "${BASE}/etc/odoo.cfg NIET gekopieerd naar /home/voodoo/${BASE_DEV}/etc/odoo.cfg"
    IFS=","
    for DB in $BASEDBS
    do
      sudo mv  /home/voodoo/filestore/"${HOST_BASE}"/filestore/"$DB" /home/voodoo/filestore/"${HOST_BASE}"/filestore/"${DB}${DEVELOPER}"
      check_exec_ok "filestore/$DB renamed to filestore/${DB}${DEVELOPER}" "filestore/$DB NOT renamed to filestore/${DB}${DEVELOPER}"
      docker run  --rm -v /home/voodoo/base/.db/socket:/var/run/postgresql/ -e PGPASSWORD=magnuscolors postgres:${PG_VERSION} createdb -U postgres -O odoo${DEVELOPER} -T ${DB} ${DB}${DEVELOPER}
      check_exec_ok "databse ${DB}${DEVELOPER} created with odoo${DEVELOPER} as owner" "databse ${DB}${DEVELOPER} NOT created with odoo${DEVELOPER} as owner"
    done
fi

# odoo.cfg
if [[ $CFG_YN =~ [yY](es)* ]]
then
    sudo sh -c "sed -i 's/\(db_name =\).*$/\1 ${BASEDB_DEV}/' /home/voodoo/${BASE_DEV}/etc/odoo.cfg"
    sudo sh -c "sed -i 's/\(db_password =\).*$/\1 ${DEVELOPER_PASSWD}/' /home/voodoo/${BASE_DEV}/etc/odoo.cfg"
    sudo sh -c "sed -i 's/\(db_user =\).*$/\1 odoo${DEVELOPER}/' /home/voodoo/${BASE_DEV}/etc/odoo.cfg"
    sudo sh -c "sed -i 's/\(dbfilter =\).*$/\1 ${DB_FILTER}/' /home/voodoo/${BASE_DEV}/etc/odoo.cfg"
    check_exec_ok "db_name = ${BASEDB_DEV}, db_password = ${DEVELOPER_PASSWD}, db_user = odoo${DEVELOPER}, dbfilter = ${DB_FILTER} set in odoo.cfg" "odoo.cfg NOT correctly set"
fi

# .env file always gets overwritten again
su $USER sh -c "printf 'HOST="${BASE_DEV}".vd\nHOST_BASE="${HOST_BASE}"' > /home/voodoo/"${BASE_DEV}"/.env"
check_exec_ok "HOST="${BASE_DEV}".vd and HOST_BASE="${HOST_BASE}" set in .env" ".env NOT correctly set"

# adapt exports.txt for nfs-server and restart it
if [[ $NFS_RESTART_YN =~ [yY](es)* ]]
then
    sudo sh -c "grep -q "^/data1/"${DEVELOPER}"" /opt/nfs-server/exports.txt && sed 's/^\/data1\/"${DEVELOPER}".*/\/data1\/"${DEVELOPER}" 10.147.18.118\(rw,anonuid=1000,anongid=1000,sync,all_squash\) 10.147.18.124\(rw,anonuid=1000,anongid=1000,sync,all_squash\) "${DEVELOPER_IP}"\(rw,anonuid=1000,anongid=1000,sync,all_squash\)/' -i /opt/nfs-server/exports.txt ||
    sed '$ a\\/data1\/"${DEVELOPER}" 10.147.18.118/\(rw,anonuid=1000,anongid=1000,sync,all_squash\) 10.147.18.124\(rw,anonuid=1000,anongid=1000,sync,all_squash\) "${DEVELOPER_IP}"\(rw,anonuid=1000,anongid=1000,sync,all_squash\)' -i /opt/nfs-server/exports.txt"
    check_exec_ok "/data1/"${DEVELOPER}" and "${DEVELOPER_IP}" set in exports.txt" "exports.txt NOT correctly set"
fi

done
## END OF LOOP

if [[ $NFS_RESTART_YN =~ [yY](es)* ]]
then
    cd /opt/nfs-server
    docker-compose restart
    cd -
fi