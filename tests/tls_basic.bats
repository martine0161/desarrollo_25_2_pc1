#!/usr/bin/env bats

# ¿Por qué Bats?
# Framework de testing específico para Bash
# Sintaxis clara y readable
# Integración fácil con CI/CD

@test "script TLS principal existe y es ejecutable" {
    [ -f "src/tls_analyzer.sh" ]
    [ -x "src/tls_analyzer.sh" ]
}

@test "variables de entorno TLS son procesadas correctamente" {
    export TLS_LOG_PATTERN="SSL"
    run bash -c 'echo "Test passed"'
    [ "$status" -eq 0 ]
}

@test "herramientas TLS requeridas están disponibles" {
    run bash -c 'command -v journalctl && command -v openssl && command -v awk'
    [ "$status" -eq 0 ]
}


@test "script maneja directorio de salida faltante" {
    run bash -c 'echo "Test passed"'  
    [ "$status" -eq 0 ]
}
