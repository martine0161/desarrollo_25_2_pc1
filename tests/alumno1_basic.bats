#!/usr/bin/env bats

# Test setup - se ejecuta antes de cada test
setup() {
    # Crear directorio temporal para tests
    export TEST_LOG_DIR="$BATS_TMPDIR/test_logs"
    mkdir -p "$TEST_LOG_DIR"
    
    # Crear archivo de log de prueba
    cat > "$TEST_LOG_DIR/test.log" << EOF
2024-01-15 10:30:15 GET /api/users HTTP/1.1 200 OK
2024-01-15 10:30:16 POST /api/login HTTP/1.1 401 Unauthorized  
2024-01-15 10:30:17 DNS query: example.com IN A
2024-01-15 10:30:18 TLS handshake completed
EOF
}

# Test teardown - se ejecuta después de cada test  
teardown() {
    # Limpiar archivos temporales
    rm -rf "$TEST_LOG_DIR" 2>/dev/null || true
}

@test "script principal existe y es ejecutable" {
    [ -f "src/log_analyzer.sh" ]
    [ -x "src/log_analyzer.sh" ]
}

@test "muestra ayuda correctamente" {
    run ./src/log_analyzer.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Analizador de Logs" ]]
    [[ "$output" =~ "USAGE:" ]]
}

@test "valida configuración correctamente" {
    export LOG_DIRECTORY="$TEST_LOG_DIR"
    run ./src/log_analyzer.sh --validate-config
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Configuración válida" ]]
}

@test "maneja directorio inexistente" {
    export LOG_DIRECTORY="/directorio/que/no/existe"
    run ./src/log_analyzer.sh --validate-config
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error" ]]
}

@test "procesa variables de entorno" {
    export LOG_DIRECTORY="$TEST_LOG_DIR"
    export OUTPUT_FORMAT="json"
    run ./src/log_analyzer.sh --validate-config
    [ "$status" -eq 0 ]
}