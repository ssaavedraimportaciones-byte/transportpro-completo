-- ══════════════════════════════════════════════════════════════
-- VIAJES — Nave, Generador de Carga, N° Factura y estado de pago
--
-- Columnas nuevas, todas opcionales (NULL permitido salvo el
-- booleano que trae un default seguro). No modifica ni elimina
-- ninguna columna existente — 100% compatible con datos actuales.
-- ══════════════════════════════════════════════════════════════

ALTER TABLE public.viajes
  ADD COLUMN IF NOT EXISTS generador_carga TEXT,
  ADD COLUMN IF NOT EXISTS nave             TEXT,
  ADD COLUMN IF NOT EXISTS numero_factura   TEXT,
  ADD COLUMN IF NOT EXISTS factura_pagada   BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.viajes.generador_carga IS 'Empresa/persona que genera la carga (shipper), distinto del cliente que se factura';
COMMENT ON COLUMN public.viajes.nave             IS 'Nombre de la nave asociada al viaje (transporte marítimo)';
COMMENT ON COLUMN public.viajes.numero_factura   IS 'N° de factura asociada al viaje, registrado manualmente';
COMMENT ON COLUMN public.viajes.factura_pagada   IS 'Estado de pago de la factura del viaje: true = pagada, false = no pagada';

NOTIFY pgrst, 'reload schema';
