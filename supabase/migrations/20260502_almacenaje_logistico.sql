-- ═══════════════════════════════════════════════════════════
-- MÓDULO: ALMACENAJE LOGÍSTICO (WMS)
-- ═══════════════════════════════════════════════════════════

-- Unidades logísticas (bultos, pallets, cajas individuales)
CREATE TABLE IF NOT EXISTS unidades_logisticas (
    id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id             uuid NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    cliente_id             uuid REFERENCES clientes(id) ON DELETE SET NULL,
    viaje_id               uuid REFERENCES viajes(id) ON DELETE SET NULL,
    numero_bl              text,
    descripcion            text NOT NULL,
    peso                   numeric,
    volumen                numeric,
    estado                 text NOT NULL DEFAULT 'recibido'
                           CHECK (estado IN ('recibido','en_bodega','asignado_a_viaje','en_transito','entregado','dañado','perdido')),
    bodega                 text,
    fecha_ingreso          date,
    fecha_salida           date,
    tarifa_almacenaje      numeric DEFAULT 0,
    observaciones          text,
    motivo_incidencia      text,
    responsable_incidencia text,
    updated_at             timestamptz DEFAULT now(),
    created_at             timestamptz DEFAULT now()
);

-- Trazabilidad por eventos (NUNCA sobrescribir sin registrar)
CREATE TABLE IF NOT EXISTS movimientos_unidad_logistica (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id  uuid NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    unidad_id   uuid NOT NULL REFERENCES unidades_logisticas(id) ON DELETE CASCADE,
    tipo_evento text NOT NULL
                CHECK (tipo_evento IN ('recepcion','traslado','asignacion','despacho','daño','pérdida','entrega')),
    fecha       date NOT NULL,
    descripcion text,
    usuario     text,
    metadata    jsonb DEFAULT '{}'::jsonb,
    created_at  timestamptz DEFAULT now()
);

-- RLS multi-tenant
ALTER TABLE unidades_logisticas        ENABLE ROW LEVEL SECURITY;
ALTER TABLE movimientos_unidad_logistica ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ul_tenant" ON unidades_logisticas FOR ALL TO authenticated
    USING (empresa_id = get_current_empresa_id() AND NOT is_superadmin())
    WITH CHECK (empresa_id = get_current_empresa_id() AND NOT is_superadmin());

CREATE POLICY "mov_ul_tenant" ON movimientos_unidad_logistica FOR ALL TO authenticated
    USING (empresa_id = get_current_empresa_id() AND NOT is_superadmin())
    WITH CHECK (empresa_id = get_current_empresa_id() AND NOT is_superadmin());

-- Trigger para updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ul_updated_at BEFORE UPDATE ON unidades_logisticas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

NOTIFY pgrst, 'reload schema';
