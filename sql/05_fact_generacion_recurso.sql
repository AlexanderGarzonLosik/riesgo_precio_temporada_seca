/*
Tabla de hechos que regrupa los códigos de cada planta generadora, fecha y generación diaria
*/

DROP TABLE IF EXISTS star.fact_generacion_recurso;

CREATE TABLE star.fact_generacion_recurso(
    fecha DATE,
    codigo_sic TEXT,
    gene_diaria DOUBLE PRECISION,
    PRIMARY KEY (fecha, codigo_sic)
);

INSERT INTO star.fact_generacion_recurso (fecha, codigo_sic, gene_diaria)
SELECT
    "Date",
    "Values_code",
    "Generacion_Diaria"
FROM
    raw.gene_recurso;
