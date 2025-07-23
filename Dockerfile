# Stage 1: Builder - Para dependencias de compilación
FROM apache/airflow:2.8.1 AS builder

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER airflow
RUN pip install --user --no-cache-dir \
    polars \
    adbc-driver-postgresql \
    adbc-driver-manager \
    psycopg2-binary

# Stage 2: Runtime - Imagen final optimizada
FROM apache/airflow:2.8.1

# Temporalmente cambia a root para instalaciones
USER root

# Instala herramientas de desarrollo solo si es necesario
ARG ENVIRONMENT=production
RUN if [ "$ENVIRONMENT" = "development" ] ; then \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    vim \
    net-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* ; \
    fi

# Copia las dependencias de Python (como root)
COPY --from=builder --chown=airflow:root /home/airflow/.local /home/airflow/.local

# Vuelve al usuario airflow para seguridad
USER airflow
ENV PATH="/home/airflow/.local/bin:${PATH}"