#!/bin/bash
# ===============================================================
# Script para cargar un archivo de configuración DHCP
# Valida antes de aplicarlo
# ===============================================================

# Verificar que se ejecute como root
if [ "$EUID" -ne 0 ]; then
  echo "Debes ejecutar este script como root (sudo)."
  exit 1
fi

# Verificar que se pase un archivo como parámetro
if [ -z "$1" ]; then
  echo "Uso: sudo $0 /ruta/al/archivo/dhcpd.conf"
  exit 1
fi

CONF_FILE="$1"

# Verificar que el archivo exista
if [ ! -f "$CONF_FILE" ]; then
  echo "Archivo no encontrado: $CONF_FILE"
  exit 1
fi

echo "=== Validando configuración DHCP ==="

# Validar la sintaxis del archivo
dhcpd -t -cf "$CONF_FILE"
if [ $? -ne 0 ]; then
  echo "Configuración inválida. Revisa el archivo: $CONF_FILE"
  exit 1
else
  echo "Configuración válida."
fi

# Copiar el archivo validado a la ubicación oficial
cp "$CONF_FILE" /etc/dhcp/dhcpd.conf
echo "Archivo cargado en /etc/dhcp/dhcpd.conf"

# Reiniciar el servicio DHCP
echo "=== Reiniciando servicio DHCP ==="
systemctl restart dhcpd

# Verificar estado
systemctl status dhcpd
