#!/bin/bash
# Script de chequeo HTTP remoto simple para Nagios
# Uso: check_httpd_remote.sh <IP o hostname>

HOST=$1

if [ -z "$HOST" ]; then
  echo "UNKNOWN - No se especificó el host"
  exit 3
fi

# Prueba de conexión HTTP
if curl -s --head "http://$HOST" | grep "200 OK" > /dev/null; then
  echo "OK - HTTPD responde correctamente en $HOST"
  exit 0
else
  echo "CRITICAL - HTTPD no responde en $HOST"
  exit 2
fi
