import json
import time
import redis

r = redis.Redis(host='localhost', port=6379, db=0, decode_responses=True)
print(r.ping())  

# Ejercicio 1:
print("\nEjercicio 1")

r.delete("tareas:pendientes")
# a) Agregar tareas
r.rpush("tareas:pendientes", "Comprar pan", "Pagar luz", "Estudiar Redis","Llamar a Ana")

# b) Recuperar todas 
print(r.lrange("tareas:pendientes", 0, -1))  

# c) Eliminar una tarea por su valor (0 = todas las apariciones)
print(r.lrem("tareas:pendientes", 0, "Pagar luz"))
print(r.lrange("tareas:pendientes", 0, -1))  

# d) corregir el texto de una tarea
indice = r.lpos("tareas:pendientes", "Estudiar Redis")
r.lset("tareas:pendientes", indice, "Estudiar Redis y MongoDB")
print(r.lrange("tareas:pendientes", 0, -1))

# e) primera y última tarea
print("Primera tarea:", r.lindex("tareas:pendientes", 0))
print("Última tarea:", r.lindex("tareas:pendientes", -1))

# Ejercicio 2:
print("\nEjercicio 2")

r.delete("usuario:1042:busquedas")
 
for busqueda in ["zapatillas", "remera negra", "campera", "mochila",
                 "gorra", "medias", "buzo"]:
    r.lpush("usuario:1042:busquedas", busqueda)     # a) al frente
    r.ltrim("usuario:1042:busquedas", 0, 4)         # b) quedan las 5 primeras
    print(r.lrange("usuario:1042:busquedas", 0, -1))  # c)


# Ejercicio 3:
print("\nEjercicio 3")

r.delete("empleado:501")
 
# a) guardar
r.hset("empleado:501", mapping={"nombre": "Marta Ruiz", "puesto": "Analista", "salario": 900000})
 
# b) leer
print(r.hgetall("empleado:501"))
 
# c) actualizar el salario
r.hset("empleado:501", "salario", 1000000)
print(r.hgetall("empleado:501"))
 
# d) eliminar el puesto
print(r.hdel("empleado:501", "puesto"))   # 1
print(r.hgetall("empleado:501"))
 
# e) sumar un bono y leer solo el salario
print(r.hincrby("empleado:501", "salario", 150000))   # 1150000
print(r.hget("empleado:501", "salario"))              # '1150000'

# Ejercicio 4:
print("\nEjercicio 4")

# a) tres conjuntos de clientes (con repetidos)
r.sadd("clientes:activos", "C1", "C2", "C3", "C4", "C5")
r.sadd("clientes:morosos", "C3", "C6", "C7")
r.sadd("clientes:premium", "C2", "C4", "C7")

# b) premium y además activos
print(r.sinter("clientes:premium", "clientes:activos"))   # {'C2', 'C4'}
 
# c) activos que no son premium
print(r.sdiff("clientes:activos", "clientes:premium"))    # {'C1', 'C3', 'C5'}
 
# d) ¿C3 es moroso?
print(r.sismember("clientes:morosos", "C3"))   # 1 (o True)
print(r.sismember("clientes:morosos", "C1"))   # 0 (o False)

# Ejercicio 5:
print("\nEjercicio 5")

# a) diccionario
reserva = {
    "salida": "EZE",
    "llegada": "MAD",
    "fecha": "2026-12-15",
    "asiento": "23A",
    "precio": 1250.50,
    "comida": ["vegetariana", "sin lactosa"],
}
 
# b) a string JSON
reserva_json = json.dumps(reserva, ensure_ascii=False)
print(type(reserva_json), reserva_json)
 
# c) guardar en Redis
r.set("reserva:AR1132", reserva_json)
 
# d) recuperar y volver a diccionario
reserva_recuperada = json.loads(r.get("reserva:AR1132"))
 
# e) imprimir
print(type(reserva_recuperada), reserva_recuperada)

 # Ejercicio 6:
print("\nEjercicio 6")

# a) clave con 45 segundos de vida
r.set("sesion:temporal", "activa", ex=45)
 
# b) y c) consultar el ttl cada segundo
avisado = False
while True:
    ttl = r.ttl("sesion:temporal")
    if ttl == -2:                      # -2: la clave ya no existe
        print("La clave expiró")
        break
    if ttl <= 10 and not avisado:      # <= y bandera: no saltearse el 10 ni avisar dos veces
        print(f"Quedan {ttl} segundos de vida")
        avisado = True
    time.sleep(1)
 
# Ejercicio 7:
print("\nEjercicio 7")

r.delete("features:cliente:1042")
 
# a) compras del cliente
compras = [
    {"fecha": "2026-10-01", "monto": 12000},
    {"fecha": "2026-10-08", "monto": 25000},
    {"fecha": "2026-10-20", "monto": 8000},
]
 
# b) calcular y guardar en el hash del cliente
cantidad = len(compras)
ticket_promedio = sum(c["monto"] for c in compras) / cantidad
r.hset("features:cliente:1042", mapping={
    "cantidad_compras": cantidad,
    "ticket_promedio": round(ticket_promedio, 2),
})
 
# c) leer solo esos dos campos, como el modelo
print(r.hmget("features:cliente:1042", ["cantidad_compras", "ticket_promedio"]))   # ['3', '15000.0']
 
# d) compra nueva: recalcular y reemplazar
compras.append({"fecha": "2026-11-02", "monto": 35000})
cantidad = len(compras)
ticket_promedio = sum(c["monto"] for c in compras) / cantidad
r.hset("features:cliente:1042", mapping={
    "cantidad_compras": cantidad,
    "ticket_promedio": round(ticket_promedio, 2),
})
print(r.hmget("features:cliente:1042", ["cantidad_compras", "ticket_promedio"]))