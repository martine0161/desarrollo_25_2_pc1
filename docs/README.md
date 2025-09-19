# Analizador de Logs de Red con Seguridad Integrada

Analizador Bash para logs de red que procesa HTTP requests, DNS queries y errores TLS usando journalctl. Aplicando principios 12-Factor, CALM lean analysis y You Build It You Run It.

## Descripción del Proyecto

Este proyecto implementa un analizador robusto de logs de red capaz de:
- Procesar logs HTTP con extracción de códigos de estado y métodos
- Analizar consultas DNS con tipos de query y dominios
- Generar reportes en múltiples formatos (JSON, CSV, texto plano)
- Proporcionar análisis estadísticos detallados por hora
- Identificar patrones de tráfico y anomalías básicas

## Variables de Entorno

| Variable | Efecto Observable | Valor por Defecto |
|----------|-------------------|-------------------|
| `LOG_DIRECTORY` | Directorio fuente de logs a analizar | `/var/log` |
| `OUTPUT_DIRECTORY` | Directorio donde se guardan las salidas | `./out` |
| `OUTPUT_FORMAT` | Formato del reporte: `json`\|`csv`\|`plain` | `plain` |
| `HTTP_LOG_PATTERN` | Patrón regex para identificar logs HTTP | `HTTP.*[0-9]{3}` |
| `DNS_LOG_PATTERN` | Patrón regex para identificar logs DNS | `query.*IN` |
| `TLS_LOG_PATTERN` | Patrón regex para identificar logs TLS | `TLS\|SSL` |
| `CONFIG_FILE` | Archivo de configuración adicional | `./config/analyzer.conf` |

## Instalación y Requisitos

### Dependencias del Sistema
```bash
# Herramientas requeridas (normalmente preinstaladas en sistemas Unix)
grep sed awk cut sort uniq find
```

### Verificar Dependencias
```bash
make tools
```

## Uso

### Ejecución Básica
```bash
# Análisis con configuración por defecto
./src/log_analyzer.sh

# O usando el Makefile
make run
```

### Configuración Personalizada
```bash
# Analizar directorio específico en formato JSON
LOG_DIRECTORY=/custom/logs OUTPUT_FORMAT=json ./src/log_analyzer.sh

# Analizar con patrón HTTP personalizado
HTTP_LOG_PATTERN="GET.*200" ./src/log_analyzer.sh
```

### Validación de Configuración
```bash
# Validar configuración sin ejecutar análisis
./src/log_analyzer.sh --validate-config

# Mostrar ayuda
./src/log_analyzer.sh --help
```

### Targets del Makefile Disponibles

```bash
make tools      # Verificar herramientas necesarias
make build      # Preparar artefactos en out/
make test       # Ejecutar tests con Bats
make run        # Ejecutar analizador principal
make pack       # Generar paquete en dist/
make clean      # Limpiar directorios temporales
make help       # Mostrar todos los targets disponibles
```

## Estructura de Archivos de Salida

El analizador genera los siguientes archivos en el directorio `out/`:

```
out/
├── process.log              # Log del proceso de análisis
├── http_analysis.txt        # Análisis básico HTTP
├── dns_analysis.txt         # Análisis básico DNS
├── {archivo}_detailed.txt   # Análisis HTTP detallado por archivo
├── {archivo}_dns_detailed.txt # Análisis DNS detallado por archivo
├── comprehensive.log        # Log del análisis comprensivo
└── analysis_report.{format} # Reporte final en formato especificado
```

## Ejemplos de Salida

### Análisis HTTP Básico
```
Código 200: 1543 ocurrencias
Código 404: 89 ocurrencias  
Código 500: 12 ocurrencias
Método GET: 1401 veces
Método POST: 243 veces
```

### Análisis DNS Básico
```
Dominio: google.com, Tipo: A, Consultas: 45
Dominio: facebook.com, Tipo: AAAA, Consultas: 23
Dominio: cloudflare.com, Tipo: CNAME, Consultas: 12
```

### Reporte JSON
```json
{
  "timestamp": "2023-10-25T10:30:00Z",
  "log_directory": "/var/log",
  "analysis_summary": {
    "http_entries": 156,
    "dns_entries": 89
  }
}
```

## Códigos de Salida

El script utiliza códigos de salida específicos para diferentes tipos de errores:

- `0`: Ejecución exitosa
- `1`: Error de configuración (directorio inexistente, formato inválido)
- `2`: Error de permisos (sin acceso de lectura)
- `3`: Error de red/DNS
- `4`: Error de análisis TLS

## Principios de Diseño

### 12-Factor App Compliance
- **I. Codebase**: Una sola base de código en control de versiones
- **III. Config**: Configuración mediante variables de entorno
- **V. Build/Run**: Separación clara entre construcción y ejecución

### CALM Principles
- **Culture**: Documentación clara y tests automatizados
- **Automation**: Makefile para automatización de tareas
- **Lean**: Análisis eficiente sin dependencias externas
- **Measurement**: Métricas y logging del proceso

### You Build It You Run It
- Responsabilidad completa del módulo de análisis de logs
- Monitoreo a través de logs detallados
- Limpieza automática mediante traps

## Testing

### Ejecutar Tests
```bash
# Tests básicos
bats tests/basic.bats

# Tests de análisis HTTP
bats tests/http_analysis.bats

# Todos los tests
make test
```

### Estructura de Tests
- `tests/basic.bats`: Validaciones básicas y configuración
- `tests/http_analysis.bats`: Tests específicos de análisis HTTP
- Tests de robustez para manejo de errores

## Desarrollo

### Estructura del Proyecto
```
├── src/
│   └── log_analyzer.sh     # Script principal
├── tests/
│   ├── basic.bats          # Tests básicos
│   └── http_analysis.bats  # Tests de análisis
├── docs/
│   └── README.md           # Esta documentación
├── out/                    # Directorio de salidas
├── dist/                   # Paquetes distribuibles
└── Makefile               # Automatización
```

### Contribuir

1. Trabajar en ramas feature específicas
2. Commits descriptivos en español
3. Tests deben pasar antes de merge
4. Documentar cambios en variables de entorno

## Troubleshooting

### Problemas Comunes

**Error: "Herramientas faltantes"**
```bash
# Verificar que tienes las herramientas básicas instaladas
which grep sed awk cut sort uniq find
```

**Error: "Directorio de logs no existe"**
```bash
# Verificar que el directorio existe y es legible
ls -la $LOG_DIRECTORY
```

**Error: "No hay permisos de lectura"**
```bash
# Verificar permisos
chmod +r $LOG_DIRECTORY/*.log
```

### Logs de Depuración

El proceso genera logs detallados en `out/process.log` para ayudar en la depuración:
```bash
tail -f out/process.log
```

## Integración con Otros Módulos

Este analizador está diseñado para integrarse con:
- **Módulo TLS**: Procesa logs TLS usando `TLS_LOG_PATTERN`
- **Módulo de Automatización**: Compatible con Makefile centralizado
- **Sistema de Empaquetado**: Genera artefactos en `out/` para distribución

## Autor

Desarrollado como parte del Proyecto 5 - Analizador de logs de red con seguridad integrada.
Módulo de Análisis HTTP/DNS implementado por Grupo 11.