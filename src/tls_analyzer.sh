#!/bin/bash
set -euo pipefail

# Variables de configuración (12-Factor III: Config)
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TLS_LOG_PATTERN="${TLS_LOG_PATTERN:-'TLS\|SSL'}"
readonly CERT_CHECK_TIMEOUT="${CERT_CHECK_TIMEOUT:-10}"
readonly OUTPUT_DIRECTORY="${OUTPUT_DIRECTORY:-./out}"
readonly LOG_DIRECTORY="${LOG_DIRECTORY:-/var/log}"
readonly TLS_PROTOCOLS="${TLS_PROTOCOLS:-'tls1 tls1_1 tls1_2 tls1_3'}"

# Arrays para almacenar resultados (Bash robusto)
declare -a tls_handshakes=()
declare -a cert_errors=()
declare -a protocol_support=()

# Función de limpieza con trap
cleanup() {
    local exit_code=$?
    echo "Realizando limpieza de análisis TLS..." >&2
    
    # Limpiar archivos temporales
    rm -f /tmp/tls_analysis_*.tmp
    
    # Reportar estadísticas
    echo "Análisis TLS completado con código: $exit_code" >&2
    exit $exit_code
}

# Trap para limpieza garantizada
#trap cleanup EXIT

# Manejo de interrupciones
trap 'handle_interrupt' INT TERM

handle_interrupt() {
    echo "Análisis TLS interrumpido por señal..." >&2
    echo "Guardando análisis parcial..." >&2
    
    # Guardar estado actual antes de salir
    if [[ ${#protocol_support[@]} -gt 0 ]]; then
        printf '%s\n' "${protocol_support[@]}" > "$OUTPUT_DIRECTORY/partial_results.txt"
    fi
    
    # Crear resumen de interrupción
    {
        echo "ANÁLISIS INTERRUMPIDO: $(date)"
        echo "Tiempo de ejecución: ${SECONDS}s"
        echo "Archivos procesados parcialmente:"
        ls -1 "$OUTPUT_DIRECTORY"/*.txt 2>/dev/null || echo "Ninguno"
    } > "$OUTPUT_DIRECTORY/interruption_summary.txt"
    
    exit 130  # Código estándar para interrupción
}

# Procesar argumentos de línea de comandos
process_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --validate-config)
                echo "Validando configuración TLS..."
                validate_tools
                echo "Configuración válida"
                exit 0
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Opción desconocida: $1" >&2
                exit 1
                ;;
        esac
        shift
    done
}

show_help() {
    cat << EOF
Uso: $0 [OPCIONES]

OPCIONES:
    --validate-config    Valida configuración y dependencias
    -h, --help          Muestra esta ayuda

VARIABLES DE ENTORNO:
    TLS_LOG_PATTERN     Patrón para logs TLS (default: 'TLS\|SSL')
    OUTPUT_DIRECTORY    Directorio de salida (default: ./out)
    LOG_DIRECTORY       Directorio de logs (default: /var/log)
    CERT_CHECK_TIMEOUT  Timeout verificaciones (default: 10)
EOF
}

# Validación de dependencias
validate_tools() {
    local missing_tools=()
    
    for tool in journalctl openssl awk grep; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "Error: Herramientas faltantes: ${missing_tools[*]}" >&2
        exit 1
    fi
    
    echo "Todas las herramientas TLS disponibles ✓"
}

# Análisis de handshakes TLS via journalctl
analyze_tls_handshakes() {
    echo "Analizando handshakes TLS en logs del sistema..."
    
    # Usar journalctl para obtener logs TLS de las últimas 24 horas
    local handshake_data
    handshake_data=$(journalctl --since="24 hours ago" --grep="$TLS_LOG_PATTERN" --output=short 2>/dev/null | \
        awk '/TLS handshake|SSL handshake/ {handshakes++} 
             /SSL error|TLS error/ {errors++} 
             /certificate/ {certs++} 
             END {
                 printf "TLS Handshakes: %d\n", handshakes+0
                 printf "Errores SSL/TLS: %d\n", errors+0
                 printf "Eventos de certificados: %d\n", certs+0
             }')
    
    echo "$handshake_data"
    
    # Guardar en archivo de salida
    echo "$handshake_data" > "$OUTPUT_DIRECTORY/tls_handshakes.txt"
}

# Análisis avanzado con pipeline Unix toolkit
analyze_tls_patterns() {
    echo "Analizando patrones TLS avanzados con Unix toolkit..."
    
    # Pipeline complejo usando múltiples herramientas Unix
    journalctl --since="1 week ago" --grep="$TLS_LOG_PATTERN" --output=short | \
        grep -E "(handshake|certificate|cipher|SSL|TLS)" | \
        sed -E 's/.*TLS/TLS/; s/.*SSL/SSL/; s/^[^:]*: //' | \
        awk '{
            # Analizar handshakes
            if($0 ~ /handshake/) {
                if($0 ~ /completed|successful/) handshakes_ok++
                else handshakes_fail++
                hosts[$(NF-1)]++
            }
            # Analizar certificados  
            if($0 ~ /certificate/) {
                if($0 ~ /expired|invalid/) certs_bad++
                else certs_good++
            }
            # Analizar ciphers
            if($0 ~ /cipher/) {
                cipher = $NF
                ciphers[cipher]++
            }
            # Contar errores
            if($0 ~ /error|failed|timeout/) errors++
        } END {
            printf "=== RESUMEN TLS ===\n"
            printf "Handshakes exitosos: %d\n", handshakes_ok+0
            printf "Handshakes fallidos: %d\n", handshakes_fail+0
            printf "Certificados válidos: %d\n", certs_good+0  
            printf "Certificados problemáticos: %d\n", certs_bad+0
            printf "Total errores TLS: %d\n", errors+0
            
            printf "\n=== TOP HOSTS ===\n"
            for(h in hosts) printf "%-25s: %d conexiones\n", h, hosts[h]
            
            printf "\n=== CIPHERS DETECTADOS ===\n"
            for(c in ciphers) printf "%-30s: %d veces\n", c, ciphers[c]
        }' | \
        tee "$OUTPUT_DIRECTORY/tls_patterns_analysis.txt"
}

# Análisis de vulnerabilidades TLS
analyze_tls_vulnerabilities() {
    echo "Analizando vulnerabilidades y configuraciones inseguras..."
    
    local vuln_file="$OUTPUT_DIRECTORY/tls_vulnerabilities.txt"
    
    {
        echo "=== ANÁLISIS DE VULNERABILIDADES TLS ==="
        echo "Generado: $(date)"
        echo ""
        
        # Buscar protocolos inseguros
        echo "PROTOCOLOS INSEGUROS DETECTADOS:"
        journalctl --since="24 hours ago" --grep="$TLS_LOG_PATTERN" | \
            grep -iE "(sslv2|sslv3|tls.*1\.0|tls.*1\.1)" | \
            cut -d' ' -f1-3,6- | \
            sort | uniq -c | \
            awk '{printf "  %s veces: %s\n", $1, substr($0, index($0,$2))}'
        
        echo ""
        echo "ERRORES DE CERTIFICADO:"
        journalctl --since="24 hours ago" --grep="$TLS_LOG_PATTERN" | \
            grep -iE "(certificate.*expired|certificate.*invalid|self.*signed)" | \
            cut -d' ' -f1-3,6- | \
            sort | uniq -c | \
            awk '{printf "  %s veces: %s\n", $1, substr($0, index($0,$2))}'
            
        echo ""
        echo "CIPHERS DÉBILES:"
        journalctl --since="24 hours ago" --grep="$TLS_LOG_PATTERN" | \
            grep -iE "(rc4|md5|des|export|null)" | \
            cut -d' ' -f6- | \
            sort | uniq -c | \
            awk '{printf "  %s veces: %s\n", $1, substr($0, index($0,$2))}'
            
    } > "$vuln_file"
    
    echo "Análisis de vulnerabilidades guardado en: $vuln_file"
}

# Pipeline de análisis con herramientas Unix
process_tls_logs_pipeline() {
    local input_logs="$1"
    local output_file="$2"
    
    echo "Procesando logs TLS con pipeline Unix toolkit..."
    
    # Pipeline complejo: find + xargs + multiple filters
    find "$input_logs" -name "*.log" -type f -mtime -7 2>/dev/null | \
        xargs grep -l "$TLS_LOG_PATTERN" 2>/dev/null | \
        while read -r logfile; do
            echo "=== Procesando: $logfile ===" 
            
            # Pipeline con múltiples herramientas Unix
            cat "$logfile" | \
                grep -E "$TLS_LOG_PATTERN" | \
                sed 's/\[.*\]//g; s/  */ /g' | \
                awk '/TLS|SSL/ {
                    gsub(/[[:punct:]]/, " ")
                    for(i=1; i<=NF; i++) {
                        if($i ~ /^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/) ips[$i]++
                        if($i ~ /^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/) domains[$i]++
                    }
                } END {
                    print "IPs detectadas:"
                    for(ip in ips) printf "  %s: %d veces\n", ip, ips[ip]
                    print "Dominios detectados:"  
                    for(d in domains) printf "  %s: %d veces\n", d, domains[d]
                }' | \
                sort | uniq | \
                tr '[:upper:]' '[:lower:]'
                
        done | tee -a "$output_file"
}

# Verificación de certificados de sitios
check_certificates() {
    local target_host="$1"
    local output_file="$2"
    
    echo "Verificando certificado para: $target_host"
    
    {
        echo "=== Análisis de Certificado para $target_host ==="
        
        # Información del certificado
        echo "| Información del Certificado |"
        timeout "$CERT_CHECK_TIMEOUT" openssl s_client \
            -connect "$target_host:443" \
            -servername "$target_host" 2>/dev/null | \
            openssl x509 -noout -subject -issuer -dates
        
        # Verificar cadena de certificados
        echo "| Cadena de Certificados |"
        local cert_count
        cert_count=$(timeout "$CERT_CHECK_TIMEOUT" openssl s_client \
            -showcerts -connect "$target_host:443" \
            -servername "$target_host" 2>/dev/null | \
            grep -c "BEGIN CERTIFICATE" || echo "0")
        echo "Certificados en cadena: $cert_count"
        
    } >> "$output_file"
}

# Verificar protocolos TLS soportados
check_tls_protocols() {
    local target_host="$1"
    local output_file="$2"
    
    echo "| Protocolos TLS Soportados |" >> "$output_file"
    
    # Convertir string de protocolos en array
    IFS=' ' read -ra protocols <<< "$TLS_PROTOCOLS"
    
    for version in "${protocols[@]}"; do
        if timeout 5 openssl s_client -"$version" \
           -connect "$target_host:443" \
           -servername "$target_host" 2>/dev/null | \
           grep -q "Cipher is"; then
            echo "✓ $version" >> "$output_file"
            protocol_support+=("$target_host:$version:supported")
        else
            echo "✗ $version" >> "$output_file"
            protocol_support+=("$target_host:$version:not_supported")
        fi
    done
}

# Generar reporte consolidado
generate_tls_report() {
    local report_file="$OUTPUT_DIRECTORY/tls_security_report.txt"
    
    {
        echo "REPORTE DE SEGURIDAD TLS - $(date)"
        echo "======================================="
        
        echo ""
        echo "HANDSHAKES DEL SISTEMA:"
        cat "$OUTPUT_DIRECTORY/tls_handshakes.txt" 2>/dev/null || echo "No hay datos de handshakes"
        
        echo ""
        echo "SOPORTE DE PROTOCOLOS:"
        printf "%-20s %-10s %-15s\n" "Host" "Protocolo" "Estado"
        printf "%-20s %-10s %-15s\n" "----" "---------" "------"
        
        for entry in "${protocol_support[@]}"; do
            IFS=':' read -r host proto status <<< "$entry"
            printf "%-20s %-10s %-15s\n" "$host" "$proto" "$status"
        done
        
    } > "$report_file"
    
    echo "Reporte generado: $report_file"
}

# Función principal integrada
main() {
    # Inicializar contador de tiempo
    SECONDS=0
    
    # Procesar argumentos
    process_arguments "$@"
    
    echo "Iniciando análisis integral de seguridad TLS..."
    
    # Crear directorio de salida si no existe
    mkdir -p "$OUTPUT_DIRECTORY"
    
    # Validar herramientas necesarias
    validate_tools
    
    # Análisis de logs del sistema
    analyze_tls_handshakes
    
    # NUEVAS funciones Sprint 2:
    analyze_tls_patterns
    analyze_tls_vulnerabilities
    
    # Procesar logs adicionales si existen
    if [[ -d "$LOG_DIRECTORY" ]]; then
        process_tls_logs_pipeline "$LOG_DIRECTORY" "$OUTPUT_DIRECTORY/processed_logs.txt"
    fi
    
    # Análisis de certificados (ejemplo con sitios conocidos)
    # Usar || true para evitar que fallos de conexión causen exit code 1
    local test_hosts=("google.com" "github.com" "stackoverflow.com")
    for host in "${test_hosts[@]}"; do
        local output_file="$OUTPUT_DIRECTORY/cert_analysis_${host//\./_}.txt"
        check_certificates "$host" "$output_file" || true
        check_tls_protocols "$host" "$output_file" || true
    done
    
    # Generar reporte summary
    generate_tls_report || true
    
    echo "Análisis TLS completado exitosamente"
    rm -f /tmp/tls_analysis_*.tmp
    exit 0
}

# Ejecutar función principal con todos los argumentos
main "$@"
