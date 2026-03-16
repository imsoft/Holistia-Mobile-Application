#!/bin/bash

# Ejecuta Holistia en simulador o iPhone.
# Usa claves de .env si existe; si no, usa las del proyecto (mismas que build_ios_release.sh).

cd "$(dirname "$0")"

if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

# Valores por defecto (mismos que build_ios_release.sh) si no hay .env
if [ -z "$SUPABASE_URL" ]; then
  SUPABASE_URL="https://imxzapeoxvdfheffxhwj.supabase.co"
fi
if [ -z "$SUPABASE_ANON_KEY" ]; then
  SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlteHphcGVveHZkZmhlZmZ4aHdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxNDI5NjgsImV4cCI6MjA4NzcxODk2OH0.-DZpeRdGJxujjLPtF9PaeiEUCPR8njJe6oysubzFQ0k"
fi

echo "🚀 Ejecutando Holistia en iOS..."

flutter run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  "$@"
