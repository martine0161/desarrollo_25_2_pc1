# Analizador de Logs de Red con Seguridad Integrada

Analizador Bash robusto para logs de red que procesa HTTP requests, DNS queries y errores TLS usando journalctl. Implementa principios 12-Factor, CALM lean analysis y "You Build It You Run It".

## Descripción del Proyecto

Este proyecto desarrolla un analizador completo de logs de red capaz de:

- **Análisis HTTP/HTTPS**: Procesamiento de requests con extracción de códigos de estado, métodos y trazas comparativas
- **Análisis DNS**: Consultas A/CNAME con resolución de dominios y estadísticas detalladas
- **Seguridad TLS**: Verificación de certificados, análisis de handshakes y validación de protocolos
- **Automatización**: Makefile con caché incremental, tests Bats y empaquetado reproducible
- **Reportes**: Generación en múltiples formatos (JSON, CSV, texto plano) con análisis estadísticos

## Estructura del Proyecto

```
proyecto5-log-analyzer/
├── src/                    # Scripts Bash principales
│   ├── log_analyzer.sh     # Analizador principal HTTP/DNS
│   ├── tls_analyzer.sh     # Módulo de seguridad TLS  
│   └── utils.sh           # Utilidades compartidas
├── tests/                  # Pruebas automatizadas con Bats
│   ├── basic.bats         # Tests básicos y configuración
│   ├── http.bats          # Tests específicos HTTP
│   ├── dns.bats           # Tests específicos DNS
│   ├── tls.bats           # Tests específicos TLS
│   └── robustness.bats    # Tests de manejo de errores
├── config/                 # Archivos de configuración
│   └── analyzer.conf      # Configuración principal
├── systemd/               # Unidades de servicio (si aplica)
├── docs/                  # Documentación y bitácoras
│   ├── README.md          # Esta documentación
│   └── bitacora-sprint-*.md # Bitácoras por sprint
├── out/                   # Salidas intermedias y reportes
├── dist/                  # Paquetes finales distribuibles
└── Makefile              # Automatización de tareas
```

## Variables de Entorno

| Variable | Tipo | Efecto Observable | Valor por Defecto |
|----------|------|-------------------|-------------------|
| `LOG_DIRECTORY` | Requerida | Directorio fuente de logs a analizar | `/var/log` |
| `OUTPUT_DIRECTORY` | Opcional | Directorio donde se guardan las salidas | `./out` |
| `OUTPUT_FORMAT` | Opcional | Formato del reporte: `json`\|`csv`\|`plain` | `plain` |
| `HTTP_LOG_PATTERN` | Opcional | Patrón regex para identificar logs HTTP | `HTTP.*[0-9]{3}` |
| `DNS_LOG_PATTERN` | Opcional | Patrón regex para identificar logs DNS | `query.*IN` |
| `TLS_LOG_PATTERN` | Opcional | Patrón regex para identificar logs TLS | `TLS\|SSL` |
| `CONFIG_FILE` | Opcional | Archivo de configuración adicional | `./config/analyzer.conf` |
| `DNS_SERVER` | Opcional | Servidor DNS para verificaciones | `8.8.8.8` |
| `RELEASE` | Opcional | Nombre de versión para empaquetado | `v1.0.0` |
| `TLS_MIN_VERSION` | Opcional | Versión mínima TLS aceptada | `1.2` |
| `HTTP_TIMEOUT` | Opcional | Timeout para requests HTTP en segundos | `30` |
| `DEBUG` | Opcional | Habilitar salida detallada | `false` |

## Instalación y Requisitos

### Dependencias del Sistema

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install curl dnsutils iproute2 systemd openssl make
npm install -g bats
```

**CentOS/RHEL:**
```bash
sudo yum install curl bind-utils iproute systemd openssl make
npm install -g bats
```

**Herramientas básicas requeridas:**
```bash
# Normalmente preinstaladas en sistemas Unix
grep sed awk cut sort uniq find journalctl
```

### Verificar Dependencias
```bash
make tools
```

## Uso

### Comandos Principales

```bash
# Verificar herramientas necesarias
make tools

# Preparar entorno y artefactos
make build

# Ejecutar análisis con configuración por defecto
make run

# Ejecutar suite completa de tests
make test

# Generar paquete distribuible
RELEASE=v1.0.0 make pack

# Limpiar directorios temporales
make clean

# Mostrar ayuda detallada
make help
```

### Configuración Personalizada

```bash
# Análisis de directorio específico en formato JSON
LOG_DIRECTORY=/custom/logs OUTPUT_FORMAT=json make run

# Análisis con configuración completa
export LOG_DIRECTORY="/var/log/nginx"
export OUTPUT_FORMAT="json"
export HTTP_LOG_PATTERN="GET.*[2-3][0-9]{2}"
export DEBUG="true"
make run
```

### Validación y Depuración

```bash
# Validar configuración sin ejecutar análisis
./src/log_analyzer.sh --validate-config

# Mostrar ayuda del script principal
./src/log_analyzer.sh --help

# Verificar idempotencia
make validate-idempotence
```

## Targets del Makefile

| Target | Descripción | Dependencias |
|--------|-------------|--------------|
| `tools` | Verifica disponibilidad de herramientas requeridas | ninguna |
| `build` | Prepara artefactos en `out/` | ninguna |
| `test` | Ejecuta suite completa Bats | `build` |
| `test-comprehensive` | Ejecuta tests específicos por protocolo | `build` |
| `run` | Ejecuta análisis principal integrado | `build` |
| `pack` | Genera paquete reproducible en `dist/` | `build`, `test` |
| `validate-idempotence` | Valida que el build es idempotente | ninguna |
| `clean` | Limpia `out/` y `dist/` | ninguna |
| `help` | Muestra ayuda detallada de todos los targets | ninguna |

## Estructura de Archivos de Salida

### Directorio `out/`
```
out/
├── build_info.txt              # Información de versión y timestamp
├── process.log                 # Log del proceso de análisis
├── analysis_complete.flag      # Flag de análisis completado
├── reports/                    # Reportes por tipo de protocolo
│   ├── http_analysis.txt       # Análisis básico HTTP
│   ├── dns_analysis.txt        # Análisis básico DNS
│   └── tls_analysis.txt        # Análisis básico TLS
├── temp/                       # Archivos temporales de procesamiento
└── analysis_report.{format}    # Reporte final en formato especificado
```

### Directorio `dist/`
```
dist/
└── analizador-logs-{RELEASE}.tar.gz  # Paquete final reproducible
```

## Ejemplos de Salida

### Análisis HTTP
```
=== Análisis HTTP ===
Código 200: 1543 ocurrencias
Código 404: 89 ocurrencias  
Código 500: 12 ocurrencias
Método GET: 1401 veces
Método POST: 243 veces
```

### Análisis DNS
```
=== Análisis DNS ===
Dominio: google.com, Tipo: A, Consultas: 45
Dominio: facebook.com, Tipo: AAAA, Consultas: 23
Dominio: cloudflare.com, Tipo: CNAME, Consultas: 12
```

### Análisis TLS
```
=== Análisis TLS ===
TLS Handshakes: 156
Errores SSL: 12
Eventos de certificados: 89
✓ tls1_2
✓ tls1_3
✗ tls1
```

### Reporte JSON
```json
{
  "timestamp": "2023-10-25T10:30:00Z",
  "log_directory": "/var/log",
  "analysis_summary": {
    "http_entries": 156,
    "dns_entries": 89,
    "tls_entries": 45
  },
  "protocols_analyzed": ["HTTP", "DNS", "TLS"],
  "execution_time_seconds": 23
}
```

## Códigos de Salida

El sistema utiliza códigos de salida específicos para diferentes tipos de errores:

- `0`: Ejecución exitosa
- `1`: Error de configuración (variables faltantes, directorio inexistente)
- `2`: Error de permisos de archivo o red (DNS, HTTP no accesible)
- `3`: Error de análisis TLS (certificados, handshakes)
- `4`: Error de herramientas faltantes
- `5`: Error interno del sistema

## Principios de Diseño

### 12-Factor App Compliance
- **I. Codebase**: Una sola base de código en control de versiones con ramas específicas
- **III. Config**: Configuración completa mediante variables de entorno
- **V. Build/Run**: Separación clara entre construcción y ejecución via Makefile

### CALM Principles
- **Culture**: Documentación clara, tests automatizados y bitácoras por sprint
- **Automation**: Makefile completo con caché incremental y validación
- **Lean**: Análisis eficiente sin dependencias externas pesadas
- **Measurement**: Métricas detalladas, logging y monitoreo del proceso

### You Build It You Run It
- Responsabilidad completa del ciclo de vida del analizador
- Monitoreo mediante logs detallados y códigos de salida específicos
- Limpieza automática mediante traps y manejo robusto de errores

## Testing

### Ejecutar Tests

```bash
# Tests básicos de configuración
bats tests/basic.bats

# Tests específicos por protocolo
bats tests/http.bats
bats tests/dns.bats
bats tests/tls.bats

# Tests de robustez y manejo de errores
bats tests/robustness.bats

# Suite completa
make test

# Suite comprehensiva con todos los protocolos
make test-comprehensive
```

### Cobertura de Tests
- **Configuración**: Validación de variables de entorno
- **HTTP**: Detección de códigos de estado y métodos
- **DNS**: Análisis de queries y resolución
- **TLS**: Verificación de certificados y protocolos
- **Robustez**: Manejo de archivos faltantes y permisos
- **Idempotencia**: Validación de builds reproducibles

## Desarrollo por Sprints

### Sprint 1 (Días 1-3): Fundamentos
- **Objetivos**: Base de código 12-Factor, configuración por variables, Bash robusto
- **Entregables**: Repositorio configurado, Makefile inicial, primera prueba Bats

### Sprint 2 (Días 4-7): Integración y Análisis  
- **Objetivos**: Pipelines Unix toolkit, systemd/journalctl, análisis HTTP/HTTPS con trazas
- **Entregables**: Funcionalidad completa por protocolo, suite de tests expandida

### Sprint 3 (Días 8-10): Integración Final
- **Objetivos**: Integración completa, caché incremental, paquete reproducible
- **Entregables**: Proyecto completo, documentación final, validación de idempotencia

## Troubleshooting

### Problemas Comunes

**Error: "Herramientas faltantes"**
```bash
# Verificar herramientas básicas
make tools
which grep sed awk cut sort uniq find journalctl
```

**Error: "Directorio de logs no existe"**
```bash
# Verificar directorio y permisos
ls -la $LOG_DIRECTORY
export LOG_DIRECTORY="/ruta/correcta"
```

**Error: "Sin permisos de lectura"**
```bash
# Verificar y corregir permisos
chmod +r $LOG_DIRECTORY/*.log
sudo chown $(whoami) $LOG_DIRECTORY
```

**Error: "Análisis TLS fallido"**
```bash
# Verificar OpenSSL y journalctl
openssl version
systemctl status systemd-journald
```

### Logs de Depuración

```bash
# Habilitar modo debug
export DEBUG="true"
make run

# Monitorear logs en tiempo real
tail -f out/process.log

# Revisar logs de análisis comprensivo
cat out/comprehensive.log
```

## Integración con Otros Módulos

### Módulo TLS (Alumno 2)
- Procesa logs TLS usando `TLS_LOG_PATTERN`
- Integración via `src/tls_analyzer.sh`
- Verificación de certificados con OpenSSL

### Módulo de Automatización (Alumno 3)  
- Makefile centralizado con caché incremental
- Tests Bats comprehensivos
- Empaquetado y distribución reproducible

### Sistema de Reportes
- Genera artefactos estándar en `out/`
- Compatible con sistemas de CI/CD
- Formatos múltiples para integración downstream

## Contribución

### Flujo de Trabajo
1. Trabajar en rama personal: `rama/alumno1`, `rama/alumno2`, `rama/alumno3`
2. Commits descriptivos en español con mensajes claros
3. Pull requests hacia `develop` con descripción completa
4. Tests deben pasar antes de merge
5. Fusión a `main` solo al final de cada sprint

### Estándares de Código
- Scripts Bash con `set -euo pipefail`
- Comentarios en español
- Funciones con documentación clara
- Manejo robusto de errores con trap
- Validación de entrada y salida

## Licencia

Desarrollado como parte del Proyecto 5 - Analizador de logs de red con seguridad integrada.
Implementación colaborativa siguiendo metodologías ágiles y principios DevOps.

---

**Contacto**: Equipo de desarrollo - Proyecto 5 Analizador de Logs
**Versión**: 1.0.0
**Última actualización**: Sprint 3 - Integración Final