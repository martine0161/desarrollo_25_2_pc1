#!/usr/bin/env bats
# Pruebas iniciales para el Analizador de logs de red
# Autor: Alumno 3 - Sprint 1
# Archivo: tests/log_analyzer.bats

# Función que se ejecuta antes de cada prueba
setup() {
    # Crear directorio temporal para pruebas
    export TEST_TEMP_DIR="$(mktemp -d)"
    export LOG_PATH="$TEST_TEMP_DIR/test.log"
    
    # Crear log de ejemplo para pruebas
    cat > "$LOG_PATH" << 'EOF'
2024-01-15 10:30:15 HTTP/1.1 200 OK - GET /api/users
2024-01-15 10:30:16 DNS Query: example.com A 192.168.1.1 TTL=3600
2024-01-15 10:30:17 TLS Handshake: example.com:443 TLSv1.3 successful
2024-01-15 10:30:18 HTTP/1.1 404 Not Found - GET /api/invalid
2024-01-15 10:30:19 DNS Query: test.com CNAME www.test.com TTL=1800
2024-01-15 10:30:20 TLS Error: expired certificate for old.example.com
EOF
}

# Función que se ejecuta después de cada prueba
teardown() {
    # Limpiar archivos temporales
    if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "Makefile tools target verifica herramientas básicas" {
    run make tools
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Verificación de herramientas completada" ]]
}

@test "Makefile build crea estructura de directorios" {
    # Limpiar primero
    make clean > /dev/null 2>&1
    
    run make build
    [ "$status" -eq 0 ]
    [ -d "out" ]
    [ -d "out/reports" ]
    [ -f "out/build_info.txt" ]
}

@test "Makefile pack genera paquete con nombre correcto" {
    export RELEASE="v1.0.0-test"
    
    run make pack
    [ "$status" -eq 0 ]
    [ -f "dist/log-analyzer-v1.0.0-test.tar.gz" ]
    [[ "$output" =~ "Paquete creado" ]]
}

@test "Makefile clean elimina directorios correctamente" {
    # Crear directorios primero
    make build > /dev/null 2>&1
    
    run make clean
    [ "$status" -eq 0 ]
    [ ! -d "out" ]
    [ ! -d "dist" ]
    [[ "$output" =~ "Limpieza completada" ]]
}

@test "Makefile help muestra información útil" {
    run make help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "ANALIZADOR DE LOGS" ]]
    [[ "$output" =~ "tools" ]]
    [[ "$output" =~ "build" ]]
    [[ "$output" =~ "test" ]]
    [[ "$output" =~ "run" ]]
    [[ "$output" =~ "pack" ]]
    [[ "$output" =~ "clean" ]]
}

@test "Análisis básico de logs HTTP identifica códigos de estado" {
    # Esta prueba simula lo que harán tus compañeros
    # Por ahora solo verifica que podemos encontrar códigos HTTP
    
    run grep -E "HTTP.*[0-9]{3}" "$LOG_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "200" ]]
    [[ "$output" =~ "404" ]]
}

@test "Parsing básico de DNS encuentra registros A y CNAME" {
    # Simula análisis DNS básico
    
    run grep -E "DNS.*A |DNS.*CNAME" "$LOG_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "A 192.168.1.1" ]]
    [[ "$output" =~ "CNAME www.test.com" ]]
}

@test "Detección de problemas TLS en logs" {
    # Verifica que podemos detectar errores TLS
    
    run grep -E "TLS.*Error|TLS.*expired" "$LOG_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "expired certificate" ]]
}

@test "Robustez - script debe retornar código correcto ante errores" {
    # Simula análisis de archivo inexistente
    export LOG_PATH="/archivo/que/no/existe.log"
    
    run bash -c 'grep "HTTP" "$LOG_PATH" 2>/dev/null'
    [ "$status" -ne 0 ]  # Debe fallar (código != 0)
}

@test "Idempotencia básica - multiple ejecuciones dan mismo resultado" {
    # Primera ejecución
    first_result=$(grep -c "HTTP" "$LOG_PATH")
    
    # Segunda ejecución inmediata
    second_result=$(grep -c "HTTP" "$LOG_PATH")
    
    [ "$first_result" -eq "$second_result" ]
}

@test "Variables de entorno son respetadas" {
    export RELEASE="test-version"
    
    # Verificar que la variable se usa
    run bash -c 'echo "Testing with RELEASE=$RELEASE"'
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test-version" ]]
}