include env

DC_EXEC = docker-compose exec

init:
	# start databases and minio
	docker-compose up -d --remove-orphans

	sleep 3
	docker-compose exec pg1 mc alias set minio http://minio:9000 $(MINIO_ACCESS_KEY) $(MINIO_SECRET_KEY)
	docker-compose exec pg1 mc mb minio/pg1 || true
	docker-compose exec pg1 mc ls minio/pg1

	# update config
	docker cp image/pg1-postgresql.conf wal-g_pg1_1:/var/lib/postgresql/data/postgresql.conf
	docker-compose restart pg1

	# create test database
	sleep 5
	$(MAKE) pgbench-init


pgbench-init:
	docker-compose exec -e PGPASSWORD=$(POSTGRES_PASSWORD) pg1 pgbench -U$(POSTGRES_USER) -i -s5

pgbench-init500:
	docker-compose exec -e PGPASSWORD=$(POSTGRES_PASSWORD) pg1 pgbench -U$(POSTGRES_USER) -i -s500

sh:
	docker-compose exec pg1 bash

pg1-sh:
	docker-compose exec pg1 bash

pg2-sh:
	docker-compose exec pg2 bash

pg2-restore:
	/var/lib/postgresql/walg-postgresql backup-fetch /pgdata/10/main LATEST




WALG_ENVS = -e AWS_ENDPOINT=$(AWS_ENDPOINT) -e WALG_S3_PREFIX=$(WALG_S3_PREFIX)


backup-full:
	docker-compose exec pg1 /opt/wg/walg-pg backup-push /var/lib/postgresql/data/ -f

backup:
	docker-compose exec $(WALG_ENVS) pg1 wal-g --pguser=app backup-push /var/lib/postgresql/data/

backup-list:
	@$(DC_EXEC) $(WALG_ENVS) pg1 wal-g --pguser=app backup-list --detail

LATEST_BACKUP = $(shell $(MAKE) backup-list | tail -n1 | cut -f1 -d' ')

backup-fetch:
	$(DC_EXEC) $(WALG_ENVS) pg2 wal-g --pguser=app backup-fetch /var/lib/postgresql/data/ LATEST

#  wal-fetch     Fetches a WAL file from storage
#  wal-push      Uploads a WAL file to storage

down:
	docker-compose down -v

clean: down
	sudo rm -rf pg1 pg2
	sudo rm -rf minio

build:
	docker-compose build
