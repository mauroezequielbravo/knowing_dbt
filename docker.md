## Docker

### Comandos que use para crear el proyecto en Windows
```bash
# En desarrollo (con herramientas extra)
# docker build --build-arg ENVIRONMENT=development -t my-airflow:dev .

# verificar las variables actuales en PS
Write-Output "BUILD_ENV: $($env:BUILD_ENV)"
Write-Output "TAG: $($env:TAG)"

# set BUILD_ENV=development => en CMD
$env:BUILD_ENV = "development" # En PS
# set TAG=dev => en CMD
$env:TAG = "dev" # En PS
docker-compose up -d --build
# podman compose -f .\docker-compose.yml up -d --build

# En produccion 
# docker build -t my-airflow:prod .
#  Para producción (o omitir las variables para usar valores por defecto):
set BUILD_ENV=production
set TAG=prod
docker-compose up -d --build

cd .\dbt\
# Crea el proyecto dbt dentro `dbt/`
docker-compose exec dbt dbt init knowing_dbt
# Enter a number: 1
# host (hostname for the instance): postgres
# port [5432]: 5432
# user (dev username): airflow
# pass (dev password): airflow
# dbname (default database that dbt will build objects in): DB_Examples
# schema (default schema that dbt will build objects in): public
# threads (1 or more) [1]: 2
```

### Iniciar contenedores en Windows con powershell
```bash
docker compose up -d
# Esto es por un error que me dio con la libreria protobuf
docker-compose exec dbt pip install --upgrade "protobuf>=5.0,<6.0" dbt-core==1.9.0 dbt-postgres==1.9.0
docker-compose exec dbt dbt seed --project-dir=/usr/app/knowing_dbt
docker-compose exec dbt dbt run --select staging --project-dir=/usr/app/knowing_dbt
docker-compose exec dbt dbt run --select intermediate --project-dir=/usr/app/knowing_dbt
docker-compose exec dbt dbt run --select marts --project-dir=/usr/app/knowing_dbt
docker-compose exec dbt dbt run --select analyses --project-dir=/usr/app/knowing_dbt
```