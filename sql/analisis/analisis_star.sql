/*
Este archivo busca profundizar un poco más el análisis de los datos extraídos y limpiados desde el API pydataxm 
*/
;
-- 1) Aportes de energía como % de la media histórica, por mes
;

WITH aporte_mensual AS (
    SELECT
        dim_fecha.anno AS "Año",
        dim_fecha.mes AS "Mes",
        -- El aporte relativo es adimensional kWh/kWh, en %
        ((SUM(aporte_ener)-SUM(aporte_med_ener))/SUM(aporte_med_ener))*100 AS aporte_relativo
    FROM star.fact_diario_sistema
    JOIN star.dim_fecha
        ON fact_diario_sistema.fecha = dim_fecha.fecha
    GROUP BY
        dim_fecha.anno, dim_fecha.mes
)
SELECT
    "Año",
    "Mes",
    aporte_relativo,
    CASE
        WHEN aporte_relativo > 10 THEN 'MAYOR'
        WHEN aporte_relativo < -10 THEN 'MENOR'
        ELSE 'IGUAL'
    END AS aporte_cualitativo
FROM aporte_mensual
ORDER BY
    "Año","Mes";

-- 2) Participación (%) de cada fuente en la generación, por mes.
--      cómo varía la matriz eléctrica mes a mes de las plantas despachadas centralmente
;

WITH generacion_tipo_fuente AS(
SELECT
    dim_fecha.anno AS "Año",
    dim_fecha.mes AS "Mes",
    dim_recurso.tipo_fuente AS "Tipo de Fuente",
    SUM(fact_generacion_recurso.gene_diaria) AS "Generación kWh",
    SUM(SUM(fact_generacion_recurso.gene_diaria)) OVER (PARTITION BY dim_fecha.anno, dim_fecha.mes) AS "Total Mensual"
FROM star.fact_generacion_recurso
JOIN star.dim_recurso
    ON fact_generacion_recurso.codigo_sic = dim_recurso.codigo_sic
JOIN star.dim_fecha
    ON fact_generacion_recurso.fecha = dim_fecha.fecha
WHERE
    dim_recurso.despacho = TRUE
GROUP BY
    dim_fecha.anno,dim_fecha.mes,dim_recurso.tipo_fuente

)
SELECT
    "Año",
    "Mes",
    "Tipo de Fuente",
    ("Generación kWh"/"Total Mensual")*100 AS "Generacion Relativa"
FROM generacion_tipo_fuente
ORDER BY
    "Año", "Mes"
;

-- 3) Días con precio mayor al percentil 90 y sus condiciones hídricas ese día
--    Busca ver cómo varía el precio de la bolsa y la matriz eléctrica asociada
;

SELECT
    fecha,
    ROUND(precio_prom::numeric,1) AS "Precio Promedio", -- en COP/kWh
    ROUND((((aporte_ener - aporte_med_ener)/aporte_med_ener)*100)::numeric, 1) AS aporte_relativo,
    ROUND(((vol_util/capa_util)*100)::numeric, 1) AS volumen_relativo
    
FROM star.fact_diario_sistema
WHERE
    precio_prom > (-- Inicio de una subconsulta para arrojar el valor necesario
        SELECT
            PERCENTILE_DISC(0.9) WITHIN GROUP (ORDER BY precio_prom)
        FROM
            star.fact_diario_sistema
            )-- Fin de la subconsulta
;

-- 4) Precio promedio de bolsa. Comparación de temporada seca y húmeda
;

SELECT
    dim_fecha.anno,
    dim_fecha.mes,
    ROUND(AVG(fact_diario_sistema.precio_prom)::numeric) AS precio_promedio, -- COP/kWh
    dim_fecha.es_temp_seca

FROM star.fact_diario_sistema
JOIN star.dim_fecha
    ON fact_diario_sistema.fecha = dim_fecha.fecha
GROUP BY
    dim_fecha.anno, dim_fecha.mes, dim_fecha.es_temp_seca
ORDER BY
    dim_fecha.anno, dim_fecha.mes
;

SELECT
    ROUND(AVG(fact_diario_sistema.precio_prom)::numeric) AS precio_promedio, -- COP/kWh
    dim_fecha.es_temp_seca
FROM star.fact_diario_sistema
JOIN star.dim_fecha
    ON fact_diario_sistema.fecha = dim_fecha.fecha
GROUP BY
     dim_fecha.es_temp_seca
;


SELECT
    ROUND(AVG(fact_diario_sistema.precio_prom)::numeric) AS precio_promedio, -- COP/kWh
    CASE
        -- Parámetro de 15% fijado para este ejercicio
        WHEN (((aporte_ener - aporte_med_ener)/aporte_med_ener)*100) < -15 THEN 'Seca'
        ELSE 'Húmeda/normal'
    END AS temporada
FROM star.fact_diario_sistema
JOIN star.dim_fecha
    ON fact_diario_sistema.fecha = dim_fecha.fecha
GROUP BY
     temporada
;

-- 5) Análisis del precio de bolsa por intervalo de volumen útil relativo
;

SELECT
    CASE
        WHEN (vol_util/capa_util)*100 <= 20 THEN ' 0 a 20%'
        WHEN (vol_util/capa_util)*100 <= 40 THEN '21 a 40%'
        WHEN (vol_util/capa_util)*100 <= 60 THEN '41 a 60%'
        WHEN (vol_util/capa_util)*100 <= 80 THEN '61 a 80%'
        ELSE '81 a 100%'
    END AS intervalo,
    ROUND(AVG(fact_diario_sistema.precio_prom)::numeric) AS precio_promedio, -- COP/kWh
    COUNT(*) as n_dias
FROM
    star.fact_diario_sistema
GROUP BY
    intervalo
ORDER BY
    intervalo
;

-- 6) Ranking de los 10 meses más caros del precio de bolsa con su déficit de aportes de energía y volumen relativo de embalses
;

WITH promedio_mensual AS (
    SELECT
        dim_fecha.anno AS "Año",
        dim_fecha.mes AS "Mes",
        -- El aporte relativo es adimensional kWh/kWh, en %
        ((SUM(aporte_ener)-SUM(aporte_med_ener))/SUM(aporte_med_ener))*100 AS aporte_relativo,
        (SUM(vol_util)/SUM(capa_util))*100 AS volumen_relativo,
        AVG(fact_diario_sistema.precio_prom) AS precio_promedio -- COP/kWh
    FROM star.fact_diario_sistema
    JOIN star.dim_fecha
        ON fact_diario_sistema.fecha = dim_fecha.fecha
    GROUP BY
        dim_fecha.anno, dim_fecha.mes
)

SELECT
    "Año",
    "Mes",
    ROUND(aporte_relativo::numeric,1) AS aporte_relativo,
    ROUND(volumen_relativo::numeric,1) AS volumen_relativo,
    ROUND(precio_promedio::numeric,1) AS precio_promedio,
    RANK() OVER (
        ORDER BY precio_promedio DESC) AS puesto
FROM promedio_mensual
ORDER BY puesto ASC
LIMIT 10
;
