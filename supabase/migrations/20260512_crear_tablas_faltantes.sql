-- ═══════════════════════════════════════════════════════════
-- TRANSPORTPRO — TABLAS FALTANTES + USUARIO CARLOS CONCHA
-- Pegar en: Supabase Dashboard → SQL Editor → Run
-- ═══════════════════════════════════════════════════════════

-- ─── 1. REMUNERACIONES ────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.remuneraciones (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id   uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    conductor_id uuid REFERENCES public.conductores(id) ON DELETE SET NULL,
    nombre       text,
    tipo         text DEFAULT 'sueldo'
        CHECK (tipo IN ('sueldo','bono','anticipo','descuento','otro')),
    monto        numeric NOT NULL DEFAULT 0,
    fecha        date NOT NULL DEFAULT CURRENT_DATE,
    mes          text,
    descripcion  text,
    created_at   timestamptz DEFAULT now()
);
ALTER TABLE public.remuneraciones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_remuneraciones" ON public.remuneraciones;
CREATE POLICY "tp_rls_remuneraciones" ON public.remuneraciones
    FOR ALL USING (empresa_id = tp_get_empresa_id() OR tp_is_superadmin())
    WITH CHECK (empresa_id = tp_get_empresa_id() OR tp_is_superadmin());
GRANT SELECT, INSERT, UPDATE, DELETE ON public.remuneraciones TO authenticated;
GRANT SELECT ON public.remuneraciones TO anon;

-- ─── 2. SUPPORT_TICKETS ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.support_tickets (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id   uuid REFERENCES public.empresas(id) ON DELETE CASCADE,
    tipo         text DEFAULT 'consulta',
    titulo       text NOT NULL,
    descripcion  text,
    estado       text DEFAULT 'abierto'
        CHECK (estado IN ('abierto','en_revision','resuelto','cerrado')),
    respuesta    text,
    updated_at   timestamptz,
    created_at   timestamptz DEFAULT now()
);
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_support" ON public.support_tickets;
CREATE POLICY "tp_rls_support" ON public.support_tickets
    FOR ALL USING (empresa_id = tp_get_empresa_id() OR tp_is_superadmin())
    WITH CHECK (empresa_id = tp_get_empresa_id() OR tp_is_superadmin());
GRANT SELECT, INSERT, UPDATE, DELETE ON public.support_tickets TO authenticated;

-- ─── 3. SUBSCRIPTIONS ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id   uuid REFERENCES public.empresas(id) ON DELETE CASCADE,
    plan         text DEFAULT 'starter',
    estado       text DEFAULT 'activa',
    fecha_inicio date DEFAULT CURRENT_DATE,
    fecha_venc   date,
    created_at   timestamptz DEFAULT now()
);
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_subs" ON public.subscriptions;
CREATE POLICY "tp_rls_subs" ON public.subscriptions
    FOR ALL USING (empresa_id = tp_get_empresa_id() OR tp_is_superadmin())
    WITH CHECK (empresa_id = tp_get_empresa_id() OR tp_is_superadmin());
GRANT SELECT, INSERT, UPDATE, DELETE ON public.subscriptions TO authenticated;

-- ─── 4. MODULOS_CUSTOM ────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.modulos_custom (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id   uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nombre       text NOT NULL,
    icono        text DEFAULT '📋',
    columnas     jsonb DEFAULT '[]',
    created_at   timestamptz DEFAULT now()
);
ALTER TABLE public.modulos_custom ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_modulos" ON public.modulos_custom;
CREATE POLICY "tp_rls_modulos" ON public.modulos_custom
    FOR ALL USING (empresa_id = tp_get_empresa_id() OR tp_is_superadmin())
    WITH CHECK (empresa_id = tp_get_empresa_id() OR tp_is_superadmin());
GRANT SELECT, INSERT, UPDATE, DELETE ON public.modulos_custom TO authenticated;

-- ─── 5. MODULOS_REGISTROS ─────────────────────────────────
CREATE TABLE IF NOT EXISTS public.modulos_registros (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    modulo_id   uuid NOT NULL REFERENCES public.modulos_custom(id) ON DELETE CASCADE,
    empresa_id  uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    datos       jsonb DEFAULT '{}',
    created_at  timestamptz DEFAULT now()
);
ALTER TABLE public.modulos_registros ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_modulos_reg" ON public.modulos_registros;
CREATE POLICY "tp_rls_modulos_reg" ON public.modulos_registros
    FOR ALL USING (empresa_id = tp_get_empresa_id() OR tp_is_superadmin())
    WITH CHECK (empresa_id = tp_get_empresa_id() OR tp_is_superadmin());
GRANT SELECT, INSERT, UPDATE, DELETE ON public.modulos_registros TO authenticated;

-- ─── 6. COTIZACION_ITEMS ──────────────────────────────────
CREATE TABLE IF NOT EXISTS public.cotizacion_items (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    cotizacion_id uuid NOT NULL REFERENCES public.cotizaciones(id) ON DELETE CASCADE,
    descripcion   text NOT NULL,
    cantidad      numeric DEFAULT 1,
    precio_unit   numeric DEFAULT 0,
    subtotal      numeric GENERATED ALWAYS AS (cantidad * precio_unit) STORED
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cotizacion_items TO authenticated;

-- ─── 7. UNIDADES_LOGISTICAS ───────────────────────────────
CREATE TABLE IF NOT EXISTS public.unidades_logisticas (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id  uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    codigo      text,
    descripcion text,
    tipo        text DEFAULT 'contenedor',
    estado      text DEFAULT 'disponible'
        CHECK (estado IN ('disponible','asignado_a_viaje','en_transito','entregado','danado')),
    cliente_id  uuid REFERENCES public.clientes(id) ON DELETE SET NULL,
    viaje_id    uuid REFERENCES public.viajes(id) ON DELETE SET NULL,
    notas       text,
    created_at  timestamptz DEFAULT now()
);
ALTER TABLE public.unidades_logisticas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tp_rls_unidades" ON public.unidades_logisticas;
CREATE POLICY "tp_rls_unidades" ON public.unidades_logisticas
    FOR ALL USING (empresa_id = tp_get_empresa_id() OR tp_is_superadmin())
    WITH CHECK (empresa_id = tp_get_empresa_id() OR tp_is_superadmin());
GRANT SELECT, INSERT, UPDATE, DELETE ON public.unidades_logisticas TO authenticated;

-- ─── 8. USUARIO: CARLOS CONCHA ────────────────────────────
-- Primero crea la cuenta en Auth: Dashboard → Authentication → Users → Add user
-- Email: carlos.concha@mcmlogistiva.cl  Pass: TransportPro2026
-- Luego toma el auth_uid del nuevo usuario y reemplaza en la línea de abajo:

-- INSERT INTO public.usuarios (auth_uid, empresa_id, nombre, email, rol, activo)
-- VALUES (
--     '<REEMPLAZAR_CON_AUTH_UID_DE_CARLOS>',
--     '77aef6c9-71b1-4178-9012-5bdd24b9e8f4',
--     'Carlos Concha',
--     'carlos.concha@mcmlogistiva.cl',
--     'operador',
--     true
-- );

-- ─── VERIFICACIÓN ─────────────────────────────────────────
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('remuneraciones','support_tickets','subscriptions',
                     'modulos_custom','modulos_registros','cotizacion_items',
                     'unidades_logisticas')
ORDER BY table_name;
