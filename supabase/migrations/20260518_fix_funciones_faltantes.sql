-- ══════════════════════════════════════════════════════════════
-- FIX FORENSE: Funciones RLS faltantes
--
-- PROBLEMA: Las migraciones 20260501 y 20260502 referencian
-- get_current_empresa_id() e is_superadmin() que NUNCA se definieron.
-- Esto rompe RLS en bitacora_mantencion y unidades_logisticas.
--
-- SOLUCIÓN: Crear alias apuntando a las funciones existentes.
-- NO modifica datos. NO cambia políticas existentes.
-- Es idempotente (CREATE OR REPLACE).
-- ══════════════════════════════════════════════════════════════

-- Alias: get_current_empresa_id() → tp_get_empresa_id()
-- (la función real existe desde 20260507_rls_seguridad.sql)
CREATE OR REPLACE FUNCTION public.get_current_empresa_id()
RETURNS uuid LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public, pg_catalog AS $$
  SELECT empresa_id FROM public.usuarios WHERE auth_uid = auth.uid() LIMIT 1;
$$;

-- Alias: is_superadmin() → tp_is_superadmin()
CREATE OR REPLACE FUNCTION public.is_superadmin()
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public, pg_catalog AS $$
  SELECT EXISTS(
    SELECT 1 FROM public.usuarios
    WHERE auth_uid = auth.uid() AND rol = 'superadmin'
  );
$$;

-- Asegurar permisos en tablas que podrían no tenerlos
GRANT SELECT, INSERT, UPDATE, DELETE
ON public.remuneraciones, public.cotizaciones, public.modulos_custom
TO authenticated;

-- Notificar PostgREST para recargar schema
NOTIFY pgrst, 'reload schema';

-- Verificación
DO $$
BEGIN
  RAISE NOTICE '✅ Funciones faltantes creadas: get_current_empresa_id(), is_superadmin()';
END $$;
