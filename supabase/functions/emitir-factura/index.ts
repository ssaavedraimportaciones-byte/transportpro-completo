import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

const DEMO_KEYS = [
  "928e15a2d14d4a6292345f04960f4bd3",
  "41eb78998d444dbaa4922c410ef14057"
]

// Helper: siempre devuelve HTTP 200 para que el SDK de Supabase JS
// no convierta errores de negocio en el mensaje genérico "non-2xx".
function ok(body: object) {
  return new Response(JSON.stringify(body), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
    status: 200
  })
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const body = await req.json()
    const { viaje_id, empresa_id, tipoDte } = body

    // 1. Validar parámetros obligatorios
    if (!empresa_id) {
      return ok({ exito: false, error: "Se requiere empresa_id" })
    }
    if (!body.testConnection && !viaje_id) {
      return ok({ exito: false, error: "Se requiere viaje_id para emitir documentos" })
    }

    // 2. Leer config de facturación de la empresa desde la BD
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    const { data: empresa, error: empresaErr } = await supabase
      .from("empresas")
      .select("haulmer_api_key, rut_empresa, razon_social, direccion, comuna, ciudad")
      .eq("id", empresa_id)
      .single()

    if (empresaErr || !empresa) {
      return ok({ exito: false, error: "Empresa no encontrada" })
    }

    if (!empresa.haulmer_api_key) {
      return ok({
        exito: false,
        error: "Esta empresa no tiene API Key de Haulmer configurada. Ve a ⚙️ Configuración."
      })
    }

    // Definir credenciales (reutilizadas en testConnection y en emisión)
    const apiKey  = empresa.haulmer_api_key
    const isDemo  = DEMO_KEYS.includes(apiKey)
    const baseUrl = isDemo
      ? "https://dev-api.haulmer.com/v2/dte"
      : "https://api.haulmer.com/v2/dte"

    // Modo test: solo verificar que la API Key funciona con Haulmer (no emite DTE)
    if (body.testConnection === true) {
      try {
        const testRes = await fetch(`${baseUrl}/organization`, {
          headers: { "apikey": apiKey, "Content-Type": "application/json" }
        })
        if (testRes.ok) {
          const org = await testRes.json()
          return ok({
            exito:   true,
            demo:    isDemo,
            mensaje: `Conexión exitosa${isDemo ? " (modo prueba)" : ""}`,
            giro:    org.giro || org.Giro || null
          })
        } else {
          const errBody = await testRes.text()
          return ok({
            exito: false,
            error: `API Key inválida o sin permisos en Haulmer (${testRes.status})`,
            detalles: errBody
          })
        }
      } catch (tErr: any) {
        return ok({ exito: false, error: "Error de red al conectar con Haulmer: " + tErr.message })
      }
    }

    // 3. Leer viaje + cliente
    const { data: viaje, error: viajeErr } = await supabase
      .from("viajes")
      .select("*, clientes(rut, razon_social, email)")
      .eq("id", viaje_id)
      .eq("empresa_id", empresa_id)
      .single()

    if (viajeErr || !viaje) {
      return ok({ exito: false, error: "Viaje no encontrado o no pertenece a esta empresa" })
    }

    // 4. Construir payload DTE
    const tipo      = tipoDte || 33
    const esFactura = tipo === 33 || tipo === 34
    const monto     = Math.round(Number(viaje.tarifa) || 0)
    const mntNeto   = Math.round(monto / 1.19)
    const iva       = Math.round(mntNeto * 0.19)
    const ruta      = `${viaje.origen || ""} - ${viaje.destino || ""}`.substring(0, 80)

    if (monto <= 0) {
      return ok({ exito: false, error: "El viaje no tiene tarifa válida para facturar" })
    }

    // Obtener giro del emisor desde Haulmer (opcional)
    let giroEmisor = "Transporte de Carga"
    try {
      const orgRes = await fetch(`${baseUrl}/organization`, {
        headers: { "apikey": apiKey, "Content-Type": "application/json" }
      })
      if (orgRes.ok) {
        const org = await orgRes.json()
        giroEmisor = org.giro || org.Giro || giroEmisor
      }
    } catch (_) { /* usar valor por defecto */ }

    const totales: Record<string, number> = { MntTotal: monto }
    if (esFactura) { totales.MntNeto = mntNeto; totales.IVA = iva }

    const dtePayload = {
      response: ["PDF", "FOLIO"],
      customer: {
        fullName: viaje.clientes?.razon_social || "Consumidor Final",
        email:    viaje.clientes?.email        || ""
      },
      dte: {
        Encabezado: {
          IdDoc: { TipoDTE: tipo, FchEmis: new Date().toISOString().split("T")[0], IndServicio: 3 },
          Emisor: {
            RUTEmisor:    empresa.rut_empresa  || "",
            RznSocEmisor: empresa.razon_social || "",
            GiroEmisor:   giroEmisor,
            DirOrigen:    empresa.direccion    || "",
            CiudadOrigen: empresa.ciudad       || "Valparaiso"
          },
          Receptor: {
            RUTRecep:    viaje.clientes?.rut          || "66666666-6",
            RznSocRecep: viaje.clientes?.razon_social || "Consumidor Final"
          },
          Totales: totales
        },
        Detalle: [{
          NroLinDet: 1,
          NmbItem:   `Flete ${ruta}`,
          QtyItem:   1,
          PrcItem:   esFactura ? mntNeto : monto,
          MontoItem: esFactura ? mntNeto : monto
        }]
      }
    }

    // 5. Llamar a API Haulmer
    const haulmerRes = await fetch(`${baseUrl}/document`, {
      method: "POST",
      headers: {
        "apikey":          apiKey,
        "Content-Type":    "application/json",
        "Idempotency-Key": `tp-${empresa_id}-${viaje_id}-${Date.now()}`
      },
      body: JSON.stringify(dtePayload)
    })

    const haulmerData = await haulmerRes.json()

    if (!haulmerRes.ok) {
      return ok({
        exito:    false,
        error:    haulmerData.message || haulmerData.error || `Error Haulmer ${haulmerRes.status}`,
        detalles: haulmerData.details || haulmerData || null,
        demo:     isDemo
      })
    }

    const folio  = haulmerData.folio  || haulmerData.Folio  || haulmerData.FOLIO  || null
    const pdfUrl = haulmerData.pdf    || haulmerData.urlPdf || haulmerData.URL_PDF || null
    const pdfB64 = haulmerData.PDF    || haulmerData.pdf_base64 || null

    // 6. Guardar en tabla facturas
    await supabase.from("facturas").insert([{
      empresa_id,
      cliente_id:  viaje.cliente_id || null,
      viaje_id:    viaje.id,
      fecha:       new Date().toISOString().split("T")[0],
      vencimiento: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split("T")[0],
      monto,
      estado:      "pendiente",
      numero:      folio ? String(folio) : null
    }])

    return ok({
      exito:  true,
      folio,
      pdfUrl,
      demo:   isDemo,
      raw:    { PDF: pdfB64, ...haulmerData }
    })

  } catch (error: any) {
    return ok({ exito: false, error: error.message || "Error interno del servidor" })
  }
})
