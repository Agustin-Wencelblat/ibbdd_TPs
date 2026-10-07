-- Ejercicio 1:

WITH tracks_vendidos AS (
	SELECT i.track_id
	FROM invoice_line i
	)

SELECT *
FROM playlist p
WHERE NOT EXISTS (
	SELECT 1 
	FROM playlist_track pt
	WHERE pt.playlist_id = p.playlist_id AND pt.track_id NOT IN (SELECT track_id FROM tracks_vendidos)
)

-- Ejercicio 2:

SELECT e.employee_id, 
		e.first_name || '-' || e.last_name AS nombre_completo,
		e.hire_date, 
		UPPER(LEFT(e.city, 3)) AS ciudad
FROM employee e
WHERE e.hire_date > (
	SELECT n.hire_date
	FROM employee n
	WHERE n.first_name = 'Nancy' AND n.last_name = 'Edwards'
)


-- Ejercicio 3:

SELECT c.*
FROM customer c
JOIN employee e ON e.employee_id = c.support_rep_id
WHERE c.country = e.country
  AND LENGTH(c.first_name) > 5;

-- Ejercicio 4:

SELECT g.genre_id, g.name
FROM genre g
WHERE NOT EXISTS (
    SELECT 1
    FROM track t
    JOIN invoice_line il ON il.track_id = t.track_id
    WHERE t.genre_id = g.genre_id
);