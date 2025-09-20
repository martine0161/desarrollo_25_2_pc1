# Bitácora Sprint 3: Integración Final

**Período:** Días 8-10  
**Objetivo:** Integración completa, caché incremental, paquete reproducible  

## Logros Alcanzados

### 1. Generador de Logs (app.py)
- **Comando ejecutado:** `python3 app.py --duration 60 --output logs`
- **Resultado:** Generación de logs HTTP, DNS y TLS realistas
- **Evidencia:** Archivos access.log, dns.log, tls.log con datos estructurados
- **Decisión técnica:** Python para mayor flexibilidad en generación de patrones

### 2. Caché Incremental en Makefile
- **Implementación:** Targets con dependencias y flags de estado
- **Comando:** `make build` solo ejecuta si cambian archivos fuente
- **Evidencia:** 
```bash
  # Primera ejecución
  $ time make build
  real    0m2.347s
  
  # Segunda ejecución (sin cambios)
  $ time make build
  make: Nothing to be done for 'build'.
  real    0m0.021s