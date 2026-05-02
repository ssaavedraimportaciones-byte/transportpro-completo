-- ═══════════════════════════════════════════════════════════
-- MÓDULO WMS: Campos adicionales para transporte de alto tonelaje
-- ═══════════════════════════════════════════════════════════

ALTER TABLE unidades_logisticas
    ADD COLUMN IF NOT EXISTS tipo_carga            text DEFAULT 'general'
                                                   CHECK (tipo_carga IN ('general','contenedor','palletizado','granel_solido','granel_liquido','frigorifico','sobredimensionado','peligroso','vehiculos')),
    ADD COLUMN IF NOT EXISTS numero_contenedor     text,
    ADD COLUMN IF NOT EXISTS numero_bultos         integer DEFAULT 1,
    ADD COLUMN IF NOT EXISTS valor_declarado       numeric DEFAULT 0,
    ADD COLUMN IF NOT EXISTS tipo_vehiculo_req     text,
    ADD COLUMN IF NOT EXISTS temp_min              numeric,
    ADD COLUMN IF NOT EXISTS temp_max              numeric,
    ADD COLUMN IF NOT EXISTS direccion_origen      text,
    ADD COLUMN IF NOT EXISTS direccion_destino     text,
    ADD COLUMN IF NOT EXISTS contacto_descarga     text,
    ADD COLUMN IF NOT EXISTS telefono_descarga     text,
    ADD COLUMN IF NOT EXISTS prioridad             text DEFAULT 'normal'
                                                   CHECK (prioridad IN ('normal','urgente','critico')),
    ADD COLUMN IF NOT EXISTS fecha_entrega_comprometida date,
    ADD COLUMN IF NOT EXISTS instrucciones_especiales   text,
    ADD COLUMN IF NOT EXISTS requiere_seguro       boolean DEFAULT false;

COMMENT ON COLUMN unidades_logisticas.tipo_carga               IS 'Tipo de mercancía/carga';
COMMENT ON COLUMN unidades_logisticas.direccion_origen         IS 'Dirección de origen/retiro';
COMMENT ON COLUMN unidades_logisticas.direccion_destino        IS 'Dirección destino/descarga final';
COMMENT ON COLUMN unidades_logisticas.tipo_vehiculo_req        IS 'Tipo de camión requerido (ej: rampla 3 ejes, furgón 3/4)';
COMMENT ON COLUMN unidades_logisticas.prioridad                IS 'Prioridad de despacho';
COMMENT ON COLUMN unidades_logisticas.fecha_entrega_comprometida IS 'Fecha de entrega comprometida al cliente';

NOTIFY pgrst, 'reload schema';
