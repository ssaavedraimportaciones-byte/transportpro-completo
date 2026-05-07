-- ═══════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY — TransportPro
-- Aislamiento total por empresa. Ningún usuario puede leer ni escribir
-- datos de otra empresa, aunque tenga el anon-key o acceso directo.
-- ═══════════════════════════════════════════════════════════════════

-- ── Helper: obtiene empresa_id del usuario autenticado ──────────────
CREATE OR REPLACE FUNCTION tp_get_empresa_id()
RETURNS uuid LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT empresa_id FROM usuarios WHERE auth_uid = auth.uid() LIMIT 1;
$$;

-- ── Helper: detecta superadmin ────────────────────────────────────────
CREATE OR REPLACE FUNCTION tp_is_superadmin()
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT EXISTS(SELECT 1 FROM usuarios WHERE auth_uid = auth.uid() AND rol = 'superadmin');
$$;

-- ── Macro para crear políticas en cada tabla ──────────────────────────
-- Se ejecuta individualmente por tabla (Postgres no tiene bucles en DDL simple)

-- ─────────────────────────────────────────────────────────────────────
-- VIAJES
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE viajes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_viajes"       ON viajes;
CREATE POLICY "tp_rls_viajes" ON viajes
    USING  (empresa_id = tp_get_empresa_id() OR tp_is_superadmin())
    WITH CHECK (empresa_id = tp_get_empresa_id() OR tp_is_superadmin());

-- ─────────────────────────────────────────────────────────────────────
-- CLIENTES
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_clientes"     ON clientes;
CREATE POLICY "tp_rls_clientes" ON clientes
    USING  (empresa_id = tp_get_empresa_id() OR tp_is_superadmin())
    WITH CHECK (empresa_id = tp_get_empresa_id() OR tp_is_superadmin());

-- ─────────────────────────────────────────────────────────────────────
-- VEHICULOS
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE vehiculos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_vehiculos"    ON vehiculos;
CREATE POLICY "tp_rls_vehiculos" ON vehiculos
    USING  (empresa_id = tp_get_empresa_id() OR tp_is_superadmin())
    WITH CHECK (empresa_id = tp_get_empresa_id() OR tp_is_superadmin());

-- ─────────────────────────────────────────────────────────────────────
-- CONDUCTORES
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE conductores ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_conductores"  ON conductores;
CREATE POLICY "tp_rls_conductores" ON conductores
    USING  (empresa_id = tp_get_empresa_id() OR tp_is_superadmin())
    WITH CHECK (empresa_id = tp_get_empresa_id() OR tp_is_superadmin());

-- ─────────────────────────────────────────────────────────────────────
-- COMBUSTIBLE
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE combustible ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_combustible"  ON combustible;
CREATE POLICY "tp_rls_combustible" ON combustible
    USING  (empresa_id = tp_get_empresa_id() OR tp_is_superadmin())
    WITH CHECK (empresa_id = tp_get_empresa_id() OR tp_is_superadmin());

-- ─────────────────────────────────────────────────────────────────────
-- GASTOS
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE gastos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_gastos"       ON gastos;
CREATE POLICY "tp_rls_gastos" ON gastos
    USING  (empresa_id = tp_get_empresa_id() OR tp_is_superadmin())
    WITH CHECK (empresa_id = tp_get_empresa_id() OR tp_is_superadmin());

-- ─────────────────────────────────────────────────────────────────────
-- MANTENIMIENTO
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE mantenimiento ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_mantenimiento" ON mantenimiento;
CREATE POLICY "tp_rls_mantenimiento" ON mantenimiento
    USING  (empresa_id = tp_get_empresa_id() OR tp_is_superadmin())
    WITH CHECK (empresa_id = tp_get_empresa_id() OR tp_is_superadmin());

-- ─────────────────────────────────────────────────────────────────────
-- FACTURAS
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE facturas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_facturas"     ON facturas;
CREATE POLICY "tp_rls_facturas" ON facturas
    USING  (empresa_id = tp_get_empresa_id() OR tp_is_superadmin())
    WITH CHECK (empresa_id = tp_get_empresa_id() OR tp_is_superadmin());

-- ─────────────────────────────────────────────────────────────────────
-- REMUNERACIONES
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE remuneraciones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_remuneraciones" ON remuneraciones;
CREATE POLICY "tp_rls_remuneraciones" ON remuneraciones
    USING  (empresa_id = tp_get_empresa_id() OR tp_is_superadmin())
    WITH CHECK (empresa_id = tp_get_empresa_id() OR tp_is_superadmin());

-- ─────────────────────────────────────────────────────────────────────
-- COTIZACIONES
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE cotizaciones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_cotizaciones" ON cotizaciones;
CREATE POLICY "tp_rls_cotizaciones" ON cotizaciones
    USING  (empresa_id = tp_get_empresa_id() OR tp_is_superadmin())
    WITH CHECK (empresa_id = tp_get_empresa_id() OR tp_is_superadmin());

-- ─────────────────────────────────────────────────────────────────────
-- BITACORA_MANTENCION
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE bitacora_mantencion ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_bitacora"     ON bitacora_mantencion;
CREATE POLICY "tp_rls_bitacora" ON bitacora_mantencion
    USING  (empresa_id = tp_get_empresa_id() OR tp_is_superadmin())
    WITH CHECK (empresa_id = tp_get_empresa_id() OR tp_is_superadmin());

-- ─────────────────────────────────────────────────────────────────────
-- UNIDADES_LOGISTICAS
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE unidades_logisticas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_unidades"     ON unidades_logisticas;
CREATE POLICY "tp_rls_unidades" ON unidades_logisticas
    USING  (empresa_id = tp_get_empresa_id() OR tp_is_superadmin())
    WITH CHECK (empresa_id = tp_get_empresa_id() OR tp_is_superadmin());

-- ─────────────────────────────────────────────────────────────────────
-- USUARIOS — cada usuario solo ve su propia empresa
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_usuarios"     ON usuarios;
CREATE POLICY "tp_rls_usuarios" ON usuarios
    USING  (auth_uid = auth.uid() OR empresa_id = tp_get_empresa_id() OR tp_is_superadmin());

-- ─────────────────────────────────────────────────────────────────────
-- EMPRESAS — solo ve la propia empresa
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE empresas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_empresas"     ON empresas;
CREATE POLICY "tp_rls_empresas" ON empresas
    USING  (id = tp_get_empresa_id() OR tp_is_superadmin());

-- ─────────────────────────────────────────────────────────────────────
-- Revocar acceso anónimo directo a todas las tablas de negocio
-- (el anon-key solo debe poder hacer auth, no leer datos)
-- ─────────────────────────────────────────────────────────────────────
REVOKE SELECT, INSERT, UPDATE, DELETE ON viajes,           clientes,     vehiculos,
                                          conductores,     combustible,  gastos,
                                          mantenimiento,   facturas,     remuneraciones,
                                          cotizaciones,    bitacora_mantencion,
                                          unidades_logisticas, usuarios, empresas
FROM anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON viajes,           clientes,     vehiculos,
                                         conductores,     combustible,  gastos,
                                         mantenimiento,   facturas,     remuneraciones,
                                         cotizaciones,    bitacora_mantencion,
                                         unidades_logisticas, usuarios, empresas
TO authenticated;

NOTIFY pgrst, 'reload schema';
