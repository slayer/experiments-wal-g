include env

DC_EXEC = docker-compose exec
DC = docker-compose

init:
	mkdir -p ./shared && chmod a+rw ./shared
	# start databases and minio
	$(MAKE) up

	sleep 3
	docker-compose exec pg1 mc alias set minio http://minio:9000 $(MINIO_ACCESS_KEY) $(MINIO_SECRET_KEY)
	docker-compose exec pg1 mc mb minio/pg1 || true
	docker-compose exec pg1 mc ls minio/pg1

pg2-replica-slave-setup:
	$(DC_EXEC) pg1 psql -c "CREATE ROLE replication REPLICATION LOGIN PASSWORD '1234';"
	$(DC) stop pg2
	$(DC) rm -f pg2
	$(DC) run --rm pg2 sh -c 'rm -r /var/lib/postgresql/data/*'
	$(DC) run --rm pg2 ls -l /var/lib/postgresql/data/
	$(DC) run --rm pg2 pg_basebackup -h pg1 -D /var/lib/postgresql/data/ -P -U replication --wal-method=stream
	$(DC) run --rm pg2 cp /etc/postgresql/pg2-recovery.conf /var/lib/postgresql/data/recovery.conf
	$(DC) up -d pg2

pg2-logical-slave-setup:
	$(DC_EXEC) pg1 psql -c "CREATE ROLE replication REPLICATION LOGIN PASSWORD '1234';"
	$(DC_EXEC) pg1 psql -c "CREATE PUBLICATION slave_pub FOR ALL TABLES;"
	$(DC_EXEC) pg2 psql -c "CREATE SUBSCRIPTION slave_sub CONNECTION 'host=pg1 dbname=app user=replication password=1234' PUBLICATION slave_pub;"

pgbench-init-small:
	$(DC_EXEC) -e PGPASSWORD=$(POSTGRES_PASSWORD) pg1 pgbench -U$(POSTGRES_USER) -i -s2

pgbench-init:
	$(DC_EXEC) -e PGPASSWORD=$(POSTGRES_PASSWORD) pg1 pgbench -U$(POSTGRES_USER) -i -s50

pgbench-init-big:
	$(DC_EXEC) -e PGPASSWORD=$(POSTGRES_PASSWORD) pg1 pgbench -U$(POSTGRES_USER) -i -s500

sh:
	docker-compose exec pg1 bash

pg1-sh:
	docker-compose exec pg1 bash
pg1-psql:
	docker-compose exec pg1 psql
pg1-stat:
	$(DC_EXEC) pg1 psql -c "SELECT * FROM pg_stat_activity WHERE usename = 'replication';"

pg2-sh:
	docker-compose exec pg2 bash
pg2-psql:
	docker-compose exec pg2 psql



WALG_ENVS = -e AWS_ENDPOINT=$(AWS_ENDPOINT) -e WALG_S3_PREFIX=$(WALG_S3_PREFIX)


backup-full:
	docker-compose exec pg1 /opt/wg/walg-pg backup-push /var/lib/postgresql/data/ -f

backup:
	docker-compose exec $(WALG_ENVS) pg1 wal-g --pguser=app backup-push /var/lib/postgresql/data/

backup-list:
	@$(DC_EXEC) $(WALG_ENVS) pg1 wal-g --pguser=app backup-list --detail

pg2-backup-restore:
	/var/lib/postgresql/walg-pg backup-fetch /var/lib/postgresql/data/ LATEST

backup-fetch:
	$(DC_EXEC) $(WALG_ENVS) pg2 wal-g --pguser=app backup-fetch /var/lib/postgresql/data/ LATEST

#  wal-fetch     Fetches a WAL file from storage
#  wal-push      Uploads a WAL file to storage

clean: down
	sudo rm -rf pg1 pg2 shared
	sudo rm -rf minio

build:
	docker-compose build

run-rm:
	docker run --rm -it wal-g_pg1 bash

up:
	docker-compose up -d --remove-orphans
down:
	docker-compose down -v
logs:
	docker-compose logs -f --tail=100
ps:
	docker-compose ps
