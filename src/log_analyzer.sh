#!/bin/bash
set -euo pipefail

# Configuración robusta con valores por defecto
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_DIRECTORY="${LOG_DIRECTORY:-/var/log}"
readonly OUTPUT_DIRECTORY="${OUTPUT_DIRECTORY:-./out}"
readonly OUTPUT_FORMAT="${OUTPUT_FORMAT:-plain}"
readonly CONFIG_FILE="${CONFIG_FILE:-./config/analyzer.conf}"

# Patrones de búsqueda configurables
readonly HTTP_LOG_PATTERN="${HTTP_LOG_PATTERN:-HTTP.*[0-9]{3}}"
readonly DNS_LOG_PATTERN="${DNS_LOG_PATTERN:-query.*IN}"
readonly TLS_LOG_PATTERN="${TLS_LOG_PATTERN:-TLS|SSL}"

# Arrays para almacenar resultados
declare -a http_results=()
declare -a dns_results=()
declare -a processing_errors=()

# Trap para limpieza automática
cleanup() {
    local exit_code=$?
    echo "Realizando limpieza..." >&2
    
    # Limpiar archivos temporales
    rm -f /tmp/analyzer_*.tmp 2>/dev/null || true
    
    # Reportar estadísticas finales
    echo "Análisis completado con código: $exit_code" >&2
    exit $exit_code
}
trap cleanup EXIT

# Validación de herramientas requeridas
validate_dependencies() {
    local missing_tools=()
    
    for tool in grep sed awk cut sort uniq find; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "Error: Herramientas faltantes: ${missing_tools[*]}" >&2
        exit 1
    fi
}

# Validación de configuración
validate_configuration() {
    if [[ ! -d "$LOG_DIRECTORY" ]]; then
        echo "Error: Directorio de logs no existe: $LOG_DIRECTORY" >&2
        exit 1
    fi
    
    if [[ ! -r "$LOG_DIRECTORY" ]]; then
        echo "Error: No hay permisos de lectura en: $LOG_DIRECTORY" >&2
        exit 2
    fi
    
    # Validar formato de salida
    case "$OUTPUT_FORMAT" in
        json|csv|plain) ;;
        *) echo "Error: Formato no válido: $OUTPUT_FORMAT" >&2; exit 1 ;;
    esac
}

# Inicializar directorio de salida
initialize_output() {
    mkdir -p "$OUTPUT_DIRECTORY"
    
    # Crear archivo de log del proceso
    readonly PROCESS_LOG="$OUTPUT_DIRECTORY/process.log"
    echo "$(date): Iniciando análisis" > "$PROCESS_LOG"
}

# Análisis específico de logs HTTP
analyze_http_logs() {
    local temp_file="/tmp/analyzer_http_$$.tmp"
    
    # Buscar archivos con contenido HTTP
    find "$LOG_DIRECTORY" -name "*.log" -type f -readable | \
    xargs grep -l "$HTTP_LOG_PATTERN" 2>/dev/null | \
    while IFS= read -r logfile; do
        echo "Procesando HTTP en: $logfile" | tee -a "$PROCESS_LOG"
        
        # Extraer códigos de estado HTTP
        grep -oE 'HTTP/[0-9.]+ [0-9]{3}' "$logfile" | \
        cut -d' ' -f2 | \
        sort | uniq -c | \
        awk '{printf "Código %s: %d ocurrencias\n", $2, $1}' >> "$temp_file"
        
        # Extraer métodos HTTP
        grep -oE '[A-Z]+ /.* HTTP' "$logfile" | \
        cut -d' ' -f1 | \
        sort | uniq -c | \
        awk '{printf "Método %s: %d veces\n", $2, $1}' >> "$temp_file"
        
    done
    
    # Consolidar resultados
    if [[ -f "$temp_file" ]]; then
        cp "$temp_file" "$OUTPUT_DIRECTORY/http_analysis.txt"
        rm -f "$temp_file"
    fi
}

# Análisis específico de logs DNS
analyze_dns_logs() {
    local temp_file="/tmp/analyzer_dns_$$.tmp"
    
    find "$LOG_DIRECTORY" -name "*.log" -type f -readable | \
    xargs grep -l "$DNS_LOG_PATTERN" 2>/dev/null | \
    while IFS= read -r logfile; do
        echo "Procesando DNS en: $logfile" | tee -a "$PROCESS_LOG"
        
        # Extraer queries DNS
        grep -i "query" "$logfile" | \
        sed -n 's/.*query: \([^ ]*\) IN \([^ ]*\).*/\1 \2/p' | \
        sort | uniq -c | \
        awk '{printf "Dominio: %s, Tipo: %s, Consultas: %d\n", $2, $3, $1}' >> "$temp_file"
        
    done
    
    if [[ -f "$temp_file" ]]; then
        cp "$temp_file" "$OUTPUT_DIRECTORY/dns_analysis.txt"
        rm -f "$temp_file"
    fi
}

# Análisis avanzado de logs HTTP con estadísticas detalladas
analyze_http_comprehensive() {
    local logfile="$1"
    local output_prefix="$2"
    
    {
        echo "=== Análisis de $logfile ==="
        
        # Códigos de estado con timestamps
        echo "== Códigos de Estado por Hora =="
        grep -oE '\[[^]]+\].*HTTP/[0-9.]+ [0-9]{3}' "$logfile" | \
        sed 's/\[\([^:]*\):\([^:]*\):[^]]*\].*HTTP\/[0-9.]* \([0-9]*\)/\1 \2 \3/' | \
        awk '{
            hour = $2
            code = $3
            counts[hour][code]++
        } 
        END {
            for (h in counts) {
                for (c in counts[h]) {
                    printf "Hora %s - Código %s: %d requests\n", h, c, counts[h][c]
                }
            }
        }' | sort
        
        # Análisis de User Agents
        echo "== Top 10 User Agents =="
        grep -oE '"[^"]*"[^"]*"[^"]*"$' "$logfile" | \
        cut -d'"' -f6 | \
        sort | uniq -c | sort -nr | head -10
        
        # IPs más activas
        echo "== Top 10 IPs =="
        awk '{print $1}' "$logfile" | \
        sort | uniq -c | sort -nr | head -10
        
    } > "${output_prefix}_detailed.txt"
}

# Análisis DNS comprensivo
analyze_dns_comprehensive() {
    local logfile="$1" 
    local output_prefix="$2"
    
    {
        echo "=== Análisis DNS de $logfile ==="
        
        # Tipos de query más comunes
        echo "== Tipos de Query DNS =="
        grep -i "query" "$logfile" | \
        grep -oE 'IN [A-Z]+' | \
        cut -d' ' -f2 | \
        sort | uniq -c | sort -nr
        
        # Dominios más consultados
        echo "== Top 20 Dominios Consultados =="
        grep -i "query" "$logfile" | \
        sed -n 's/.*query: \([^ ]*\) IN.*/\1/p' | \
        sort | uniq -c | sort -nr | head -20
        
        # Análisis por hora
        echo "== Consultas DNS por Hora =="
        grep -i "query" "$logfile" | \
        grep -oE '^[^:]*:[0-9]{2}' | \
        cut -d: -f2 | \
        sort | uniq -c
        
    } > "${output_prefix}_dns_detailed.txt"
}

# Pipeline completo mejorado
analyze_comprehensive() {
    find "$LOG_DIRECTORY" -name "*.log" -type f -readable | \
    xargs grep -l "HTTP\|DNS\|TLS" | \
    while IFS= read -r logfile; do
        echo "=== Análisis detallado de $logfile ===" | tee -a "$OUTPUT_DIRECTORY/comprehensive.log"
        
        # Análisis HTTP detallado si el archivo contiene HTTP
        if grep -q "$HTTP_LOG_PATTERN" "$logfile"; then
            analyze_http_comprehensive "$logfile" "$OUTPUT_DIRECTORY/$(basename "$logfile" .log)"
        fi
        
        # Análisis DNS si contiene DNS
        if grep -q "$DNS_LOG_PATTERN" "$logfile"; then
            analyze_dns_comprehensive "$logfile" "$OUTPUT_DIRECTORY/$(basename "$logfile" .log)"
        fi
    done
}

# Análisis principal de todos los logs
analyze_all_logs() {
    local start_time
    start_time=$(date +%s)
    
    echo "Fase 1: Análisis HTTP..."
    analyze_http_logs
    
    echo "Fase 2: Análisis DNS..."
    analyze_dns_logs
    
    echo "Fase 3: Análisis comprensivo..."
    analyze_comprehensive
    
    local end_time
    end_time=$(date +%s)
    echo "Tiempo total de análisis: $((end_time - start_time)) segundos"
}

# Reporte en formato JSON
generate_json_report() {
    echo "{"
    echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"log_directory\": \"$LOG_DIRECTORY\","
    echo "  \"analysis_summary\": {"
    
    if [[ -f "$OUTPUT_DIRECTORY/http_analysis.txt" ]]; then
        echo "    \"http_entries\": $(wc -l < "$OUTPUT_DIRECTORY/http_analysis.txt"),"
    fi
    
    if [[ -f "$OUTPUT_DIRECTORY/dns_analysis.txt" ]]; then
        echo "    \"dns_entries\": $(wc -l < "$OUTPUT_DIRECTORY/dns_analysis.txt")"
    fi
    
    echo "  }"
    echo "}"
}

# Reporte en formato CSV
generate_csv_report() {
    echo "Type,Category,Value,Count"
    
    if [[ -f "$OUTPUT_DIRECTORY/http_analysis.txt" ]]; then
        awk -F': ' '/Código/ {print "HTTP,StatusCode," $1 "," $2}' "$OUTPUT_DIRECTORY/http_analysis.txt"
        awk -F': ' '/Método/ {print "HTTP,Method," $1 "," $2}' "$OUTPUT_DIRECTORY/http_analysis.txt"
    fi
    
    if [[ -f "$OUTPUT_DIRECTORY/dns_analysis.txt" ]]; then
        awk -F', ' '{gsub(/[^:]*: /, "", $1); gsub(/[^:]*: /, "", $2); gsub(/[^:]*: /, "", $3); print "DNS,Query," $1 "," $3}' "$OUTPUT_DIRECTORY/dns_analysis.txt"
    fi
}

# Reporte en formato texto plano
generate_plain_report() {
    echo "=== REPORTE DE ANÁLISIS DE LOGS ==="
    echo "Fecha: $(date)"
    echo "Directorio analizado: $LOG_DIRECTORY"
    echo "Formato de salida: $OUTPUT_FORMAT"
    echo ""
    
    if [[ -f "$OUTPUT_DIRECTORY/http_analysis.txt" ]]; then
        echo "=== ANÁLISIS HTTP ==="
        cat "$OUTPUT_DIRECTORY/http_analysis.txt"
        echo ""
    fi
    
    if [[ -f "$OUTPUT_DIRECTORY/dns_analysis.txt" ]]; then
        echo "=== ANÁLISIS DNS ==="
        cat "$OUTPUT_DIRECTORY/dns_analysis.txt"
        echo ""
    fi
    
    echo "=== ESTADÍSTICAS GENERALES ==="
    echo "Archivos procesados: $(find "$LOG_DIRECTORY" -name "*.log" -type f | wc -l)"
    echo "Proceso completado: $(date)"
}

# Generación de reporte consolidado
generate_report() {
    local report_file="$OUTPUT_DIRECTORY/analysis_report.$OUTPUT_FORMAT"
    
    case "$OUTPUT_FORMAT" in
        json)
            generate_json_report > "$report_file"
            ;;
        csv)
            generate_csv_report > "$report_file"
            ;;
        plain)
            generate_plain_report > "$report_file"
            ;;
    esac
    
    echo "Reporte generado: $report_file"
}

# Función para validar argumentos de línea de comandos
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --validate-config)
                validate_configuration
                echo "Configuración válida"
                exit 0
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo "Argumento desconocido: $1" >&2
                exit 1
                ;;
        esac
        shift
    done
}

# Ayuda del script
show_help() {
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  --validate-config  Validar configuración únicamente"
    echo "  --help            Mostrar esta ayuda"
    echo ""
    echo "Variables de entorno:"
    echo "  LOG_DIRECTORY      Directorio de logs (default: /var/log)"
    echo "  OUTPUT_DIRECTORY   Directorio de salida (default: ./out)"
    echo "  OUTPUT_FORMAT      Formato: json|csv|plain (default: plain)"
}

# Función principal
main() {
    validate_dependencies
    validate_configuration
    initialize_output
    
    echo "Iniciando análisis de logs en: $LOG_DIRECTORY"
    
    analyze_all_logs
    generate_report
    
    echo "Análisis completado exitosamente"
}

# Ejecutar función principal si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_arguments "$@"
    main "$@"
fi