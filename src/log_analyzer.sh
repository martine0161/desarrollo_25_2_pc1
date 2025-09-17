#!/bin/bash
set -euo pipefail

# Variables de configuración con valores por defecto
readonly LOG_DIRECTORY="${LOG_DIRECTORY:-/var/log}"
readonly OUTPUT_FORMAT="${OUTPUT_FORMAT:-plain}"
readonly HTTP_LOG_PATTERN="${HTTP_LOG_PATTERN:-'HTTP.*[0-9]{3}'}"
readonly DNS_LOG_PATTERN="${DNS_LOG_PATTERN:-'query.*IN'}"
readonly OUTPUT_FILE="${OUTPUT_FILE:-./out/analysis_results.txt}"

# Array para almacenar resultados de análisis
declare -a analysis_results=()

# Función de limpieza con trap
cleanup() {
    local exit_code=$?
    echo "Realizando limpieza de archivos temporales..." >&2
    
    # Limpiar archivos temporales que pudieron quedar
    rm -f /tmp/log_analyzer_*.tmp
    
    # Mostrar resumen final
    if [[ $exit_code -eq 0 ]]; then
        echo "Análisis completado exitosamente" >&2
    else
        echo "Análisis terminado con errores (código: $exit_code)" >&2
    fi
    
    exit $exit_code
}

# Configurar trap para limpieza
trap cleanup EXIT

# Validar que el entorno está configurado correctamente
validate_environment() {
    echo "Validando configuración del entorno..."
    
    # Verificar que el directorio de logs existe
    if [[ ! -d "$LOG_DIRECTORY" ]]; then
        echo "Error: El directorio de logs no existe: $LOG_DIRECTORY" >&2
        return 1
    fi
    
    # Verificar permisos de lectura
    if [[ ! -r "$LOG_DIRECTORY" ]]; then
        echo "Error: Sin permisos de lectura en: $LOG_DIRECTORY" >&2
        return 2
    fi
    
    # Crear directorio de salida si no existe
    mkdir -p "$(dirname "$OUTPUT_FILE")"
    
    echo "✓ Entorno validado correctamente"
    return 0
}

# Función principal de análisis básico
analyze_logs_basic() {
    echo "Iniciando análisis básico de logs..."
    echo "Directorio: $LOG_DIRECTORY"
    echo "Patrón HTTP: $HTTP_LOG_PATTERN"
    
    # Buscar archivos de log
    local log_files
    log_files=$(find "$LOG_DIRECTORY" -name "*.log" -type f 2>/dev/null || true)
    
    if [[ -z "$log_files" ]]; then
        echo "Advertencia: No se encontraron archivos .log en $LOG_DIRECTORY"
        return 0
    fi
    
    # Contar archivos encontrados
    local file_count
    file_count=$(echo "$log_files" | wc -l)
    echo "Archivos de log encontrados: $file_count"
    
    # Análisis básico por ahora
    echo "$log_files" | while read -r log_file; do
        if [[ -r "$log_file" ]]; then
            echo "Analizando: $log_file"
            local line_count
            line_count=$(wc -l < "$log_file")
            echo "  - Líneas: $line_count"
            analysis_results+=("$log_file:$line_count")
        fi
    done
}

# Mostrar ayuda
show_help() {
    cat << EOF
Analizador de Logs de Red - Alumno 1

USAGE:
    $0 [OPCIONES]

OPCIONES:
    --help              Muestra esta ayuda
    --validate-config   Solo valida la configuración
    --version           Muestra la versión

VARIABLES DE ENTORNO:
    LOG_DIRECTORY       Directorio de logs (default: /var/log)
    OUTPUT_FORMAT       Formato de salida: plain|json|csv (default: plain)
    HTTP_LOG_PATTERN    Patrón regex para HTTP (default: 'HTTP.*[0-9]{3}')
    DNS_LOG_PATTERN     Patrón regex para DNS (default: 'query.*IN')
    OUTPUT_FILE         Archivo de salida (default: ./out/analysis_results.txt)

EJEMPLOS:
    $0                                    # Análisis básico
    LOG_DIRECTORY=/tmp $0                 # Usar directorio personalizado
    OUTPUT_FORMAT=json $0 --validate-config  # Solo validar configuración
EOF
}

# Función principal
main() {
    echo "=== Analizador de Logs de Red - Alumno 1 ==="
    echo "Inicio: $(date)"
    
    # Procesar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                return 0
                ;;
            --validate-config)
                validate_environment
                echo "Configuración válida"
                return 0
                ;;
            --version)
                echo "Versión: 1.0.0-sprint1"
                return 0
                ;;
            *)
                echo "Opción desconocida: $1" >&2
                show_help
                return 1
                ;;
        esac
        shift
    done
    
    # Ejecutar análisis
    validate_environment
    analyze_logs_basic
    
    echo "Fin: $(date)"
    echo "Resultados guardados en: $OUTPUT_FILE"
}

# Ejecutar función principal con todos los argumentos
main "$@"