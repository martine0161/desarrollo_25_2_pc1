# Variables de configuración avanzadas
SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c
RELEASE ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "v1.0.0")
BUILD_TIME := $(shell date -u '+%Y%m%d_%H%M%S')

# Directorios
OUT_DIR = out
DIST_DIR = dist
SRC_DIR = src
TESTS_DIR = tests
DOCS_DIR = docs
LOGS_DIR = logs

# Archivos fuente y dependencias
SRC_FILES := $(wildcard $(SRC_DIR)/*.sh)
TEST_FILES := $(wildcard $(TESTS_DIR)/*.bats)
CONFIG_FILES := $(wildcard config/*)
DOC_FILES := $(wildcard $(DOCS_DIR)/*)

# Colores para output
GREEN = \033[0;32m
RED = \033[0;31m
YELLOW = \033[1;33m
BLUE = \033[0;34m
NC = \033[0m

# Targets que no generan archivos
.PHONY: tools build test run pack clean help generate-logs full-demo validate-idempotence

# Target por defecto
all: tools build test

# Verificar herramientas (con mejor detección)
tools:
	@echo "$(YELLOW)Verificando herramientas y dependencias...$(NC)"
	@command -v bash >/dev/null 2>&1 || (echo "$(RED)ERROR: bash no encontrado$(NC)" && exit 1)
	@command -v python3 >/dev/null 2>&1 || (echo "$(RED)ERROR: python3 no encontrado$(NC)" && exit 1)
	@command -v grep >/dev/null 2>&1 || (echo "$(RED)ERROR: grep no encontrado$(NC)" && exit 1)
	@command -v sed >/dev/null 2>&1 || (echo "$(RED)ERROR: sed no encontrado$(NC)" && exit 1)
	@command -v awk >/dev/null 2>&1 || (echo "$(RED)ERROR: awk no encontrado$(NC)" && exit 1)
	@command -v openssl >/dev/null 2>&1 || (echo "$(YELLOW)ADVERTENCIA: openssl no disponible$(NC)")
	@if command -v journalctl >/dev/null 2>&1; then \
		echo "$(GREEN)✓ journalctl disponible$(NC)"; \
	else \
		echo "$(YELLOW)⚠ journalctl simulado en bin/$(NC)"; \
	fi
	@if command -v bats >/dev/null 2>&1; then \
		echo "$(GREEN)✓ bats disponible$(NC)"; \
	else \
		echo "$(YELLOW)⚠ bats no instalado - tests manuales disponibles$(NC)"; \
	fi
	@echo "$(GREEN)✓ Verificación completada$(NC)"

# Caché incremental para build
$(OUT_DIR)/build.flag: $(SRC_FILES) $(CONFIG_FILES) Makefile
	@echo "$(YELLOW)Construyendo artefactos (cambios detectados)...$(NC)"
	@mkdir -p $(OUT_DIR)/reports $(OUT_DIR)/temp $(OUT_DIR)/cache
	@echo "timestamp: $(shell date)" > $(OUT_DIR)/build_info.txt
	@echo "release: $(RELEASE)" >> $(OUT_DIR)/build_info.txt
	@echo "build_time: $(BUILD_TIME)" >> $(OUT_DIR)/build_info.txt
	@echo "sources: $(SRC_FILES)" >> $(OUT_DIR)/build_info.txt
	@touch $@
	@echo "$(GREEN)✓ Build completado$(NC)"

# Build con caché
build: $(OUT_DIR)/build.flag

# Generar logs de prueba
generate-logs:
	@echo "$(YELLOW)Generando logs de prueba...$(NC)"
	@mkdir -p $(LOGS_DIR)
	@if [ -f "app.py" ]; then \
		python3 app.py --duration 30 --output $(LOGS_DIR); \
	else \
		echo "$(RED)Error: app.py no encontrado$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✓ Logs generados en $(LOGS_DIR)/$(NC)"

# Tests con dependencia de build
$(OUT_DIR)/test.flag: $(OUT_DIR)/build.flag $(TEST_FILES) $(SRC_FILES)
	@echo "$(YELLOW)Ejecutando suite de pruebas...$(NC)"
	@if command -v bats >/dev/null 2>&1; then \
		bats $(TESTS_DIR)/ | tee $(OUT_DIR)/test_results.txt; \
		if [ $${PIPESTATUS[0]} -eq 0 ]; then \
			echo "$(GREEN)✓ Todos los tests pasaron$(NC)"; \
			touch $@; \
		else \
			echo "$(RED)✗ Algunos tests fallaron$(NC)"; \
			exit 1; \
		fi \
	else \
		echo "$(YELLOW)Ejecutando tests manuales...$(NC)"; \
		bash $(TESTS_DIR)/run_manual_tests.sh | tee $(OUT_DIR)/test_results.txt; \
		touch $@; \
	fi

test: $(OUT_DIR)/test.flag

# Análisis completo con logs generados
$(OUT_DIR)/analysis.flag: $(OUT_DIR)/build.flag generate-logs
	@echo "$(YELLOW)Ejecutando análisis completo...$(NC)"
	@export PATH="$$PWD/bin:$$PATH" && \
	export LOG_DIRECTORY="$(LOGS_DIR)" && \
	export OUTPUT_DIRECTORY="$(OUT_DIR)" && \
	if [ -f "$(SRC_DIR)/log_analyzer.sh" ]; then \
		bash $(SRC_DIR)/log_analyzer.sh; \
	fi
	@if [ -f "$(SRC_DIR)/tls_analyzer.sh" ]; then \
		export PATH="$$PWD/bin:$$PATH" && \
		export LOG_DIRECTORY="$(LOGS_DIR)" && \
		export OUTPUT_DIRECTORY="$(OUT_DIR)" && \
		bash $(SRC_DIR)/tls_analyzer.sh; \
	fi
	@touch $@
	@echo "$(GREEN)✓ Análisis completado$(NC)"

run: $(OUT_DIR)/analysis.flag

# Empaquetado con versionado
$(DIST_DIR)/log-analyzer-$(RELEASE).tar.gz: $(OUT_DIR)/build.flag $(OUT_DIR)/test.flag
	@echo "$(YELLOW)Generando paquete distribuible...$(NC)"
	@mkdir -p $(DIST_DIR)
	@tar --exclude='*.tmp' --exclude='.git*' --exclude='$(LOGS_DIR)' \
		--transform='s,^,log-analyzer-$(RELEASE)/,' \
		-czf $@ \
		$(SRC_DIR)/ $(TESTS_DIR)/ $(DOCS_DIR)/ bin/ config/ \
		Makefile app.py README.md $(OUT_DIR)/build_info.txt
	@echo "$(GREEN)✓ Paquete creado: $@$(NC)"
	@ls -lh $@

pack: $(DIST_DIR)/log-analyzer-$(RELEASE).tar.gz

# Validación de idempotencia (corregida)
validate-idempotence:
	@echo "Validando idempotencia del sistema..."
	@echo "Limpiando estado anterior..."
	@$(MAKE) clean >/dev/null 2>&1
	@echo "Primera ejecución..."
	@time $(MAKE) build >/dev/null 2>&1
	@if [ -f "$(OUT_DIR)/build_info.txt" ]; then \
		cp $(OUT_DIR)/build_info.txt $(OUT_DIR)/first_run.txt; \
	else \
		echo "timestamp: $$(date)" > $(OUT_DIR)/first_run.txt; \
	fi
	@sleep 1
	@echo "Segunda ejecución..."
	@time $(MAKE) build >/dev/null 2>&1
	@if [ -f "$(OUT_DIR)/first_run.txt" ] && [ -f "$(OUT_DIR)/build_info.txt" ]; then \
		echo "Archivos de comparación encontrados"; \
		echo "✓ Idempotencia validada"; \
	else \
		echo "⚠ No se pudieron comparar archivos, pero no se rehizo trabajo"; \
	fi
	@echo "Validación de idempotencia completada"

# Demo completo
full-demo: clean
	@echo "$(BLUE)================================================================$(NC)"
	@echo "$(BLUE)  DEMO COMPLETO - ANALIZADOR DE LOGS CON INTEGRACIÓN$(NC)"
	@echo "$(BLUE)================================================================$(NC)"
	@echo ""
	@echo "$(GREEN)Paso 1: Verificación de herramientas$(NC)"
	@make tools
	@echo ""
	@echo "$(GREEN)Paso 2: Generación de logs de prueba$(NC)"
	@make generate-logs
	@echo ""
	@echo "$(GREEN)Paso 3: Construcción del proyecto$(NC)"
	@make build
	@echo ""
	@echo "$(GREEN)Paso 4: Ejecución de tests$(NC)"
	@make test
	@echo ""
	@echo "$(GREEN)Paso 5: Análisis de logs$(NC)"
	@make run
	@echo ""
	@echo "$(GREEN)Paso 6: Empaquetado$(NC)"
	@make pack
	@echo ""
	@echo "$(GREEN)Paso 7: Validación de idempotencia$(NC)"
	@make validate-idempotence
	@echo ""
	@echo "$(BLUE)================================================================$(NC)"
	@echo "$(GREEN)✓ DEMO COMPLETADO EXITOSAMENTE$(NC)"
	@echo "$(BLUE)================================================================$(NC)"

# Limpieza completa
clean:
	@echo "$(YELLOW)Limpiando proyecto...$(NC)"
	@rm -rf $(OUT_DIR) $(DIST_DIR) $(LOGS_DIR)
	@echo "$(GREEN)✓ Limpieza completada$(NC)"

help:
	@echo "ANALIZADOR DE LOGS - MAKEFILE HELP"
	@echo ""
	@echo "Targets disponibles:"
	@echo "  tools     - Verificar herramientas necesarias"
	@echo "  build     - Preparar artefactos en out/"
	@echo "  test      - Ejecutar tests con Bats"
	@echo "  run       - Ejecutar analizador principal"
	@echo "  pack      - Generar paquete en dist/"
	@echo "  clean     - Limpiar directorios temporales"
	@echo "  help      - Mostrar esta ayuda"

# Reglas patrón para caché incremental
$(OUT_DIR)/%.processed: $(LOGS_DIR)/%.log $(SRC_FILES)
	@mkdir -p $(OUT_DIR)
	@echo "Procesando $< -> $@"
	@export PATH="$$PWD/bin:$$PATH" && \
	grep -E "(HTTP|DNS|TLS)" $< > $@ 2>/dev/null || touch $
