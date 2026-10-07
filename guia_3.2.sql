DROP TABLE IF EXISTS temperaturas;
 
CREATE TABLE temperaturas (
    id_paciente VARCHAR(30) NOT NULL,
    dia         INT         NOT NULL,
    temp        INT         NOT NULL,
    PRIMARY KEY (id_paciente, dia)
);
 
INSERT INTO temperaturas (id_paciente, dia, temp) VALUES
    ('Dante', 1, 39), ('Dante', 2, 40), ('Dante', 3, 38), ('Dante', 4, 37), ('Dante', 5, 0),
    ('Lucas', 1, 39), ('Lucas', 2, 37), ('Lucas', 3, 0),
    ('Pablo', 1, 39),
    ('Zulema', 1, 40), ('Zulema', 2, 38), ('Zulema', 3, 38), ('Zulema', 4, 40), ('Zulema', 5, 38);
 
-- Ejercicio 0: 

-- Definir, con lenguaje natural y con SQL, todos los controles posibles para garantizar que el
-- conjunto de datos está completo y bien formado. Testearlos.
-- Ejemplo: “Todos los pacientes tienen un registro de su dia de ingreso”

SELECT COUNT(DISTINCT id_paciente) pacientes
FROM temperaturas

SELECT COUNT(*) ingresos
FROM temperaturas
WHERE dia = 1

-- Defino controles, si devuelve 0 filas, pasa el control

SELECT DISTINCT id_paciente
FROM temperaturas t
WHERE NOT EXISTS (
    SELECT 1 FROM temperaturas i
    WHERE i.id_paciente = t.id_paciente AND i.dia = 1
);

--  Hay un único registro por paciente y día.

SELECT id_paciente, dia, COUNT(*) AS registros
FROM temperaturas
GROUP BY id_paciente, dia
HAVING COUNT(*) > 1;

-- Los dias de cada paciente son consecutivos

SELECT id_paciente, MIN(dia) AS primer_dia, MAX(dia) AS ultimo_dia, COUNT(*) AS registros
FROM temperaturas
GROUP BY id_paciente
HAVING MIN(dia) <> 1 OR MAX(dia) <> COUNT(*)

-- Los pacientes ingresan con temperatura > 37

SELECT *
FROM temperaturas
WHERE dia = 1 AND temp <= 37

-- El alta es el ultimo registro del paciente

SELECT a.* 
FROM temperaturas a
WHERE temp = 0 AND 
	EXISTS(SELECT l.id_paciente, l.dia 
			FROM temperaturas l 
			WHERE l.id_paciente = a.id_paciente AND l.dia > a.dia)

-- El dia anterior al alta la temp fue <= 37

SELECT a.*
FROM temperaturas a
JOIN temperaturas p ON p.id_paciente = a.id_paciente AND p.dia = a.dia - 1
WHERE a.temp = 0 AND p.temp > 37


-- Hay alta despues de un dia con temp <= 37


SELECT d.*, s.temp AS temp_siguiente
FROM temperaturas d
JOIN temperaturas s ON s.id_paciente = d.id_paciente AND s.dia = d.dia + 1
WHERE d.temp BETWEEN 1 AND 37 AND s.temp <> 0;
 
-- Ejercicio 1: Se quiere analizar si a algún paciente le subió la temperatura durante su internación en la sala.
-- Para esto (y otras cosas) se le quiere agregar a los datos una columna con la temperatura del paciente al
-- día siguiente (llamada temp_sig)

-- Resolucion SIN funciones de ventana

SELECT t.id_paciente, t.dia, t.temp, s.temp AS temp_sig
FROM temperaturas t
LEFT JOIN temperaturas s ON s.id_paciente = t.id_paciente AND s.dia = t.dia + 1
ORDER BY t.id_paciente, t.dia;

-- Resolucion CON funciones de ventana

SELECT id_paciente, dia, temp,
       LEAD(temp) OVER (PARTITION BY id_paciente ORDER BY dia) AS temp_sig
FROM temperaturas
ORDER BY id_paciente, dia;

-- Nuevo control: cada paciente tiene exactamente un temp_sig NULL (su último registro).
WITH t2 AS (
    SELECT id_paciente, dia, temp,
           LEAD(temp) OVER (PARTITION BY id_paciente ORDER BY dia) AS temp_sig
    FROM temperaturas
)
SELECT id_paciente, COUNT(*) AS nulos
FROM t2
WHERE temp_sig IS NULL
GROUP BY id_paciente
HAVING COUNT(*) <> 1;
 
-- Nuevo control: si temp_sig = 0 (alta al día siguiente), entonces temp <= 37.
WITH t2 AS (
    SELECT id_paciente, dia, temp,
           LEAD(temp) OVER (PARTITION BY id_paciente ORDER BY dia) AS temp_sig
    FROM temperaturas
)
SELECT *
FROM t2
WHERE temp_sig = 0 AND temp > 37;


-- Ejercicio 2: ¿Cuál es la última temperatura registrada para los pacientes que se dieron de alta?

WITH t2 AS (
	SELECT id_paciente, dia, temp, 
		LEAD(temp) OVER (PARTITION BY id_paciente ORDER BY dia) AS temp_sig
	FROM temperaturas 
)

SELECT id_paciente, temp AS ultima_temp
FROM t2 
WHERE temp_sig = 0

-- Ejercicio 3: agregar dias (total de días del paciente)

SELECT id_paciente, dia, temp,
	LEAD(temp) OVER (PARTITION BY id_paciente ORDER BY dia) AS temp_sig,
	COUNT(*) OVER (PARTITION BY id_paciente) AS dias
FROM temperaturas
ORDER BY id_paciente, dia

-- Parte 2

WITH t3 AS (
	SELECT id_paciente, dia, temp,
		COUNT(*) OVER (PARTITION BY id_paciente) AS dias,
		FIRST_VALUE(temp) OVER (PARTITION BY id_paciente ORDER BY dia) AS temperatura_inicial
	FROM temperaturas
	ORDER BY id_paciente, dia
)

SELECT id_paciente, temperatura_inicial AS temp, dias
FROM t3
WHERE temp = 0
ORDER BY id_paciente

-- Ejercicio 4: ¿con qué temperatura entró cada paciente? (sin filtrar por dia 1)

SELECT DISTINCT id_paciente,
	FIRST_VALUE(temp) OVER (PARTITION BY id_paciente ORDER BY dia) AS temperatura_inicial
FROM temperaturas
ORDER BY id_paciente

-- Ejercicio 5: mayor baja diaria de temperatura entre pacientes con fiebre (donde baja = temp - temp_sig. Se excluye temp_sig = 0)

WITH t2 AS (
	SELECT id_paciente, dia, temp,
		LEAD(temp) OVER (PARTITION BY id_paciente ORDER BY dia) AS temp_sig
	FROM temperaturas
),

bajas AS (
    SELECT id_paciente, dia, temp, temp_sig, temp - temp_sig AS baja
    FROM t2
    WHERE temp > 37 AND temp_sig > 0
)

SELECT *
FROM bajas
WHERE baja = (SELECT MAX(baja) FROM bajas)
ORDER BY id_paciente, dia;

-- Ejercicio 6: ¿Cuál fue la mayor variación de temperatura registrada en un paciente internado?

WITH t2 AS (
    SELECT id_paciente, dia, temp,
           LEAD(temp) OVER (PARTITION BY id_paciente ORDER BY dia) AS temp_sig
    FROM temperaturas
),
variaciones AS (
    SELECT id_paciente, dia, temp, temp_sig, ABS(temp_sig - temp) AS variacion
    FROM t2
    WHERE temp_sig > 0
)
SELECT *
FROM variaciones
WHERE variacion = (SELECT MAX(variacion) FROM variaciones)
ORDER BY id_paciente, dia;
 
-- Interpretación alternativa: variación total durante la internación
-- (máxima menos mínima temperatura del paciente, sin contar el alta).
WITH rangos AS (
    SELECT DISTINCT id_paciente,
           MAX(temp) OVER (PARTITION BY id_paciente)
         - MIN(temp) OVER (PARTITION BY id_paciente) AS variacion
    FROM temperaturas
    WHERE temp > 0
)
SELECT *
FROM rangos
WHERE variacion = (SELECT MAX(variacion) FROM rangos);


-- Ejercicio 7: ranking de pacientes por días de internación (descendente) Primero se deja UNA fila por paciente; si se rankea sobre la tabla 3 completa, se rankean filas (días), no pacientes.

WITH t3 AS (
    SELECT id_paciente, dia, temp,
           COUNT(*) OVER (PARTITION BY id_paciente) AS dias
    FROM temperaturas
),
pacientes AS (
    SELECT DISTINCT id_paciente, dias
    FROM t3
)
SELECT id_paciente, dias,
       RANK()       OVER (ORDER BY dias DESC) AS rank_,        -- 7-a
       ROW_NUMBER() OVER (ORDER BY dias DESC) AS row_number_,  -- 7-b
       DENSE_RANK() OVER (ORDER BY dias DESC) AS dense_rank_   -- para comparar
FROM pacientes
ORDER BY dias DESC, id_paciente;


-- Ejercicio 8 ¿Qué días alcanzaron los pacientes su máxima temperatura? (devolver el número de orden del día)

WITH t AS (
    SELECT id_paciente, dia, temp,
           ROW_NUMBER() OVER (PARTITION BY id_paciente ORDER BY dia) AS nro_dia,
           MAX(temp)    OVER (PARTITION BY id_paciente)              AS temp_max
    FROM temperaturas
)
SELECT id_paciente, nro_dia, temp
FROM t
WHERE temp = temp_max
ORDER BY id_paciente, nro_dia;



