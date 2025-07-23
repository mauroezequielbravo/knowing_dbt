# 🎯 Ejercicios Unificados de dbt-core

## 📋 Descripción General

Este conjunto de ejercicios te guiará a través de un flujo completo de desarrollo en dbt-core, desde la limpieza de datos brutos hasta la construcción de un modelo dimensional completo. Los ejercicios están diseñados para ser ejecutados secuencialmente, construyendo sobre el trabajo anterior.

## 🏗️ Arquitectura del Proyecto

```
dbt/knowing_dbt/
├── models/
│   ├── staging/          # Ejercicio 1: Limpieza de datos
│   │   ├── stg_customers.sql
│   │   ├── stg_products.sql
│   │   └── stg_orders.sql
│   ├── intermediate/     # Ejercicio 3: Preparación para marts
│   │   └── int_orders_enriched.sql
│   └── marts/           # Ejercicios 2 & 3: Modelos finales
│       ├── fct_orders_incremental.sql
│       ├── fact_orders.sql
│       ├── dim_customers.sql
│       ├── dim_products.sql
│       └── dim_date.sql
├── seeds/               # Datos de entrada
│   ├── raw_customers.csv
│   ├── raw_products.csv
│   ├── raw_orders.csv
│   └── raw_orders_updates.csv
└── tests/               # Tests adicionales
```

## 📊 Dataset Unificado

### Archivos de Datos
- **`raw_customers.csv`**: 6 clientes con problemas de calidad de datos
- **`raw_products.csv`**: 8 productos con inconsistencias
- **`raw_orders.csv`**: 8 pedidos iniciales con referencias inválidas
- **`raw_orders_updates.csv`**: 4 actualizaciones para el ejercicio incremental

### Problemas de Calidad Incluidos
- Emails inválidos y nulos
- Precios nulos en productos
- Referencias a clientes inexistentes
- Estados de pedidos inconsistentes
- Formatos de datos no estandarizados

## 🎯 Flujo de Ejercicios

### 📝 Ejercicio 1: Modelos Staging
**Objetivo**: Limpiar y estandarizar datos brutos
- Crear modelos staging con validaciones
- Implementar tests de calidad de datos
- Establecer base sólida para ejercicios posteriores

**Archivo**: `1.-Staging_Models.md`

### ⚡ Ejercicio 2: Modelos Incrementales
**Objetivo**: Optimizar procesamiento de datos
- Crear modelo incremental basado en `last_updated`
- Manejar actualizaciones eficientemente
- Evitar reprocesar datos históricos

**Archivo**: `2.-Incremental_Models.md`

### ⭐ Ejercicio 3: Modelo Estrella
**Objetivo**: Construir arquitectura dimensional completa
- Crear dimensiones y tabla de hechos
- Implementar modelo estrella
- Agregar métricas y documentación completa

**Archivo**: `3.-Star_Schema.md`

## 🚀 Configuración Inicial

### 1. Preparar el Entorno
```bash
# Navegar al directorio del proyecto
cd /path/to/knowing_dbt

# Verificar que Docker esté corriendo
docker-compose up -d
```

### 2. Configurar dbt
```bash
# Verificar conexión a la base de datos
docker-compose exec dbt dbt debug --project-dir=/usr/app/knowing_dbt
```

### 3. Cargar Datos Iniciales
```bash
# Cargar todos los archivos CSV
docker-compose exec dbt dbt seed --project-dir=/usr/app/knowing_dbt
```

## 📈 Progresión de Aprendizaje

### Nivel Básico (Ejercicio 1)
- ✅ Comprensión de modelos staging
- ✅ Tests básicos de dbt
- ✅ Limpieza de datos
- ✅ Validaciones de calidad

### Nivel Intermedio (Ejercicio 2)
- ✅ Modelos incrementales
- ✅ Optimización de rendimiento
- ✅ Manejo de actualizaciones
- ✅ Configuración avanzada

### Nivel Avanzado (Ejercicio 3)
- ✅ Arquitectura dimensional
- ✅ Modelo estrella
- ✅ Métricas agregadas
- ✅ Documentación completa

## 🔧 Comandos Útiles

### Desarrollo
```bash
# Ejecutar modelos específicos
docker-compose exec dbt dbt run --models staging --project-dir=/usr/app/knowing_dbt
docker-compose exec dbt dbt run --models marts --project-dir=/usr/app/knowing_dbt

# Ejecutar tests
docker-compose exec dbt dbt test --project-dir=/usr/app/knowing_dbt

# Generar documentación
docker-compose exec dbt dbt docs generate --project-dir=/usr/app/knowing_dbt
docker-compose exec dbt dbt docs serve --project-dir=/usr/app/knowing_dbt
```

### Debugging
```bash
# Verificar sintaxis
docker-compose exec dbt dbt parse --project-dir=/usr/app/knowing_dbt

# Ver dependencias
docker-compose exec dbt dbt list --project-dir=/usr/app/knowing_dbt

# Limpiar cache
docker-compose exec dbt dbt clean --project-dir=/usr/app/knowing_dbt
```

## 📚 Recursos Adicionales

### Documentación Oficial
- [dbt Core Documentation](https://docs.getdbt.com/)
- [dbt Testing](https://docs.getdbt.com/docs/build/tests)
- [dbt Incremental Models](https://docs.getdbt.com/docs/build/incremental-models)

### Conceptos Clave
- **Data Quality**: Validación y limpieza de datos
- **Incremental Processing**: Procesamiento eficiente de datos
- **Dimensional Modeling**: Arquitectura para análisis
- **Testing**: Asegurar calidad y consistencia

## 🎓 Resultados Esperados

Al completar todos los ejercicios, tendrás:
- ✅ Un pipeline completo de datos en dbt
- ✅ Modelos bien estructurados y documentados
- ✅ Tests robustos para validar calidad
- ✅ Arquitectura escalable para análisis
- ✅ Experiencia práctica con casos reales

## 🤝 Contribuciones

Estos ejercicios están diseñados para aprendizaje. Si encuentras errores o tienes sugerencias de mejora, no dudes en contribuir.

---

**¡Disfruta aprendiendo dbt! 🚀** 