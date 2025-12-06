#!/bin/bash

# Host definido en Nagios
HOST="server1"
SERVICE="SNMP Shutdown"
STATUS=2   # CRITICAL
MESSAGE="Trap SNMP Shutdown recibido"

# Pipe de comandos externos de Nagios
NAGIOS_CMD_FILE="/var/spool/nagios/cmd/nagios.cmd"
TIMESTAMP=$(date +%s)

# Enviar resultado pasivo
echo "[$TIMESTAMP] PROCESS_SERVICE_CHECK_RESULT;$HOST;$SERVICE;$STATUS;$MESSAGE" > $NAGIOS_CMD_FILE

# Logging opcional
echo "[$(date '+%Y-%m-%d %H:%M:%S')] CRITICAL enviado al servicio $SERVICE de $HOST" >> /var/log/snmp_shutdown_handler.log