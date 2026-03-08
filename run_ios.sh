#!/bin/bash

# Ejecuta Holistia en iPhone usando las claves del archivo .env
# Asegúrate de tener SUPABASE_URL y SUPABASE_ANON_KEY en .env

cd "$(dirname "$0")"

if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "❌ Faltan SUPABASE_URL o SUPABASE_ANON_KEY en .env"
  exit 1
fi

echo "🚀 Ejecutando Holistia en iPhone (con claves de .env)..."

flutter run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  "$@"
