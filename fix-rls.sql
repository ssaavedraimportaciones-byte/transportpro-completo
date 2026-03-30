-- ═══════════════════════════════════════════════════════════
-- REPARACIÓN RLS TRANSPORTPRO
-- Pegar TODO este texto en Supabase → SQL Editor → Run
-- ═══════════════════════════════════════════════════════════

-- 1. Crear función helper que obtiene empresa_id SIN recursión
--    (SECURITY DEFINER = corre como admin, evita el loop)
CREATE OR REPLACE FUNCTION get_my_empresa_id()
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT empresa_id FROM public.usuarios WHERE id = auth.uid() LIMIT 1;
$$;

-- 2. USUARIOS - política simple sin recursión
DROP POLICY IF EXISTS "Usuarios de la misma empresa" ON public.usuarios;
DROP POLICY IF EXISTS "usuarios_select_own" ON public.usuarios;
DROP POLICY IF EXISTS "select_own_usuario" ON public.usuarios;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.usuarios;
DROP POLICY IF EXISTS "Usuarios pueden ver su empresa" ON public.usuarios;
DROP POLICY IF EXISTS "usuario_empresa" ON public.usuarios;

-- Política correcta: cada usuario solo ve su propio registro
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='usuarios' AND policyname='usuarios_own'
  ) THEN
    CREATE POLICY "usuarios_own" ON public.usuarios
      FOR ALL USING (auth.uid() = id);
  END IF;
END $$;

-- 3. EMPRESAS - política usando la función helper
DROP POLICY IF EXISTS "Empresas de su empresa" ON public.empresas;
DROP POLICY IF EXISTS "empresa_propia" ON public.empresas;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.empresas;
DROP POLICY IF EXISTS "empresas_own" ON public.empresas;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='empresas' AND policyname='empresas_own'
  ) THEN
    CREATE POLICY "empresas_own" ON public.empresas
      FOR ALL USING (id = get_my_empresa_id());
  END IF;
END $$;

-- 4. VIAJES
DROP POLICY IF EXISTS "Viajes de su empresa" ON public.viajes;
DROP POLICY IF EXISTS "viajes_empresa" ON public.viajes;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.viajes;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='viajes' AND policyname='viajes_empresa'
  ) THEN
    CREATE POLICY "viajes_empresa" ON public.viajes
      FOR ALL USING (empresa_id = get_my_empresa_id());
  END IF;
END $$;

-- 5. CLIENTES
DROP POLICY IF EXISTS "Clientes de su empresa" ON public.clientes;
DROP POLICY IF EXISTS "clientes_empresa" ON public.clientes;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.clientes;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='clientes' AND policyname='clientes_empresa'
  ) THEN
    CREATE POLICY "clientes_empresa" ON public.clientes
      FOR ALL USING (empresa_id = get_my_empresa_id());
  END IF;
END $$;

-- 6. VEHICULOS
DROP POLICY IF EXISTS "Vehiculos de su empresa" ON public.vehiculos;
DROP POLICY IF EXISTS "vehiculos_empresa" ON public.vehiculos;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.vehiculos;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='vehiculos' AND policyname='vehiculos_empresa'
  ) THEN
    CREATE POLICY "vehiculos_empresa" ON public.vehiculos
      FOR ALL USING (empresa_id = get_my_empresa_id());
  END IF;
END $$;

-- 7. CONDUCTORES
DROP POLICY IF EXISTS "Conductores de su empresa" ON public.conductores;
DROP POLICY IF EXISTS "conductores_empresa" ON public.conductores;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.conductores;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='conductores' AND policyname='conductores_empresa'
  ) THEN
    CREATE POLICY "conductores_empresa" ON public.conductores
      FOR ALL USING (empresa_id = get_my_empresa_id());
  END IF;
END $$;

-- 8. FACTURAS
DROP POLICY IF EXISTS "Facturas de su empresa" ON public.facturas;
DROP POLICY IF EXISTS "facturas_empresa" ON public.facturas;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.facturas;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='facturas' AND policyname='facturas_empresa'
  ) THEN
    CREATE POLICY "facturas_empresa" ON public.facturas
      FOR ALL USING (empresa_id = get_my_empresa_id());
  END IF;
END $$;

-- 9. COMBUSTIBLE
DROP POLICY IF EXISTS "Combustible de su empresa" ON public.combustible;
DROP POLICY IF EXISTS "combustible_empresa" ON public.combustible;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.combustible;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='combustible' AND policyname='combustible_empresa'
  ) THEN
    CREATE POLICY "combustible_empresa" ON public.combustible
      FOR ALL USING (empresa_id = get_my_empresa_id());
  END IF;
END $$;

-- 10. GASTOS
DROP POLICY IF EXISTS "Gastos de su empresa" ON public.gastos;
DROP POLICY IF EXISTS "gastos_empresa" ON public.gastos;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.gastos;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='gastos' AND policyname='gastos_empresa'
  ) THEN
    CREATE POLICY "gastos_empresa" ON public.gastos
      FOR ALL USING (empresa_id = get_my_empresa_id());
  END IF;
END $$;

-- 11. MANTENIMIENTO
DROP POLICY IF EXISTS "Mantenimiento de su empresa" ON public.mantenimiento;
DROP POLICY IF EXISTS "mantenimiento_empresa" ON public.mantenimiento;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.mantenimiento;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='mantenimiento' AND policyname='mantenimiento_empresa'
  ) THEN
    CREATE POLICY "mantenimiento_empresa" ON public.mantenimiento
      FOR ALL USING (empresa_id = get_my_empresa_id());
  END IF;
END $$;

-- Verificación final
SELECT tablename, policyname FROM pg_policies
WHERE tablename IN ('usuarios','empresas','viajes','clientes','vehiculos','conductores','facturas','combustible','gastos','mantenimiento')
ORDER BY tablename, policyname;
