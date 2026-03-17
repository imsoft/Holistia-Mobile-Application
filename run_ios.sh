#!/bin/bash

# Ejecuta Holistia en simulador o iPhone.
# Requiere SUPABASE_URL y SUPABASE_ANON_KEY en .env (copia .env.example).

cd "$(dirname "$0")"

if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "❌ Error: SUPABASE_URL y SUPABASE_ANON_KEY deben estar en .env"
  echo "   Copia .env.example a .env y rellena los valores."
  exit 1
fi

echo "🚀 Ejecutando Holistia en iOS..."

flutter run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  "$@"
