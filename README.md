# TransportPro

**Software de gestión de flotas y logística para Chile.** Aplicación web para
administrar viajes, conductores, mantención de vehículos, almacenaje, gastos y
facturación, con panel de administración y autenticación por roles.

> ⚠️ **Antes de nada, lee [`SECURITY.md`](SECURITY.md).** Este repositorio tuvo
> credenciales expuestas en su historial; hay que **rotarlas**.

## Qué es y cómo está construido

TransportPro es una aplicación **estática** (HTML + JavaScript en el navegador)
que habla directamente con **Supabase** como backend (base de datos PostgreSQL,
autenticación y Edge Functions). No hay servidor propio que mantener: se
publica como archivos estáticos y toda la lógica de datos vive en Supabase.

| Capa | Tecnología |
| --- | --- |
| Frontend | HTML + JavaScript (SDK `@supabase/supabase-js@2` por CDN) |
| Backend | Supabase: PostgreSQL + Auth + Row Level Security |
| Lógica servidor | Supabase Edge Functions (Deno/TypeScript) |
| Despliegue | Estático (Surge / Vercel / Netlify) |

## Estructura del paquete

```
landing.html                     Página de marketing (entrada pública)
transportpro-login.html          Login
index.html                       Aplicación principal (gestión de flota)
admin-profesional.html           Panel de administración
transportpro-final-standalone.html  Versión standalone de la app
fix-rls.sql                      Ajustes de Row Level Security
vercel.json                      Configuración de despliegue en Vercel
supabase/
  config.toml                    Configuración del proyecto Supabase
  migrations/*.sql               Esquema e histórico de migraciones
  functions/                     Edge Functions (Deno):
    ai-chat/                       asistente IA
    emitir-factura/                emisión de facturas
    fix-rls/                       reparación de políticas RLS
    run-migration/                 ejecutor de migraciones
    set-admin/                     asignación de rol admin
```

## Puesta en marcha

### 1. Backend (Supabase)

1. Crea un proyecto en [Supabase](https://supabase.com).
2. Aplica las migraciones en orden (Dashboard → SQL Editor, o con la CLI):
   ```bash
   supabase link --project-ref <TU_PROJECT_REF>
   supabase db push        # aplica supabase/migrations/*.sql
   ```
3. Despliega las Edge Functions:
   ```bash
   supabase functions deploy ai-chat emitir-factura set-admin
   ```
4. Configura las variables de entorno de las funciones (ver [`.env.example`](.env.example))
   en Supabase → Edge Functions → Secrets. **Nunca** las pongas en el código.

### 2. Frontend (configuración)

Las páginas usan la **URL** y la **anon key** de tu proyecto Supabase. La anon
key es pública por diseño (protegida por RLS), pero la URL/anon key deben ser
**las de tu proyecto**. Busca en los HTML la inicialización del cliente
Supabase (`createClient(...)`) y ponla apuntando a tu proyecto.

### 3. Servir en local

Al ser estático, cualquier servidor de archivos vale:

```bash
npx serve .            # o: python3 -m http.server 8080
# abre http://localhost:8080/landing.html
```

### 4. Desplegar

- **Vercel**: el `vercel.json` incluido sirve los HTML como estáticos.
  `vercel --prod`.
- **Surge**: hay un workflow en `.github/workflows/deploy.yml` que publica al
  hacer push a `main`. Requiere los secrets `SURGE_LOGIN`, `SURGE_TOKEN`,
  `SURGE_DOMAIN` y `SUPABASE_DB_URL` (ver [`SECURITY.md`](SECURITY.md)).
  Configúralos con `setup-github-secrets.py` o en Settings → Secrets.
- **Netlify**: ver `GUIA-NETLIFY-DEPLOY.md`.

## Seguridad (resumen)

- La **anon key** de Supabase es pública; la seguridad real la da **RLS**
  (Row Level Security). Revisa que todas las tablas tengan políticas
  (`supabase/migrations/20260507_rls_seguridad.sql`).
- La **service_role key**, el **token de gestión** (`sbp_…`), `JWT_SECRET`,
  `ADMIN_SECRET` y las contraseñas de base de datos son **secretos**: van en
  variables de entorno de Supabase / GitHub Secrets, **jamás** en el repo.
- Ver [`SECURITY.md`](SECURITY.md) para la lista de credenciales a rotar y cómo.

## Documentación adicional

- `GUIA-NETLIFY-DEPLOY.md` — despliegue en Netlify.
- `PLAN_IMPORT_ENGINE.md` — motor de importación de datos.
- `HISTORIAL_REPARACION.md` — histórico de reparaciones.
