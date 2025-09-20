#!/bin/bash
# Script para ejecutar pruebas básicas sin Bats
# Autor: Alumno 3
# Uso: bash tests/run_manual_tests.sh

set -euo pipefail

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== EJECUTANDO PRUEBAS MANUALES ===${NC}"
echo ""

# Contador de pruebas
total_tests=0
passed_tests=0

# Función para ejecutar una prueba
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    total_tests=$((total_tests + 1))
    echo -n "Prueba $total_tests: $test_name ... "
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        passed_tests=$((passed_tests + 1))
    else
        echo -e "${RED}FAIL${NC}"
    fi
}

# Crear datos de prueba temporal
create_test_data() {
    local temp_log="$(mktemp)"
    cat > "$temp_log" << 'EOF'
2024-01-15 10:30:15 HTTP/1.1 200 OK - GET /api/users
2024-01-15 10:30:16 DNS Query: example.com A 192.168.1.1 TTL=3600
2024-01-15 10:30:17 TLS Handshake: example.com:443 TLSv1.3 successful
2024-01-15 10:30:18 HTTP/1.1 404 Not Found - GET /api/invalid
2024-01-15 10:30:19 DNS Query: test.com CNAME www.test.com TTL=1800
2024-01-15 10:30:20 TLS Error: expired certificate for old.example.com
EOF
    echo "$temp_log"
}

# Ejecutar pruebas
main() {
    local test_log
    test_log=$(create_test_data)
    
    # Pruebas del Makefile
    run_test "Makefile tools target funciona" "make tools"
    run_test "Makefile build crea directorios" "make build && [ -d 'out' ]"
    run_test "Makefile clean funciona" "make clean"
    run_test "Makefile help muestra información" "make help | grep -q 'ANALIZADOR'"
    
    # Pruebas de análisis básico
    run_test "Encuentra códigos HTTP 200" "grep -q '200' '$test_log'"
    run_test "Encuentra códigos HTTP 404" "grep -q '404' '$test_log'"
    run_test "Encuentra registros DNS A" "grep -q 'DNS.*A' '$test_log'"
    run_test "Encuentra registros DNS CNAME" "grep -q 'DNS.*CNAME' '$test_log'"
    run_test "Detecta errores TLS" "grep -q 'TLS.*Error' '$test_log'"
    
    # Pruebas de herramientas básicas
    run_test "curl disponible" "command -v curl"
    run_test "grep disponible" "command -v grep"
    run_test "sed disponible" "command -v sed"
    run_test "awk disponible" "command -v awk"
    
    # Limpiar archivo temporal
    rm -f "$test_log"
    
    # Mostrar resultados
    echo ""
    echo -e "${YELLOW}=== RESUMEN DE PRUEBAS ===${NC}"
    echo "Total de pruebas: $total_tests"
    echo -e "Pruebas exitosas: ${GREEN}$passed_tests${NC}"
    echo -e "Pruebas fallidas: ${RED}$((total_tests - passed_tests))${NC}"
    
    if [ $passed_tests -eq $total_tests ]; then
        echo -e "${GREEN}✓ Todas las pruebas pasaron${NC}"
        exit 0
    else
        echo -e "${RED}✗ Algunas pruebas fallaron${NC}"
        exit 1
    fi
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi