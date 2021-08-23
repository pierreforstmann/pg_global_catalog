--
-- test0.sql
--
-- NB: main database name and superuser name are hard-coded 
--
--
\t on
select '\c ' || current_database();
\g connect.sql
\t off
--
create extension postgres_fdw;
--
drop database db1;
drop database db2;
drop database db3;
create database db1;
create database db2;
create database db3;
--
\! (./setup.sh)
--
\c db1 
create table t1a(x int);
create table t1b(x int);
create table t1c(x int);
create table t1d(x int);
\c db2
create table t2a(x int);
create table t2b(x int);
create table t2c(x int);
\c db3
create table t3a(x int);
create table t3b(x int);
create table t3c(x int);
--
\i connect.sql
--
select
datname, relname
from 
global_catalog.pg_class c
join pg_database d
on c.dbid = d.oid
where relname like 't1%' or relname like 't2%' or relname like 't3%'
order by datname, relname;
--
