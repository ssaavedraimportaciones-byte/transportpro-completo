# Seguridad de TransportPro

## ⚠️ Acción urgente: rotar credenciales expuestas

Este repositorio es **público** y en su historial de git se subieron
credenciales de producción reales. Sacarlas de los archivos actuales **no
basta**: siguen accesibles en commits antiguos y es muy probable que ya hayan
sido indexadas por terceros. **La única solución real es rotarlas.**

### Qué hay que rotar (por orden de gravedad)

1. **Supabase `service_role` key** (dos proyectos aparecían en los backups).
   Da acceso total a la base de datos saltándose RLS.
   → Supabase → Project Settings → API → *Reset* / genera un proyecto nuevo.
2. **Supabase Management token** (`sbp_…`). Controla toda la cuenta.
   → https://supabase.com/dashboard/account/tokens → revoca y crea otro.
3. **Contraseña de la base de datos** (aparecía en la cadena de conexión del
   workflow). → Supabase → Database → *Reset database password*.
4. **`JWT_SECRET`** del proyecto. → rotarlo invalida todas las sesiones (es lo
   correcto tras una fuga). Supabase → Auth → JWT settings.
5. **`ADMIN_SECRET`** usado por las Edge Functions. → genera uno nuevo y
   ponlo como secret de las funciones.
6. **Token de despliegue de Surge**. → `surge token` (regenera) y revoca el
   anterior; guárdalo solo como GitHub Secret.

Después de rotar, actualiza los valores **solo** en:
- Supabase → Edge Functions → Secrets (para las funciones).
- GitHub → Settings → Secrets and variables → Actions (para el workflow).

### Opcional pero recomendado: purgar el historial

Rotar es lo que de verdad cierra el riesgo. Si además quieres borrar los
secretos del historial de git (para que no queden a la vista):

```bash
# con git-filter-repo (recomendado)
pip install git-filter-repo
git filter-repo --invert-paths \
  --path CONFIG_BACKUP_20260322.txt \
  --path VERIFICACION_COMPLETA_20260322.txt \
  --path DOCUMENTACION-COMPLETA-PARA-GEMINI.md
git push --force --all    # reescribe la historia remota (coordínalo)
```

> El force-push reescribe la historia: hazlo con cuidado y avisa a cualquiera
> que tenga clones. Aun así, **asume que las claves ya están comprometidas y
> rótalas igualmente.**

## Buenas prácticas a partir de ahora

- Ningún secreto en el repo. Los archivos `CONFIG_BACKUP_*.txt`,
  `VERIFICACION_*.txt`, `*.env` y similares están en `.gitignore`.
- La **anon key** de Supabase sí puede ser pública (está protegida por RLS);
  la `service_role` **no**.
- Verifica que **todas** las tablas tienen políticas RLS activas
  (`supabase/migrations/20260507_rls_seguridad.sql`) — sin RLS, la anon key
  expondría datos.
- Los secretos de despliegue van como **GitHub Secrets** (usa
  `setup-github-secrets.py`); los de las funciones, como **Supabase Secrets**.
- Revisa las Edge Functions: deben leer las claves con `Deno.env.get(...)`,
  nunca tenerlas escritas en el código.

## Cómo reportar un problema de seguridad

Escribe a ssaavedra.importaciones@gmail.com. No abras un issue público con
detalles del fallo ni con credenciales.
