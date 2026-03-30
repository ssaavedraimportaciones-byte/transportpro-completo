import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { Pool } from "https://deno.land/x/postgres@v0.17.0/mod.ts"

const TABLAS = ['viajes','clientes','vehiculos','conductores','facturas','combustible','gastos','mantenimiento']

serve(async (_req) => {
  const pool = new Pool(Deno.env.get('SUPABASE_DB_URL')!, 1, true)
  const db   = await pool.connect()
  const log: string[] = []

  try {
    // 1. Crear función helper SECURITY DEFINER
    await db.queryArray(`
      CREATE OR REPLACE FUNCTION get_my_empresa_id()
      RETURNS uuid LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
        SELECT empresa_id FROM public.usuarios WHERE id = auth.uid() LIMIT 1;
      $$
    `)
    log.push("✅ función helper creada")

    // 2. Borrar políticas de USUARIOS y crear la correcta
    const { rows: polUs } = await db.queryArray(
      `SELECT policyname FROM pg_policies WHERE tablename='usuarios' AND schemaname='public'`
    )
    for (const [name] of polUs) {
      await db.queryArray(`DROP POLICY IF EXISTS "${name}" ON public.usuarios`)
    }
    await db.queryArray(`CREATE POLICY "usuarios_own" ON public.usuarios FOR ALL USING (auth.uid() = id)`)
    log.push(`✅ usuarios: ${polUs.length} políticas reemplazadas`)

    // 3. Política especial para EMPRESAS (usa id, no empresa_id)
    const { rows: polEmp } = await db.queryArray(
      `SELECT policyname FROM pg_policies WHERE tablename='empresas' AND schemaname='public'`
    )
    for (const [name] of polEmp) {
      await db.queryArray(`DROP POLICY IF EXISTS "${name}" ON public.empresas`)
    }
    await db.queryArray(`CREATE POLICY "empresas_own" ON public.empresas FOR ALL USING (id = get_my_empresa_id())`)
    log.push(`✅ empresas: ${polEmp.length} políticas reemplazadas`)

    // 4. Para cada tabla de empresa, borrar políticas y crear nueva con helper
    for (const tabla of TABLAS) {
      const { rows: pols } = await db.queryArray(
        `SELECT policyname FROM pg_policies WHERE tablename='${tabla}' AND schemaname='public'`
      )
      for (const [name] of pols) {
        await db.queryArray(`DROP POLICY IF EXISTS "${name}" ON public.${tabla}`)
      }
      await db.queryArray(
        `CREATE POLICY "${tabla}_empresa" ON public.${tabla} FOR ALL USING (empresa_id = get_my_empresa_id())`
      )
      log.push(`✅ ${tabla}: ${pols.length} políticas reemplazadas`)
    }

    return new Response(JSON.stringify({ ok: true, log }), {
      headers: { "Content-Type": "application/json" }, status: 200
    })
  } catch (err) {
    return new Response(JSON.stringify({ ok: false, error: err.message, log }), {
      headers: { "Content-Type": "application/json" }, status: 500
    })
  } finally {
    db.release()
    await pool.end()
  }
})
