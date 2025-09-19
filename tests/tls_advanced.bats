#!/usr/bin/env bats

@test "análisis de patrones TLS genera archivo de salida" {
    ./src/tls_analyzer.sh || true
    [ -f "out/tls_patterns_analysis.txt" ]
}

@test "análisis detecta handshakes en logs simulados" {
    run ./src/tls_analyzer.sh
    [[ "$output" =~ "Handshakes exitosos" ]]
}

@test "script crea archivos de vulnerabilidades" {
    ./src/tls_analyzer.sh || true
    [ -f "out/tls_vulnerabilities.txt" ]
}

@test "script genera reporte de seguridad" {
    ./src/tls_analyzer.sh || true
    # Verificar que al menos uno de los reportes principales existe
    [[ -f "out/tls_patterns_analysis.txt" || -f "out/tls_vulnerabilities.txt" ]]
}
