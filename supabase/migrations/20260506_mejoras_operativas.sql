-- ═══════════════════════════════════════════════════════════
-- MEJORAS OPERATIVAS: combustible + facturas
-- ═══════════════════════════════════════════════════════════

-- N° Factura en combustible (evitar duplicados de carga)
ALTER TABLE combustible
    ADD COLUMN IF NOT EXISTS numero_factura text;

-- Gestión de cobro en facturas
ALTER TABLE facturas
    ADD COLUMN IF NOT EXISTS fecha_pago       date,
    ADD COLUMN IF NOT EXISTS monto_pagado     numeric DEFAULT 0,
    ADD COLUMN IF NOT EXISTS notas_cobro      text,
    ADD COLUMN IF NOT EXISTS tipo_pago        text DEFAULT 'transferencia'
        CHECK (tipo_pago IN ('transferencia','cheque','efectivo','credito','otro'));

-- El estado ya soporta 'parcial' en algunos casos; aseguramos que el CHECK lo permita
-- (si el CHECK no existe simplemente lo omitimos — depende de cómo fue creada la tabla)

NOTIFY pgrst, 'reload schema';
