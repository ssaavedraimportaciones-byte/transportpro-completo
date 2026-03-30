import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { Client } from "https://deno.land/x/postgres@v0.17.0/mod.ts";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// SQL para crear todas las tablas de FinancePro Chile con prefijo fp_
const MIGRATION_SQL = `
-- Extensiones
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- fp_empresas
CREATE TABLE IF NOT EXISTS fp_empresas (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre        TEXT NOT NULL,
  rut           TEXT NOT NULL,
  giro          TEXT,
  regimen_tributario TEXT NOT NULL DEFAULT 'pro_pyme_general'
                CHECK (regimen_tributario IN ('pro_pyme_general','pro_pyme_transparente','general')),
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- fp_proyectos
CREATE TABLE IF NOT EXISTS fp_proyectos (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  empresa_id    UUID NOT NULL REFERENCES fp_empresas(id) ON DELETE CASCADE,
  nombre        TEXT NOT NULL,
  cliente       TEXT,
  fecha_inicio  DATE NOT NULL,
  fecha_fin     DATE,
  estado        TEXT NOT NULL DEFAULT 'activo'
                CHECK (estado IN ('activo','pausado','terminado')),
  presupuesto   NUMERIC(14,2),
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- fp_ingresos
CREATE TABLE IF NOT EXISTS fp_ingresos (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  empresa_id    UUID NOT NULL REFERENCES fp_empresas(id) ON DELETE CASCADE,
  descripcion   TEXT NOT NULL,
  monto         NUMERIC(14,2) NOT NULL,
  monto_iva     NUMERIC(14,2) DEFAULT 0,
  fecha         DATE NOT NULL,
  categoria     TEXT NOT NULL DEFAULT 'servicios'
                CHECK (categoria IN ('servicios','venta_producto','honorarios','arriendo','otro')),
  proyecto_id   UUID REFERENCES fp_proyectos(id),
  cliente       TEXT,
  documento     TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- fp_gastos
CREATE TABLE IF NOT EXISTS fp_gastos (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  empresa_id    UUID NOT NULL REFERENCES fp_empresas(id) ON DELETE CASCADE,
  descripcion   TEXT NOT NULL,
  monto         NUMERIC(14,2) NOT NULL,
  monto_iva     NUMERIC(14,2) DEFAULT 0,
  fecha         DATE NOT NULL,
  categoria     TEXT NOT NULL
                CHECK (categoria IN ('formalizacion','tecnologia','operativo','capital_humano',
                                     'tributario','marketing','arriendo','otro')),
  subcategoria  TEXT,
  proyecto_id   UUID REFERENCES fp_proyectos(id),
  proveedor     TEXT,
  imagen_url    TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- fp_empleados
CREATE TABLE IF NOT EXISTS fp_empleados (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  empresa_id      UUID NOT NULL REFERENCES fp_empresas(id) ON DELETE CASCADE,
  nombre          TEXT NOT NULL,
  rut             TEXT NOT NULL,
  cargo           TEXT,
  tipo            TEXT NOT NULL DEFAULT 'contrato'
                  CHECK (tipo IN ('contrato','honorarios')),
  sueldo_bruto    NUMERIC(14,2) NOT NULL,
  afp             TEXT DEFAULT 'Habitat',
  salud           TEXT DEFAULT 'fonasa' CHECK (salud IN ('fonasa','isapre')),
  monto_salud     NUMERIC(14,2) DEFAULT 0,
  activo          BOOLEAN DEFAULT TRUE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- fp_costos_formalizacion
CREATE TABLE IF NOT EXISTS fp_costos_formalizacion (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  empresa_id              UUID NOT NULL REFERENCES fp_empresas(id) ON DELETE CASCADE,
  descripcion             TEXT NOT NULL,
  monto                   NUMERIC(14,2) NOT NULL,
  fecha                   DATE NOT NULL,
  tipo                    TEXT NOT NULL
                          CHECK (tipo IN ('constitucion','fea','notaria','marca_inapi',
                                          'patente_municipal','otro')),
  amortizacion_meses      INT NOT NULL DEFAULT 12,
  costo_mensual_amortizado NUMERIC(14,2) GENERATED ALWAYS AS (monto / amortizacion_meses) STORED,
  created_at              TIMESTAMPTZ DEFAULT NOW()
);

-- fp_costos_tecnologicos
CREATE TABLE IF NOT EXISTS fp_costos_tecnologicos (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  empresa_id        UUID NOT NULL REFERENCES fp_empresas(id) ON DELETE CASCADE,
  descripcion       TEXT NOT NULL,
  proveedor         TEXT,
  costo             NUMERIC(14,2) NOT NULL,
  moneda            TEXT NOT NULL DEFAULT 'CLP' CHECK (moneda IN ('CLP','USD','EUR')),
  frecuencia        TEXT NOT NULL DEFAULT 'mensual'
                    CHECK (frecuencia IN ('mensual','anual','unico')),
  categoria         TEXT NOT NULL
                    CHECK (categoria IN ('hosting','dominio','base_datos','despliegue',
                                         'api_externa','licencia','pasarela_pago','otro')),
  proyecto_id       UUID REFERENCES fp_proyectos(id),
  fecha_vencimiento DATE,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- fp_registros_tributarios
CREATE TABLE IF NOT EXISTS fp_registros_tributarios (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  empresa_id   UUID NOT NULL REFERENCES fp_empresas(id) ON DELETE CASCADE,
  periodo      TEXT NOT NULL,
  iva_debito   NUMERIC(14,2) DEFAULT 0,
  iva_credito  NUMERIC(14,2) DEFAULT 0,
  iva_pagar    NUMERIC(14,2) GENERATED ALWAYS AS
               (GREATEST(iva_debito - iva_credito, 0)) STORED,
  ppm          NUMERIC(14,2) DEFAULT 0,
  pagado       BOOLEAN DEFAULT FALSE,
  fecha_pago   DATE,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(empresa_id, periodo)
);

-- fp_fondo_emergencia
CREATE TABLE IF NOT EXISTS fp_fondo_emergencia (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  empresa_id        UUID NOT NULL REFERENCES fp_empresas(id) ON DELETE CASCADE UNIQUE,
  porcentaje_ahorro NUMERIC(5,2) DEFAULT 5,
  monto_acumulado   NUMERIC(14,2) DEFAULT 0,
  meta              NUMERIC(14,2) DEFAULT 0,
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

-- fp_config_fundador
CREATE TABLE IF NOT EXISTS fp_config_fundador (
  id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  empresa_id           UUID NOT NULL REFERENCES fp_empresas(id) ON DELETE CASCADE UNIQUE,
  nombre               TEXT NOT NULL,
  sueldo_reemplazo     NUMERIC(14,2) NOT NULL DEFAULT 2000000,
  horas_mensuales      INT NOT NULL DEFAULT 160,
  multiplicador_riesgo NUMERIC(4,2) NOT NULL DEFAULT 1.4,
  valor_hora           NUMERIC(14,2) GENERATED ALWAYS AS
                       (sueldo_reemplazo / horas_mensuales * multiplicador_riesgo) STORED,
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);

-- fp_subscripciones (SaaS billing)
CREATE TABLE IF NOT EXISTS fp_subscripciones (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  empresa_id  UUID NOT NULL REFERENCES fp_empresas(id) ON DELETE CASCADE UNIQUE,
  plan        TEXT NOT NULL DEFAULT 'trial' CHECK (plan IN ('trial','starter','professional','enterprise')),
  estado      TEXT NOT NULL DEFAULT 'trial' CHECK (estado IN ('trial','activa','vencida','cancelada')),
  monto       NUMERIC(10,2) DEFAULT 0,
  fecha_inicio TIMESTAMPTZ DEFAULT NOW(),
  fecha_fin   TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================================

ALTER TABLE fp_empresas              ENABLE ROW LEVEL SECURITY;
ALTER TABLE fp_proyectos             ENABLE ROW LEVEL SECURITY;
ALTER TABLE fp_ingresos              ENABLE ROW LEVEL SECURITY;
ALTER TABLE fp_gastos                ENABLE ROW LEVEL SECURITY;
ALTER TABLE fp_empleados             ENABLE ROW LEVEL SECURITY;
ALTER TABLE fp_costos_formalizacion  ENABLE ROW LEVEL SECURITY;
ALTER TABLE fp_costos_tecnologicos   ENABLE ROW LEVEL SECURITY;
ALTER TABLE fp_registros_tributarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE fp_fondo_emergencia      ENABLE ROW LEVEL SECURITY;
ALTER TABLE fp_config_fundador       ENABLE ROW LEVEL SECURITY;
ALTER TABLE fp_subscripciones        ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
DO $$ BEGIN
  -- fp_empresas
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fp_empresas' AND policyname = 'fp usuario ve sus empresas') THEN
    CREATE POLICY "fp usuario ve sus empresas" ON fp_empresas FOR ALL USING (user_id = auth.uid());
  END IF;

  -- fp_proyectos
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fp_proyectos' AND policyname = 'fp usuario ve sus proyectos') THEN
    CREATE POLICY "fp usuario ve sus proyectos" ON fp_proyectos FOR ALL USING (
      empresa_id IN (SELECT id FROM fp_empresas WHERE user_id = auth.uid())
    );
  END IF;

  -- fp_ingresos
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fp_ingresos' AND policyname = 'fp usuario ve sus ingresos') THEN
    CREATE POLICY "fp usuario ve sus ingresos" ON fp_ingresos FOR ALL USING (
      empresa_id IN (SELECT id FROM fp_empresas WHERE user_id = auth.uid())
    );
  END IF;

  -- fp_gastos
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fp_gastos' AND policyname = 'fp usuario ve sus gastos') THEN
    CREATE POLICY "fp usuario ve sus gastos" ON fp_gastos FOR ALL USING (
      empresa_id IN (SELECT id FROM fp_empresas WHERE user_id = auth.uid())
    );
  END IF;

  -- fp_empleados
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fp_empleados' AND policyname = 'fp usuario ve sus empleados') THEN
    CREATE POLICY "fp usuario ve sus empleados" ON fp_empleados FOR ALL USING (
      empresa_id IN (SELECT id FROM fp_empresas WHERE user_id = auth.uid())
    );
  END IF;

  -- fp_costos_formalizacion
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fp_costos_formalizacion' AND policyname = 'fp usuario ve costos formalizacion') THEN
    CREATE POLICY "fp usuario ve costos formalizacion" ON fp_costos_formalizacion FOR ALL USING (
      empresa_id IN (SELECT id FROM fp_empresas WHERE user_id = auth.uid())
    );
  END IF;

  -- fp_costos_tecnologicos
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fp_costos_tecnologicos' AND policyname = 'fp usuario ve costos tecnologicos') THEN
    CREATE POLICY "fp usuario ve costos tecnologicos" ON fp_costos_tecnologicos FOR ALL USING (
      empresa_id IN (SELECT id FROM fp_empresas WHERE user_id = auth.uid())
    );
  END IF;

  -- fp_registros_tributarios
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fp_registros_tributarios' AND policyname = 'fp usuario ve registros tributarios') THEN
    CREATE POLICY "fp usuario ve registros tributarios" ON fp_registros_tributarios FOR ALL USING (
      empresa_id IN (SELECT id FROM fp_empresas WHERE user_id = auth.uid())
    );
  END IF;

  -- fp_fondo_emergencia
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fp_fondo_emergencia' AND policyname = 'fp usuario ve fondo emergencia') THEN
    CREATE POLICY "fp usuario ve fondo emergencia" ON fp_fondo_emergencia FOR ALL USING (
      empresa_id IN (SELECT id FROM fp_empresas WHERE user_id = auth.uid())
    );
  END IF;

  -- fp_config_fundador
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fp_config_fundador' AND policyname = 'fp usuario ve config fundador') THEN
    CREATE POLICY "fp usuario ve config fundador" ON fp_config_fundador FOR ALL USING (
      empresa_id IN (SELECT id FROM fp_empresas WHERE user_id = auth.uid())
    );
  END IF;

  -- fp_subscripciones
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fp_subscripciones' AND policyname = 'fp usuario ve subscripcion') THEN
    CREATE POLICY "fp usuario ve subscripcion" ON fp_subscripciones FOR ALL USING (
      empresa_id IN (SELECT id FROM fp_empresas WHERE user_id = auth.uid())
    );
  END IF;
END $$;

-- Vista admin (sin RLS - solo para service role)
CREATE OR REPLACE VIEW admin_empresas_view AS
  SELECT
    e.id,
    e.user_id,
    e.nombre,
    e.rut,
    e.giro,
    e.regimen_tributario,
    e.created_at,
    COALESCE(s.plan, 'trial') as plan,
    COALESCE(s.estado, 'trial') as estado,
    COALESCE(s.monto, 0) as monto_plan,
    s.fecha_inicio as suscripcion_inicio,
    s.fecha_fin as suscripcion_fin
  FROM fp_empresas e
  LEFT JOIN fp_subscripciones s ON s.empresa_id = e.id;
`;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  // Proteger con secret param
  const url = new URL(req.url);
  const secret = url.searchParams.get("secret");
  if (secret !== "fp_migrate_2026") {
    return new Response(JSON.stringify({ error: "No autorizado" }), {
      status: 401,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });
  }

  const dbUrl = Deno.env.get("SUPABASE_DB_URL");
  if (!dbUrl) {
    return new Response(JSON.stringify({ error: "SUPABASE_DB_URL no disponible" }), {
      status: 500,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });
  }

  try {
    const client = new Client(dbUrl);
    await client.connect();

    await client.queryArray(MIGRATION_SQL);
    await client.end();

    return new Response(
      JSON.stringify({ success: true, message: "Migración FinancePro ejecutada correctamente. Tablas fp_* creadas." }),
      { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: (e as Error).message }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  }
});
