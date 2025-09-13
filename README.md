# Proyecto 25_2_PC1: Analizador de logs de red con seguridad integrada

Este proyecto consiste en crear un script en Bash para analizar logs de red (HTTP requests, DNS queries, TLS errors) y garantizar la seguridad utilizando herramientas como `curl`, `dig`, `ss`, y validación de certificados TLS.

## Requisitos
- Bash
- Makefile (para automatización)
- Herramientas de red (`curl`, `dig`, `ss`)

## Estructura
- `src/`: Scripts de análisis de logs
- `tests/`: Pruebas automatizadas con Bats
- `docs/`: Documentación

## Ejecución
1. Clonar el repositorio.
2. Ejecutar `make test` para correr las pruebas.
