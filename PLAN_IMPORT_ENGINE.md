# PLAN: Import Engine Universal + Cotización Profesional Multi-Ítem

## RESUMEN EJECUTIVO

Dos funcionalidades a implementar:
1. **Import Engine Universal** — Importar Excel/CSV en 6 módulos (Clientes, Vehículos, Conductores, Combustible, Gastos, Mantenimiento) con preview, mapeo inteligente y validación
2. **Cotización Profesional Multi-Ítem** — Rediseñar cotizaciones para soportar múltiples líneas de servicio (Carga Suelta, Contenedor, Round Trip, etc.) como la imagen de MCM Logística

---

## PARTE 1: IMPORT ENGINE UNIVERSAL

### Arquitectura

```
Frontend (index.html)                 Backend (Express)
┌──────────────────────┐         ┌──────────────────────────┐
│ Botón 📤 Importar    │         │ POST /import/analyze     │
│ en cada módulo       │────→    │  - Lee XLSX/CSV          │
│                      │         │  - Detecta columnas      │
│ Modal Import Preview │←────    │  - Mapea con sinónimos   │
│ - Columnas detectadas│         │  - Retorna preview JSON  │
│ - Mapeo sugerido     │         │                          │
│ - Errores mostrados  │         │ POST /import/confirm     │
│ - Editar mapeo manual│────→    │  - Valida datos          │
│                      │         │  - Normaliza             │
│ Resultado final      │←────    │  - Inserta en BD         │
│ ✅ 45 importados     │         │  - Resuelve duplicados   │
│ ⚠️ 3 con errores     │         │  - Resuelve FKs          │
└──────────────────────┘         └──────────────────────────┘
```

### Archivos a crear/modificar

#### BACKEND — Archivos NUEVOS:

**1. `src/services/importEngine.js`** — Motor central (≈200 líneas)
- `analyzeFile(buffer, fileType, moduleName)` → Retorna: `{ headers, mappings, preview, errors }`
- `confirmImport(mappedData, moduleName, empresaId, duplicateAction)` → Retorna: `{ insertados, actualizados, errores }`
- Diccionario de sinónimos por módulo (NO hardcoded, configurable)
- Fuzzy matching con scoring de confianza (distancia Levenshtein simplificada)

**2. `src/config/importSchemas.js`** — Schemas declarativos por módulo (≈150 líneas)
```js
export const IMPORT_SCHEMAS = {
  clientes: {
    table: 'clientes',
    fields: {
      rut:          { type: 'rut',    required: false, synonyms: ['rut','rut_empresa','id_tributario','tax_id'] },
      razon_social: { type: 'text',   required: true,  synonyms: ['razon_social','nombre','empresa','company','cliente','razón social'] },
      contacto:     { type: 'text',   required: false, synonyms: ['contacto','persona_contacto','contact','responsable'] },
      telefono:     { type: 'phone',  required: false, synonyms: ['telefono','fono','tel','phone','celular','móvil'] },
      email:        { type: 'email',  required: false, synonyms: ['email','correo','mail','e-mail'] },
      tarifa_base:  { type: 'money',  required: false, synonyms: ['tarifa','tarifa_base','precio','rate','monto'] },
    },
    uniqueKey: ['rut'],           // Para detectar duplicados
    uniqueFallback: ['razon_social'], // Si no hay rut, usar nombre
  },
  vehiculos: {
    table: 'vehiculos',
    fields: {
      patente:  { type: 'patente', required: true,  synonyms: ['patente','placa','plate','matricula','licencia_vehiculo'] },
      marca:    { type: 'text',    required: false, synonyms: ['marca','brand','fabricante'] },
      modelo:   { type: 'text',    required: false, synonyms: ['modelo','model','tipo_vehiculo'] },
      ano:      { type: 'year',    required: false, synonyms: ['año','ano','year','año_fabricacion'] },
      km:       { type: 'number',  required: false, synonyms: ['km','kilometraje','odometro','mileage','kilometros'] },
      estado:   { type: 'enum',    required: false, synonyms: ['estado','status','condicion'], values: ['operativo','mantenimiento','baja'] },
    },
    uniqueKey: ['patente'],
  },
  conductores: {
    table: 'conductores',
    fields: {
      rut:                   { type: 'rut',   required: false, synonyms: ['rut','rut_conductor','cedula','id'] },
      nombre:                { type: 'name',  required: true,  synonyms: ['nombre','nombre_completo','conductor','driver','chofer'] },
      telefono:              { type: 'phone', required: false, synonyms: ['telefono','fono','tel','celular','phone'] },
      licencia:              { type: 'text',  required: false, synonyms: ['licencia','tipo_licencia','license','clase_licencia'] },
      vencimiento_licencia:  { type: 'date',  required: false, synonyms: ['vencimiento','venc_licencia','expiry','caducidad','vigencia'] },
      estado:                { type: 'enum',  required: false, synonyms: ['estado','status'], values: ['activo','inactivo'] },
    },
    uniqueKey: ['rut'],
    uniqueFallback: ['nombre'],
  },
  combustible: {
    table: 'combustible',
    fields: {
      fecha:        { type: 'date',   required: false, synonyms: ['fecha','date','dia'] },
      litros:       { type: 'number', required: true,  synonyms: ['litros','lts','galones','cantidad','liters'] },
      precio_litro: { type: 'money',  required: true,  synonyms: ['precio_litro','precio','price','costo_litro','precio_por_litro'] },
      odometro:     { type: 'number', required: false, synonyms: ['odometro','km','kilometraje','mileage'] },
      _vehiculo:    { type: 'fk_patente', required: false, synonyms: ['vehiculo','patente','placa','camion','truck'], resolveTo: 'vehiculo_id' },
    },
    uniqueKey: null, // No hay duplicados en combustible
  },
  gastos: {
    table: 'gastos',
    fields: {
      fecha:       { type: 'date',   required: false, synonyms: ['fecha','date'] },
      categoria:   { type: 'enum',   required: false, synonyms: ['categoria','tipo','category','tipo_gasto'], values: ['repuesto','lubricante','lavado','peaje','multa','seguro','otro'] },
      descripcion: { type: 'text',   required: true,  synonyms: ['descripcion','detalle','concepto','description','motivo','glosa'] },
      monto:       { type: 'money',  required: true,  synonyms: ['monto','valor','total','amount','costo','precio'] },
      _vehiculo:   { type: 'fk_patente', required: false, synonyms: ['vehiculo','patente','placa','camion'], resolveTo: 'vehiculo_id' },
    },
    uniqueKey: null,
  },
  mantenimiento: {
    table: 'mantenimiento',
    fields: {
      tipo:             { type: 'enum',   required: false, synonyms: ['tipo','type','clase'], values: ['preventivo','correctivo','revision'] },
      descripcion:      { type: 'text',   required: true,  synonyms: ['descripcion','detalle','trabajo','description','motivo'] },
      km_programado:    { type: 'number', required: false, synonyms: ['km','kilometraje','km_programado'] },
      fecha_programada: { type: 'date',   required: false, synonyms: ['fecha','fecha_programada','scheduled_date','date'] },
      estado:           { type: 'enum',   required: false, synonyms: ['estado','status'], values: ['pendiente','en_progreso','completado'] },
      _vehiculo:        { type: 'fk_patente', required: false, synonyms: ['vehiculo','patente','placa','camion'], resolveTo: 'vehiculo_id' },
    },
    uniqueKey: null,
  },
};
```

**3. `src/routes/importRoutes.js`** — 2 endpoints (≈30 líneas)
- `POST /import/analyze` — Recibe archivo + módulo, retorna preview
- `POST /import/confirm` — Recibe datos mapeados, ejecuta inserción

**4. `src/controllers/importController.js`** — Lógica HTTP (≈80 líneas)

#### BACKEND — Archivos a MODIFICAR:

**5. `src/app.js`** — Agregar `app.use('/import', importRoutes)`

**6. `src/services/aiService.js`** — Agregar normalizador de teléfono y email (reusar normalizers existentes)

**7. `package.json`** — Agregar `csv-parser` para soporte CSV

#### FRONTEND — Archivo a MODIFICAR:

**8. `index.html`** — Agregar en cada módulo:

a) **Botón "📤 Importar"** al lado del botón "📥 Excel" existente (6 módulos)

b) **Modal Import Universal** (`mImport`) — Un solo modal reutilizable:
   - Paso 1: Subir archivo + seleccionar módulo (auto-detectado según tab activo)
   - Paso 2: Preview con tabla de mapeo (columna Excel ↔ campo BD, score confianza)
   - Paso 3: Editar mapeo manual + elegir acción duplicados (ignorar/actualizar/duplicar)
   - Paso 4: Resultado (X importados, Y errores descargables)

c) **Funciones JS** (≈250 líneas):
   - `openImportModal(modulo)` — Abre modal con módulo preseleccionado
   - `importAnalyze()` — Envía archivo a backend, muestra preview
   - `importEditMapping(colIdx)` — Permite cambiar mapeo manual
   - `importConfirm()` — Confirma importación
   - `importDownloadErrors()` — Descarga errores como Excel

### Flujo de usuario

```
1. Click "📤 Importar" en módulo Clientes
2. Modal abre → seleccionar archivo .xlsx o .csv
3. Backend analiza → retorna:
   {
     headers: ["RUT", "Nombre Empresa", "Fono", "Mail"],
     mappings: [
       { header: "RUT",            field: "rut",          score: 1.0  },
       { header: "Nombre Empresa", field: "razon_social", score: 0.85 },
       { header: "Fono",           field: "telefono",     score: 0.80 },
       { header: "Mail",           field: "email",        score: 0.90 },
     ],
     preview: [
       { rut: "76.543.210-K", razon_social: "Trans. Valpo SpA", telefono: "...", email: "..." },
       ...primeras 5 filas...
     ],
     stats: { total_rows: 48, valid: 45, errors: 3 },
     errors: [
       { row: 12, field: "rut", message: "RUT inválido: abc" },
       ...
     ]
   }
4. Usuario ve preview → puede cambiar mapeo manualmente
5. Selecciona acción duplicados: "Ignorar" / "Actualizar" / "Crear duplicado"
6. Click "Confirmar Importación"
7. Backend procesa → retorna resultado final
8. Toast: "✅ 45 clientes importados · 3 omitidos (descargar log)"
```

### Resolución de Foreign Keys

Para módulos que tienen `vehiculo_id` (Combustible, Gastos, Mantenimiento):
- Si el Excel tiene una columna "Patente" o "Vehículo"
- El backend busca en `vehiculos WHERE patente = X AND empresa_id = Y`
- Si encuentra → usa el UUID
- Si no encuentra → campo queda NULL + warning "Vehículo XYZ-12 no encontrado"

### Detección de duplicados

Cada schema define `uniqueKey` (ej: `['rut']` para clientes, `['patente']` para vehículos).
El backend consulta la BD antes de insertar y marca cada fila como:
- `new` — No existe, se insertará
- `duplicate` — Ya existe, según acción del usuario: ignorar/actualizar/crear

---

## PARTE 2: COTIZACIÓN PROFESIONAL MULTI-ÍTEM

### Cambios requeridos

**Problema actual:** Cotizaciones tienen 1 solo monto y 1 descripción genérica.
**Lo que pide el usuario:** Múltiples ítems como "Carga Suelta", "Contenedor", "Round Trip" con cantidad, precio unitario, total por línea, subtotal neto, IVA 19%, total general.

### Cambio en BD — Nueva tabla `cotizacion_items`

```sql
CREATE TABLE cotizacion_items (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cotizacion_id UUID NOT NULL REFERENCES cotizaciones(id) ON DELETE CASCADE,
  descripcion   TEXT NOT NULL,
  cantidad      INTEGER DEFAULT 1,
  precio_unit   NUMERIC DEFAULT 0,
  total         NUMERIC GENERATED ALWAYS AS (cantidad * precio_unit) STORED,
  orden         INTEGER DEFAULT 0
);

-- RLS
ALTER TABLE cotizacion_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "items by cotizacion owner" ON cotizacion_items
  FOR ALL USING (
    cotizacion_id IN (SELECT id FROM cotizaciones WHERE empresa_id = get_my_empresa_id())
  );
```

Además agregar columnas a `cotizaciones`:
```sql
ALTER TABLE cotizaciones ADD COLUMN IF NOT EXISTS condiciones_comerciales TEXT;
ALTER TABLE cotizaciones ADD COLUMN IF NOT EXISTS datos_bancarios TEXT;
ALTER TABLE cotizaciones ADD COLUMN IF NOT EXISTS atencion TEXT;  -- "Atención a: Sergio Carrasco"
ALTER TABLE cotizaciones ADD COLUMN IF NOT EXISTS direccion_cliente TEXT;
```

### Cambio en el modal de cotización (index.html)

El modal actual tiene 1 campo "Monto". Cambiará a:

- Campo "Atención a" (persona de contacto del cliente)
- **Tabla de ítems dinámica** con botón "+ Agregar Ítem":
  | Descripción del Servicio | Cantidad | Precio Unitario | Total |
  | Flete carga suelta - puerto Valparaíso a SCL | 1 | $340.000 | $340.000 |
  | Round Trip desde SAI o VAP (Devolución vacío mismo Puerto) | 1 | $350.000 | $350.000 |
  | [+ Agregar Ítem] | | | |

- Cálculo automático: Subtotal Neto, IVA 19%, Total General
- Campo "Condiciones Comerciales" (textarea)
- Campo "Datos Bancarios" (textarea)
- Select rápido tipo servicio: Carga Suelta, Contenedor 20', Contenedor 40', Round Trip, Devolución Vacío, Almacenaje, etc.

### Template "Corporativo" inspirado en MCM Logística

Se agregará un **4to template** al preview de cotizaciones:

- Header con logo + nombre empresa + banner decorativo
- Título "COTIZACIÓN FORMAL"
- Nro. de Cotización + Fecha de Emisión
- Sección 1: Datos del Emisor (RUT, dirección, contacto)
- Sección 2: Datos del Cliente (empresa, atención a, dirección)
- Sección 3: Tabla de servicios con columnas: Descripción, Cantidad, Precio Unitario, Total
- Fila Subtotal Neto + fila IVA 19% + fila TOTAL GENERAL destacada
- Condiciones Comerciales
- Datos para Transferencia
- Footer con logo empresa

### Tipos de servicio predefinidos (modificables)

```js
const SERVICIOS_COTIZACION = [
  { label: 'Flete carga suelta', value: 'carga_suelta' },
  { label: 'Contenedor 20\'', value: 'contenedor_20' },
  { label: 'Contenedor 40\'', value: 'contenedor_40' },
  { label: 'Round Trip (devolución vacío mismo puerto)', value: 'round_trip_mismo' },
  { label: 'Round Trip (devolución vacío distinto puerto)', value: 'round_trip_distinto' },
  { label: 'Almacenaje', value: 'almacenaje' },
  { label: 'Servicio personalizado', value: 'custom' },
];
```

El usuario puede seleccionar uno de estos o escribir descripción libre.

---

## ORDEN DE IMPLEMENTACIÓN

### FASE 1 — Import Engine Backend (archivos nuevos, no rompe nada)
1. Crear `src/config/importSchemas.js`
2. Crear `src/services/importEngine.js`
3. Instalar `csv-parser`
4. Crear `src/controllers/importController.js`
5. Crear `src/routes/importRoutes.js`
6. Registrar en `src/app.js`
7. Test: todos los endpoints existentes siguen funcionando

### FASE 2 — Import Engine Frontend (agregar modal + botones)
1. Agregar botón "📤 Importar" a los 6 módulos
2. Crear modal universal `mImport` con flujo 4 pasos
3. Funciones JS: openImportModal, importAnalyze, importConfirm
4. Test: importar archivo Excel de clientes de prueba

### FASE 3 — Cotización Multi-Ítem (BD + formulario)
1. Crear tabla `cotizacion_items` + RLS
2. Agregar columnas a `cotizaciones`
3. Modificar modal cotización → tabla ítems dinámica con "+ Agregar Ítem"
4. Modificar `saveCotizacion()` → guardar ítems
5. Modificar `renderCotizaciones()` → mostrar total calculado
6. Agregar select de tipos de servicio (carga suelta, contenedor, etc.)

### FASE 4 — Template Corporativo cotización
1. Agregar 4to template "🏢 Corporativo" al selector
2. Implementar `_renderPreview` para template corporativo (estilo MCM Logística)
3. Renderizar múltiples ítems en la tabla del PDF/preview
4. Mostrar Subtotal + IVA + Total General
5. Mostrar condiciones comerciales y datos bancarios
6. Test: crear cotización con 3 ítems y generar preview

---

## QUÉ NO SE TOCA

- ❌ No se modifica el flujo de login/auth
- ❌ No se tocan las tablas existentes (solo se agregan columnas opcionales)
- ❌ No se modifica rescate-sabor, FinancePro ni tradeos
- ❌ No se rompe la importación actual de Documentos
- ❌ No se eliminan templates existentes de cotización (clásico, moderno, minimal siguen)
- ❌ No se mueven controllers/routes existentes

## RIESGO CERO

Todo es **aditivo**:
- Archivos nuevos en backend (no modifica controllers existentes)
- Botones nuevos en HTML (al lado de los existentes)
- 1 modal nuevo reutilizable
- 1 tabla nueva en BD (cotizacion_items)
- Columnas nuevas con DEFAULT NULL (no rompen queries existentes)
