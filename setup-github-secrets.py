#!/usr/bin/env python3
"""
TransportPro — Configurador de GitHub Secrets
Ejecutar UNA VEZ desde tu terminal local (Mac/Linux):
  python3 setup-github-secrets.py
Requiere: pip install PyNaCl requests
"""

import sys, base64, requests

try:
    from nacl import encoding, public
except ImportError:
    print("Instalando dependencias...")
    import subprocess
    subprocess.run([sys.executable, "-m", "pip", "install", "PyNaCl", "requests"], check=True)
    from nacl import encoding, public

REPO = "ssaavedraimportaciones-byte/transportpro-completo"

SECRETS = {
    "SURGE_LOGIN": "ssaavedra.importaciones@gmail.com",
    "SURGE_TOKEN": "917ceb996e01d6f911baff79cde3ef7b",
    "DB_URL": "postgresql://postgres.ozmnfdndauyzcsxunxig:TransportPro2026DB@aws-0-sa-east-1.pooler.supabase.com:6543/postgres",
}

def encrypt_secret(public_key_value: str, secret_value: str) -> str:
    key = public.PublicKey(public_key_value.encode(), encoding.Base64Encoder())
    box = public.SealedBox(key)
    encrypted = box.encrypt(secret_value.encode())
    return base64.b64encode(encrypted).decode()

def main():
    print("\n=== TransportPro — GitHub Secrets Setup ===\n")
    print("Necesitas un GitHub Personal Access Token (PAT) con permisos:")
    print("  repo → secrets (Actions secrets) write")
    print("\nCrear en: https://github.com/settings/tokens/new")
    print("  Scope requerido: repo (full)\n")

    pat = input("Pega tu GitHub PAT aquí: ").strip()
    if not pat:
        print("❌ Token vacío. Cancelado.")
        sys.exit(1)

    headers = {
        "Authorization": f"Bearer {pat}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }

    # Get public key
    r = requests.get(
        f"https://api.github.com/repos/{REPO}/actions/secrets/public-key",
        headers=headers
    )
    if r.status_code != 200:
        print(f"❌ Error obteniendo public key: {r.status_code} {r.text}")
        sys.exit(1)

    key_data = r.json()
    pub_key = key_data["key"]
    key_id  = key_data["key_id"]
    print(f"\n✅ Repositorio autenticado. Key ID: {key_id}\n")

    for name, value in SECRETS.items():
        encrypted = encrypt_secret(pub_key, value)
        put = requests.put(
            f"https://api.github.com/repos/{REPO}/actions/secrets/{name}",
            headers=headers,
            json={"encrypted_value": encrypted, "key_id": key_id}
        )
        if put.status_code in (201, 204):
            print(f"  ✅ Secret '{name}' creado/actualizado")
        else:
            print(f"  ❌ Error en '{name}': {put.status_code} {put.text}")

    print("\n🎉 Listo. El workflow de GitHub Actions ahora usará los secrets seguros.")
    print("   Puedes regenerar SURGE_TOKEN en https://surge.sh/account")
    print("   y actualizar el secret con este mismo script.\n")

if __name__ == "__main__":
    main()
