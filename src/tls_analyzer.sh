#!/bin/bash
set -euo pipefail

# ¿Por qué set -euo pipefail?
# -e: Sale inmediatamente si un comando falla (exit on error)
# -u: Trata variables no definidas como error (unset variables)
# -o pipefail: El pipe falla si cualquier comando en él falla

# Variables de configuración (12-Factor III: Config)
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TLS_LOG_PATTERN="${TLS_LOG_PATTERN:-'TLS\|SSL'}"
readonly CERT_CHECK_TIMEOUT="${CERT_CHECK_TIMEOUT:-10}"
readonly OUTPUT_DIRECTORY="${OUTPUT_DIRECTORY:-./out}"
readonly TLS_PROTOCOLS="${TLS_PROTOCOLS:-'tls1 tls1_1 tls1_2 tls1_3'}"

# ¿Por qué readonly?
# Evita modificaciones accidentales de variables críticas
# Principio de seguridad: datos inmutables

# Arrays para almacenar resultados (Bash robusto)
declare -a tls_handshakes=()
declare -a cert_errors=()
declare -a protocol_support=()

# Agregar después de las variables readonly, antes de la función cleanup:

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
    CERT_CHECK_TIMEOUT  Timeout verificaciones (default: 10)
EOF
}

# Procesar argumentos de línea de comandos
process_arguments() {
    case "${1:-}" in
        --help|-h)
            echo "Uso: $0 [OPCIONES]"
            echo "Analizador de seguridad TLS"
            echo ""
            echo "OPCIONES:"
            echo "  --help, -h    Muestra esta ayuda"
            exit 0
            ;;
        --validate-config)
            echo "Validando configuración..."
            validate_tools
            echo "Configuración válida"
            exit 0
            ;;
        "")
            # Sin argumentos, continuar ejecución normal
            return 0
            ;;
        *)
            echo "Opción desconocida: $1" >&2
            exit 1
            ;;
    esac
}

# En la función main(), agregar al inicio:
main() {
    # Procesar argumentos primero
    process_arguments "$1"
    
    echo "Iniciando análisis integral de seguridad TLS..."
    # ... resto de la función main igual
}

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

# ¿Por qué trap?
# Garantiza limpieza incluso si el script es interrumpido
# Maneja señales SIGINT, SIGTERM, EXIT
trap cleanup EXIT

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

# ¿Por qué validar herramientas?
# Principio "fail fast": detectar problemas temprano
# Evita errores confusos más adelante en la ejecución

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

# ¿Por qué journalctl?
# Es el sistema estándar de logs en systemd (requisito del proyecto)
# Permite filtrado eficiente por tiempo y patrones
# --since: Filtra por tiempo (evita procesar logs antiguos innecesarios)
# --grep: Filtra por patrón (más eficiente que grep posterior)

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

# ¿Por qué openssl s_client?
# Es la herramienta estándar para análisis TLS
# -connect: Especifica host:puerto
# -servername: Para SNI (Server Name Indication) - crítico para sitios con múltiples certificados
# timeout: Evita que conexiones lentas cuelguen el script
# 2>/dev/null: Suprime stderr (conexión tiene mucho ruido)

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

# ¿Por qué verificar múltiples protocolos?
# Seguridad: TLS 1.0/1.1 son inseguros y deben estar deshabilitados
# TLS 1.2 es mínimo aceptable, TLS 1.3 es óptimo
# "Cipher is" indica que la negociación TLS fue exitosa

# Función principal integrada
main() {
    echo "Iniciando análisis integral de seguridad TLS..."
    
    # Crear directorio de salida si no existe
    mkdir -p "$OUTPUT_DIRECTORY"
    
    # Validar herramientas necesarias
    validate_tools
    
    # Análisis de logs del sistema
    analyze_tls_handshakes
    
    # Análisis de certificados (ejemplo con sitios conocidos)
    local test_hosts=("google.com" "github.com" "stackoverflow.com")
    
    for host in "${test_hosts[@]}"; do
        local output_file="$OUTPUT_DIRECTORY/cert_analysis_${host//\./_}.txt"
        check_certificates "$host" "$output_file"
        check_tls_protocols "$host" "$output_file"
    done
    
    # Generar reporte summary
    generate_tls_report
    
    echo "Análisis TLS completado exitosamente"
}

# ¿Por qué hosts de ejemplo?
# Permite testing reproducible sin depender de configuración local
# Google/GitHub tienen configuración TLS robusta para comparación
# ${host//\./_} reemplaza puntos con guiones bajos para nombres de archivo válidos

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

# ¿Por qué un reporte consolidado?
# Facilita la presentación y análisis posterior
# Formato tabular para fácil lectura
# Timestamp para trazabilidad

# Ejecutar función principal con todos los argumentos
main "$@"
