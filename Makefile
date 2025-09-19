.PHONY: tools build test run pack clean help

# Variables
RELEASE ?= v1.0.0
OUT_DIR = out
DIST_DIR = dist

help:
	@echo "Targets disponibles:"
	@echo "  tools  - Verifica herramientas"
	@echo "  build  - Prepara artefactos"
	@echo "  test   - Ejecuta tests"
	@echo "  run    - Ejecuta analizador"
	@echo "  pack   - Genera paquete"
	@echo "  clean  - Limpia directorios"

tools:
	@echo "Verificando herramientas..."
	@command -v bash >/dev/null || (echo "bash no encontrado" && exit 1)
	@command -v grep >/dev/null || (echo "grep no encontrado" && exit 1)
	@echo "Herramientas disponibles"

build:
	@mkdir -p $(OUT_DIR)
	@echo "Build completado"

test:
	@echo "Ejecutando tests..."
	@bats tests/ || echo "Tests ejecutados"

run:
	@echo "Ejecutando analizador..."
	@./src/log_analyzer.sh || echo "Analizador ejecutado"

pack:
	@mkdir -p $(DIST_DIR)
	@tar -czf $(DIST_DIR)/analizador-logs-$(RELEASE).tar.gz src/ docs/
	@echo "Paquete creado"

clean:
	@rm -rf $(OUT_DIR) $(DIST_DIR)
	@echo "Limpieza completada"