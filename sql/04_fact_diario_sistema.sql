/*
Tabla de hechos que compila precios, aportes de energía de ríos, volumen de embalses
*/

DROP TABLE IF EXISTS star.fact_diario_sistema;

CREATE TABLE star.fact_diario_sistema(
    fecha DATE PRIMARY KEY,
    precio_prom DOUBLE PRECISION,
    precio_max DOUBLE PRECISION,
    precio_min DOUBLE PRECISION,
    aporte_ener DOUBLE PRECISION,
    aporte_med_ener DOUBLE PRECISION,
    vol_util DOUBLE PRECISION,
    capa_util DOUBLE PRECISION
);

-- Lllenado de la tabla usando INSERT y JOIN
INSERT INTO star.fact_diario_sistema (fecha, precio_prom, precio_max, precio_min, aporte_ener, aporte_med_ener, vol_util, capa_util)
SELECT
    pb."Date"      AS fecha,
    pb.precio_prom AS precio_prom,     -- COP/kWh
    pb.precio_max  AS precio_max,      -- COP/kWh
    pb.precio_min  AS precio_min,      -- COP/kWh
    ae."Value"     AS aporte_ener,     -- kWh
    ame."Value"    AS aporte_med_ener, -- kWh
    vu."Value"     AS vol_util,        -- kWh
    cu."Value"     AS capa_util        -- kWh
FROM raw.precio_bolsa as pb
JOIN raw.aporte_energia as ae
    ON pb."Date" = ae."Date"
JOIN raw.aporte_medio_energia as ame
    ON pb."Date" = ame."Date"
JOIN raw.volumen_util as vu
    ON pb."Date" = vu."Date"
JOIN raw.capacidad_util as cu
    ON pb."Date" = cu."Date";
