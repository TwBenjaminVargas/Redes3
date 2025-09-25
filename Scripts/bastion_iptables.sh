#!/bin/bash
# Script de configuración de iptables para un host bastión sin salida.
# Objetivo:
# - Bloquear todo el tráfico por defecto.
# - Permitir únicamente SSH (22), HTTP (80) y HTTPS (443) entrante.
# - No permitir que el host inicie conexiones salientes.
# - Solo responder a conexiones ya establecidas.
# - Permitir tráfico local (loopback).

echo "[INFO] Configurando iptables para host bastión sin salida..."

### 1. Limpiar reglas existentes ###
iptables -F                # Elimina todas las reglas de la cadena 'filter' (INPUT, OUTPUT, FORWARD)
iptables -X                # Elimina todas las cadenas definidas por el usuario
iptables -t nat -F         # Limpia reglas de la tabla 'nat' (redirecciones, NAT)
iptables -t mangle -F      # Limpia reglas de la tabla 'mangle' (modificación avanzada de paquetes)
iptables -Z                # Pone en cero los contadores de paquetes y bytes

### 2. Definir políticas por defecto ###
iptables -P INPUT DROP     # Bloquea todo tráfico entrante si no coincide con una regla
iptables -P FORWARD DROP   # Bloquea todo tráfico reenviado (no somos router)
iptables -P OUTPUT DROP    # Bloquea todo tráfico saliente por defecto (sin salida)

### 3. Permitir loopback (localhost) ###
iptables -A INPUT -i lo -j ACCEPT   # Permite recibir tráfico desde la interfaz local (lo)
iptables -A OUTPUT -o lo -j ACCEPT  # Permite enviar tráfico hacia la interfaz local (lo)

### 4. Permitir conexiones entrantes ya establecidas o relacionadas ###
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# -m conntrack: usa el módulo de seguimiento de conexiones
# --ctstate ESTABLISHED: paquetes que forman parte de una conexión ya existente
# --ctstate RELATED: conexiones asociadas a otra (ej: FTP abre canal secundario)

### 5. Permitir nuevas conexiones entrantes en puertos específicos ###
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT
# -p tcp: aplica solo al protocolo TCP
# --dport 22: puerto de destino 22 (SSH)
# --ctstate NEW: solo conexiones nuevas
# -j ACCEPT: aceptar el tráfico

iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT
# Puerto 80 (HTTP)

iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT
# Puerto 443 (HTTPS)

### 6. Permitir salida solo para responder a conexiones ya establecidas ###
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# Permite respuestas de salida, pero no iniciar conexiones nuevas hacia afuera.

### (Opcional) Log de paquetes bloqueados ###
# iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "IPTables-Dropped: " --log-level 4
# -m limit --limit 5/min: evita que el log se sature (máx. 5 logs por minuto)
# --log-prefix: prefijo para identificar los logs
# --log-level 4: nivel de log de advertencia

echo "[OK] Reglas aplicadas. Verifica con: iptables -L -v"