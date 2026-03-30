import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

/**
 * Edge Function: set-admin
 * Promueve un usuario a rol=admin en la tabla `usuarios` de TransportPro
 * Y crea la empresa si no existe.
 *
 * POST /functions/v1/set-admin
 * Body: { user_id, email, nombre, empresa_nombre? }
 * Auth: Bearer <service_role_key>
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";

  const supabase = createClient(supabaseUrl, serviceKey);

  let body: { user_id?: string; email?: string; nombre?: string; empresa_nombre?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Body JSON inválido" }), {
      status: 400,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });
  }

  const { user_id, email, nombre = "Administrador", empresa_nombre = "Mi Empresa" } = body;
  if (!user_id) {
    return new Response(JSON.stringify({ error: "user_id requerido" }), {
      status: 400,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });
  }

  try {
    // 1. Verificar si ya existe empresa para este user
    let { data: empresa } = await supabase
      .from("empresas")
      .select("id")
      .eq("id", user_id)  // empresas en TransportPro no tienen user_id directo, buscar de otra forma
      .maybeSingle();

    // Buscar empresa por usuario en tabla usuarios
    const { data: usuarioExist } = await supabase
      .from("usuarios")
      .select("empresa_id")
      .eq("id", user_id)
      .maybeSingle();

    let empresa_id: string;

    if (usuarioExist?.empresa_id) {
      empresa_id = usuarioExist.empresa_id;
    } else {
      // Crear empresa nueva
      const { data: nuevaEmpresa, error: errEmpresa } = await supabase
        .from("empresas")
        .insert({
          nombre: empresa_nombre,
          rut: "00.000.000-0",
          plan: "enterprise",
          activa: true,
        })
        .select("id")
        .single();

      if (errEmpresa) throw new Error(`Error creando empresa: ${errEmpresa.message}`);
      empresa_id = nuevaEmpresa.id;
    }

    // 2. Insertar o actualizar usuario con rol admin
    const { error: errUser } = await supabase
      .from("usuarios")
      .upsert({
        id: user_id,
        empresa_id,
        nombre,
        rol: "admin",
        activo: true,
      }, { onConflict: "id" });

    if (errUser) throw new Error(`Error creando usuario: ${errUser.message}`);

    // 3. Para FinancePro: crear fp_empresas si no existe
    const { data: fpEmpresa } = await supabase
      .from("fp_empresas")
      .select("id")
      .eq("user_id", user_id)
      .maybeSingle();

    if (!fpEmpresa) {
      await supabase.from("fp_empresas").insert({
        user_id,
        nombre: empresa_nombre,
        rut: "00.000.000-0",
        giro: "Servicios",
        regimen_tributario: "pro_pyme_general",
      });
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `✅ Usuario ${email ?? user_id} es ahora ADMINISTRADOR`,
        empresa_id,
        rol: "admin",
        apps: ["TransportPro", "FinancePro Chile"],
      }),
      { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: (e as Error).message }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  }
});
