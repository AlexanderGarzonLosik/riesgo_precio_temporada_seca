/*
Dimensión de recursos de generación, desde raw.listado_recursos
*/

-- Crear el Schema star
CREATE SCHEMA IF NOT EXISTS star;

DROP TABLE IF EXISTS star.dim_recurso;

-- Crear el modelo vacío de dim_recurso (el DDL)
CREATE TABLE star.dim_recurso (
    codigo_sic TEXT PRIMARY KEY,
    nombre     TEXT,
    tipo_fuente   TEXT,
    despacho      BOOLEAN
);

-- Insertar los datos desde raw
INSERT INTO star.dim_recurso (codigo_sic, nombre, tipo_fuente, despacho)
SELECT DISTINCT ON ("Values_Code")
       "Values_Code",
       "Values_Name",
       "Values_Type",
       CASE
            WHEN "Values_Disp" = 'DESPACHADO CENTRALMENTE' THEN TRUE
            WHEN "Values_Disp" = 'NO DESPACHADO CENTRALMENTE' THEN FALSE
        END
FROM raw.listado_recursos
ORDER BY "Values_Code", "Date" DESC; -- Permite seleccionar la fuente de generación más reciente
