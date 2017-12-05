#!/bin/bash

# Load Env
export PGPORT=5432
export PGHOST=127.0.0.1
export PGUSER=clustercheck
export PGDBNAME=clustercheck
export PGDATA=/data/9.6
export LANG=en_US.utf8
export PATH=$PATH:/usr/pgsql-9.6/bin

MONITOR_LOG="/tmp/pg_monitor.log"
SQL1="update cluster_status set last_alive = now();"
SQL2='select 1;'

# check if db is master or standby
standby_flg=`psql -p $PGPORT -h $PGHOST -U postgres -At -c "select pg_is_in_recovery();"`
if [[ ${standby_flg} == 't' ]]; then
    echo -e "`date +%F\ %T`: This is a standby database, exit!\n" >> $MONITOR_LOG
    exit 0
fi

# update pgsql log
echo $SQL1 | psql -At -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDBNAME >> $MONITOR_LOG


# check if db is writable
echo $SQL2 | psql -At -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDBNAME
if [ $? -eq 0 ]; then
   echo -e "`date +%F\ %T`:  Primary db is healthy."  >> $MONITOR_LOG
   exit 0
else
   echo -e "`date +%F\ %T`:  Attention: Primary db is not healthy!" >> $MONITOR_LOG
   exit 1
fi