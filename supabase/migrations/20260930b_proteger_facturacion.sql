-- Protege la facturación contra manipulación por el propio tenant.
-- * empresas: solo superadmin / backend (service_role, funciones SECURITY DEFINER)
--   pueden cambiar columnas de plan, límites, fechas y estado de suscripción.
--   El cliente sigue pudiendo editar sus datos (nombre, rut, contacto, etc.).
-- * payments / subscriptions / usage_monthly: el tenant solo LEE lo suyo.
--   (el consumo se incrementa vía increment_usage, que es SECURITY DEFINER)
-- Deshacer: supabase/rollback/20260930b_proteger_facturacion_rollback.sql

CREATE OR REPLACE FUNCTION public.tp_proteger_facturacion_empresa()
 RETURNS trigger LANGUAGE plpgsql SET search_path TO 'public'
AS $function$
DECLARE
  k text;
  protegidas text[] := ARRAY['plan','plan_name','sub_status','sub_start_date','sub_end_date',
                             'monthly_price','max_vehicles','max_ops','activa'];
BEGIN
  -- Solo aplica a escrituras directas desde el cliente (rol authenticated/anon).
  -- service_role y funciones SECURITY DEFINER (current_user = owner) pasan.
  IF current_user NOT IN ('authenticated', 'anon') OR public.is_superadmin() THEN
    RETURN NEW;
  END IF;
  FOREACH k IN ARRAY protegidas LOOP
    IF (to_jsonb(NEW) -> k) IS DISTINCT FROM (to_jsonb(OLD) -> k) THEN
      RAISE EXCEPTION 'No autorizado: el campo "%" solo lo puede cambiar el administrador de TransportPro', k
        USING ERRCODE = '42501';
    END IF;
  END LOOP;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS tp_proteger_facturacion ON public.empresas;
CREATE TRIGGER tp_proteger_facturacion
  BEFORE UPDATE ON public.empresas
  FOR EACH ROW EXECUTE FUNCTION public.tp_proteger_facturacion_empresa();

-- Tablas de facturación: solo lectura para el tenant
DROP POLICY IF EXISTS payments_empresa ON public.payments;
CREATE POLICY payments_empresa ON public.payments FOR SELECT TO authenticated
  USING (empresa_id IN (SELECT usuarios.empresa_id FROM usuarios WHERE usuarios.auth_uid = auth.uid()));

DROP POLICY IF EXISTS subscriptions_empresa ON public.subscriptions;
CREATE POLICY subscriptions_empresa ON public.subscriptions FOR SELECT TO authenticated
  USING (empresa_id IN (SELECT usuarios.empresa_id FROM usuarios WHERE usuarios.auth_uid = auth.uid()));

DROP POLICY IF EXISTS usage_empresa ON public.usage_monthly;
CREATE POLICY usage_empresa ON public.usage_monthly FOR SELECT TO authenticated
  USING (empresa_id IN (SELECT usuarios.empresa_id FROM usuarios WHERE usuarios.auth_uid = auth.uid()));
