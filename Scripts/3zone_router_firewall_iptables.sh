#!/bin/bash
set -e

# ----------------------------
# CONFIG
# ----------------------------
SOURCE_IFACE="enp0s3"        # Interfaz por donde llegan los paquetes (WAN/public)
DEST_IFACE="enp0s8"          # Interfaz hacia la DMZ / red interna
DEST_IP_REAL="192.168.10.11" # IP del servidor interno al que se le hará DNAT para 80/443/22
DEST_NET="192.168.10.0/24"   # Red de la DMZ (usada para reglas de bloqueo)
LAN_IFACE="enp0s9"          # Interfaz hacia la red de usuarios (LAN)
LAN_NET="192.168.20.0/24"   # Red de usuarios LAN

# ----------------------------
# LIMPIEZA (estado inicial)
# ----------------------------
echo "[*] Limpiando reglas previas..."
iptables -F                  # Borra reglas de la tabla filter (INPUT/FORWARD/OUTPUT)
iptables -t nat -F           # Borra reglas de la tabla nat (PREROUTING/POSTROUTING/OUTPUT)
iptables -X                  # Elimina cadenas definidas por el usuario (si existen)

# ----------------------------
# FUNCION: BLOQUEAR TODO HACIA LA DMZ 
# ----------------------------
# Esta sección aplica capa para asegurar que nada de WAN alcance la DMZ:

echo "[*] Aplicando bloqueo a la DMZ y LAN (DROP total) ..."

# DNAT hacia loopback: cambia destino en PREROUTING para que apunte al loopback local
iptables -t nat -A PREROUTING -i $SOURCE_IFACE -d $DEST_NET -j DNAT --to-destination 127.0.0.4
iptables -t nat -A PREROUTING -i $SOURCE_IFACE -d $LAN_NET -j DNAT --to-destination 127.0.0.4

# ----------------------------
# REGLAS PARA NAT SELECTIVO (solo 80, 443, 22)
# ----------------------------
echo "[*] Configurando DNAT por servicio (80, 443, 22) hacia $DEST_IP_REAL ..."

# HTTP
iptables -t nat -A PREROUTING -i $SOURCE_IFACE -p tcp --dport 80 -j DNAT --to-destination ${DEST_IP_REAL}:80

# HTTPS
iptables -t nat -A PREROUTING -i $SOURCE_IFACE -p tcp --dport 443 -j DNAT --to-destination ${DEST_IP_REAL}:443

# SSH
iptables -t nat -A PREROUTING -i $SOURCE_IFACE -p tcp --dport 22 -j DNAT --to-destination ${DEST_IP_REAL}:22

# ----------------------------
# FORWARD: permitir solo esos servicios
# ----------------------------
echo "[*] Configurando FORWARD para permitir solo 80/443/22 hacia $DEST_IP_REAL ..."

# Permitir nuevas conexiones entrantes hacia el servidor para cada puerto
iptables -A FORWARD -i $SOURCE_IFACE -o $DEST_IFACE -p tcp -d $DEST_IP_REAL --dport 80  -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $SOURCE_IFACE -o $DEST_IFACE -p tcp -d $DEST_IP_REAL --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $SOURCE_IFACE -o $DEST_IFACE -p tcp -d $DEST_IP_REAL --dport 22  -m state --state NEW,ESTABLISHED -j ACCEPT

# Permitir tráfico de respuesta del servidor hacia el cliente (ESTABLISHED)
iptables -A FORWARD -i $DEST_IFACE -o $SOURCE_IFACE -p tcp -s $DEST_IP_REAL --sport 80  -m state --state ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $DEST_IFACE -o $SOURCE_IFACE -p tcp -s $DEST_IP_REAL --sport 443 -m state --state ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $DEST_IFACE -o $SOURCE_IFACE -p tcp -s $DEST_IP_REAL --sport 22  -m state --state ESTABLISHED -j ACCEPT

# LAN -> DMZ (solo puertos 22, 80 y 443)
iptables -A FORWARD -i $LAN_IFACE -o $DEST_IFACE -s $LAN_NET -d $DEST_IP_REAL -p tcp --dport 22  -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $LAN_IFACE -o $DEST_IFACE -s $LAN_NET -d $DEST_IP_REAL -p tcp --dport 80  -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $LAN_IFACE -o $DEST_IFACE -s $LAN_NET -d $DEST_IP_REAL -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT

# DMZ -> LAN (respuestas de esos mismos servicios)
iptables -A FORWARD -i $DEST_IFACE -o $LAN_IFACE -s $DEST_IP_REAL -d $LAN_NET -p tcp --sport 22  -m state --state ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $DEST_IFACE -o $LAN_IFACE -s $DEST_IP_REAL -d $LAN_NET -p tcp --sport 80  -m state --state ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $DEST_IFACE -o $LAN_IFACE -s $DEST_IP_REAL -d $LAN_NET -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT

# Permitir LAN -> WAN
iptables -A FORWARD -i $LAN_IFACE -o $SOURCE_IFACE -s $LAN_NET -j ACCEPT
# Respuestas WAN → LAN
iptables -A FORWARD -i $SOURCE_IFACE -o $LAN_IFACE -d $LAN_NET -m state --state ESTABLISHED,RELATED -j ACCEPT

# ----------------------------
# MASQUERADE (SNAT dinámico) en la salida hacia WAN
# ----------------------------
echo "[*] Configurando MASQUERADE en la interfaz WAN ($SOURCE_IFACE) ..."
# IMPORTANTE: las respuestas que salen al cliente deben parecer origen del firewall (WAN IP).
iptables -t nat -A POSTROUTING -o $SOURCE_IFACE -j MASQUERADE

echo "[*] Configuración completada."
