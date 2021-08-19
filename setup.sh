#!/bin/bash
#
# setup.sh
#
# pg_global_catalog setup script
#
# Script must be run on machine hosting PG instance where pg_global_catalog is going
# to be installed.
#
# Script requires: 
# - extension postgres_fdw must be installed in default database
# - TCP/IP access needed to create FDW servers
# - passwordless superuser access by current Linux user
# - current Linux user must have an associated database with same name
# - current Linux user must have password file ~./.pgpass.
#
# Copyright 2021 Pierre Forstmann
# ----------------------------------------------------------------------------------
#
# check .pgpass
#
if [ ! -f $HOME/.pgpass ]
then
 echo "Cannot find assword file $HOME/.pgpass" 
 exit 1
else
 echo "Password file $HOME/.pgpass found."
fi
#
# check passwordless access
#
psql -c '\l' >/dev/null 2>&1
RC=$?
if [ $RC -ne 0 ]
then
 echo "Cannot connect to PostgreSQL instance without password."
 exit 1
else 
 echo "Can connect to PostgreSQL instance without password."
fi
#
# check superuser
#
TMP=/tmp/setup.$$.log
psql -c 'select rolname from pg_roles where rolname=current_user and rolsuper' | grep $LOGNAME  > $TMP 2>&1
RC=$?
if [ $RC -ne 0 ]
then
  echo "Unix account $LOGNAME is not superuser."
  exit 1
else
 echo "Unix account $LOGNAME is superuser."
fi
#  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#  no need to set PGDATA/PGHOST/PGPORT, instance must be configured
#  to accept local Unix-domain socket ("local" entry in pg_hba.conf)
#  for first SQL scripts *but* TCP/IP connection needed for FDW
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
# create schema local_catalog in each database except template0 and template1
#
for DB in $(psql -t -c "select datname from pg_database where datname not like 'template%'")
do
  echo "=> $DB"
  psql $DB -f pg_global_catalog-local--0.0.1.sql
  RC=$?
  if [ $RC -ne 0 ]
  then
   echo "local_catalog schema creation failed in database $DB"
   exit 1
 fi
done
#  no need to set PGDATA/PGHOST/PGPORT, instance must be configured
#  to accept local Unix-domain socket ("local" entry in pg_hba.conf)
#  for first SQL scripts *but* TCP/IP connection needed for FDW
#
# create schema global_catalog in default database 
#
psql -f pg_global_catalog--0.0.1.sql
RC=$?
if [ $RC -ne 0 ]
 then
  echo "global_catalog schema creation failed"
  exit 1
fi
#
echo "pg_global_catalog successfully installed."
exit 0
