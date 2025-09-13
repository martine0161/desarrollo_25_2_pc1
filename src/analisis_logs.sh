# Analiza los logs HTTP y muestra la cantidad de códigos de estado

LOG_FILE="access.log"

# Verifica si el archivo de log existe
if [[ ! -f "$LOG_FILE" ]]; then
  echo "No se encuentra el archivo de logs: $LOG_FILE"
  exit 1
fi

# Filtra los códigos de estado HTTP
grep -o 'HTTP/1.1" [0-9]\{3\}' $LOG_FILE | sort | uniq -c

