-- Ejercicio 1: Listar todos los campos de la tabla Employee.

SELECT * FROM "employee"


-- Ejercicio 2: Listar todas las BillingCity de la tabla Invoice, sin repetir.

SELECT DISTINCT "billing_city" FROM "invoice"


-- Ejercicio 3: Listar los nombres, apellidos y el estado de los empleados tal que vivan en la ciudad de Calgary.
SELECT "first_name", "last_name", "state" FROM "employee" WHERE "city" = 'Calgary'


-- Ejercicio 4: Listar los nombres, la duración y Bytes de los tracks cuya duración sea mayor a 500 segundos.

SELECT "name","milliseconds", "bytes" FROM "track" WHERE "milliseconds" > 500000


-- Ejercicio 5: Listar todos los campos de la tabla Invoice, tales que el país de facturación sea Alemania, Francia o
-- Italia ordenados en forma ascendente por el nombre de la ciudad de facturacion.

SELECT * FROM "invoice" WHERE "billing_country" IN ('Germany','France','Italy')
ORDER BY "billing_city" ASC


-- Ejercicio 6: Listar todas las BillingCity, que comiencen con la letra ‘B’ de la tabla Invoice ordenadas
-- descendentemente.

SELECT "billing_city" 
FROM "invoice" 
WHERE "billing_city" LIKE 'B%' 
ORDER BY "billing_city" DESC 


-- Ejercicio 7: Seleccionar el nombre, albumId, el compositor de los tracks y además el género del mismo. 	

SELECT t."name", t."album_id", t."composer", g."name" AS "genre"
FROM "track" t
JOIN "genre" g ON t."genre_id" = g."genre_id"


-- Ejercicio 8: A la consulta anterior, agregar el nombre del MediaType de cada track

SELECT t."name", t."album_id", t."composer", 
g."name" AS "genre", 
m."name" AS "media_type"
FROM "track" t
JOIN "genre" g ON t."genre_id" = g."genre_id"
JOIN "media_type" m ON t."media_type_id" = m."media_type_id"


-- Ejercicio 9: Listar la cantidad de tracks que tiene cada género y el nombre del género.

SELECT g."name" AS "genre", COUNT(*) AS "number_tracks"
FROM "genre" g
JOIN "track" t on t."genre_id" = g. "genre_id"
GROUP BY g."genre_id", g."name"
ORDER BY "number_tracks" DESC


-- Ejercicio 10: Obtener los artistas que no tienen álbumes.

SELECT  ar."artist_id", ar."name" AS "artist"
FROM "artist" ar

EXCEPT

SELECT ar."artist_id", ar."name"
FROM "artist" ar
JOIN "album" al ON ar."artist_id" = al."artist_id"

-- Otra version mas limpia

SELECT ar."artist_id", ar."name" AS "artist"
FROM "artist" ar
LEFT JOIN "album" al ON ar."artist_id" = al."artist_id"
WHERE al."album_id" IS NULL


-- Ejercicio 11: Listar todos los nombres de los artistas que comienzan con la letra 'M' y la cantidad de tracks, de
-- esos artistas, con más de 25 tracks, ordenado por cantidad de tracks de forma descendente.

SELECT ar."name" AS "artist", COUNT(*) AS "number_tracks"
FROM "artist" ar
JOIN "album" al ON ar."artist_id" = al."artist_id"
JOIN "track" t ON t."album_id" = al."album_id"
WHERE ar."name" LIKE 'M%'
GROUP BY ar."name", ar."artist_id"
HAVING COUNT(*) > 25
ORDER BY "number_tracks" DESC


-- Ejercicio 12: Listar todos los artistas, y para el caso en que corresponda los álbumes asociados que tengan
SELECT ar."name", ar."artist_id", al."title", al."album_id"
FROM "artist" ar
LEFT JOIN "album" al ON al."artist_id" = ar."artist_id"
ORDER BY ar."name", al."title"


-- Ejercicio 13: Listar todos los álbumes, y para el caso en que corresponda los artistas asociados que tengan.

SELECT al."album_id", al."title", ar."artist_id", ar."name" AS "artist"
FROM "album" al
LEFT JOIN "artist" ar ON ar."artist_id" = al."artist_id"
ORDER BY al."title"


-- Ejercicio 14: CTE - Obtener las playlists más caras.

WITH precio_playlist AS (
	SELECT p."playlist_id", p."name", SUM(t."unit_price") AS "price"
	FROM "playlist" p
	JOIN "playlist_track" pt ON pt."playlist_id" = p."playlist_id"
	JOIN "track" t ON t."track_id" = pt."track_id"
	GROUP BY p."playlist_id", p."name"
)

SELECT "playlist_id", "name", "price"
FROM "precio_playlist"
WHERE "price" = (SELECT MAX("price") FROM precio_playlist);


-- Ejercicio 15: CTE: ¿Cuál es el promedio de álbumes por PlayList?

WITH "albumes_por_playlist" AS (
SELECT p."playlist_id", COUNT(DISTINCT t."album_id") AS "cant_albumes"
FROM "playlist" p 
LEFT JOIN "playlist_track" pt ON pt."playlist_id" = p."playlist_id"
LEFT JOIN "track" t ON t."track_id" = pt."track_id"
GROUP BY p."playlist_id"
)

SELECT ROUND(AVG("cant_albumes"), 2) AS "promedio_albumes_por_playlist" FROM "albumes_por_playlist"	

-- Se puede usar LEFT JOIN, si quiero contar las playlists que no tienen ninguna cancion o solo JOIN si no.


-- Ejercicio 16: Obtener los datos de todos los tracks del álbum 'Led Zeppelin I'.
SELECT *
FROM "track"
WHERE "album_id" = (
	SELECT "album_id"
	FROM "album"
	WHERE "title" = 'Led Zeppelin I'
	)



-- Ejercicio 17: Obtener los nombres, en mayúscula de los tracks que se llaman igual que el álbum al que pertenecen.

SELECT UPPER(t."name")
FROM "track" t
WHERE t."name" = (
	SELECT al."title"
	FROM "album" al
	WHERE al."title" = t."name"
	)

-- Mejor version, busca pares album track

SELECT UPPER(t."name")
FROM "track" t
WHERE (t."album_id", t."name") IN (
	SELECT al."album_id", al."title" 
	FROM "album" al
	)


-- Ejercicio 18: Obtener los playlist que no contengan ningún track de los álbumes de los artistas “AC/DC” o “Audioslave” o "Chris Cornell".

WITH "tracks_prohibidos" AS (
	SELECT t."track_id" 
	FROM "track" t
	JOIN "album" al ON al."album_id" = t."album_id"
	JOIN "artist" ar ON ar."artist_id" = al."album_id" 
	WHERE ar."name" IN ('AC/DC', 'Audioslave', 'Chris Cornell')
),

"playlists_prohibidas" AS (
	SELECT DISTINCT pt."playlist_id"
	FROM "playlist_track" pt
	JOIN "tracks_prohibidos" tp ON pt."track_id" = tp."track_id"
)

SELECT p."playlist_id", p."name" 
FROM "playlist" p
WHERE p."playlist_id" NOT IN (SELECT pp."playlist_id" FROM "playlists_prohibidas" pp)
ORDER BY p."playlist_id"


-- Ejercicio 19: Ordenar los géneros según la cantidad de facturas generadas.

SELECT g."genre_id", g."name", COUNT(DISTINCT il."invoice_id") AS "numero_facturas_generadas"
FROM "genre" g
JOIN "track" t ON t."genre_id" = g."genre_id"
JOIN "invoice_line" il ON il."track_id" = t."track_id"
GROUP BY g."genre_id", g."name"
ORDER BY "numero_facturas_generadas" DESC


-- Ejercicio 20: Seleccione nombre y composer de los tracks que nunca fueron facturados.

WITH "tracks_facturados" AS (
	SELECT il."track_id"
	FROM "invoice_line" il 
)

SELECT t."track_id", t."name", t."composer"
FROM "track" t
WHERE t."track_id" NOT IN (SELECT tf."track_id" FROM "tracks_facturados" tf)


-- Ejercicio 21: Seleccione nombre y composer de los tracks que nunca fueron facturados, usandolo con EXCEPT.

SELECT t."track_id", t."name", t."composer"
FROM "track" t

EXCEPT 

SELECT t."track_id", t."name", t."composer"
FROM "track" t 
JOIN "invoice_line" il ON t."track_id" = il."track_id"


-- Ejercicio 22: Devolver el id del track, nombre del artista, título del álbum y nombre del track, tal que éste sea el más
-- largo en cantidad de caracteres, de todos los tracks

WITH "max_length" AS (
	SELECT MAX(LENGTH(t."name")) AS "length"
	FROM "track" t
)

SELECT t."track_id", ar."name" AS "artist", al."title" AS "album", t."name" AS "track"
FROM "track" t
JOIN "album" al ON al."album_id" = t."album_id"
JOIN "artist" ar ON ar."artist_id" = al."artist_id"
WHERE LENGTH(t."name") = (SELECT "length" FROM "max_length")


-- Ejercicio 23:Para cada canción (Track) devolver: Id de la canción, nombre de la canción, nombre del álbum al
-- que pertenece, nombre del género, cantidad total de canciones del álbum al que pertenece,
-- cantidad total de canciones del género al que pertenece y cantidad total de canciones del sistema

SELECT t."track_id",
		t."name" AS "cancion", 
		al."title" AS "album", 
		g."name" AS "genero", 
		COUNT(*) OVER (PARTITION BY t."album_id") AS "canciones_album",
		COUNT(*) OVER (PARTITION BY t."genre_id") AS "canciones_genero",
		COUNT(*) OVER () AS "canciones_totales_sistema"
FROM "track" t
LEFT JOIN "album" al ON al."album_id" = t."album_id"
LEFT JOIN "genre" g ON g."genre_id" = t."genre_id"
ORDER BY t."track_id"


-- Ejercicio 24:Ídem anterior, con el agregado de un campo que indique el porcentaje que representa el total de
-- canciones del género al que pertenece sobre el total de canciones del sistema. El porcentaje debe
-- mostrarse con 2 decimales.
WITH conteo AS (
SELECT t."track_id",
		t."name" AS "cancion", 
		al."title" AS "album", 
		g."name" AS "genero", 
		COUNT(*) OVER (PARTITION BY t."album_id") AS "canciones_album",
		COUNT(*) OVER (PARTITION BY t."genre_id") AS "canciones_genero",
		COUNT(*) OVER () AS "canciones_totales_sistema"
FROM "track" t
LEFT JOIN "album" al ON al."album_id" = t."album_id"
LEFT JOIN "genre" g ON g."genre_id" = t."genre_id"
ORDER BY t."track_id"
)

SELECT *, ROUND(100.0*"canciones_genero"/"canciones_totales_sistema",2) AS "porcentaje_genero"
FROM "conteo"
ORDER BY "porcentaje_genero" DESC


-- Ejercicio 25: Enumerar todas las facturas (Invoice), ordenadas por ID, mostrando los siguientes datos: id de
-- factura, fecha de factura, id de cliente, nombre y apellido del cliente, monto total, diferencia de
-- monto con la factura previa del sistema y la diferencia de monto con la factura previa del mismo
-- cliente. En caso de no tener factura previa, registrar null


SELECT i."invoice_id", 
		i."invoice_date", 
		i."customer_id", 
		c."first_name", 
		c."last_name", 
		i."total",
		i."total" - LAG(i.total) OVER (ORDER BY i."invoice_id") AS "dif_factura_previa",
		i."total" - LAG(i.total) OVER (PARTITION BY i."customer_id" ORDER BY i."invoice_id") AS "dif_previa_cliente"
FROM "invoice" i
JOIN "customer" c ON c."customer_id" = i."customer_id"
ORDER BY i."invoice_id"


-- Ejercicio 26: Devolver las facturas (Invoice) que tengan el mínimo monto total de las facturas del sistema,
-- ordenadas por ID Cliente y ID Factura, mostrando los siguientes datos: id de factura, fecha de
-- factura, id de cliente, nombre y apellido del cliente, monto total.

-- A: Con funciones de ventana

WITH facturas AS (
	SELECT i."invoice_id", i."invoice_date", i."customer_id", c."first_name", c."last_name", i."total", 
			MIN(i."total") OVER() AS "min_total"
	FROM "invoice" i
	JOIN "customer" c ON c."customer_id" = i."customer_id" 
)

SELECT "invoice_id", "invoice_date", "customer_id", "first_name", "last_name", "total"
FROM "facturas"
WHERE "total" = "min_total"
ORDER BY "customer_id", "invoice_id"


-- B: Sin funciones de ventana

SELECT i."invoice_id", i."invoice_date", i."customer_id", c."first_name", c."last_name", i."total"
FROM "invoice" i
JOIN "customer" c ON i."customer_id" = c."customer_id"
WHERE i."total" = (SELECT MIN(total) FROM "invoice")
ORDER BY "customer_id", "invoice_id"


-- Ejercicio 27: Devolver las facturas (Invoice) que tengan el mínimo y el máximo monto total de las facturas de
-- cada cliente, ordenadas por ID , mostrando los siguientes datos: id de factura, fecha de factura, id
-- de cliente, nombre y apellido del cliente, monto total y un campo indicativo de mínimo/máximo.
-- Utilizar funciones de ventana en la solución

WITH facturas AS (
	SELECT i."invoice_id", i."invoice_date", i."customer_id", c."first_name", c."last_name", i."total", 
			MIN(i."total") OVER(PARTITION BY i."customer_id") AS "min_cliente",
			MAX(i."total") OVER(PARTITION BY i."customer_id") AS "max_cliente"
	FROM "invoice" i
	JOIN "customer" c ON c."customer_id" = i."customer_id" 
)

SELECT "invoice_id", "invoice_date", "customer_id", "first_name", "last_name", "total",
	CASE
		WHEN "min_cliente" = "max_cliente" THEN 'Minimo y Maximo'
		WHEN "total" = "min_cliente" THEN 'Minimo'
		ELSE 'Maximo'
	END AS "tipo"
FROM "facturas"
WHERE "total" = "min_cliente" OR "total" = "max_cliente"
ORDER BY "customer_id", "invoice_id"




















