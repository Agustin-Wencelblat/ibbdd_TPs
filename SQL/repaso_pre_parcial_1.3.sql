-- Ejercicio 1: Listar los tracks cuyo nombre contenga la palabra "love", sin importar mayúsculas, junto con el título del álbum y el nombre del artista. Ordenar por artista y después por track.

SELECT t.track_id, t.name, al.title, ar.name
FROM track t
JOIN album al ON t.album_id = al.album_id
JOIN artist ar ON ar.artist_id = al.artist_id
WHERE LOWER(t.name) LIKE '%love%'
ORDER BY ar.name, t.name

-- Ejercicio 2: Listar el nombre, el apellido y el país de los clientes de Brasil o Argentina que no tienen empresa informada.

SELECT c.first_name, c.last_name, c.country
FROM customer c
WHERE c.country IN ('Brazil','Argentina') AND c.company IS NULL

-- Ejercicio 3: Mostrar la cantidad de facturas y el monto total facturado por anio

SELECT EXTRACT(YEAR FROM i.invoice_date) AS anio,
       COUNT(*)                           AS cantidad_facturas,
       SUM(i.total)                       AS monto_total
FROM invoice i
GROUP BY EXTRACT(YEAR FROM i.invoice_date)
ORDER BY anio;

-- Ejercicio 4: Listar los 10 tracks más largos, mostrando la duración en minutos con 2 decimales. Si hay empates, desempatar por track_id.

WITH ranking AS (
    SELECT t.track_id,
           t.name AS track,
           ROUND(t.milliseconds / 60000.0, 2) AS minutos,
           RANK() OVER (ORDER BY t.milliseconds DESC, t.track_id) AS pos
    FROM track t
)
SELECT r.pos, r.track_id, r.track, r.minutos
FROM ranking r
WHERE r.pos <= 10
ORDER BY r.pos, r.track_id;

-- Ejercicio 5: Para cada tipo de medio (media_type), mostrar la cantidad de tracks y el precio unitario promedio con 2 decimales. Mostrar solo los tipos con precio promedio mayor a $0.99$.

WITH stats AS (
    SELECT DISTINCT m.media_type_id, m.name AS media_type,
            COUNT(t.track_id) OVER(PARTITION BY (t.media_type_id)) AS numero_tracks,
            AVG(ROUND(t.unit_price,2)) OVER(PARTITION BY (t.media_type_id)) AS promedio_precio
    FROM track t
    JOIN media_type m ON t.media_type_id = m.media_type_id
)

SELECT s.media_type_id, s.media_type, s.numero_tracks, s.promedio_precio
FROM stats s
WHERE s.promedio_precio > 0.99

-- Version alternativa, con group by

SELECT m.media_type_id,
		m.name AS media_type,
		COUNT(*) AS cantidad_tracks,
		ROUND(AVG(t.unit_price),2) AS precio_promedio
FROM track t
JOIN media_type m ON t.media_type_id = m.media_type_id
GROUP BY m.media_type_id, m.name
HAVING AVG(t.unit_price) > 0.99
ORDER BY precio_promedio DESC	


-- Ejercicio 6: Listar los álbumes con más de 20 tracks, con el nombre del artista y la cantidad de tracks.

WITH detalles AS (
	SELECT al.album_id,
			al.title,
			ar.name AS artista,
			COUNT(*) AS cantidad_tracks
	FROM track t
	JOIN album al ON t.album_id = al.album_id
	JOIN artist ar ON ar.artist_id = al.artist_id
	GROUP BY al.album_id, ar.name
)

SELECT d.album_id, d.title, d.artista, d.cantidad_tracks
FROM detalles d
WHERE d.cantidad_tracks > 20
ORDER BY d.cantidad_tracks DESC

-- Ejercicio 7: Para cada empleado, mostrar la cantidad de clientes que atiende (support_rep_id) y el monto total facturado a esos clientes. Incluir a los empleados que no atienden a ningún cliente, mostrando $0$ en lugar de NULL.

SELECT e.employee_id, e.first_name, e.last_name, 
	COUNT(DISTINCT c.customer_id) AS cant_clientes,
	COALESCE(SUM(i.total),0) AS total_facturado
FROM employee e
LEFT JOIN customer c ON e.employee_id = c.support_rep_id
LEFT JOIN invoice i ON i.customer_id = c.customer_id
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY e.employee_id

-- Ejercicio 8: Listar los géneros que nunca se vendieron. Resolverlo de dos formas: con NOT EXISTS y con LEFT JOIN. Si el resultado es vacío, explicar cómo verificaste que es correcto.

-- Con NOT EXISTS

SELECT g.genre_id, g.name
FROM genre g 
WHERE NOT EXISTS (
	SELECT 1 
	FROM track t
	JOIN invoice_line il ON il.track_id = t.track_id
	WHERE t.genre_id = g.genre_id
)

-- Con LEFT JOIN

SELECT g.genre_id, g.name
FROM genre g 
LEFT JOIN track t ON t.genre_id = g.genre_id
LEFT JOIN invoice_line il ON il.track_id = t.track_id
GROUP BY g.genre_id, g.name
HAVING COUNT(il.invoice_line_id) = 0

-- Ejercicio 9: Listar los clientes que compraron tracks de al menos 3 géneros distintos.

WITH compras AS (
	SELECT c.customer_id, c.first_name, c.last_name, COUNT(DISTINCT t.genre_id) AS generos_distintos
	FROM customer c
	JOIN invoice i ON i.customer_id = c.customer_id
	JOIN invoice_line il ON il.invoice_id = i.invoice_id
	JOIN track t ON t.track_id = il.track_id
	GROUP BY c.customer_id, c.first_name, c.last_name
)

SELECT co.customer_id, co.first_name, co.last_name, co.generos_distintos
FROM compras co 
WHERE co.generos_distintos > 2

-- Ejercicio 10: Listar los artistas que tienen tracks en más de un tipo de medio.

SELECT ar.artist_id, ar.name, COUNT(DISTINCT t.media_type_id) AS cant_medios
FROM artist ar
JOIN album al ON al.artist_id = ar.artist_id
JOIN track t ON t.album_id = al.album_id
GROUP BY ar.artist_id, ar.name
HAVING COUNT(DISTINCT t.media_type_id) > 1


-- Ejercicio 11: Listar las playlists que contienen todos los tracks del álbum Big Ones. Resolverlo de dos formas: con doble NOT EXISTS y comparando conteos.

-- Con doble NOT EXISTS

SELECT p.*
FROM playlist p
WHERE NOT EXISTS (
	SELECT 1
	FROM track t
	JOIN album a ON a.album_id = t.album_id
	WHERE a.title = 'Big Ones'
		AND NOT EXISTS (
			SELECT 1
			FROM playlist_track pt
			WHERE p.playlist_id = pt.playlist_id AND pt.track_id = t.track_id
		)
)

-- Con conteos: 

SELECT p.playlist_id, p.name
FROM playlist p
JOIN playlist_track pt ON p.playlist_id = pt.playlist_id
JOIN track t ON t.track_id = pt.track_id
JOIN album al ON al.album_id = t.album_id
WHERE al.title = 'Big Ones'
GROUP BY p.playlist_id, p.name
HAVING COUNT(DISTINCT pt.track_id) = (
	SELECT COUNT(*)
	FROM track t2
	JOIN album a2 ON a2.album_id = t2.album_id
	WHERE a2.title = 'Big Ones'
)

-- Ejercicio 12: Para cada país, mostrar el cliente que más gastó, incluyendo empates. Resolverlo con una subconsulta correlacionada, sin funciones de ventana.

-- Sin funciones de ventana

SELECT c.country, c.customer_id, c.first_name, c.last_name, SUM(i.total) AS gasto
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.country, c.first_name, c.last_name
HAVING SUM(i.total) >= ALL(
	SELECT SUM(i2.total)
	FROM customer c2
	JOIN invoice i2 ON c2.customer_id = i2.customer_id
	WHERE c2.country = c.country
	GROUP BY c2.customer_id
)

-- Con funciones de ventana

WITH ranking AS (
	SELECT c.country, c.customer_id, c.first_name, c.last_name,
	SUM(i.total) AS gasto,
	RANK () OVER (PARTITION BY c.country ORDER BY SUM(i.total) DESC) AS rk
	FROM customer c
	JOIN invoice i ON c.customer_id = i.customer_id
	GROUP BY c.customer_id, c.country, c.first_name, c.last_name
)

SELECT r.country, r.customer_id, r.first_name, r.last_name, r.gasto
FROM ranking r
WHERE r.rk = 1
ORDER BY c.country, c.customer_id
	

-- Ejercicio 13: Listar las facturas cuyo total supera el promedio de las facturas de su mismo país de facturación.

SELECT i.invoice_id, i.billing_country, i.total
FROM invoice i
WHERE i.total > (
	SELECT AVG(i2.total)
	FROM invoice i2
	WHERE i2.billing_country = i.billing_country
)
ORDER BY i.billing_country, i.invoice_id

-- Ejercicio 14: Con operadores de conjuntos: (a) las ciudades donde hay clientes y empleados; (b) las ciudades donde hay clientes pero no hay empleados.

SELECT c.city, c.country 
FROM customer c
INTERSECT
SELECT e.city, e.country
FROM employee e

SELECT c.city, c.country 
FROM customer c
EXCEPT
SELECT e.city, e.country
FROM employee e

-- Ejercicio 15: Para cada cliente, numerar sus facturas en orden cronológico, y mostrar en cada fila el monto de su primera y de su última factura. Ojo con el marco de LAST_VALUE.

SELECT i.customer_id, i.invoice_id, i.invoice_date, i.total,
		ROW_NUMBER() OVER (PARTITION BY i.customer_id ORDER BY i.invoice_date, i.invoice_id) AS nro_factura,
		FIRST_VALUE(i.total) OVER (PARTITION BY i.customer_id ORDER BY i.invoice_date, i.invoice_id) AS primera_factura,
		LAST_VALUE(i.total) OVER (PARTITION BY i.customer_id ORDER BY i.invoice_date, i.invoice_id ROWS BETWEEN UNBOUNDED PRECEDING
                                           AND UNBOUNDED FOLLOWING) AS ultima_factura
FROM invoice i
ORDER BY i.customer_id, nro_factura

		

-- Ejercicio 16: Calcular la facturación total del sistema por mes, y su promedio móvil de 3 meses (el mes anterior, el actual y el siguiente).

SELECT EXTRACT(YEAR  FROM i.invoice_date) AS anio,
       EXTRACT(MONTH FROM i.invoice_date) AS mes,
       SUM(i.total) AS facturacion,
       ROUND(AVG(SUM(i.total)) OVER (
           ORDER BY EXTRACT(YEAR FROM i.invoice_date) * 12
                  + EXTRACT(MONTH FROM i.invoice_date)
           RANGE BETWEEN 1 PRECEDING AND 1 FOLLOWING
       ), 2) AS promedio_movil_3m
FROM invoice i
GROUP BY anio, mes
ORDER BY anio, mes;

-- Ejercicio 17: Para cada género, mostrar el monto facturado, el porcentaje sobre la facturación total con 2 decimales, y su posición en un ranking.

SELECT g.genre_id,
       g.name AS genero,
       COALESCE(SUM(il.unit_price * il.quantity), 0) AS monto,
       ROUND(100.0 * COALESCE(SUM(il.unit_price * il.quantity), 0)
             / SUM(COALESCE(SUM(il.unit_price * il.quantity), 0)) OVER (), 2) AS porcentaje,
       RANK() OVER (ORDER BY COALESCE(SUM(il.unit_price * il.quantity), 0) DESC) AS ranking
FROM genre g
LEFT JOIN track t         ON t.genre_id  = g.genre_id
LEFT JOIN invoice_line il ON il.track_id = t.track_id
GROUP BY g.genre_id, g.name
ORDER BY ranking, g.genre_id;

-- Ejercicio 18: Rankear a los empleados de soporte según el monto facturado a sus clientes, mostrando RANK, DENSE_RANK y PERCENT_RANK. Explicar en qué caso darían resultados distintos.

SELECT e.employee_id, e.first_name, e.last_name,
		COALESCE(SUM(i.total),0) AS monto,
		RANK() OVER (ORDER BY COALESCE(SUM(i.total),0) DESC) AS rk,
		DENSE_RANK() OVER (ORDER BY COALESCE(SUM(i.total),0) DESC) AS drk,
		PERCENT_RANK() OVER (ORDER BY COALESCE(SUM(i.total),0) DESC) AS prk
FROM employee e
LEFT JOIN customer c ON e.employee_id = c.support_rep_id
LEFT JOIN invoice i ON c.customer_id = i.customer_id
WHERE e.title = 'Sales Support Agent'
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY rk DESC

-- Ejercicio 19: Para cada género, mostrar la mediana y el desvío estándar de la duración en minutos. Además, calcular la correlación global entre bytes y milliseconds, e interpretar el resultado.

SELECT g.name AS genero,
       COUNT(*) AS tracks,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY t.milliseconds / 60000.0)::numeric, 2) AS mediana_min,
       ROUND(STDDEV_SAMP(t.milliseconds / 60000.0), 2) AS desvio_min
FROM genre g
JOIN track t ON t.genre_id = g.genre_id
GROUP BY g.genre_id, g.name
ORDER BY g.name;
 
-- Correlación global
SELECT ROUND(CORR(t.bytes, t.milliseconds)::numeric, 4) AS correlacion
FROM track t;
 
-- Para interpretarla: correlación separada por tipo de medio (audio vs. video)
SELECT m.name AS media_type,
       COUNT(*) AS tracks,
       ROUND(CORR(t.bytes, t.milliseconds)::numeric, 4) AS correlacion
FROM track t
JOIN media_type m ON m.media_type_id = t.media_type_id
GROUP BY m.media_type_id, m.name
ORDER BY m.name;

-- Ejercicio 20: para cada álbum, sus géneros distintos en una sola columna separados por '/'.

SELECT al.album_id, al.title,
	STRING_AGG(DISTINCT g.name, '/' ORDER BY g.name) AS generos
FROM album al
JOIN track t ON t.album_id = al.album_id
JOIN genre g ON g.genre_id = t.genre_id
GROUP BY al.album_id, al.title
ORDER BY al.album_id


-- Ejercicio 21: monto de la primera factura de cada cliente, sin y con funciones de ventana.

-- Sin:

SELECT i.customer_id, i.invoice_id, i.invoice_date, i.total AS primera_factura
FROM invoice i
WHERE NOT EXISTS(
	SELECT 1 
	FROM invoice i2
	WHERE i2.customer_id = i.customer_id
		AND (i2.invoice_date < i.invoice_date)
			OR (i2.invoice_date = i.invoice_date AND i2.invoice_id < i.invoice_id))
)

-- Con: 

SELECT i.customer_id, i.invoice_id, i.invoice_date,
	FIRST_VALUE(i.total) OVER (PARTITION BY i.customer_id ORDER BY i.invoice_date, i.invoice_id) AS primera_factura
FROM invoice i
ORDER BY i.customer_id
