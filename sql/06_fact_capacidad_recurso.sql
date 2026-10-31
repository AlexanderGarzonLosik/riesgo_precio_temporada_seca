/*
Tabla de hechos que agrupa las capacidades efectivas netas de cada planta generadora, fecha y código asociado a cada planta
*/

DROP TABLE IF EXISTS star.fact_capacidad_recurso;

CREATE TABLE star.fact_capacidad_recurso(
    fecha DATE,
    codigo_sic TEXT,
    capacidad_efec_neta DOUBLE PRECISION, -- kW
    PRIMARY KEY (fecha, codigo_sic)
);


INSERT INTO star.fact_capacidad_recurso(fecha,codigo_sic,capacidad_efec_neta)
SELECT DISTINCT ON ("Date","Code")
    "Date",
    "Code",
    "Value" -- kW
FROM
    raw.capacidad_efectiva_neta
ORDER BY "Date", "Code", "Value" DESC; --Conserva la mayor capacidad, si la misma planta se repite el mismo día
