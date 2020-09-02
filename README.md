# Postgres experiments

## Requirements

- docker
- docker-compose
- make
- luck

## WAL-G backup:

- `make clean init`
- `make pg1-pgbench-init` or `make pg1-pgbench-init-big` for larger database
- `make backup-full`
- `make backup-list`


## Physical Replication:

- `make clean init`
- `make pg1-pgbench-init` or `make pg1-pgbench-init-big` for larger database
- `make pg2-replica-slave-setup`
- `make pg1-pgbench-init` again

## Logical Replication:

- `make clean init`
- `make pg1-pgbench-init` or `make pg1-pgbench-init-big` for larger database
- `make pg2-logical-slave-setup`
- `make pg1-pgbench-init` again (will fail, no DDL support)


## Useful commands

- `make up`, `make down`
- `make logs`, `make ps`
- `make pg1-sh`, `make pg2-sh`
- `make pg1-psql`, `make pg2-psql`
- `make pg1-stat`
- `make pg1-replication-stat`, `make pg2-replication-stat`


## Useful links

- https://pgdash.io/blog/monitoring-postgres-replication.html