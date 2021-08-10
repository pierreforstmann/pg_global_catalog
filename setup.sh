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
# - passwordless superuser access by current Linux user
# - PGDATA must be set (PGPORT is needed if PG instance port is different from 5432)
# - current Linux user must have an associated database with same name
# - current Linux user must have password file ~./.pgpass.
#
# Copyright 2021 Pierre Forstmann
# ----------------------------------------------------------------------------------
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
