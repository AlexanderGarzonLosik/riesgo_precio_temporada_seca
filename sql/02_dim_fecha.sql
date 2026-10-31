/*
Dimensión de fechas, con la marca de temporada seca (diciembre a marzo)
*/

DROP TABLE IF EXISTS star.dim_fecha;

-- Crear dim_fecha
CREATE TABLE star.dim_fecha(
    fecha          DATE PRIMARY KEY,
    anno           INTEGER,
    mes            INTEGER,
    trimestre      INTEGER,
    dia_semana     INTEGER,
    es_temp_seca   BOOLEAN
);

-- Rellenar dim_fecha
INSERT INTO star.dim_fecha (fecha, anno, mes, trimestre, dia_semana, es_temp_seca)
SELECT
dia::date AS fecha,
EXTRACT(YEAR FROM dia) AS anno,
EXTRACT(MONTH FROM dia) AS mes,
EXTRACT(QUARTER FROM dia) AS trimestre,
EXTRACT(ISODOW FROM dia) AS dia_semana,
EXTRACT(MONTH FROM dia) IN (12,1,2,3) AS es_temp_seca
FROM generate_series(
    (SELECT MIN("Date")::date FROM raw.precio_bolsa),
    (SELECT MAX("Date")::date FROM raw.precio_bolsa),
    '1 day'::interval
) AS dia;

