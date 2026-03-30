# 🚀 GUÍA RÁPIDA: DEPLOY A NETLIFY (2 MINUTOS)

## PASO 1: IR A NETLIFY DROP

Abre en tu navegador:
```
https://app.netlify.com/drop
```

---

## PASO 2: CREAR CUENTA (30 SEGUNDOS)

Si no tienes cuenta:
1. Click "Sign up"
2. Usa tu cuenta GitHub (más rápido) o email
3. Confirma email si es necesario

Si ya tienes cuenta:
1. Click "Log in"

---

## PASO 3: ARRASTRAR ARCHIVOS (10 SEGUNDOS)

**Arrastra estos 3 archivos a la página:**

1. `admin-profesional.html`
2. `transportpro-login.html`
3. `transportpro-final-standalone.html`

Netlify los subirá automáticamente.

---

## PASO 4: OBTENER TUS URLs (INSTANTÁNEO)

Netlify te dará un nombre aleatorio tipo:
```
https://clever-einstein-abc123.netlify.app
```

**Tus 3 URLs serán:**
```
https://clever-einstein-abc123.netlify.app/admin-profesional.html
https://clever-einstein-abc123.netlify.app/transportpro-login.html
https://clever-einstein-abc123.netlify.app/transportpro-final-standalone.html
```

---

## PASO 5: PROBAR QUE FUNCIONA (1 MINUTO)

### Test 1: Sistema Standalone
Abre:
```
https://TU-URL.netlify.app/transportpro-final-standalone.html
```

Deberías ver:
- ✅ Sistema carga correctamente
- ✅ Tabs funcionan
- ✅ Puedes registrar vehículos

### Test 2: Panel Admin
Abre:
```
https://TU-URL.netlify.app/admin-profesional.html
```

Deberías ver:
- ✅ Panel oscuro profesional
- ✅ Stats: 1 empresa, 0 usuarios, 1 activa
- ✅ Formularios funcionan

### Test 3: Login
Abre:
```
https://TU-URL.netlify.app/transportpro-login.html
```

Deberías ver:
- ✅ Pantalla de login
- ✅ Formulario email/password

---

## PASO 6: CREAR PRIMER USUARIO (2 MINUTOS)

1. **Ve al panel admin:**
   ```
   https://TU-URL.netlify.app/admin-profesional.html
   ```

2. **Click en "Empresas" (sidebar)**

3. **Crear empresa:**
   - Nombre: Mi Empresa Test
   - RUT: 77.888.999-0
   - Plan: Professional
   - Click "Crear Empresa"

4. **Click en "Usuarios" (sidebar)**

5. **Crear usuario:**
   - Empresa: 77.888.999-0
   - Nombre: Admin Test
   - Email: admin@test.cl
   - Password: test123
   - Rol: Admin
   - Click "Crear Usuario"

6. **Guardar credenciales mostradas en pantalla**

---

## PASO 7: PROBAR LOGIN (30 SEGUNDOS)

1. **Ve al sistema con login:**
   ```
   https://TU-URL.netlify.app/transportpro-login.html
   ```

2. **Login con:**
   - Email: admin@test.cl
   - Password: test123

3. **Click "Iniciar Sesión"**

**Deberías ver:**
- ✅ Mensaje "Inicio de sesión exitoso"
- ✅ Sistema carga
- ✅ Datos de la empresa demo aparecen

---

## ✅ VERIFICACIÓN FINAL

Si todo funcionó, tienes:

- ✅ 3 URLs públicas funcionando
- ✅ Sistema standalone operativo
- ✅ Panel admin funcional
- ✅ Login funcionando
- ✅ Empresa y usuario de prueba creados

---

## 📋 GUARDA ESTAS URLs

**Apunta en un documento:**

```
SISTEMA TRANSPORTPRO - URLS DE PRODUCCIÓN

Panel Admin (solo tú):
https://TU-URL.netlify.app/admin-profesional.html

Sistema con Login (clientes):
https://TU-URL.netlify.app/transportpro-login.html

Sistema Demo (sin login):
https://TU-URL.netlify.app/transportpro-final-standalone.html

Credenciales Admin:
Email: admin@test.cl
Password: test123
```

---

## 🎯 PRÓXIMOS PASOS

Con Gemini, pídele:

1. **Cambiar el nombre del sitio:**
   "Quiero cambiar clever-einstein-abc123 a transportpro-chile"

2. **Configurar dominio personalizado:**
   "Quiero usar mi dominio zeropaper.cl en Netlify"

3. **Crear video demo:**
   "Ayúdame a crear script de video demo de 90 segundos"

4. **Estrategia de ventas:**
   "Dame pitch deck y emails para prospectar empresas de transporte"

---

## ❌ SI ALGO FALLA

**Error en panel admin:**
- Abre consola del navegador (F12)
- Pestaña "Console"
- Copia el error
- Pégaselo a Gemini: "Tengo este error en el panel admin: [ERROR]"

**No puedo crear empresa:**
- Verifica que estás en la URL de Netlify (no archivo local)
- Verifica conexión a internet
- Pregunta a Gemini: "No puedo crear empresa en el panel admin"

**Login no funciona:**
- Verifica que creaste el usuario correctamente
- Verifica email/password
- Pregunta a Gemini: "El login me da error: [MENSAJE]"

---

FIN - ¡LISTO PARA OPERAR!
