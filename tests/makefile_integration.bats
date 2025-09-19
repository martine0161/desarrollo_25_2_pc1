#!/usr/bin/env bats

@test "Makefile existe y tiene targets principales" {
    [ -f "Makefile" ]
    run make help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "tools" ]]
    [[ "$output" =~ "build" ]]
    [[ "$output" =~ "test" ]]
    [[ "$output" =~ "run" ]]
}

@test "target tools verifica herramientas correctamente" {
    run make tools
    [ "$status" -eq 0 ]
    [[ "$output" =~ "herramientas disponibles" ]]
}

@test "target build crea directorio out" {
    run make build
    [ "$status" -eq 0 ]
    [ -d "out" ]
}

@test "target clean elimina directorios temporales" {
    mkdir -p out dist
    run make clean
    [ "$status" -eq 0 ]
    [ ! -d "out" ]
    [ ! -d "dist" ]
}