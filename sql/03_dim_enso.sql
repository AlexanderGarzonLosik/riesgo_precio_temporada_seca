/*
Dimensión de datos de la NOAA, desde raw.oni_noaa
*/


DROP TABLE IF EXISTS star.dim_enso;

-- Crear el modelo vacío de dim_enso

CREATE TABLE star.dim_enso(
    "SEAS" TEXT,
    "YR" INTEGER,
    "TOTAL" DOUBLE PRECISION,
    "ANOM" DOUBLE PRECISION,
    fase_enso TEXT,
    mes INTEGER
);

-- Insertar los datos desde raw

INSERT INTO star.dim_enso("SEAS", "YR", "TOTAL", "ANOM", fase_enso, mes)
SELECT
    "SEAS", -- comillas para encontrar el nombre exacto
    "YR",
    "TOTAL",
    "ANOM",
    fase_enso, -- en minúscula no son necesarias las comillas
    mes
FROM raw.oni_noaa;

