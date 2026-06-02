-- Agregar conductor_id y viaje_id a gastos
-- Permiten vincular un gasto a un conductor y/o viaje específico
ALTER TABLE gastos
    ADD COLUMN IF NOT EXISTS conductor_id UUID REFERENCES conductores(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS viaje_id     UUID REFERENCES viajes(id) ON DELETE SET NULL;

NOTIFY pgrst, 'reload schema';
