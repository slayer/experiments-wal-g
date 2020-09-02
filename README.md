# wal-g experiments

## Backup:

- `make clean init`
- `make pgbench-init` or `make pgbench-init-big` for larger database
- `make backup-full`
- `make backup-list`


## Replication:

- `make clean init`
- `make pgbench-init` or `make pgbench-init-big` for larger database
- `make pg2-replica-slave-setup`
- `make pgbench-init` again