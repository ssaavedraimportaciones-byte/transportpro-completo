-- Bitácora de mantención por vehículo
CREATE TABLE IF NOT EXISTS bitacora_mantencion (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id  uuid NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    vehiculo_id uuid REFERENCES vehiculos(id) ON DELETE SET NULL,
    fecha       date NOT NULL,
    tipo        text NOT NULL DEFAULT 'revision',
    descripcion text,
    km          integer DEFAULT 0,
    costo       numeric DEFAULT 0,
    taller      text,
    created_at  timestamptz DEFAULT now()
);

ALTER TABLE bitacora_mantencion ENABLE ROW LEVEL SECURITY;

CREATE POLICY "bitacora_tenant" ON bitacora_mantencion
    FOR ALL TO authenticated
    USING (empresa_id = get_current_empresa_id() AND NOT is_superadmin())
    WITH CHECK (empresa_id = get_current_empresa_id() AND NOT is_superadmin());

NOTIFY pgrst, 'reload schema';
