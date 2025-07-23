#!/bin/bash
set -e

# Esperar a que la base de datos esté lista
echo "Esperando a que la base de datos esté lista..."
while ! pg_isready -h postgres -p 5432 -U airflow; do
  sleep 2
done

echo "Base de datos lista."

# Inicializar la base de datos de Airflow (usar migrate para evitar warning)
airflow db migrate

# Crear usuario admin si no existe
airflow users create \
    --username admin \
    --password admin \
    --firstname Admin \
    --lastname User \
    --role Admin \
    --email admin@example.com || true

# Instalar dbt-postgres
pip install dbt-postgres

# Eliminar PID viejo si existe
rm -f /opt/airflow/airflow-webserver.pid

# Iniciar webserver y scheduler
airflow webserver &
airflow scheduler 