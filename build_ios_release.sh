#!/bin/bash

# Script para compilar Holistia en modo Release para iPhone
# Este build funcionará sin necesidad de estar conectado a la computadora

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔨 Compilando Holistia en modo Release para iPhone...${NC}"
echo ""

# Verificar que hay un dispositivo iOS conectado
echo -e "${YELLOW}Verificando dispositivos iOS conectados...${NC}"
DEVICES=$(flutter devices | grep -i "ios" | grep -v "simulator" | wc -l | tr -d ' ')

if [ "$DEVICES" -eq "0" ]; then
    echo -e "${YELLOW}⚠️  No se detectó ningún iPhone físico conectado.${NC}"
    echo -e "${YELLOW}   Conecta tu iPhone por USB antes de continuar.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Dispositivo iOS detectado${NC}"
echo ""

# Cargar variables del .env
if [ -f .env ]; then
  set -a; source .env; set +a
fi

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo -e "${YELLOW}❌ Error: SUPABASE_URL y SUPABASE_ANON_KEY deben estar en .env${NC}"
  echo "   Copia .env.example a .env y rellena los valores."
  exit 1
fi

# Compilar en modo Release
echo -e "${BLUE}Compilando...${NC}"
flutter build ios --release \
  --no-tree-shake-icons \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Compilación exitosa${NC}"
    echo ""
    echo -e "${BLUE}📱 Para instalar la app en tu iPhone:${NC}"
    echo ""
    echo "   Opción 1: Desde Xcode (recomendado)"
    echo "   1. Abre: open ios/Runner.xcworkspace"
    echo "   2. Selecciona tu iPhone como destino"
    echo "   3. Selecciona 'Any iOS Device' o tu iPhone específico"
    echo "   4. Ve a Product → Archive"
    echo "   5. En el Organizer, selecciona 'Distribute App'"
    echo "   6. Elige 'Development' y selecciona tu iPhone"
    echo ""
    echo "   Opción 2: Desde la terminal"
    echo "   flutter install --release"
    echo ""
    echo -e "${YELLOW}💡 Nota: Este build funcionará sin conexión a la computadora${NC}"
else
    echo ""
    echo -e "${YELLOW}❌ Error en la compilación. Verifica los errores arriba.${NC}"
    exit 1
fi
