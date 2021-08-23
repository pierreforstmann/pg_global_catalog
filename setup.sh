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
# 2. via TCP/IP to create FDW servers: host name and port number are retrieved
# from listen_addresses and port parameters.
#
#
# Copyright 2021 Pierre Forstmann
# ----------------------------------------------------------------------------------
#
function check_rc ()
{
	if [ $1 -eq 127 ]
	then
		echo "ERROR: cannot find psql."
		return 1
	elif [ $1 -eq 2 ]
	then
		echo "ERROR: cannot connect to PostgreSQL."
		return 1
	elif  [ $1 -ne 0 ]
	then
		echo "ERROR in SQL statement run by psql."
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
 echo "ERROR: cannot find password file $HOME/.pgpass" 
 exit 1
else
 echo "Password file $HOME/.pgpass found: OK."
fi
#
# check passwordless access:
#
# - via Unix-domain socket
# 
psql -w -c '\l' >/dev/null 2>&1
RC1=$?
check_rc $RC1
RC2=$?
if [ $RC2 -ne 0 ]
then
 echo "ERROR: cannot connect to PostgreSQL instance without password."
 exit 1
else 
 echo "Can connect locally to PostgreSQL instance without password: OK."
fi
#
# - via TCP/IP
#
#
#  retrieve instance port
#
TMP=/tmp/setup.$$.log
psql -Awtc 'show port' > $TMP 2>&1
RC1=$?
check_rc $RC1
RC2=$?
if [ $RC2 -eq 0 ]
then
  LN=$(wc -l $TMP | cut -f1 -d ' ') 
  if [ $LN -eq 1 ]
  then
   PORT=$(cat $TMP)
   rm $TMP
   echo "Instance port number: $PORT"
  else
   echo "ERROR: cannot retrieve instance port"
   exit 1
  fi
else 
 echo "ERROR in port check"
 exit 1
fi
#
# retrieve first hostname from instance listener_addresses parameter
#
TMP=/tmp/setup.$$.log
psql -Awtc 'show listen_addresses' > $TMP 2>&1
RC1=$?
check_rc $RC1
RC2=$?
if [ $RC2 -eq 0 ]
then
  LN=$(wc -l $TMP | cut -f1 -d ' ')
  if [ $LN -eq 1 ]
  then
   HOST=$(cat $TMP | cut -f1 -d ' ')
   rm $TMP
   echo "First host in listen_addresses parameter: $HOST"
  else
   echo "ERROR: cannot retrieve instance listen_addresses"
   exit 1
  fi
else
 echo "ERROR in listen_addresses check"
 exit 1
fi
#
psql -Awtc '\l+' -h $HOST -p $PORT >/dev/null 2>&1
RC1=$?
check_rc $RC1
RC2=$?
if [ $RC2 -ne 0 ]
then
 echo "ERROR: cannot connect via TCP/IP to PostgreSQL instance without password."
 exit 1
else
 echo "Can connect via TCP/IP to PostgreSQL instance without password: OK."
fi
#
#
# check superuser
#
TMP=/tmp/setup.$$.log
psql -Awtc 'select rolname from pg_roles where rolname=current_user and rolsuper' > $TMP 2>&1
RC1=$?
check_rc $RC1
RC2=$?
if [ $RC2 -eq 0 ]
then
  LN=$(wc -l $TMP | cut -f1 -d ' ') 
  if [ $LN -eq 1 ]
  then
    echo "Linux account $LOGNAME is superuser in current instance: OK."
    rm $TMP
  else
    echo "ERROR: Linux account $LOGNAME is not superuser in current instance."
    exit 1
  fi
else
 echo "ERROR in superuser check."
 exit 1
fi
#
# check postgres_fdw
#
TMP=/tmp/setup.$$.log
psql -Awtc '\dx postgres_fdw' > $TMP 2>&1
RC1=$?
check_rc $RC1
RC2=$?
if [ $RC2 -eq 0 ]
then
  LN=$(wc -l $TMP | cut -f1 -d ' ') 
  if [ $LN -eq 1 ]
  then
    echo "Extension postgres_fdw found in current instance database $LOGNAME: OK."
    rm $TMP
  else
    echo "ERROR: Extension postgres_fdw not found in current instance database $LOGNAME."
    exit 1
  fi
else
 echo "ERROR in postgres_fdw check."
 exit 1
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
   echo "ERROR: local_catalog schema creation failed in database $DB."
   exit 1
  else
   echo "local_catalog schema created in database $DB: OK."
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
  echo "ERROR: global_catalog schema creation failed."
  exit 1
 else
  echo "global_catalog schema created in database $LOGNAME: OK"
fi
#
echo ""
echo "pg_global_catalog successfully installed."
echo ""
exit 0
