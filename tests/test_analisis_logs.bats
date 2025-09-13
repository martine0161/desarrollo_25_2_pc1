#!/usr/bin/env bats

@test "El script de análisis de logs HTTP funciona" {
  run bash src/analisis_logs.sh
  [ "$status" -eq 0 ]  # Verifica que el script se ejecute correctamente
  [ "${lines[0]}" == "200" ]  # Verifica que se haya encontrado un código 200
}
