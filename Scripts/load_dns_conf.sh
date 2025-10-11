#!/bin/bash
# Script para cargar configuración de DNS en Fedora/RHEL
# Uso: ./cargar_dns.sh ruta/del/archivo.conf

set -e  # Termina si hay error

# Validar que el usuario pasó un parámetro
if [ -z "$1" ]; then
    echo "Uso: $0 ruta/del/archivo.conf"
    exit 1
fi

CONFIG_ORIG="$1"              # Archivo que se quiere cargar
CONFIG_DEST="/etc/named.conf" # Destino donde BIND espera la config

# Validar que el archivo de origen existe
if [ ! -f "$CONFIG_ORIG" ]; then
    echo "Error: archivo $CONFIG_ORIG no encontrado"
    exit 1
fi

# Validar sintaxis antes de sobrescribir
sudo named-checkconf "$CONFIG_ORIG"
echo "[INFO] Sintaxis del archivo OK"

# 5Copiar archivo al destino
sudo cp "$CONFIG_ORIG" "$CONFIG_DEST"
sudo chown root:named "$CONFIG_DEST"
sudo chmod 644 "$CONFIG_DEST"
echo "[INFO] Archivo copiado como /etc/named.conf"

# Reiniciar servicio BIND
sudo systemctl restart named
echo "[INFO] Servicio named reiniciado correctamente"
