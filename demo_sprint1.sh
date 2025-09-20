#!/bin/bash
# Script de demostración para Sprint 1
# Autor: Alumno 3
# Uso: bash demo_sprint1.sh

set -euo pipefail

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}  PROYECTO 5: ANALIZADOR DE LOGS - DEMO SPRINT 1${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

# Función para pausar entre demostraciones
pause_demo() {
    echo -e "${YELLOW}Presiona Enter para continuar...${NC}"
    read -r
}

echo -e "${GREEN}=== 1. VERIFICACIÓN DE HERRAMIENTAS ===${NC}"
echo "Ejecutando: make tools"
make tools
echo ""
pause_demo

echo -e "${GREEN}=== 2. PREPARACIÓN DEL ENTORNO ===${NC}"
echo "Ejecutando: make build"
make build
echo ""
echo "Verificando estructura creada:"
ls -la out/
echo ""
pause_demo

echo -e "${GREEN}=== 3. EJECUCIÓN DE PRUEBAS ===${NC}"
echo "Ejecutando: make test"
make test
echo ""
pause_demo

echo -e "${GREEN}=== 4. SIMULACIÓN DE ANÁLISIS ===${NC}"
echo "Ejecutando: make run"
make run
echo ""
pause_demo

echo -e "${GREEN}=== 5. EMPAQUETADO ===${NC}"
echo "Ejecutando: RELEASE=sprint1-demo make pack"
RELEASE=sprint1-demo make pack
echo ""
echo "Verificando paquete creado:"
ls -la dist/
echo ""
pause_demo

echo -e "${GREEN}=== 6. AYUDA Y DOCUMENTACIÓN ===${NC}"
echo "Ejecutando: make help"
make help
echo ""
pause_demo

echo -e "${GREEN}=== 7. LIMPIEZA ===${NC}"
echo "Ejecutando: make clean"
make clean
echo ""
echo "Verificando limpieza:"
ls -la
echo ""

echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}✓ DEMO COMPLETADA - Sprint 1${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""
echo -e "${YELLOW}Logros alcanzados:${NC}"
echo "  ✓ Makefile funcional con todos los targets"
echo "  ✓ Pruebas automatizadas básicas" 
echo "  ✓ Empaquetado reproducible"
echo "  ✓ Documentación inicial"
echo "  ✓ Estructura del proyecto establecida"
echo ""
echo -e "${YELLOW}Siguiente paso: Coordinar con Alumno 1 y 2 para Sprint 2${NC}"    