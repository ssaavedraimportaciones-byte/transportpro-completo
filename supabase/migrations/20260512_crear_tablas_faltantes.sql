-- ══════════════════════════════════════════════════════════════
-- TRANSPORTPRO — Crear tablas faltantes
-- Ejecutar con: psql $DATABASE_URL -f este_archivo.sql
-- ══════════════════════════════════════════════════════════════

-- ── remuneraciones ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS remuneraciones (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id    UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    conductor_id  UUID REFERENCES conductores(id) ON DELETE SET NULL,
    fecha         DATE NOT NULL,
    concepto      TEXT NOT NULL,
    monto         BIGINT NOT NULL DEFAULT 0,
    tipo          TEXT NOT NULL DEFAULT 'sueldo',
    observaciones TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE remuneraciones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS remuneraciones_empresa ON remuneraciones;
CREATE POLICY remuneraciones_empresa ON remuneraciones
    USING (empresa_id = (SELECT empresa_id FROM usuarios WHERE auth_uid = auth.uid() LIMIT 1));

-- ── support_tickets ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS support_tickets (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id  UUID REFERENCES empresas(id) ON DELETE CASCADE,
    usuario_id  UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    asunto      TEXT NOT NULL,
    mensaje     TEXT NOT NULL,
    estado      TEXT NOT NULL DEFAULT 'abierto',
    respuesta   TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS support_tickets_empresa ON support_tickets;
CREATE POLICY support_tickets_empresa ON support_tickets
    USING (empresa_id = (SELECT empresa_id FROM usuarios WHERE auth_uid = auth.uid() LIMIT 1)
           OR (SELECT rol FROM usuarios WHERE auth_uid = auth.uid() LIMIT 1) = 'superadmin');

-- ── subscriptions ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS subscriptions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id  UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    plan        TEXT NOT NULL DEFAULT 'starter',
    estado      TEXT NOT NULL DEFAULT 'activo',
    monto       BIGINT DEFAULT 0,
    fecha_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_fin    DATE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS subscriptions_empresa ON subscriptions;
CREATE POLICY subscriptions_empresa ON subscriptions
    USING (empresa_id = (SELECT empresa_id FROM usuarios WHERE auth_uid = auth.uid() LIMIT 1)
           OR (SELECT rol FROM usuarios WHERE auth_uid = auth.uid() LIMIT 1) = 'superadmin');

-- ── modulos_custom ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS modulos_custom (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id  UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre      TEXT NOT NULL,
    icono       TEXT DEFAULT '📋',
    campos      JSONB DEFAULT '[]',
    activo      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE modulos_custom ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS modulos_custom_empresa ON modulos_custom;
CREATE POLICY modulos_custom_empresa ON modulos_custom
    USING (empresa_id = (SELECT empresa_id FROM usuarios WHERE auth_uid = auth.uid() LIMIT 1));

-- ── modulos_registros ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS modulos_registros (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id  UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    modulo_id   UUID NOT NULL REFERENCES modulos_custom(id) ON DELETE CASCADE,
    datos       JSONB DEFAULT '{}',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE modulos_registros ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS modulos_registros_empresa ON modulos_registros;
CREATE POLICY modulos_registros_empresa ON modulos_registros
    USING (empresa_id = (SELECT empresa_id FROM usuarios WHERE auth_uid = auth.uid() LIMIT 1));

-- ── cotizaciones ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cotizaciones (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id      UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    cliente_id      UUID REFERENCES clientes(id) ON DELETE SET NULL,
    numero          TEXT,
    fecha           DATE NOT NULL DEFAULT CURRENT_DATE,
    validez         DATE,
    estado          TEXT NOT NULL DEFAULT 'borrador',
    subtotal        BIGINT DEFAULT 0,
    impuesto        BIGINT DEFAULT 0,
    total           BIGINT DEFAULT 0,
    notas           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE cotizaciones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS cotizaciones_empresa ON cotizaciones;
CREATE POLICY cotizaciones_empresa ON cotizaciones
    USING (empresa_id = (SELECT empresa_id FROM usuarios WHERE auth_uid = auth.uid() LIMIT 1));

-- ── cotizacion_items ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cotizacion_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cotizacion_id   UUID NOT NULL REFERENCES cotizaciones(id) ON DELETE CASCADE,
    descripcion     TEXT NOT NULL,
    cantidad        NUMERIC DEFAULT 1,
    precio_unitario BIGINT DEFAULT 0,
    subtotal        BIGINT DEFAULT 0
);

-- ── incidencias ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS incidencias (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id  UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    vehiculo_id UUID REFERENCES vehiculos(id) ON DELETE SET NULL,
    conductor_id UUID REFERENCES conductores(id) ON DELETE SET NULL,
    viaje_id    UUID REFERENCES viajes(id) ON DELETE SET NULL,
    fecha       DATE NOT NULL DEFAULT CURRENT_DATE,
    tipo        TEXT NOT NULL DEFAULT 'otro',
    descripcion TEXT NOT NULL,
    estado      TEXT NOT NULL DEFAULT 'abierto',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE incidencias ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS incidencias_empresa ON incidencias;
CREATE POLICY incidencias_empresa ON incidencias
    USING (empresa_id = (SELECT empresa_id FROM usuarios WHERE auth_uid = auth.uid() LIMIT 1));

-- ── superadmin access ─────────────────────────────────────────
UPDATE usuarios
SET rol = 'superadmin'
WHERE email = 'ssaavedra.importaciones@gmail.com';

-- ── Confirmar ─────────────────────────────────────────────────
DO $$
BEGIN
    RAISE NOTICE '✅ Migración completada — Todas las tablas creadas/verificadas';
END $$;
