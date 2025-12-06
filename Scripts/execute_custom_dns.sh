#!/bin/bash
# Script para probar un archivo de configuración de BIND
# Uso: ./execute_custom_dns.sh ruta/del/archivo.conf [debug]
# Si se pasa "debug" como segundo parámetro, activa modo debug (-g -d 3)

set -e  # Termina si hay error

# Validar que se pasó al menos un parámetro
if [ -z "$1" ]; then
    echo "Uso: $0 ruta/del/archivo.conf [debug]"
    exit 1
fi

CONFIG_TEST="$1"
DEBUG_MODE="$2"

# Validar que el archivo existe
if [ ! -f "$CONFIG_TEST" ]; then
    echo "Error: archivo $CONFIG_TEST no encontrado"
    exit 1
fi

# Validar sintaxis del archivo
sudo named-checkconf "$CONFIG_TEST"
echo "[INFO] Sintaxis del archivo OK"

# Elegir cómo levantar BIND según parámetro opcional
if [ "$DEBUG_MODE" == "debug" ]; then
    echo "[INFO] Iniciando BIND en modo debug con $CONFIG_TEST"
    sudo named -c "$CONFIG_TEST" -g -d 3
else
    echo "[INFO] Iniciando BIND en modo normal con $CONFIG_TEST"
    sudo named -c "$CONFIG_TEST"
fi
