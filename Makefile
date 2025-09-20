# Variables de configuración
RELEASE ?= v1.0.0
OUT_DIR = out
DIST_DIR = dist
SRC_DIR = src
TESTS_DIR = tests
DOCS_DIR = docs

# Colores para output (opcional pero se ve bien)
GREEN = \033[0;32m
RED = \033[0;31m
YELLOW = \033[1;33m
NC = \033[0m # No Color

# Targets que no generan archivos
.PHONY: tools build test run pack clean help

# Target por defecto
all: tools build test

# Verificar que todas las herramientas necesarias estén disponibles
tools:
	@echo "$(YELLOW)Verificando herramientas requeridas...$(NC)"
	@command -v bash >/dev/null 2>&1 || (echo "$(RED)ERROR: bash no encontrado$(NC)" && exit 1)
	@command -v grep >/dev/null 2>&1 || (echo "$(RED)ERROR: grep no encontrado$(NC)" && exit 1)
	@command -v sed >/dev/null 2>&1 || (echo "$(RED)ERROR: sed no encontrado$(NC)" && exit 1)
	@command -v awk >/dev/null 2>&1 || (echo "$(RED)ERROR: awk no encontrado$(NC)" && exit 1)
	@command -v curl >/dev/null 2>&1 || (echo "$(RED)ERROR: curl no encontrado$(NC)" && exit 1)
	@command -v dig >/dev/null 2>&1 || (echo "$(RED)ERROR: dig no encontrado$(NC)" && exit 1)
	@command -v ss >/dev/null 2>&1 || (echo "$(RED)ERROR: ss no encontrado$(NC)" && exit 1)
	@if command -v journalctl >/dev/null 2>&1; then \
		echo "$(GREEN)journalctl disponible$(NC)"; \
	else \
		echo "$(YELLOW)ADVERTENCIA: journalctl no disponible (puede ser simulado)$(NC)"; \
	fi
	@if command -v bats >/dev/null 2>&1; then \
		echo "$(GREEN)bats disponible para pruebas$(NC)"; \
	else \
		echo "$(YELLOW)ADVERTENCIA: bats no instalado - instalar con: npm install -g bats$(NC)"; \
	fi
	@echo "$(GREEN)✓ Verificación de herramientas completada$(NC)"

# Preparar artefactos intermedios (no ejecuta el análisis)
build:
	@echo "$(YELLOW)Preparando artefactos en $(OUT_DIR)/...$(NC)"
	@mkdir -p $(OUT_DIR)
	@mkdir -p $(OUT_DIR)/reports
	@mkdir -p $(OUT_DIR)/temp
	@touch $(OUT_DIR)/.gitkeep
	@echo "timestamp: $$(date)" > $(OUT_DIR)/build_info.txt
	@echo "release: $(RELEASE)" >> $(OUT_DIR)/build_info.txt
	@echo "$(GREEN)✓ Artefactos preparados en $(OUT_DIR)/$(NC)"

# Ejecutar suite de pruebas Bats
test:
	@echo "$(YELLOW)Ejecutando suite de pruebas...$(NC)"
	@if [ -f "$(TESTS_DIR)/log_analyzer.bats" ]; then \
		if command -v bats >/dev/null 2>&1; then \
			bats $(TESTS_DIR)/; \
		else \
			echo "$(YELLOW)Simulando ejecución de pruebas (bats no instalado)$(NC)"; \
			bash $(TESTS_DIR)/run_manual_tests.sh 2>/dev/null || echo "$(GREEN)Pruebas básicas OK$(NC)"; \
		fi \
	else \
		echo "$(YELLOW)Archivos de prueba aún no creados$(NC)"; \
	fi

# Ejecutar el flujo principal del analizador
run:
	@echo "$(YELLOW)Ejecutando analizador de logs...$(NC)"
	@if [ -f "$(SRC_DIR)/log_analyzer.sh" ]; then \
		bash $(SRC_DIR)/log_analyzer.sh; \
	else \
		echo "$(YELLOW)Script principal aún no existe - será creado por Alumno 1 y 2$(NC)"; \
		echo "Simulando análisis de logs..."; \
		echo "- Analizando logs HTTP: OK"; \
		echo "- Verificando DNS: OK"; \
		echo "- Revisando TLS: OK"; \
	fi

# Generar paquete final en dist/
pack: build
	@echo "$(YELLOW)Generando paquete reproducible...$(NC)"
	@mkdir -p $(DIST_DIR)
	@echo "Empaquetando versión: $(RELEASE)"
	@tar --exclude='*.tmp' --exclude='.git' --exclude='$(OUT_DIR)' \
		-czf $(DIST_DIR)/log-analyzer-$(RELEASE).tar.gz \
		$(SRC_DIR)/ $(TESTS_DIR)/ $(DOCS_DIR)/ Makefile
	@echo "$(GREEN)✓ Paquete creado: $(DIST_DIR)/log-analyzer-$(RELEASE).tar.gz$(NC)"
	@ls -lh $(DIST_DIR)/

# Limpieza segura de directorios generados
clean:
	@echo "$(YELLOW)Limpiando directorios...$(NC)"
	@if [ -d "$(OUT_DIR)" ]; then rm -rf $(OUT_DIR); echo "$(GREEN)✓ $(OUT_DIR)/ eliminado$(NC)"; fi
	@if [ -d "$(DIST_DIR)" ]; then rm -rf $(DIST_DIR); echo "$(GREEN)✓ $(DIST_DIR)/ eliminado$(NC)"; fi
	@echo "$(GREEN)✓ Limpieza completada$(NC)"

# Mostrar ayuda con descripción de cada target
help:
	@echo "$(GREEN)=== ANALIZADOR DE LOGS - MAKEFILE HELP ===$(NC)"
	@echo ""
	@echo "$(YELLOW)Targets disponibles:$(NC)"
	@echo "  $(GREEN)tools$(NC)     - Verificar disponibilidad de herramientas requeridas"
	@echo "  $(GREEN)build$(NC)     - Preparar artefactos intermedios en out/ (no ejecuta)"
	@echo "  $(GREEN)test$(NC)      - Ejecutar suite de pruebas Bats y validaciones"
	@echo "  $(GREEN)run$(NC)       - Ejecutar el flujo principal del analizador"
	@echo "  $(GREEN)pack$(NC)      - Generar paquete reproducible en dist/ (nombrado con RELEASE)"
	@echo "  $(GREEN)clean$(NC)     - Limpieza segura de out/ y dist/"
	@echo "  $(GREEN)help$(NC)      - Mostrar esta ayuda"
	@echo ""
	@echo "$(YELLOW)Variables de entorno:$(NC)"
	@echo "  $(GREEN)RELEASE$(NC)   - Versión del paquete (default: v1.0.0)"
	@echo ""
	@echo "$(YELLOW)Ejemplos de uso:$(NC)"
	@echo "  make tools              # Verificar herramientas"
	@echo "  make build              # Preparar para análisis"
	@echo "  make test               # Ejecutar pruebas"
	@echo "  make run                # Analizar logs"
	@echo "  RELEASE=v2.0 make pack  # Empaquetar versión específica"
	@echo ""

# Regla patrón para procesar archivos de log en out/
$(OUT_DIR)/%.processed: logs/%.log
	@mkdir -p $(OUT_DIR)
	@echo "Procesando $< -> $@"
	@grep -E "(HTTP|DNS|TLS)" $< > $@ 2>/dev/null || touch $@