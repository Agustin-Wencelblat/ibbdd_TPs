-- Ejercicio 1: Para cada país de los clientes, mostrar la cantidad de clientes y el monto total facturado. Solo los países con más de 5 clientes, ordenados por monto en forma descendente.

SELECT c.country, COUNT(DISTINCT c.customer_id) AS cant_clientes, SUM(i.total	) AS monto_total_facturado
FROM customer c
LEFT JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.country
HAVING COUNT(DISTINCT c.customer_id) > 5
ORDER BY monto_total_facturado DESC

-- Ejercicio 2: Listar cada empleado junto con el nombre y apellido de su jefe (reports_to). Incluir a los empleados que no tienen jefe.

SELECT e.last_name, e.first_name, j.last_name AS apellido_jefe, j.first_name AS nombre_jefe
FROM employee e
LEFT JOIN employee j ON j.employee_id = e.reports_to

-- Ejercicio 3: Listar los artistas cuyos tracks duran todos más de 4 minutos.

SELECT ar.artist_id, ar.name
FROM artist ar
JOIN album al ON al.artist_id = ar.artist_id
JOIN track t ON t.album_id = al.album_id
GROUP BY ar.artist_id, ar.name
HAVING MIN(t.milliseconds) > 240000 
ORDER BY ar.name

-- Ejercicio 4: Para cada género, mostrar: la cantidad de tracks; la duración mediana en minutos, con 2 decimales; la cantidad de tracks de más de 5 minutos, usando FILTER.

SELECT g.genre_id, 
		g.name, 
		COUNT(DISTINCT t.track_id) AS cant_tracks, 
		ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY t.milliseconds)/ 60000.0)::numeric, 2) AS mediana_min,
		COUNT(DISTINCT t.track_id) FILTER (WHERE t.milliseconds > 300000) AS tracks_mas_5_min
FROM genre g
JOIN track t ON t.genre_id = g.genre_id
GROUP BY g.genre_id, g.name
ORDER BY cant_tracks DESC

-- Ejercicio 5: Mostrar el top 3 de tracks más vendidos (en unidades) de cada género, incluyendo los empates.

WITH ventas AS (
    SELECT t.genre_id, t.track_id, t.name,
           SUM(il.quantity)                AS unidades,
           SUM(il.quantity * il.unit_price) AS recaudado
    FROM track t
    JOIN invoice_line il ON il.track_id = t.track_id
    GROUP BY t.genre_id, t.track_id, t.name
),
ranking AS (
    SELECT v.genre_id, v.track_id, v.name, v.unidades, v.recaudado,
           RANK() OVER (PARTITION BY v.genre_id
                              ORDER BY v.unidades DESC,    
                                       v.recaudado DESC,   
                                       v.track_id) AS pos   
    FROM ventas v
)
SELECT g.name AS genero, r.name AS track, r.unidades, r.recaudado, r.pos
FROM ranking r
JOIN genre g ON g.genre_id = r.genre_id
WHERE r.pos <= 3
ORDER BY g.name, r.pos;


-- Ejercicio 6: Para cada factura, mostrar los días transcurridos desde la factura anterior del mismo cliente. Después, calcular el promedio de días entre compras de cada cliente.

WITH dif AS (
	SELECT i.invoice_id, i.customer_id, i.invoice_date,
		i.invoice_date::date - LAG(i.invoice_date::date) OVER(PARTITION BY i.customer_id ORDER BY i.invoice_date, i.customer_id) AS dias_desde_anterior_factura
	FROM invoice i
)

SELECT d.invoice_id, d.customer_id, d.invoice_date, d.dias_desde_anterior_factura
FROM dif d
ORDER BY d.customer_id, d.invoice_date

-- Parte 2, promedio

WITH dif AS (
	SELECT i.invoice_id, i.customer_id, i.invoice_date,
		i.invoice_date::date - LAG(i.invoice_date::date) OVER(PARTITION BY i.customer_id ORDER BY i.invoice_date, i.customer_id) AS dias_desde_anterior_factura
	FROM invoice i
)

SELECT d.customer_id, ROUND(AVG(d.dias_desde_anterior_factura), 2) AS prom_dias_entre_compras
FROM dif d
GROUP BY d.customer_id


-- Ejercicio 7: Listar las playlists cuyo precio total (suma de los precios de sus tracks) supera el promedio de precio de todas las playlists.

WITH precio_playlist AS (
	SELECT pt.playlist_id, SUM(t.unit_price) AS precio
	FROM playlist_track pt
	JOIN track t ON t.track_id = pt.track_id
	GROUP BY pt.playlist_id
)

SELECT p.playlist_id, p.name, pp.precio
FROM precio_playlist pp
JOIN playlist p ON p.playlist_id = pp.playlist_id
WHERE pp.precio > (SELECT AVG(pp2.precio) FROM precio_playlist pp2)
ORDER BY pp.precio DESC


-- Ejercicio 8: Control de calidad: verificar que invoice.total coincide con la suma de unit_price * quantity de sus líneas, y listar las facturas que no coinciden.

WITH totales AS (
    SELECT il.invoice_id,
           SUM(il.unit_price * il.quantity) AS total_lineas
    FROM invoice_line il
    GROUP BY il.invoice_id
)
SELECT i.invoice_id,
       i.total,
       t.total_lineas,
       i.total - t.total_lineas AS diferencia
FROM invoice i
LEFT JOIN totales t ON t.invoice_id = i.invoice_id   
WHERE t.total_lineas IS NULL                          
   OR i.total <> t.total_lineas;   


-- Ejercicio 9: Para cada cliente, mostrar su facturación por mes y el acumulado dentro de cada año.
WITH facturas AS (
	SELECT i.customer_id,
		EXTRACT(YEAR FROM i.invoice_date)::int AS anio,
		EXTRACT(MONTH FROM i.invoice_date)::int AS mes,
		SUM(i.total) AS facturado
	FROM invoice i
	GROUP BY i.customer_id, EXTRACT(YEAR FROM i.invoice_date), EXTRACT(MONTH FROM i.invoice_date)
)

SELECT f.customer_id, f.anio, f.mes, f.facturado, 
	SUM(f.facturado) OVER (PARTITION BY f.customer_id, f.anio ORDER BY f.mes) AS acumulado_anual
	FROM facturas f
	ORDER BY f.customer_id, f.anio, f.mes
	

