# Guia de Ejercicios
## Neo4J

Realizar las consultas que se enumeran a continuación y analizar los resultados. Completar los títulos que faltan.

### Consultas
1. ¿?
MATCH (n) RETURN (n);
2. // Count all
MATCH (n) RETURN count(n);
3. // Count all relationships
MATCH ()-->() RETURN count(*);
MATCH ()-[r]->() RETURN type(r), count(*);
4. // List relationship types
CALL db.relationshipTypes();
5. // What is related, and how
CALL db.schema.visualization();
6. // What kind of nodes exist
MATCH (n) 
RETURN KEYS(n), COUNT(*) AS s ORDER BY s DESC;
7. // Exist?
MATCH (a{name: "Keanu Reeves"} ) RETURN a;
8. ¿?
MATCH (a{name: "Keanu Reeves"} ) -[]-> (f) 
RETURN a, f;
MATCH (a) -[]-> (f) 
WHERE a.name = "Keanu Reeves"
RETURN a, f;
MATCH (a{name: "Keanu Reeves"} ) -[r]-> (f) 
RETURN a, r, f;
9. ¿?
MATCH (a{name: "Keanu Reeves"} ) -[:ACTED_IN]-> (f) 
RETURN a, count(f);
10. ¿?
MATCH (a{name: "Keanu Reeves"} ) -[:ACTED_IN]-> (f) 
RETURN a,  f;

11. ¿?
MATCH (a{name: "Keanu Reeves"} ) -[:ACTED_IN]-> (f) 
RETURN f.title;
12. ¿?
MATCH (n:Movie)
WHERE n.released = 2008
RETURN n.title;
13. ¿?
MATCH (p:Person) RETURN p.name ORDER BY p.name LIMIT 10;
14. ¿?
MATCH (m:Movie) WHERE m.released >1990 AND m.released < 2001 
RETURN m.title, m.released AS y
ORDER BY y DESC;

MATCH (p:Person) 
WHERE p.born IS NOT NULL 
RETURN p.name, (2024-p.born) AS s ORDER BY s DESC  LIMIT 3;
15. ¿?
MATCH (tom:Person {name: "Tom Hanks"})-[:ACTED_IN]->(tomHanksMovies) 
RETURN tom, tomHanksMovies;
16. ¿?
MATCH (cloudAtlas {title: "Cloud Atlas"})<-[:DIRECTED]-(directors) 
RETURN directors.name;
17. ¿?
MATCH (tom:Person {name:"Tom Hanks"})-[:ACTED_IN]->(m)<-[:ACTED_IN]-(coActors) 
RETURN coActors.name;
18. ¿?
MATCH (people:Person)-[relatedTo]-(:Movie {title: "Cloud Atlas"}) 
RETURN people.name, Type(relatedTo), relatedTo;
19. ¿?
MATCH (bacon:Person {name:"Kevin Bacon"})-[*1..4]-(hollywood)
RETURN DISTINCT bacon, hollywood;
20. ¿?
MATCH p=shortestPath(
(bacon:Person {name:"Kevin Bacon"})-[*]-(meg:Person {name:"Meg Ryan"}) )
RETURN p;
21. ¿?
MATCH (tom:Person {name:"Tom Hanks"})-[:ACTED_IN]->(m)<-[:ACTED_IN]-(coActors),
  (coActors)-[:ACTED_IN]->(m2)<-[:ACTED_IN]-(cocoActors)
WHERE NOT (tom)-[:ACTED_IN]->()<-[:ACTED_IN]-(cocoActors) AND tom <> cocoActors
RETURN cocoActors.name AS Recommended, count(*) AS Strength ORDER BY Strength DESC;
22. ¿?
MATCH (tom:Person {name:"Tom Hanks"})-[:ACTED_IN]->(m)<-[:ACTED_IN]-(coActors),
  (coActors)-[:ACTED_IN]->(m2)<-[:ACTED_IN]-(cruise:Person {name:"Tom Cruise"})
RETURN tom, m, coActors, m2, cruise;
23. ¿?
MATCH (p:Person) 
RETURN p.born, COUNT(*) AS s ORDER BY s DESC LIMIT 10;
24. ¿?
MATCH (m:Movie) 
RETURN m.released, COUNT(*) AS s ORDER BY s 
LIMIT 10;
25. ¿?
MATCH (p:Person) SET p.etiqueta = p.name;
MATCH (p:Movie) SET p.etiqueta = p.title;

