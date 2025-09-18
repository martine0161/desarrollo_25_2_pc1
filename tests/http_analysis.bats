#!/usr/bin/env bats

setup() {
    # Crear datos de prueba
    export TEST_LOG_DIR="$BATS_TMPDIR/test_logs"
    mkdir -p "$TEST_LOG_DIR"
    
    cat > "$TEST_LOG_DIR/access.log" << EOF
127.0.0.1 - - [25/Dec/2021:10:00:00 +0000] "GET /index.html HTTP/1.1" 200 1234
127.0.0.1 - - [25/Dec/2021:10:01:00 +0000] "POST /api/data HTTP/1.1" 404 567
192.168.1.1 - - [25/Dec/2021:10:02:00 +0000] "GET /favicon.ico HTTP/1.1" 200 890
192.168.1.1 - - [25/Dec/2021:11:00:00 +0000] "PUT /api/update HTTP/1.1" 500 234
127.0.0.1 - - [25/Dec/2021:11:30:00 +0000] "DELETE /api/delete HTTP/1.1" 403 0
EOF

    cat > "$TEST_LOG_DIR/dns.log" << EOF
Dec 25 10:00:01 server named[1234]: client 127.0.0.1#12345: query: google.com IN A + (192.168.1.1)
Dec 25 10:01:00 server named[1234]: client 192.168.1.1#54321: query: facebook.com IN AAAA + (127.0.0.1)
Dec 25 10:02:00 server named[1234]: client 127.0.0.1#12345: query: cloudflare.com IN CNAME + (192.168.1.1)
EOF
}

@test "análisis HTTP detecta códigos de estado correctamente" {
    export LOG_DIRECTORY="$TEST_LOG_DIR"
    export OUTPUT_DIRECTORY="$BATS_TMPDIR/out"
    
    run ./src/log_analyzer.sh
    [ "$status" -eq 0 ]
    
    # Verificar que se detectaron códigos 200, 404, 500, 403
    run grep "200" "$OUTPUT_DIRECTORY/http_analysis.txt"
    [ "$status" -eq 0 ]
    
    run grep "404" "$OUTPUT_DIRECTORY/http_analysis.txt"
    [ "$status" -eq 0 ]
    
    run grep "500" "$OUTPUT_DIRECTORY/http_analysis.txt"
    [ "$status" -eq 0 ]
}

@test "análisis detecta métodos HTTP correctamente" {
    export LOG_DIRECTORY="$TEST_LOG_DIR"
    export OUTPUT_DIRECTORY="$BATS_TMPDIR/out"
    
    run ./src/log_analyzer.sh
    [ "$status" -eq 0 ]
    
    # Verificar métodos GET, POST, PUT, DELETE
    run grep -i "GET" "$OUTPUT_DIRECTORY/http_analysis.txt"
    [ "$status" -eq 0 ]
    
    run grep -i "POST" "$OUTPUT_DIRECTORY/http_analysis.txt" 
    [ "$status" -eq 0 ]
    
    run grep -i "PUT" "$OUTPUT_DIRECTORY/http_analysis.txt"
    [ "$status" -eq 0 ]
    
    run grep -i "DELETE" "$OUTPUT_DIRECTORY/http_analysis.txt"
    [ "$status" -eq 0 ]
}

@test "análisis DNS procesa consultas correctamente" {
    export LOG_DIRECTORY="$TEST_LOG_DIR"
    export OUTPUT_DIRECTORY="$BATS_TMPDIR/out"
    
    run ./src/log_analyzer.sh
    [ "$status" -eq 0 ]
    
    # Verificar que se procesaron consultas DNS
    [ -f "$OUTPUT_DIRECTORY/dns_analysis.txt" ]
    
    run grep -i "google.com" "$OUTPUT_DIRECTORY/dns_analysis.txt"
    [ "$status" -eq 0 ]
}

@test "generación de reporte JSON funciona" {
    export LOG_DIRECTORY="$TEST_LOG_DIR"
    export OUTPUT_DIRECTORY="$BATS_TMPDIR/out"
    export OUTPUT_FORMAT="json"
    
    run ./src/log_analyzer.sh
    [ "$status" -eq 0 ]
    
    # Verificar que se creó el archivo JSON
    [ -f "$OUTPUT_DIRECTORY/analysis_report.json" ]
    
    # Verificar que contiene estructura JSON válida
    run grep "timestamp" "$OUTPUT_DIRECTORY/analysis_report.json"
    [ "$status" -eq 0 ]
}

@test "generación de reporte CSV funciona" {
    export LOG_DIRECTORY="$TEST_LOG_DIR"
    export OUTPUT_DIRECTORY="$BATS_TMPDIR/out"
    export OUTPUT_FORMAT="csv"
    
    run ./src/log_analyzer.sh
    [ "$status" -eq 0 ]
    
    # Verificar que se creó el archivo CSV
    [ -f "$OUTPUT_DIRECTORY/analysis_report.csv" ]
    
    # Verificar header CSV
    run head -1 "$OUTPUT_DIRECTORY/analysis_report.csv"
    [[ "$output" =~ "Type,Category,Value,Count" ]]
}

@test "script maneja archivos faltantes gracefully" {
    export LOG_DIRECTORY="/directorio/inexistente"
    export OUTPUT_DIRECTORY="$BATS_TMPDIR/out"
    
    run ./src/log_analyzer.sh
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error" ]]
}

@test "script cuenta correctamente ocurrencias de códigos HTTP" {
    export LOG_DIRECTORY="$TEST_LOG_DIR"
    export OUTPUT_DIRECTORY="$BATS_TMPDIR/out"
    
    run ./src/log_analyzer.sh
    [ "$status" -eq 0 ]
    
    # Verificar conteos específicos (2 códigos 200, 1 código 404, etc.)
    run grep "200.*2" "$OUTPUT_DIRECTORY/http_analysis.txt"
    [ "$status" -eq 0 ]
    
    run grep "404.*1" "$OUTPUT_DIRECTORY/http_analysis.txt"
    [ "$status" -eq 0 ]
}

@test "análisis comprensivo genera archivos detallados" {
    export LOG_DIRECTORY="$TEST_LOG_DIR"
    export OUTPUT_DIRECTORY="$BATS_TMPDIR/out"
    
    run ./src/log_analyzer.sh
    [ "$status" -eq 0 ]
    
    # Verificar que se generaron archivos detallados
    run find "$OUTPUT_DIRECTORY" -name "*_detailed.txt"
    [ "$status" -eq 0 ]
    
    run find "$OUTPUT_DIRECTORY" -name "*_dns_detailed.txt"
    [ "$status" -eq 0 ]
}

teardown() {
    rm -rf "$TEST_LOG_DIR"
    rm -rf "$BATS_TMPDIR/out"
}