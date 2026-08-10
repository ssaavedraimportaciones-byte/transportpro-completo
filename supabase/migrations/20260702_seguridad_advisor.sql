-- ══════════════════════════════════════════════════════════════
-- SEGURIDAD — Corrección de alertas del Security Advisor de Supabase
--
-- 1. search_path fijo en TODAS las funciones (alerta
--    "Function Search Path Mutable")
-- 2. RLS habilitado en tablas que quedaron sin protección
--    (alerta "RLS Disabled in Public"), en particular cotizacion_items
-- 3. Eliminación de políticas legacy duplicadas del esquema antiguo
--    get_my_empresa_id/usuarios.id (alerta "Multiple Permissive
--    Policies" y riesgo de semántica inconsistente)
-- 4. Revocación de privilegios del rol anon en todas las tablas
--
-- Idempotente: se puede ejecutar múltiples veces sin efectos extra.
-- ══════════════════════════════════════════════════════════════

-- ── 1. Funciones con search_path fijo ─────────────────────────

CREATE OR REPLACE FUNCTION public.tp_get_empresa_id()
RETURNS uuid LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public, pg_catalog AS $$
  SELECT empresa_id FROM public.usuarios WHERE auth_uid = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.tp_is_superadmin()
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public, pg_catalog AS $$
  SELECT EXISTS(
    SELECT 1 FROM public.usuarios
    WHERE auth_uid = auth.uid() AND rol = 'superadmin'
  );
$$;

CREATE OR REPLACE FUNCTION public.get_my_empresa_id()
RETURNS uuid LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public, pg_catalog AS $$
  SELECT empresa_id FROM public.usuarios WHERE auth_uid = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.get_current_empresa_id()
RETURNS uuid LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public, pg_catalog AS $$
  SELECT empresa_id FROM public.usuarios WHERE auth_uid = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.is_superadmin()
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public, pg_catalog AS $$
  SELECT EXISTS(
    SELECT 1 FROM public.usuarios
    WHERE auth_uid = auth.uid() AND rol = 'superadmin'
  );
$$;

-- Trigger de updated_at (no es SECURITY DEFINER, pero el advisor
-- también exige search_path fijo)
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS trigger LANGUAGE plpgsql
SET search_path = public, pg_catalog AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

-- ── 2. Políticas legacy duplicadas ─────────────────────────────
-- El esquema antiguo (función get_my_empresa_id basada en usuarios.id
-- en vez de auth_uid) dejó políticas paralelas a las tp_rls_*.
-- Se eliminan SOLO si la política tp_rls_* correspondiente existe,
-- para no dejar ninguna tabla sin política.
DO $$
DECLARE
  t text;
  legacy text;
BEGIN
  FOREACH t IN ARRAY ARRAY['viajes','clientes','vehiculos','conductores',
                           'facturas','combustible','gastos','mantenimiento'] LOOP
    IF EXISTS (SELECT 1 FROM pg_policies
               WHERE schemaname='public' AND tablename=t
                 AND policyname='tp_rls_'||t) THEN
      legacy := t || '_empresa';
      EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', legacy, t);
    END IF;
  END LOOP;

  IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public'
             AND tablename='usuarios' AND policyname='tp_rls_usuarios') THEN
    DROP POLICY IF EXISTS "usuarios_own" ON public.usuarios;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public'
             AND tablename='empresas' AND policyname='tp_rls_empresas') THEN
    DROP POLICY IF EXISTS "empresas_own" ON public.empresas;
  END IF;
END $$;

-- ── 3. RLS en cotizacion_items (aislamiento vía cotización padre) ──
ALTER TABLE IF EXISTS public.cotizacion_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_cotizacion_items" ON public.cotizacion_items;
CREATE POLICY "tp_rls_cotizacion_items" ON public.cotizacion_items
  USING (EXISTS (
    SELECT 1 FROM public.cotizaciones c
    WHERE c.id = cotizacion_id
      AND (c.empresa_id = public.tp_get_empresa_id() OR public.tp_is_superadmin())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.cotizaciones c
    WHERE c.id = cotizacion_id
      AND (c.empresa_id = public.tp_get_empresa_id() OR public.tp_is_superadmin())
  ));

-- ── 4. Red de seguridad: RLS en cualquier tabla pública restante ──
-- Habilita RLS donde falte. Si la tabla tiene empresa_id y quedó sin
-- ninguna política, crea la política tenant estándar.
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT c.relname AS tabla
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind = 'r' AND NOT c.relrowsecurity
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', r.tabla);

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='public' AND table_name=r.tabla
                 AND column_name='empresa_id')
       AND NOT EXISTS (SELECT 1 FROM pg_policies
                       WHERE schemaname='public' AND tablename=r.tabla) THEN
      EXECUTE format(
        'CREATE POLICY %I ON public.%I '
        || 'USING (empresa_id = public.tp_get_empresa_id() OR public.tp_is_superadmin()) '
        || 'WITH CHECK (empresa_id = public.tp_get_empresa_id() OR public.tp_is_superadmin())',
        'tp_rls_' || r.tabla, r.tabla);
    END IF;

    RAISE NOTICE 'RLS habilitado en public.%', r.tabla;
  END LOOP;
END $$;

-- ── 5. Revocar todo privilegio del rol anon en tablas públicas ──
-- (el anon key solo debe servir para autenticarse)
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT tablename FROM pg_tables WHERE schemaname='public'
  LOOP
    EXECUTE format('REVOKE ALL ON public.%I FROM anon', r.tablename);
  END LOOP;
END $$;

NOTIFY pgrst, 'reload schema';

DO $$ BEGIN
  RAISE NOTICE '✅ Migración de seguridad aplicada: search_path fijo, RLS completo, políticas legacy eliminadas, anon revocado';
END $$;
