-- Migración: configuración de facturación por empresa
-- Ejecutar en: Supabase > SQL Editor

ALTER TABLE empresas
  ADD COLUMN IF NOT EXISTS haulmer_api_key TEXT,
  ADD COLUMN IF NOT EXISTS rut_empresa     TEXT,
  ADD COLUMN IF NOT EXISTS razon_social    TEXT,
  ADD COLUMN IF NOT EXISTS direccion       TEXT,
  ADD COLUMN IF NOT EXISTS comuna          TEXT,
  ADD COLUMN IF NOT EXISTS ciudad          TEXT DEFAULT 'Valparaíso';
