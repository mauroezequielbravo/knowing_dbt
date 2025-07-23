# 📝 Resoluciones de Ejercicios - dbt-core

## 🎯 Ejercicio 1: Modelos Staging

### stg_customers.sql
```sql
SELECT 
    customer_id,
    INITCAP(LOWER(TRIM(customer_name))) as customer_name,
    CASE 
        WHEN email IS NULL THEN 'no-email@placeholder.com'
        WHEN email NOT LIKE '%@%' THEN CONCAT(email, '@placeholder.com')
        ELSE email 
    END as email,
    TRIM(address) as address,
    join_date,
    created_at,
    updated_at
FROM {{ ref('raw_customers') }}
WHERE customer_id IS NOT NULL
```

### stg_products.sql
```sql
SELECT 
    product_id,
    INITCAP(LOWER(TRIM(product_name))) as product_name,
    CASE 
        WHEN price IS NULL THEN 0.00
        ELSE price 
    END as price,
    CASE 
        WHEN category = 'Electronics' THEN 'Electrónica'
        ELSE INITCAP(LOWER(TRIM(category)))
    END as category,
    created_at
FROM {{ ref('raw_products') }}
WHERE product_id IS NOT NULL
```

### stg_orders.sql
```sql
SELECT 
    order_id,
    customer_id,
    product_id,
    order_date,
    quantity,
    unit_price,
    quantity * unit_price as total_amount,
    CASE 
        WHEN status = 'pending' THEN 'pendiente'
        WHEN status = 'shipped' THEN 'enviado'
        WHEN status = 'delivered' THEN 'entregado'
        WHEN status = 'cancelled' THEN 'cancelado'
        ELSE LOWER(TRIM(status))
    END as status,
    last_updated
FROM {{ ref('raw_orders') }}
WHERE order_id IS NOT NULL
  AND customer_id IN (SELECT customer_id FROM {{ ref('stg_customers') }})
  AND product_id IN (SELECT product_id FROM {{ ref('stg_products') }})
```

### schema.yml para Staging
```yaml
version: 2

models:
  - name: stg_customers
    description: "Datos de clientes limpios y estandarizados"
    columns:
      - name: customer_id
        description: "Identificador único del cliente"
        tests:
          - not_null
          - unique
      - name: email
        description: "Email del cliente (validado)"
        tests:
          - custom:
              name: valid_email
              description: "Email debe contener @"
              sql: "email like '%@%'"
      - name: customer_name
        description: "Nombre del cliente estandarizado"
        tests:
          - custom:
              name: proper_case_name
              description: "Nombre debe estar en formato título"
              sql: "customer_name = INITCAP(customer_name)"
  
  - name: stg_products
    description: "Catálogo de productos limpio"
    columns:
      - name: product_id
        description: "Identificador único del producto"
        tests:
          - not_null
          - unique
      - name: price
        description: "Precio del producto"
        tests:
          - not_null
          - custom:
              name: positive_price
              description: "Precio debe ser positivo"
              sql: "price >= 0"
      - name: category
        description: "Categoría estandarizada"
        tests:
          - accepted_values:
              values: ['Electrónica', 'Libros', 'Ropa']
  
  - name: stg_orders
    description: "Pedidos validados y enriquecidos"
    columns:
      - name: order_id
        description: "Identificador único del pedido"
        tests:
          - not_null
          - unique
      - name: customer_id
        description: "Referencia al cliente"
        tests:
          - relationships:
              to: ref('stg_customers')
              field: customer_id
      - name: product_id
        description: "Referencia al producto"
        tests:
          - relationships:
              to: ref('stg_products')
              field: product_id
      - name: total_amount
        description: "Monto total del pedido"
        tests:
          - not_null
          - custom:
              name: positive_total
              description: "Total debe ser positivo"
              sql: "total_amount > 0"
      - name: status
        description: "Estado del pedido estandarizado"
        tests:
          - accepted_values:
              values: ['pendiente', 'enviado', 'entregado', 'cancelado']
```

### Comandos de Ejecución para Staging
```bash
# Cargar datos
docker-compose exec dbt dbt seed --project-dir=/usr/app/knowing_dbt

# Ejecutar modelos staging
docker-compose exec dbt dbt run --models staging --project-dir=/usr/app/knowing_dbt

# Ejecutar tests
docker-compose exec dbt dbt test --models staging --project-dir=/usr/app/knowing_dbt

# Generar documentación
docker-compose exec dbt dbt docs generate --project-dir=/usr/app/knowing_dbt
docker-compose exec dbt dbt docs serve --project-dir=/usr/app/knowing_dbt
```

---

## ⚡ Ejercicio 2: Modelos Incrementales

### Tests para Incremental
```yaml
models:
  - name: fct_orders_incremental
    description: "Tabla de hechos incremental para pedidos"
    columns:
      - name: order_id
        description: "Identificador único del pedido"
        tests:
          - not_null
          - unique
      - name: total_amount
        description: "Monto total del pedido"
        tests:
          - not_null
          - custom:
              name: positive_total_amount
              description: "Total amount debe ser positivo"
              sql: "total_amount > 0"
      - name: delivered_amount
        description: "Monto de pedidos entregados"
        tests:
          - custom:
              name: delivered_less_than_total
              description: "Delivered amount no puede ser mayor al total"
              sql: "delivered_amount <= total_amount"
      - name: cancelled_amount
        description: "Monto de pedidos cancelados"
        tests:
          - custom:
              name: cancelled_less_than_total
              description: "Cancelled amount no puede ser mayor al total"
              sql: "cancelled_amount <= total_amount"
      - name: last_updated
        description: "Fecha de última actualización"
        tests:
          - not_null
```

### Comandos de Ejecución para Incrementales
```bash
# Ejecutar modelo incremental inicial
docker-compose exec dbt dbt run -m fct_orders_incremental --project-dir=/usr/app/knowing_dbt

# Cargar actualizaciones
docker-compose exec dbt dbt seed --project-dir=/usr/app/knowing_dbt

# Ejecutar incremental con nuevos datos
docker-compose exec dbt dbt run -m fct_orders_incremental --project-dir=/usr/app/knowing_dbt

# Ejecutar tests
docker-compose exec dbt dbt test -m fct_orders_incremental --project-dir=/usr/app/knowing_dbt
```

---

## ⚡ Ejercicio 2: Modelos Incrementales

### fct_orders_incremental.sql
```sql
{{ config(
    materialized='incremental',
    unique_key='order_id',
    on_schema_change='sync_all_columns'
) }}

SELECT 
    order_id,
    customer_id,
    product_id,
    order_date,
    quantity,
    unit_price,
    total_amount,
    status,
    last_updated,
    
    -- Métricas adicionales
    CASE 
        WHEN status = 'entregado' THEN total_amount
        ELSE 0 
    END as delivered_amount,
    
    CASE 
        WHEN status = 'cancelado' THEN total_amount
        ELSE 0 
    END as cancelled_amount,
    
    -- Timestamps para auditoría
    CURRENT_TIMESTAMP() as dbt_updated_at
    
FROM {{ ref('stg_orders') }}

{% if is_incremental() %}
    WHERE last_updated > (SELECT MAX(last_updated) FROM {{ this }})
{% endif %}
```

### Tests para Incremental
```yaml
models:
  - name: fct_orders_incremental
    description: "Tabla de hechos incremental para pedidos"
    columns:
      - name: order_id
        description: "Identificador único del pedido"
        tests:
          - not_null
          - unique
      - name: total_amount
        description: "Monto total del pedido"
        tests:
          - not_null
          - custom:
              name: positive_total_amount
              description: "Total amount debe ser positivo"
              sql: "total_amount > 0"
      - name: delivered_amount
        description: "Monto de pedidos entregados"
        tests:
          - custom:
              name: delivered_less_than_total
              description: "Delivered amount no puede ser mayor al total"
              sql: "delivered_amount <= total_amount"
```

---

## ⭐ Ejercicio 3: Modelo Estrella

### int_orders_enriched.sql
```sql
SELECT 
    o.order_id,
    o.customer_id,
    o.product_id,
    o.order_date,
    o.quantity,
    o.unit_price,
    o.total_amount,
    o.status,
    o.last_updated,
    
    -- Dimensiones de cliente
    c.customer_name,
    c.email,
    c.address,
    c.join_date,
    
    -- Dimensiones de producto
    p.product_name,
    p.category,
    p.price as product_price,
    
    -- Dimensiones de tiempo
    EXTRACT(YEAR FROM o.order_date) as order_year,
    EXTRACT(MONTH FROM o.order_date) as order_month,
    EXTRACT(DAY FROM o.order_date) as order_day,
    EXTRACT(DAYOFWEEK FROM o.order_date) as day_of_week,
    FORMAT_DATE('%B', o.order_date) as month_name,
    FORMAT_DATE('%A', o.order_date) as day_name
    
FROM {{ ref('stg_orders') }} o
LEFT JOIN {{ ref('stg_customers') }} c ON o.customer_id = c.customer_id
LEFT JOIN {{ ref('stg_products') }} p ON o.product_id = p.product_id
```

### dim_customers.sql
```sql
SELECT 
    customer_id,
    customer_name,
    email,
    address,
    join_date,
    created_at,
    updated_at,
    
    -- Métricas agregadas
    COUNT(DISTINCT order_id) as total_orders,
    SUM(total_amount) as total_spent,
    AVG(total_amount) as avg_order_value,
    MAX(order_date) as last_order_date,
    
    -- Segmentación
    CASE 
        WHEN SUM(total_amount) >= 1000 THEN 'VIP'
        WHEN SUM(total_amount) >= 500 THEN 'Regular'
        ELSE 'Nuevo'
    END as customer_segment
    
FROM {{ ref('int_orders_enriched') }}
GROUP BY 1,2,3,4,5,6,7
```

### dim_products.sql
```sql
SELECT 
    product_id,
    product_name,
    category,
    price,
    created_at,
    
    -- Métricas agregadas
    COUNT(DISTINCT order_id) as total_orders,
    SUM(quantity) as total_quantity_sold,
    SUM(total_amount) as total_revenue,
    AVG(quantity) as avg_quantity_per_order,
    
    -- Análisis de rendimiento
    CASE 
        WHEN SUM(total_amount) >= 1000 THEN 'Alto rendimiento'
        WHEN SUM(total_amount) >= 500 THEN 'Rendimiento medio'
        ELSE 'Bajo rendimiento'
    END as performance_category
    
FROM {{ ref('int_orders_enriched') }}
GROUP BY 1,2,3,4,5
```

### dim_date.sql
```sql
WITH date_spine AS (
    SELECT date_value
    FROM UNNEST(GENERATE_DATE_ARRAY('2023-01-01', '2023-12-31')) as date_value
)

SELECT 
    date_value as date_key,
    EXTRACT(YEAR FROM date_value) as year,
    EXTRACT(MONTH FROM date_value) as month,
    EXTRACT(DAY FROM date_value) as day,
    FORMAT_DATE('%B', date_value) as month_name,
    FORMAT_DATE('%A', date_value) as day_name,
    EXTRACT(DAYOFWEEK FROM date_value) as day_of_week,
    EXTRACT(QUARTER FROM date_value) as quarter,
    
    -- Indicadores de negocio
    CASE 
        WHEN EXTRACT(DAYOFWEEK FROM date_value) IN (1, 7) THEN 'Fin de semana'
        ELSE 'Día laboral'
    END as day_type,
    
    CASE 
        WHEN EXTRACT(MONTH FROM date_value) IN (12, 1, 2) THEN 'Invierno'
        WHEN EXTRACT(MONTH FROM date_value) IN (3, 4, 5) THEN 'Primavera'
        WHEN EXTRACT(MONTH FROM date_value) IN (6, 7, 8) THEN 'Verano'
        ELSE 'Otoño'
    END as season
    
FROM date_spine
```

### fact_orders.sql
```sql
SELECT 
    order_id,
    customer_id,
    product_id,
    DATE(order_date) as date_key,
    order_date,
    quantity,
    unit_price,
    total_amount,
    status,
    last_updated,
    
    -- Métricas por estado
    CASE 
        WHEN status = 'entregado' THEN total_amount
        ELSE 0 
    END as delivered_amount,
    
    CASE 
        WHEN status = 'cancelado' THEN total_amount
        ELSE 0 
    END as cancelled_amount,
    
    CASE 
        WHEN status = 'enviado' THEN total_amount
        ELSE 0 
    END as shipped_amount,
    
    -- Métricas de tiempo
    DATE_DIFF(order_date, join_date, DAY) as days_since_customer_joined,
    
    -- Timestamps
    CURRENT_TIMESTAMP() as dbt_updated_at
    
FROM {{ ref('int_orders_enriched') }}
```

### schema.yml para Modelo Estrella
```yaml
version: 2

models:
  - name: fact_orders
    description: "Tabla de hechos con todas las transacciones de pedidos"
    columns:
      - name: order_id
        description: "Identificador único del pedido"
        tests:
          - not_null
          - unique
      - name: customer_id
        description: "Referencia al cliente"
        tests:
          - relationships:
              to: ref('dim_customers')
              field: customer_id
      - name: product_id
        description: "Referencia al producto"
        tests:
          - relationships:
              to: ref('dim_products')
              field: product_id
      - name: date_key
        description: "Referencia a la dimensión de fecha"
        tests:
          - relationships:
              to: ref('dim_date')
              field: date_key
      - name: total_amount
        description: "Monto total del pedido"
        tests:
          - not_null
          - custom:
              name: positive_total
              description: "Total debe ser positivo"
              sql: "total_amount > 0"
      - name: delivered_amount
        description: "Monto de pedidos entregados"
      - name: cancelled_amount
        description: "Monto de pedidos cancelados"
      - name: shipped_amount
        description: "Monto de pedidos enviados"
  
  - name: dim_customers
    description: "Dimensión de clientes con métricas agregadas"
    columns:
      - name: customer_id
        description: "Identificador único del cliente"
        tests:
          - not_null
          - unique
      - name: total_spent
        description: "Total gastado por el cliente"
        tests:
          - not_null
      - name: customer_segment
        description: "Segmento del cliente basado en gasto"
        tests:
          - accepted_values:
              values: ['VIP', 'Regular', 'Nuevo']
      - name: total_orders
        description: "Número total de pedidos del cliente"
      - name: avg_order_value
        description: "Valor promedio por pedido"
      - name: last_order_date
        description: "Fecha del último pedido"
  
  - name: dim_products
    description: "Dimensión de productos con métricas de ventas"
    columns:
      - name: product_id
        description: "Identificador único del producto"
        tests:
          - not_null
          - unique
      - name: total_revenue
        description: "Ingresos totales generados por el producto"
        tests:
          - not_null
      - name: performance_category
        description: "Categoría de rendimiento del producto"
        tests:
          - accepted_values:
              values: ['Alto rendimiento', 'Rendimiento medio', 'Bajo rendimiento']
      - name: total_orders
        description: "Número total de pedidos del producto"
      - name: total_quantity_sold
        description: "Cantidad total vendida"
      - name: avg_quantity_per_order
        description: "Cantidad promedio por pedido"
  
  - name: dim_date
    description: "Dimensión de tiempo para análisis temporal"
    columns:
      - name: date_key
        description: "Clave única de fecha"
        tests:
          - not_null
          - unique
      - name: day_type
        description: "Tipo de día (laboral o fin de semana)"
        tests:
          - accepted_values:
              values: ['Día laboral', 'Fin de semana']
      - name: season
        description: "Estación del año"
        tests:
          - accepted_values:
              values: ['Invierno', 'Primavera', 'Verano', 'Otoño']
      - name: month_name
        description: "Nombre del mes"
      - name: day_name
        description: "Nombre del día de la semana"
      - name: quarter
        description: "Trimestre del año"
```

### Comandos de Ejecución para Modelo Estrella
```bash
# Ejecutar todo el modelo estrella
docker-compose exec dbt dbt run --models marts --project-dir=/usr/app/knowing_dbt

# Ejecutar tests
docker-compose exec dbt dbt test --models marts --project-dir=/usr/app/knowing_dbt

# Generar documentación
docker-compose exec dbt dbt docs generate --project-dir=/usr/app/knowing_dbt
docker-compose exec dbt dbt docs serve --project-dir=/usr/app/knowing_dbt
```

---

## 🎯 Comandos de Ejecución

### Ejercicio 1 - Staging
```bash
# Cargar datos
docker-compose exec dbt dbt seed --project-dir=/usr/app/knowing_dbt

# Ejecutar modelos staging
docker-compose exec dbt dbt run --models staging --project-dir=/usr/app/knowing_dbt

# Ejecutar tests
docker-compose exec dbt dbt test --models staging --project-dir=/usr/app/knowing_dbt
```

### Ejercicio 2 - Incrementales
```bash
# Ejecutar modelo incremental inicial
docker-compose exec dbt dbt run -m fct_orders_incremental --project-dir=/usr/app/knowing_dbt

# Cargar actualizaciones
docker-compose exec dbt dbt seed --project-dir=/usr/app/knowing_dbt

# Ejecutar incremental con nuevos datos
docker-compose exec dbt dbt run -m fct_orders_incremental --project-dir=/usr/app/knowing_dbt
```

### Ejercicio 3 - Modelo Estrella
```bash
# Ejecutar todo el modelo estrella
docker-compose exec dbt dbt run --models marts --project-dir=/usr/app/knowing_dbt

# Ejecutar tests
docker-compose exec dbt dbt test --models marts --project-dir=/usr/app/knowing_dbt

# Generar documentación
docker-compose exec dbt dbt docs generate --project-dir=/usr/app/knowing_dbt
docker-compose exec dbt dbt docs serve --project-dir=/usr/app/knowing_dbt
```

---

## ✅ Validaciones Esperadas

### Después del Ejercicio 1
- 6 clientes válidos (1 cliente filtrado por email inválido)
- 8 productos válidos (todos con precios)
- 7 pedidos válidos (1 pedido filtrado por customer_id inválido)

### Después del Ejercicio 2
- 7 registros en la carga inicial
- 10 registros después de la actualización
- Tiempo de ejecución significativamente menor en la segunda ejecución

### Después del Ejercicio 3
- fact_orders: 7 registros
- dim_customers: 5 clientes con métricas
- dim_products: 7 productos con métricas
- dim_date: 365 días del año 2023
- Todos los tests pasando 