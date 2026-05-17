-- ══════════════════════════════════════════════════════════════
-- DIAGNÓSTICO Y REPARACIÓN: auth_uid + empresa_id + RLS
-- Ejecutar después de 20260517_fix_columnas_faltantes.sql
-- ══════════════════════════════════════════════════════════════

-- 1. Vincular auth_uid automáticamente desde auth.users → public.usuarios
--    (Repara casos donde auth_uid quedó NULL o incorrecto)
UPDATE public.usuarios u
SET auth_uid = a.id
FROM auth.users a
WHERE a.email = u.email
  AND (u.auth_uid IS NULL OR u.auth_uid != a.id);

-- 2. Asegurar que todos los usuarios tengan activo = true
UPDATE public.usuarios
SET activo = true
WHERE activo IS NULL OR activo = false;

-- 3. Función tp_get_empresa_id — crear si no existe aún
CREATE OR REPLACE FUNCTION public.tp_get_empresa_id()
RETURNS uuid LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT empresa_id FROM public.usuarios WHERE auth_uid = auth.uid() LIMIT 1;
$$;

-- 4. Función tp_is_superadmin — crear si no existe aún
CREATE OR REPLACE FUNCTION public.tp_is_superadmin()
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT EXISTS(
    SELECT 1 FROM public.usuarios
    WHERE auth_uid = auth.uid() AND rol = 'superadmin'
  );
$$;

-- 5. Función get_my_empresa_id (nombre original — mantener por compatibilidad)
CREATE OR REPLACE FUNCTION public.get_my_empresa_id()
RETURNS uuid LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT empresa_id FROM public.usuarios WHERE auth_uid = auth.uid() LIMIT 1;
$$;

-- 6. Verificar y reparar RLS en tablas principales
--    (idempotente: DROP IF EXISTS + CREATE)

ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_usuarios"   ON public.usuarios;
CREATE POLICY "tp_rls_usuarios" ON public.usuarios
    USING (auth_uid = auth.uid()
        OR empresa_id = public.tp_get_empresa_id()
        OR public.tp_is_superadmin());

ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_empresas"   ON public.empresas;
CREATE POLICY "tp_rls_empresas" ON public.empresas
    USING (id = public.tp_get_empresa_id() OR public.tp_is_superadmin());

ALTER TABLE public.viajes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_viajes"     ON public.viajes;
CREATE POLICY "tp_rls_viajes" ON public.viajes
    USING  (empresa_id = public.tp_get_empresa_id() OR public.tp_is_superadmin())
    WITH CHECK (empresa_id = public.tp_get_empresa_id() OR public.tp_is_superadmin());

ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_clientes"   ON public.clientes;
CREATE POLICY "tp_rls_clientes" ON public.clientes
    USING  (empresa_id = public.tp_get_empresa_id() OR public.tp_is_superadmin())
    WITH CHECK (empresa_id = public.tp_get_empresa_id() OR public.tp_is_superadmin());

ALTER TABLE public.vehiculos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_vehiculos"  ON public.vehiculos;
CREATE POLICY "tp_rls_vehiculos" ON public.vehiculos
    USING  (empresa_id = public.tp_get_empresa_id() OR public.tp_is_superadmin())
    WITH CHECK (empresa_id = public.tp_get_empresa_id() OR public.tp_is_superadmin());

ALTER TABLE public.conductores ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_conductores" ON public.conductores;
CREATE POLICY "tp_rls_conductores" ON public.conductores
    USING  (empresa_id = public.tp_get_empresa_id() OR public.tp_is_superadmin())
    WITH CHECK (empresa_id = public.tp_get_empresa_id() OR public.tp_is_superadmin());

ALTER TABLE public.gastos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_gastos"     ON public.gastos;
CREATE POLICY "tp_rls_gastos" ON public.gastos
    USING  (empresa_id = public.tp_get_empresa_id() OR public.tp_is_superadmin())
    WITH CHECK (empresa_id = public.tp_get_empresa_id() OR public.tp_is_superadmin());

ALTER TABLE public.combustible ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_combustible" ON public.combustible;
CREATE POLICY "tp_rls_combustible" ON public.combustible
    USING  (empresa_id = public.tp_get_empresa_id() OR public.tp_is_superadmin())
    WITH CHECK (empresa_id = public.tp_get_empresa_id() OR public.tp_is_superadmin());

ALTER TABLE public.facturas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_facturas"   ON public.facturas;
CREATE POLICY "tp_rls_facturas" ON public.facturas
    USING  (empresa_id = public.tp_get_empresa_id() OR public.tp_is_superadmin())
    WITH CHECK (empresa_id = public.tp_get_empresa_id() OR public.tp_is_superadmin());

ALTER TABLE public.mantenimiento ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_mantenimiento" ON public.mantenimiento;
CREATE POLICY "tp_rls_mantenimiento" ON public.mantenimiento
    USING  (empresa_id = public.tp_get_empresa_id() OR public.tp_is_superadmin())
    WITH CHECK (empresa_id = public.tp_get_empresa_id() OR public.tp_is_superadmin());

-- 7. Permisos para usuarios autenticados en todas las tablas
GRANT SELECT, INSERT, UPDATE, DELETE
ON public.viajes, public.clientes, public.vehiculos, public.conductores,
   public.gastos, public.combustible, public.facturas, public.mantenimiento,
   public.usuarios, public.empresas
TO authenticated;

-- 8. Permitir que authenticated lea auth.users (necesario para algunos joins)
GRANT USAGE ON SCHEMA auth TO authenticated;

-- 9. Recargar PostgREST
NOTIFY pgrst, 'reload schema';

-- 10. Diagnóstico: mostrar usuarios sin auth_uid o sin empresa
DO $$
DECLARE
  v_sin_auth  integer;
  v_sin_emp   integer;
  v_total     integer;
BEGIN
  SELECT COUNT(*) INTO v_sin_auth FROM public.usuarios WHERE auth_uid IS NULL;
  SELECT COUNT(*) INTO v_sin_emp  FROM public.usuarios WHERE empresa_id IS NULL AND rol != 'superadmin';
  SELECT COUNT(*) INTO v_total    FROM public.usuarios;
  RAISE NOTICE '✅ DIAGNÓSTICO: % usuarios total | % sin auth_uid | % sin empresa (no-superadmin)',
    v_total, v_sin_auth, v_sin_emp;
END $$;
