-- ROLLBACK de 20260930_aislamiento_multitenant.sql
-- Restaura el estado previo EXACTO (incluye los agujeros de seguridad).
-- Úsalo solo si la migración rompiera algo en producción.

DROP POLICY IF EXISTS usuarios_insert ON public.usuarios;
CREATE POLICY usuarios_insert ON public.usuarios AS PERMISSIVE FOR INSERT TO public
  WITH CHECK ((empresa_id = get_my_empresa_id()));

DROP POLICY IF EXISTS usuarios_update ON public.usuarios;
CREATE POLICY usuarios_update ON public.usuarios AS PERMISSIVE FOR UPDATE TO public
  USING ((empresa_id = get_my_empresa_id())) WITH CHECK ((empresa_id = get_my_empresa_id()));

DROP POLICY IF EXISTS usuarios_write ON public.usuarios;
CREATE POLICY usuarios_write ON public.usuarios AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE OR REPLACE FUNCTION public.crear_tenant(p_auth_uid uuid, p_empresa_nombre text, p_nombre_usuario text, p_email text, p_plan text)
 RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
    v_empresa_id uuid;
    v_price      integer := 55000;
    v_max_veh    integer := 3;
    v_max_ops    integer := 300;
BEGIN
    SET LOCAL row_security = off;
    SELECT monthly_price, max_vehicles, max_ops INTO v_price, v_max_veh, v_max_ops
    FROM plan_definitions WHERE plan_name = upper(trim(p_plan)) LIMIT 1;
    IF EXISTS (SELECT 1 FROM usuarios WHERE auth_uid = p_auth_uid) THEN
        RETURN json_build_object('success', false, 'error', 'Este usuario ya tiene un perfil registrado');
    END IF;
    INSERT INTO empresas (nombre, razon_social, activa, plan, plan_name, sub_status,
        sub_start_date, sub_end_date, monthly_price, max_vehicles, max_ops)
    VALUES (trim(p_empresa_nombre), trim(p_empresa_nombre), true,
        lower(trim(p_plan)), upper(trim(p_plan)), 'active',
        CURRENT_DATE, CURRENT_DATE + interval '30 days', v_price, v_max_veh, v_max_ops)
    RETURNING id INTO v_empresa_id;
    INSERT INTO usuarios (auth_uid, empresa_id, nombre, email, rol, activo)
    VALUES (p_auth_uid, v_empresa_id, trim(p_nombre_usuario), lower(trim(p_email)), 'admin', true);
    INSERT INTO usage_monthly (empresa_id, year_month, ops_count, ops_limit)
    VALUES (v_empresa_id, to_char(now(), 'YYYY-MM'), 0, v_max_ops)
    ON CONFLICT (empresa_id, year_month) DO NOTHING;
    RETURN json_build_object('success', true, 'empresa_id', v_empresa_id);
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_usage_summary(p_empresa_id uuid)
 RETURNS json LANGUAGE plpgsql SECURITY DEFINER
AS $function$
DECLARE
    v_year_month text;
    v_row        usage_monthly%ROWTYPE;
    v_emp        empresas%ROWTYPE;
BEGIN
    v_year_month := to_char(now(), 'YYYY-MM');
    SELECT * INTO v_emp FROM empresas WHERE id = p_empresa_id;
    SELECT * INTO v_row FROM usage_monthly
        WHERE empresa_id = p_empresa_id AND year_month = v_year_month;
    RETURN json_build_object(
        'ops_count',      COALESCE(v_row.ops_count, 0),
        'ops_limit',      COALESCE(v_emp.max_ops, 300),
        'overage_ops',    GREATEST(0, COALESCE(v_row.ops_count, 0) - COALESCE(v_emp.max_ops, 300)),
        'plan_name',      COALESCE(v_emp.plan_name, 'BASIC'),
        'sub_status',     COALESCE(v_emp.sub_status, 'active'),
        'sub_end_date',   v_emp.sub_end_date,
        'monthly_price',  COALESCE(v_emp.monthly_price, 55000),
        'max_vehicles',   COALESCE(v_emp.max_vehicles, 3),
        'year_month',     v_year_month
    );
END;
$function$;
ALTER FUNCTION public.get_usage_summary(uuid) RESET search_path;

CREATE OR REPLACE FUNCTION public.increment_usage(p_empresa_id uuid, p_year_month text, p_ops_limit integer)
 RETURNS integer LANGUAGE plpgsql SECURITY DEFINER
AS $function$
DECLARE
    v_ops integer;
BEGIN
    INSERT INTO usage_monthly (empresa_id, year_month, ops_count, ops_limit)
    VALUES (p_empresa_id, p_year_month, 1, p_ops_limit)
    ON CONFLICT (empresa_id, year_month)
    DO UPDATE SET ops_count = usage_monthly.ops_count + 1
    RETURNING ops_count INTO v_ops;
    RETURN v_ops;
END;
$function$;
ALTER FUNCTION public.increment_usage(uuid, text, integer) RESET search_path;

ALTER FUNCTION public.recalc_overages(text) RESET search_path;
ALTER FUNCTION public.mark_overdue_subscriptions() RESET search_path;

GRANT EXECUTE ON FUNCTION public.recalc_overages(text) TO PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.mark_overdue_subscriptions() TO PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.crear_tenant(uuid, text, text, text, text) TO PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_usage_summary(uuid) TO PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.increment_usage(uuid, text, integer) TO PUBLIC, anon, authenticated;
