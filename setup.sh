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
# - passwordless superuser access by current Linux user
# - current Linux user must have an associated database with same name
# - current Linux user must have password file ~./.pgpass.
# - extension postgres_fdw must be installed in default database
#
# This script requires connection:
# 1. via Unix-domain socket for some SQL scripts:
# it is assumed that current PG instance can be accessed with default Unix-domain
# socket and default port number on local host (if this is not the case socket name and
# port number must be specified with PGHOST and PGPORT environement variables)
#
# 2. with TCP/IP to create FDW servers: host name and port number are retrieved
# from listen_addresses and port parameters.
#
#
# Copyright 2021 Pierre Forstmann
# ----------------------------------------------------------------------------------
#
function check_rc ()
{
	if [ $1 = 127 ]
	then
		echo "Cannot find psql"
		return 1
	elif [ $1 = 2 ]
	then
		echo "Cannot connect to PostgreSQL"
		return 1
	elif  [ $1 != 0 ]
	then
		echo "Error in SQL statement run by psql"
		return 1
	else
		return 0
	fi
}
#
# check .pgpass
#
if [ ! -f $HOME/.pgpass ]
then
 echo "Cannot find password file $HOME/.pgpass" 
 exit 1
else
 echo "Password file $HOME/.pgpass found."
fi
#
# check passwordless access
#
psql -w -c '\l' >/dev/null 2>&1
RC1=$?
check_rc $RC1
RC2=$?
if [ $RC2 -ne 0 ]
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
psql -wtc 'select rolname from pg_roles where rolname=current_user and rolsuper' | grep $LOGNAME  > $TMP 2>&1
RC1=$?
check_rc $RC1
RC2=$?
if [ $RC2 -ne 0 ]
then
  echo "Unix account $LOGNAME is not superuser."
  exit 1
else
 echo "Unix account $LOGNAME is superuser in current instance."
fi
#
# create schema local_catalog in each database except template0 and template1
#
for DB in $(psql -t -c "select datname from pg_database where datname not like 'template%'")
do
  echo "=> current database is $DB"
  psql $DB -b -f pg_global_catalog-local--0.0.1.sql
  RC1=$?
  check_rc $RC1
  RC2=$?
  if [ $RC2 -ne 0 ]
  then
   echo "local_catalog schema creation failed in database $DB."
   exit 1
  else
   echo "local_catalog schema created in database $DB."
  fi
done
#
# create schema global_catalog in default database 
#
echo "=> current database is $LOGNAME"
psql -f pg_global_catalog--0.0.1.sql
RC1=$?
check_rc $RC1
RC2=$?
if [ $RC2 -ne 0 ]
 then
  echo "global_catalog schema creation failed."
  exit 1
 else
  echo "global_catalog schema created in database $LOGNAME."
fi
#
echo ""
echo "pg_global_catalog successfully installed."
exit 0
