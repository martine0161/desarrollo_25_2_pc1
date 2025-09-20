# Crear src/integrated_analyzer.sh
#!/bin/bash
set -euo pipefail

# Configuración integrada
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_DIRECTORY="${LOG_DIRECTORY:-./logs}"
readonly OUTPUT_DIRECTORY="${OUTPUT_DIRECTORY:-./out}"
readonly OUTPUT_FORMAT="${OUTPUT_FORMAT:-plain}"

# Importar módulos de análisis
source "$SCRIPT_DIR/log_analyzer.sh" 2>/dev/null || true
source "$SCRIPT_DIR/tls_analyzer.sh" 2>/dev/null || true

# Función principal integrada
main() {
    echo "=== ANÁLISIS INTEGRADO DE LOGS DE RED ==="
    echo "Timestamp: $(date)"
    echo "Log Directory: $LOG_DIRECTORY"
    echo "Output Directory: $OUTPUT_DIRECTORY"
    echo ""
    
    # Crear directorio de salida
    mkdir -p "$OUTPUT_DIRECTORY"
    
    # Análisis HTTP/DNS (Alumno 1)
    if command -v analyze_all_logs >/dev/null 2>&1; then
        echo "Ejecutando análisis HTTP/DNS..."
        analyze_all_logs
    else
        echo "Módulo HTTP/DNS no disponible, ejecutando directamente..."
        bash "$SCRIPT_DIR/log_analyzer.sh"
    fi
    
    echo ""
    
    # Análisis TLS (Alumno 2)
    if command -v analyze_tls_handshakes >/dev/null 2>&1; then
        echo "Ejecutando análisis TLS..."
        analyze_tls_handshakes
        analyze_tls_patterns
        analyze_tls_vulnerabilities
    else
        echo "Módulo TLS no disponible, ejecutando directamente..."
        bash "$SCRIPT_DIR/tls_analyzer.sh"
    fi
    
    echo ""
    
    # Reporte consolidado
    generate_integrated_report
    
    echo "=== ANÁLISIS INTEGRADO COMPLETADO ==="
}

generate_integrated_report() {
    local report_file="$OUTPUT_DIRECTORY/integrated_report.txt"
    
    {
        echo "REPORTE INTEGRADO DE ANÁLISIS DE LOGS"
        echo "======================================"
        echo "Generado: $(date)"
        echo "Directorio analizado: $LOG_DIRECTORY"
        echo ""
        
        echo "RESUMEN EJECUTIVO:"
        echo "- Archivos procesados: $(find "$LOG_DIRECTORY" -name "*.log" -type f 2>/dev/null | wc -l)"
        
        if [[ -f "$OUTPUT_DIRECTORY/http_analysis.txt" ]]; then
            echo "- Entradas HTTP analizadas: $(wc -l < "$OUTPUT_DIRECTORY/http_analysis.txt")"
        fi
        
        if [[ -f "$OUTPUT_DIRECTORY/tls_handshakes.txt" ]]; then
            echo "- Eventos TLS procesados: $(grep -c ":" "$OUTPUT_DIRECTORY/tls_handshakes.txt" 2>/dev/null || echo 0)"
        fi
        
        echo ""
        echo "ARCHIVOS GENERADOS:"
        find "$OUTPUT_DIRECTORY" -name "*.txt" -type f | sed 's/^/  - /'
        
    } > "$report_file"
    
    echo "Reporte integrado generado: $report_file"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi