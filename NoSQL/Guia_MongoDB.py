from pymongo import MongoClient

client = MongoClient("mongodb://admin:secret@localhost:27018/?authSource=admin")
db = client["clase_mongo"]
coleccion_covid = db["datos-covid"]
coleccion_countryCodes = db["datos-country-codes"]

# Seccion 1: Ejercicios introductorios

# Ejercicio 1:
print("\nEjercicio 1 - Continentes distintos")

print(coleccion_covid.distinct("continent"))

# Ejercicio 2:
print("\nEjercicio 2 - Documentos de Australia")
print(coleccion_covid.count_documents({"location": "Australia"}))

# Ejercicio 3:
print("\nEjercicio 3 - Paises con datos el 2022-12-25")
print(coleccion_covid.distinct("location", {
    "date": "2022-12-25",
    "iso_code": {"$regex": "^[A-Z]{3}$"},
}))

# Ejercicio 4:
print("\nEjercicio 4 - Mas de 500 muertes nuevas")

print(coleccion_covid.count_documents({"new_deaths": {"$gt": 500}}))

for doc in coleccion_covid.find(
    {"new_deaths": {"$gt": 500}},
    {"_id": 0, "location": 1, "date": 1, "new_deaths": 1},
).limit(10):
    print(doc)

# Ejercicio 5: 
print("\nEjercicio 5 - Mexico en julio de 2021")

for doc in coleccion_covid.find({
    "location": "Mexico",
    "date": {"$gte": "2021-07-01", "$lte": "2021-07-31"},
}).limit(10):
    print(doc)

# Ejercicio 6
print("\nEjercicio 6 - Argentina, Chile y Uruguay el 2021-01-01")

for doc in coleccion_covid.find({
    "location": {"$in": ["Argentina","Chile","Uruguay"]},
    "date": "2021-01-01",
}).limit(10):
    print(doc)

# Ejercicio 7:
print("\nEjercicio 7 - Paises con mas de 100 millones de habitantes el 2021-01-01")

print(coleccion_covid.count_documents({
    "population": {"$gt": 100_000_000},
    "date": "2021-01-01",
    "iso_code": {"$regex": "^[A-Z]{3}$"},
}))

# Ejercicio 8: 
print("\nEjercicio 8 - Paises in total_tests el 2021-06-01")

print(coleccion_covid.count_documents({
    "date": "2021-06-01",
    "total_tests": None,
    "iso_code": {"$regex": "^[A-Z]{3}$"},
}))

# Ejercicio 9:
print("\nEjercicio 9 - Los 5 dias con mas new_cases de Argentina")

for doc in coleccion_covid.find(
    {"location":"Argentina"},
    {"_id": 0, "location": 1, "date": 1, "new_cases": 1},
).sort("new_cases", -1).limit(5):
    print(doc)


# Seccion 2: Pipelines y aggregate

# Ejercicio 10:
print("\nEjercicio 10 - Documentos de Australia con pipeline")

pipeline = [
    {"$match": {"location": "Australia"}},
    {"$count": "cantidad"}  
]

for doc in coleccion_covid.aggregate(pipeline):
    print(doc)

# Ejercicio 11:
print("\nEjercicio 11 - Suma de new_cases por pais")

pipeline = [
    {"$match": {"iso_code": {"$regex": "^[A-Z]{3}$"}}},
    {"$group": {
        "_id": "$location",
        "total_cases": {"$sum":{"$ifNull": ["$new_cases", 0]}}
    }}]

for doc in coleccion_covid.aggregate(pipeline):
    print(doc)

# Ejercicio 12:
print("\nEjercicio 12 -  Top 10 por casos acumulados")

pipeline = [
    {"$match":{"iso_code": {"$regex":"^[A-Z]{3}$"}}},
    {"$group":{
        "_id": "$location",
        "max_total_cases": {"$max":"$total_cases"}
    }},
    {"$sort": {"max_total_cases": -1}},
    {"$limit": 10},
]

for doc in coleccion_covid.aggregate(pipeline):
    print(doc)

# Ejercicio 13:
print("\nEjercicio 13 - America del Sur: registros por pais")
pipeline = [
    {"$match": {"continentcode": "SA"}},
    {"$lookup": {
        "from": "datos-covid",
        "localField": "ISO_3166_3",
        "foreignField": "iso_code",
        "as": "registros",
    }},
    {"$project": {
        "_id": 0,
        "ISO_3166_3": 1,
        "pais": {"$arrayElemAt": ["$registros.location", 0]},
        "cantidad_registros": {"$size": "$registros"},
    }},
    {"$sort": {"cantidad_registros": -1}},
]
for doc in coleccion_countryCodes.aggregate(pipeline):   # empieza en country-codes
    print(doc)

# Ejercicio 14:
print("\nEjercicio 14 - Argentina: region, area, max tests y proemdios de edad")

pipeline = [
    {"$match": {"iso_code": "ARG"}},
    {"$group": {
        "_id": "$iso_code",
        "max_total_tests": {"$max": "$total_tests"},
        "prom_median_age": {"$avg": "$median_age"},
        "prom_aged_65_older": {"$avg": "$aged_65_older"},
        "prom_aged_70_older": {"$avg": "$aged_70_older"},
    }},
    {"$lookup": {
        "from": "datos-country-codes",
        "localField": "_id",
        "foreignField": "ISO_3166_3",
        "as": "pais",
    }},
    {"$unwind": "$pais"},
    {"$project": {
        "_id": 0,
        "iso_code": "$_id",
        "regioncode": "$pais.regioncode",
        "area_km2": "$pais.area_km2",
        "max_total_tests": 1,
        "prom_median_age": 1,
        "prom_aged_65_older": 1,
        "prom_aged_70_older": 1,
    }},
]
for doc in coleccion_covid.aggregate(pipeline):
    print(doc)

# Ejercicio 15:
print("\nEjercicio 15 - Casos de Argentina por anio")

pipeline = [
    {"$match":{"location":"Argentina"}}
    {"$group"}{
        "_id" : {"$substr": ["$date",0,4]}
    }
]
