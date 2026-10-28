"""
Carga las colecciones de la guía de MongoDB en el Mongo local (docker compose).

  - clase_mongo.datos-covid          <- owid-covid-data.csv (un documento por país y día)
  - clase_mongo.datos-country-codes  <- Countrycodesfull.json (un documento por país)

Uso:  python cargar_mongo.py
Se puede volver a correr: borra y recrea las dos colecciones.
Los archivos se descargan una sola vez y quedan en esta carpeta.
"""
import json
from pathlib import Path

import pandas as pd
import requests
from pymongo import ASCENDING, MongoClient

URI = "mongodb://admin:secret@localhost:27018/?authSource=admin"
BASE = "clase_mongo"

CSV_URL = "https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/owid-covid-data.csv"
JSON_URL = ("https://raw.githubusercontent.com/dieghernan/Country-Codes-and-International-Organizations/"
            "refs/heads/master/outputs/Countrycodesfull.json")

CARPETA = Path(__file__).resolve().parent
CSV = CARPETA / "owid-covid-data.csv"
JSN = CARPETA / "Countrycodesfull.json"


def descargar(url: str, destino: Path) -> None:
    if destino.exists():
        print(f"{destino.name} ya está descargado.")
        return
    print(f"Descargando {destino.name}...")
    with requests.get(url, stream=True, timeout=60) as resp:
        resp.raise_for_status()
        with open(destino, "wb") as f:
            for parte in resp.iter_content(chunk_size=1 << 20):
                f.write(parte)


def cargar_covid(db) -> None:
    db.drop_collection("datos-covid")
    col = db["datos-covid"]
    total = 0
    # Por partes, para no cargar todo el CSV en memoria de una vez.
    # to_json pasa los NaN a null, igual que en la clase. date queda como texto "AAAA-MM-DD".
    for parte in pd.read_csv(CSV, chunksize=50_000):
        docs = json.loads(parte.to_json(orient="records"))
        col.insert_many(docs)
        total += len(docs)
        print(f"  datos-covid: {total} documentos")
    # Índices para que los filtros de la guía respondan rápido.
    col.create_index([("location", ASCENDING), ("date", ASCENDING)])
    col.create_index("iso_code")
    col.create_index("date")


def cargar_country_codes(db) -> None:
    with open(JSN, encoding="utf-8") as f:
        datos = json.load(f)
    if isinstance(datos, dict):
        datos = [datos]
    # CAPITAL.EN tiene un punto en el nombre: en un pipeline se leería como campo anidado.
    for doc in datos:
        if "CAPITAL.EN" in doc:
            doc["capital_en"] = doc.pop("CAPITAL.EN")
    db.drop_collection("datos-country-codes")
    db["datos-country-codes"].insert_many(datos)


def main() -> None:
    descargar(CSV_URL, CSV)
    descargar(JSON_URL, JSN)

    client = MongoClient(URI, serverSelectionTimeoutMS=5000)
    client.admin.command("ping")  # falla acá si el contenedor no está corriendo
    db = client[BASE]

    print("Cargando datos-covid (puede tardar unos minutos)...")
    cargar_covid(db)
    print("Cargando datos-country-codes...")
    cargar_country_codes(db)

    print("\nListo:")
    for nombre in ("datos-covid", "datos-country-codes"):
        print(f"  {nombre}: {db[nombre].count_documents({})} documentos")


if __name__ == "__main__":
    main()
