#!/usr/bin/env bats

@test "script principal existe y es ejecutable" {
    [ -f "src/log_analyzer.sh" ]
    [ -x "src/log_analyzer.sh" ]
}

@test "variables de entorno son procesadas correctamente" {
    export LOG_DIRECTORY="/tmp"
    export OUTPUT_FORMAT="json"
    run ./src/log_analyzer.sh --validate-config
    [ "$status" -eq 0 ]
}

@test "herramientas requeridas están disponibles" {
    run bash -c 'command -v grep && command -v sed && command -v awk'
    [ "$status" -eq 0 ]
}

@test "script maneja directorio inexistente gracefully" {
    export LOG_DIRECTORY="/directorio/inexistente"
    run ./src/log_analyzer.sh --validate-config
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error" ]]
}

@test "script muestra ayuda correctamente" {
    run ./src/log_analyzer.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Uso:" ]]
}

@test "validación de formato de salida funciona" {
    export OUTPUT_FORMAT="formato_invalido"
    export LOG_DIRECTORY="/tmp"
    run ./src/log_analyzer.sh --validate-config
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Formato no válido" ]]
}