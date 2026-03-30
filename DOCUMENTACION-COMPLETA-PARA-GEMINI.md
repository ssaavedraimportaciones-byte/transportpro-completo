# 📋 DOCUMENTACIÓN COMPLETA - TRANSPORTPRO
## Para continuar configuración con Gemini u otra IA

---

## 🎯 ESTADO ACTUAL DEL PROYECTO

### ✅ LO QUE YA ESTÁ HECHO:

1. **Base de datos Supabase:** ✅ CREADA
   - Proyecto: transportpro
   - URL: https://wylmxqjpkdqxtqjkuqqn.supabase.co
   - Tablas creadas: empresas, usuarios, vehiculos, conductores, clientes, viajes, combustible, neumaticos, mantenimiento, gastos, facturas
   - Función SQL creada: `crear_usuario_directo()`

2. **Archivos del sistema:** ✅ COMPLETADOS
   - admin-profesional.html (Panel admin)
   - transportpro-login.html (Sistema con login)
   - transportpro-final-standalone.html (Sistema sin login)

3. **Credenciales Supabase:**
   - ANON KEY: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind5bG14cWpwa2RxeHRxamt1cXFuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MjM1NjIsImV4cCI6MjA4ODE5OTU2Mn0.w48iwlUoXw1dQVm_j58vBElTWTSN57Vym8T1Wy-Osy4
   - SERVICE_ROLE KEY: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind5bG14cWpwa2RxeHRxamt1cXFuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MjYyMzU2MiwiZXhwIjoyMDg4MTk5NTYyfQ.2z0ExceaUfUXoj-XocTeO8l1EhUszzc5E3Rr8PqgCCE
   - PROJECT URL: https://wylmxqjpkdqxtqjkuqqn.supabase.co

---

## 🚀 PRÓXIMOS PASOS (PARA GEMINI)

### PASO 1: DEPLOY A NETLIFY (URGENTE - 2 MIN)

**Instrucciones para Gemini:**

"Necesito hacer deploy de 3 archivos HTML a Netlify. Los archivos son:
- admin-profesional.html
- transportpro-login.html
- transportpro-final-standalone.html

Guíame paso a paso para:
1. Crear cuenta en Netlify
2. Usar Netlify Drop para subir los archivos
3. Obtener las URLs públicas
4. Verificar que funcionan correctamente"

---

### PASO 2: CONFIGURAR EMAIL CONFIRMATION EN SUPABASE

**Contexto para Gemini:**

"Tengo un proyecto Supabase (transportpro) y necesito desactivar la confirmación de email. 

Mi problema: Los usuarios que creo con la función SQL necesitan iniciar sesión sin confirmar email.

URL Supabase: https://wylmxqjpkdqxtqjkuqqn.supabase.co

Guíame paso a paso para:
1. Ir a Authentication → Settings
2. Encontrar la opción 'Enable email confirmations'
3. Desactivarla correctamente
4. Verificar que funcionó"

---

### PASO 3: CREAR PRIMERA EMPRESA Y USUARIO DE PRUEBA

**Instrucciones para Gemini:**

"Ya tengo el panel admin desplegado en Netlify. Necesito crear una empresa y un usuario de prueba.

Panel admin URL: [LA QUE TE DIO NETLIFY]

Datos de la empresa demo existente:
- RUT: 76.123.456-7
- Nombre: Transportes Demo SpA

Guíame para:
1. Abrir el panel admin
2. Crear una nueva empresa de prueba
3. Crear un usuario admin para esa empresa
4. Guardar las credenciales de acceso
5. Probar el login en transportpro-login.html"

---

### PASO 4: CONFIGURAR DOMINIO PERSONALIZADO (OPCIONAL)

**Para Gemini:**

"Quiero configurar un dominio personalizado para el sistema. Tengo o quiero registrar: zeropaper.cl

Opciones:
A) Conectar dominio existente a Netlify
B) Registrar nuevo dominio en nic.cl y conectarlo

Guíame paso a paso según la opción que elija."

---

### PASO 5: PREPARAR VIDEO DEMO

**Instrucciones para Gemini:**

"Necesito crear un video demo profesional de 90 segundos para mostrar TransportPro a empresas de transporte en Chile.

Contexto:
- Sistema de gestión de transporte
- Target: Empresas con 5-20 camiones
- Precio: $59.990 CLP/mes
- Beneficio principal: Ahorran $300.000+/mes en combustible y mantenimiento

Necesito:
1. Script completo del video (90 segundos)
2. Recomendación de herramienta: HeyGen vs ElevenLabs vs Loom
3. Guión técnico (qué mostrar en cada segundo)
4. Call to action efectivo

El sistema tiene estos módulos:
- Dashboard ejecutivo
- Viajes
- Clientes
- Facturación
- Combustible
- Neumáticos
- Mantenimiento preventivo
- Gastos
- Flota
- Conductores
- Rentabilidad"

---

### PASO 6: ESTRATEGIA DE VENTAS

**Para Gemini:**

"Tengo TransportPro listo para vender. Necesito estrategia go-to-market para Chile.

Target: Empresas de transporte en Valparaíso y San Antonio
Competencia: Cobran $80.000-$150.000/mes
Mi precio: $59.990/mes plan Professional

Necesito:
1. Pitch deck (estructura de 10 slides)
2. Email de prospección (3 variantes)
3. Script de llamada telefónica
4. Oferta piloto gratis 30 días
5. Lista de primeras 20 empresas a contactar en Valparaíso"

---

## 📊 INFORMACIÓN TÉCNICA DEL SISTEMA

### Arquitectura:
- **Frontend:** HTML + JavaScript vanilla
- **Base de datos:** Supabase (PostgreSQL)
- **Autenticación:** Supabase Auth
- **Storage:** localStorage (standalone) / Supabase (multi-user)
- **Deploy:** Netlify (frontend) + Supabase (backend)

### Módulos implementados:
1. Dashboard ejecutivo con KPIs
2. Gestión de viajes (estados: planificado, en_ruta, completado)
3. Clientes (RUT, razón social, contacto)
4. Facturación y cobranza (estados: pendiente, pagada, vencida)
5. Control de combustible (litros, precio, rendimiento)
6. Control de neumáticos (profundidad, alertas cambio)
7. Mantenimiento preventivo (programación por KM)
8. Gastos operacionales (categorías múltiples)
9. Flota de vehículos (estado, kilometraje)
10. Conductores (licencias, vencimientos)
11. Análisis de rentabilidad (por ruta, cliente, vehículo)

### Esquema de base de datos:
- empresas (id, nombre, rut, plan, activa, fecha_inicio)
- usuarios (id, empresa_id, nombre, rol, activo)
- vehiculos (id, empresa_id, patente, marca, modelo, ano, km, estado)
- conductores (id, empresa_id, rut, nombre, telefono, licencia, vencimiento_licencia, estado)
- clientes (id, empresa_id, rut, razon_social, contacto, telefono, email, tarifa_base, estado)
- viajes (id, empresa_id, numero, cliente_id, vehiculo_id, conductor_id, fecha, origen, destino, km_inicial, km_final, tarifa, estado)
- combustible (id, empresa_id, vehiculo_id, fecha, litros, precio_litro, total, odometro)
- neumaticos (id, empresa_id, vehiculo_id, serie, posicion, marca, km_instalacion, profundidad_inicial, profundidad_actual, estado)
- mantenimiento (id, empresa_id, vehiculo_id, tipo, descripcion, km_programado, fecha_programada, estado)
- gastos (id, empresa_id, vehiculo_id, fecha, categoria, descripcion, monto)
- facturas (id, empresa_id, numero, cliente_id, fecha, vencimiento, monto, estado)

### Row Level Security (RLS):
- Cada empresa solo ve sus propios datos
- Roles: admin (control total), contador (lectura + edición), operador (solo lectura)

---

## 💰 MODELO DE NEGOCIO

### Planes de precios (CLP):
- **Starter:** $29.990/mes (hasta 3 vehículos)
- **Professional:** $59.990/mes (hasta 10 vehículos) ⭐ Recomendado
- **Enterprise:** $99.990/mes (vehículos ilimitados + soporte)

### Propuesta de valor:
- Ahorro combustible: $300.000/mes (5% mejor rendimiento)
- Ahorro neumáticos: $150.000/mes (control desgaste)
- Reducción paradas: $200.000/mes (mantenimiento preventivo)
- Mejora cobranza: $400.000/mes (facturación ordenada)
- **ROI estimado: 2,070%**

### Mercado objetivo:
- Empresas de transporte 5-20 vehículos
- Región Valparaíso y San Antonio
- Target inicial: 30 empresas = $1.8M CLP/mes ($21.6M anuales)

---

## 🔐 CREDENCIALES Y ACCESOS

### Supabase:
- Email cuenta: [TU EMAIL]
- Password: [TU PASSWORD]
- Proyecto: transportpro
- Region: South America (São Paulo)

### Netlify:
- [Crear cuenta cuando hagas deploy]

### Dominio (futuro):
- zeropaper.cl (pendiente registro en nic.cl)

---

## 📞 INFORMACIÓN DE CONTACTO DEL PROYECTO

- **Fundador:** [TU NOMBRE]
- **Ubicación:** Chile, región Valparaíso
- **Target:** TPS Valparaíso, STI San Antonio
- **Fase:** MVP listo, preparando go-to-market

---

## 🎯 OBJETIVOS PRÓXIMOS 30 DÍAS

1. ✅ Sistema desplegado en producción (Netlify)
2. ✅ Primera empresa demo funcionando
3. 📹 Video demo profesional creado
4. 📧 Pitch deck y materiales de venta listos
5. 🤝 Primer piloto gratis con empresa real
6. 💰 Primera venta pagada

---

## ❓ PREGUNTAS FRECUENTES PARA GEMINI

**P: ¿Cómo agrego más módulos al sistema?**
R: El sistema es HTML standalone. Para agregar módulos, necesitas editar el HTML y agregar nuevas secciones con sus funciones JS correspondientes.

**P: ¿Puedo cambiar los precios?**
R: Sí, los precios son solo referenciales. Ajusta según tu mercado.

**P: ¿Funciona sin internet?**
R: La versión standalone (transportpro-final-standalone.html) SÍ. Las versiones con login necesitan internet para Supabase.

**P: ¿Cómo hago backup de los datos?**
R: En Supabase → Database → Backups. También puedes exportar tablas a CSV.

**P: ¿Puedo personalizar el diseño?**
R: Sí, editando los estilos CSS en la sección <style> del HTML.

---

## 🆘 TROUBLESHOOTING COMÚN

**Error: "Failed to fetch"**
- Verificar que URLs de Supabase son correctas
- Verificar que credenciales (anon key) están bien
- Verificar conexión a internet

**Error: "No se puede crear usuario"**
- Verificar que la función `crear_usuario_directo` existe
- Verificar que la empresa existe (RUT correcto)
- Verificar que usas service_role key en admin panel

**Login no funciona:**
- Verificar que usuario tiene email_confirmed_at no nulo
- Ejecutar: `UPDATE auth.users SET email_confirmed_at = NOW() WHERE email = 'usuario@test.cl'`

---

FIN DEL DOCUMENTO
Fecha: 4 de Marzo 2026
Versión: 1.0
