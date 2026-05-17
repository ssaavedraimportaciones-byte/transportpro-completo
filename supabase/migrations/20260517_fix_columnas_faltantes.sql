-- ══════════════════════════════════════════════════════════════
-- FIX: columnas faltantes en support_tickets y otras tablas
-- ══════════════════════════════════════════════════════════════

-- support_tickets: el código usa tipo/titulo/descripcion, la migración original tenía asunto/mensaje
ALTER TABLE support_tickets
    ADD COLUMN IF NOT EXISTS tipo        TEXT NOT NULL DEFAULT 'consulta',
    ADD COLUMN IF NOT EXISTS titulo      TEXT,
    ADD COLUMN IF NOT EXISTS descripcion TEXT;

-- Migrar datos existentes si usaban asunto/mensaje
UPDATE support_tickets
    SET titulo = COALESCE(titulo, asunto),
        descripcion = COALESCE(descripcion, mensaje)
    WHERE titulo IS NULL AND asunto IS NOT NULL;

-- viajes: columnas agregadas en migraciones anteriores (idempotente)
ALTER TABLE viajes
    ADD COLUMN IF NOT EXISTS tipo_carga         TEXT,
    ADD COLUMN IF NOT EXISTS numero_guia        TEXT,
    ADD COLUMN IF NOT EXISTS numero_contenedor  TEXT,
    ADD COLUMN IF NOT EXISTS observaciones      TEXT,
    ADD COLUMN IF NOT EXISTS datos_extra        JSONB;

-- clientes: tarifa_base y dirección
ALTER TABLE clientes
    ADD COLUMN IF NOT EXISTS tarifa_base BIGINT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS direccion   TEXT,
    ADD COLUMN IF NOT EXISTS ciudad      TEXT,
    ADD COLUMN IF NOT EXISTS comuna      TEXT;

-- facturas: campos de cobro
ALTER TABLE facturas
    ADD COLUMN IF NOT EXISTS fecha_pago    DATE,
    ADD COLUMN IF NOT EXISTS monto_pagado  BIGINT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS notas_cobro   TEXT,
    ADD COLUMN IF NOT EXISTS tipo_pago     TEXT DEFAULT 'transferencia';

-- combustible: número de factura
ALTER TABLE combustible
    ADD COLUMN IF NOT EXISTS numero_factura TEXT;

-- gastos: categoría y referencia
ALTER TABLE gastos
    ADD COLUMN IF NOT EXISTS categoria   TEXT,
    ADD COLUMN IF NOT EXISTS referencia  TEXT,
    ADD COLUMN IF NOT EXISTS vehiculo_id UUID REFERENCES vehiculos(id) ON DELETE SET NULL;

-- conductores: campos extendidos
ALTER TABLE conductores
    ADD COLUMN IF NOT EXISTS rut                    TEXT,
    ADD COLUMN IF NOT EXISTS fecha_contrato         DATE,
    ADD COLUMN IF NOT EXISTS tipo_contrato          TEXT DEFAULT 'indefinido',
    ADD COLUMN IF NOT EXISTS sueldo_base            BIGINT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS vencimiento_licencia   DATE,
    ADD COLUMN IF NOT EXISTS tipo_licencia          TEXT;

-- vehiculos: campos extendidos
ALTER TABLE vehiculos
    ADD COLUMN IF NOT EXISTS año        INTEGER,
    ADD COLUMN IF NOT EXISTS color      TEXT,
    ADD COLUMN IF NOT EXISTS motor      TEXT,
    ADD COLUMN IF NOT EXISTS permiso_circulacion    DATE,
    ADD COLUMN IF NOT EXISTS revision_tecnica       DATE,
    ADD COLUMN IF NOT EXISTS seguro_vencimiento     DATE;

-- mantenimiento: asegurar campo estado existe
ALTER TABLE mantenimiento
    ADD COLUMN IF NOT EXISTS estado          TEXT DEFAULT 'pendiente',
    ADD COLUMN IF NOT EXISTS tipo            TEXT,
    ADD COLUMN IF NOT EXISTS fecha_programada DATE,
    ADD COLUMN IF NOT EXISTS descripcion     TEXT,
    ADD COLUMN IF NOT EXISTS costo           BIGINT DEFAULT 0;

-- empresas: campos de plan y suscripción usados en el panel admin
ALTER TABLE empresas
    ADD COLUMN IF NOT EXISTS plan_name    TEXT DEFAULT 'starter',
    ADD COLUMN IF NOT EXISTS sub_status   TEXT DEFAULT 'active',
    ADD COLUMN IF NOT EXISTS sub_end_date DATE,
    ADD COLUMN IF NOT EXISTS max_vehicles INTEGER DEFAULT 3,
    ADD COLUMN IF NOT EXISTS max_ops      INTEGER DEFAULT 300,
    ADD COLUMN IF NOT EXISTS activa       BOOLEAN DEFAULT TRUE;

-- Recargar esquema PostgREST
NOTIFY pgrst, 'reload schema';

DO $$
BEGIN
    RAISE NOTICE '✅ 20260517 — columnas faltantes añadidas correctamente';
END $$;
