-- Fix numero nullable y agregar campos de carga
ALTER TABLE viajes ALTER COLUMN numero DROP NOT NULL;
ALTER TABLE viajes ADD COLUMN IF NOT EXISTS tipo_carga text;
ALTER TABLE viajes ADD COLUMN IF NOT EXISTS numero_guia text;
ALTER TABLE viajes ADD COLUMN IF NOT EXISTS numero_contenedor text;
