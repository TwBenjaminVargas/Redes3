#!/bin/bash
# Indica que el script debe ejecutarse usando /bin/bash como intérprete

# ----------------------------
# Configuración de parámetros
# ----------------------------
ORIGEN="$1"          # $1 → primer argumento: directorio que se quiere respaldar (origen)
DESTINO="$2"         # $2 → segundo argumento: carpeta donde se guardarán los backups (destino)
RETENCION="$3"       # $3 → tercer argumento: cantidad de días que se conservarán los backups
# ----------------------------

# Validar que se hayan pasado los 3 parámetros requeridos
# -z "$VAR" → evalúa si la variable está vacía
# || → operador OR, si alguna variable está vacía se cumple la condición
# $0 → nombre del script, se usa para mostrar cómo debe ejecutarse
if [[ -z "$ORIGEN" || -z "$DESTINO" || -z "$RETENCION" ]]; then
    echo "Uso: $0 <directorio_origen> <directorio_backup> <dias_retencion>"
    exit 1    # exit 1 → salir con error, indicando que no se ejecutó correctamente
fi

# Crear nombre de archivo con la fecha actual
FECHA=$(date +%F)               # date +%F → devuelve la fecha en formato AAAA-MM-DD
ARCHIVO_BACKUP="backup_${FECHA}.tar.gz"   # nombre del backup comprimido con fecha

# Comprimir los datos del directorio origen
# tar:
#   -c → crear un nuevo archivo tar
#   -z → comprimir con gzip
#   -f → especificar el nombre del archivo de salida
#   -C "$ORIGEN" → empaquetar solo el contenido de un directorio(No la ruta completa)
#   . → indica que se empaqueta todo lo que está dentro del directorio
tar -czf "/tmp/$ARCHIVO_BACKUP" -C "$ORIGEN" .

# Copiar el backup comprimido al directorio de destino con rsync
# rsync:
#   -a → "archive mode": copia recursiva, mantiene permisos, dueños, grupos, fechas y enlaces simbólicos
#   -v → "verbose": muestra en pantalla qué archivos está copiando, útil para monitorear
rsync -av "/tmp/$ARCHIVO_BACKUP" "$DESTINO/"

# Borrar el archivo temporal generado en /tmp para liberar espacio
# rm:
#   elimina el archivo que se indica
rm "/tmp/$ARCHIVO_BACKUP"

# Eliminar backups antiguos según la retención definida
# find:
#   "$DESTINO" → carpeta donde buscar los backups
#   -name "backup_*.tar.gz" → busca archivos cuyo nombre empiece con "backup_" y terminen en .tar.gz
#   -type f → asegura que solo sean archivos (no carpetas)
#   -mtime +"$RETENCION" → selecciona archivos con más de X días de antigüedad
#   -exec rm {} \; → ejecuta rm sobre cada archivo encontrado para borrarlo
find "$DESTINO" -name "backup_*.tar.gz" -type f -mtime +"$RETENCION" -exec rm {} \;

# Mensaje final de confirmación en la terminal
echo "Backup completado: $ARCHIVO_BACKUP"

# ----------------------------
# Ejemplo de uso del script:
# ./backup.sh /home/usuario/Documentos /mnt/backups 7
#   - Respaldará la carpeta /home/usuario/Documentos
#   - Guardará el backup en /mnt/backups
#   - Mantendrá solo los últimos 7 días de backups
# ----------------------------
