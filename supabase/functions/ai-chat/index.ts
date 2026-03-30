import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Siempre HTTP 200 — el SDK de Supabase JS convierte cualquier non-2xx
// en error genérico "Edge Function returned a non-2xx status code"
function ok(body: object) {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

const SYSTEM_PROMPT = `Eres TransportBot, el asistente inteligente de TransportPro — sistema de gestión de flotas para empresas de transporte en Chile.

MÓDULOS DE TRANSPORTPRO:
- Viajes: Registro y seguimiento de viajes (origen, destino, conductor, vehículo, tarifa, estado)
- Cotizaciones: Presupuestos para clientes, se convierten a viaje al aceptar
- Clientes: Base de datos de clientes (RUT, razón social, contacto, historial)
- Facturación: Emisión de facturas/boletas electrónicas DTE vía Haulmer o Lioren API
- Flota: Gestión de vehículos (patente, modelo, año, estado, kilometraje)
- Conductores: Registro de conductores (licencia, vencimiento, estado)
- Combustible: Control de consumo por vehículo y fecha, costo/km
- Gastos: Categorización de egresos (mantenimiento, peaje, combustible, etc.)
- Mantenimiento: Historial de mantenciones preventivas y correctivas
- Rentabilidad: Análisis de ingresos vs gastos por ruta o período
- Exportar: Todos los módulos exportan a Excel (.xlsx) con o sin cálculos de IVA
- Configuración: Datos de empresa y API Key para DTE (Haulmer/Lioren)

CONOCIMIENTO DEL NEGOCIO:
- DTE (Documento Tributario Electrónico): facturas electrónicas requeridas por SII Chile
- Tipos DTE: Factura afecta (33), Boleta electrónica (39), Nota de crédito (61)
- Haulmer y Lioren: Proveedores de facturación electrónica en Chile (Lioren: 2.500 docs gratis/mes)
- IVA 19% se aplica a servicios de transporte de carga
- Libro de guías de despacho para transporte
- TAG autopista: gasto deducible
- SII: misiicl.sii.cl — Portal para registro como contribuyente electrónico

ESTILO DE RESPUESTA:
- Español chileno directo y conciso.
- Ayuda a interpretar datos de la flota (costos, rendimiento, mantenimiento).
- Sugiere acciones concretas en los módulos de TransportPro.
- Si es pregunta técnica de facturación SII, recomienda verificar con contador.
- Máximo 3-4 párrafos o lista con guiones.`;

function toGeminiContents(messages: { role: string; content: string }[], systemPrompt: string) {
  const contents = messages.map((m) => ({
    role: m.role === "assistant" ? "model" : "user",
    parts: [{ text: m.content }],
  }));
  if (contents.length > 0 && contents[0].role === "user") {
    contents[0] = {
      role: "user",
      parts: [{ text: `${systemPrompt}\n\n---\n\n${contents[0].parts[0].text}` }],
    };
  }
  return contents;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  try {
    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) {
      return ok({ error: "IA no configurada. Contacta al administrador (falta GEMINI_API_KEY)." });
    }

    const body = await req.json().catch(() => null);
    if (!body?.messages || !Array.isArray(body.messages)) {
      return ok({ error: "Formato inválido: se requiere { messages: [...] }" });
    }

    // Gemini 2.0 Flash — gratuito, rápido, 1500 req/día
    const model = "gemini-2.0-flash";
    const url   = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

    const geminiBody = {
      contents: toGeminiContents(body.messages.slice(-12), SYSTEM_PROMPT),
      generationConfig: {
        maxOutputTokens: 1024,
        temperature: 0.7,
        topP: 0.9,
      },
    };

    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(geminiBody),
    });

    const geminiData = await response.json();

    if (!response.ok) {
      // Error de Gemini — devolver 200 con mensaje claro
      const errMsg = geminiData?.error?.message || `Error Gemini (${response.status})`;
      return ok({ error: `Error del asistente: ${errMsg}` });
    }

    const content = geminiData.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!content) {
      return ok({ error: "El asistente no generó respuesta. Intenta de nuevo." });
    }

    return ok({ content });

  } catch (e: any) {
    return ok({ error: "Error interno: " + (e?.message || "desconocido") });
  }
});
