# Proyecto 5: Analizador de logs de red con seguridad integrada

## Descripción general
Analizador en Bash para procesar logs de HTTP requests, DNS queries y errores TLS usando `journalctl`. Implementa principios 12-Factor, CALM y "You Build It You Run It".

## Estructura del proyecto
```
proyecto5-log-analyzer/
├── src/                 # Scripts Bash principales
├── tests/               # Pruebas automatizadas con Bats
├── systemd/            # Unidades de servicio (si aplica)
├── docs/               # Documentación y bitácoras
├── out/                # Salidas intermedias
├── dist/               # Paquetes finales
└── Makefile            # Automatización de tareas
```

## Variables de entorno

| Variable | Tipo | Efecto observable | Ejemplo |
|----------|------|------------------|---------|
| `LOG_PATH` | Requerida | Ruta del archivo de logs a analizar | `/var/log/system.log` |
| `DNS_SERVER` | Opcional | Servidor DNS para verificaciones | `8.8.8.8` |
| `RELEASE` | Opcional | Nombre de versión para empaquetado | `v1.0.0` |
| `TLS_MIN_VERSION` | Opcional | Versión mínima TLS aceptada | `1.2` |
| `HTTP_TIMEOUT` | Opcional | Timeout para requests HTTP en segundos | `30` |
| `DEBUG` | Opcional | Habilitar salida detallada | `1` o `true` |

## Uso básico

### 1. Verificar herramientas
```bash
make tools
```

### 2. Preparar entorno
```bash
make build
```

### 3. Ejecutar análisis
```bash
export LOG_PATH="/var/log/system.log"
make run
```

### 4. Ejecutar pruebas
```bash
make test
```

### 5. Generar paquete final
```bash
RELEASE=v1.0.0 make pack
```

## Targets del Makefile

| Target | Descripción | Dependencias |
|--------|-------------|--------------|
| `tools` | Verifica disponibilidad de herramientas | ninguna |
| `build` | Prepara artefactos en `out/` | ninguna |
| `test` | Ejecuta suite Bats | `build` |
| `run` | Ejecuta análisis principal | `build` |
| `pack` | Genera paquete en `dist/` | `build` |
| `clean` | Limpia `out/` y `dist/` | ninguna |
| `help` | Muestra ayuda detallada | ninguna |

## Contrato de salidas

### Archivos generados en `out/`
- `build_info.txt`: Información de versión y timestamp
- `reports/`: Reportes de análisis por tipo
- `temp/`: Archivos temporales de procesamiento

### Archivos generados en `dist/`
- `log-analyzer-{RELEASE}.tar.gz`: Paquete final reproducible

### Códigos de salida
- `0`: Ejecución exitosa
- `1`: Error de configuración (variables faltantes)
- `2`: Error de red (DNS, HTTP no accesible)
- `3`: Error de análisis TLS
- `4`: Error de permisos de archivo
- `5`: Error de herramientas faltantes

## Instalación de dependencias

### En Ubuntu/Debian:
```bash
sudo apt update
sudo apt install curl dnsutils iproute2 systemd
npm install -g bats
```

### En CentOS/RHEL:
```bash
sudo yum install curl bind-utils iproute systemd
npm install -g bats
```

## Estado del desarrollo

### Sprint 1 
- [x] Makefile inicial con targets básicos
- [x] Estructura de directorios
- [x] Primera prueba Bats representativa
- [x] Documentación base

### Sprint 2 
- [ ] Expansión de pruebas Bats
- [ ] Análisis HTTP/DNS 
- [ ] Integración TLS/journalctl

### Sprint 3 
- [ ] Makefile con caché incremental
- [ ] Empaquetado final
- [ ] Integración completa

## Notas técnicas
- Todos los scripts en español con comentarios descriptivos
- Manejo robusto de errores con `set -euo pipefail`
- Limpieza automática con `trap`
- Idempotencia verificada en cada ejecución

## Contribución
1. Trabajar en rama personal: `rama/diego`
2. Commits pequeños y descriptivos en español
3. PRs hacia `develop` con descripción completa
4. Fusión a `main` solo al final del sprint
