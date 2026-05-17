#!/usr/bin/env python3
"""
TransportPro — Configurador de GitHub Secrets
Ejecutar desde tu terminal local (Mac/Linux):
  python3 setup-github-secrets.py
Requiere: pip install PyNaCl requests
"""

import sys, base64, requests, getpass

try:
    from nacl import encoding, public
except ImportError:
    print("Instalando dependencias...")
    import subprocess
    subprocess.run([sys.executable, "-m", "pip", "install", "PyNaCl", "requests"], check=True)
    from nacl import encoding, public

REPO = "ssaavedraimportaciones-byte/transportpro-completo"

def encrypt_secret(public_key_value: str, secret_value: str) -> str:
    key = public.PublicKey(public_key_value.encode(), encoding.Base64Encoder())
    box = public.SealedBox(key)
    encrypted = box.encrypt(secret_value.encode())
    return base64.b64encode(encrypted).decode()

def set_secret(headers, pub_key, key_id, name, value):
    encrypted = encrypt_secret(pub_key, value)
    r = requests.put(
        f"https://api.github.com/repos/{REPO}/actions/secrets/{name}",
        headers=headers,
        json={"encrypted_value": encrypted, "key_id": key_id}
    )
    if r.status_code in (201, 204):
        print(f"  ✅ Secret '{name}' configurado")
    else:
        print(f"  ❌ Error en '{name}': {r.status_code} {r.text}")

def main():
    print("\n=== TransportPro — GitHub Secrets Setup ===\n")

    pat = getpass.getpass("GitHub PAT (repo scope): ").strip()
    if not pat:
        print("❌ Token vacío. Cancelado.")
        sys.exit(1)

    headers = {
        "Authorization": f"Bearer {pat}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }

    r = requests.get(
        f"https://api.github.com/repos/{REPO}/actions/secrets/public-key",
        headers=headers
    )
    if r.status_code != 200:
        print(f"❌ Error autenticando: {r.status_code} {r.text}")
        sys.exit(1)

    key_data = r.json()
    pub_key = key_data["key"]
    key_id  = key_data["key_id"]
    print(f"✅ Autenticado.\n")

    secrets = {
        "SURGE_LOGIN": "ssaavedra.importaciones@gmail.com",
        "SURGE_PASS":  "No8686no",
    }

    print("Configurando secrets de deploy...")
    for name, value in secrets.items():
        set_secret(headers, pub_key, key_id, name, value)

    print("\nIngresa los otros valores (Enter para omitir):")
    surge_token = getpass.getpass("SURGE_TOKEN (dejar vacío si no tienes): ").strip()
    db_url      = getpass.getpass("DB_URL (postgresql://...): ").strip()

    if surge_token: set_secret(headers, pub_key, key_id, "SURGE_TOKEN", surge_token)
    if db_url:      set_secret(headers, pub_key, key_id, "DB_URL", db_url)

    print("\n🎉 Listo. GitHub Actions va a deployar automáticamente ahora.\n")

if __name__ == "__main__":
    main()
