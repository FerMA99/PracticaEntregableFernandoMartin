# This script should download the file specified in the first argument ($1),
# place it in the directory specified in the second argument ($2),
# and *optionally*:
# - uncompress the downloaded file with gunzip if the third
#   argument ($3) contains the word "yes"
# - filter the sequences based on a word contained in their header lines:
#   sequences containing the specified word in their header should be **excluded**
#
# Example of the desired filtering:
#
#   > this is my sequence
#   CACTATGGGAGGACATTATAC
#   > this is my second sequence
#   CACTATGGGAGGGAGAGGAGA
#   > this is another sequence
#   CCAGGATTTACAGACTTTAAA
#
#   If $4 == "another" only the **first two sequence** should be output

# Asignamos nombres a los argumentos para que el codigo sea legible

url=$1
directory=$2
uncompress=$3
filter_word=$4

# 1. Descargar el archivo -P define el directorio, -N evita volver a descargar si ya existe
wget -P "$directory" -nc "$url"

# Obtenemos el nombre del archivo descargado
filename=$(basename "$url")
filepath="${directory}/${filename}"

# 2. Descomprimir si el tercer argumento es "yes"
if [ "$uncompress" == "yes" ]; then
    echo "Descomprimiendo $filepath..."
    gunzip -f "$filepath"
    
    # Actualizamos la variable filepath porque al descomprimir se va el .gz
   
    filepath="${filepath%.gz}"
fi

# 3. Filtrar secuencias si hay un cuarto argumento
if [ -n "$filter_word" ]; then
    echo "Filtrando secuencias que contienen '$filter_word' en $filepath..."
    
 
    # Guardamos en un temporal y luego renombramos
    seqkit grep -v -n -p "$filter_word" "$filepath" > "${filepath}.tmp"
    
    # Reemplazamos el archivo original con el filtrado
    mv "${filepath}.tmp" "$filepath"
fi

#COMPROBACIÓN MD5

# URL del archivo .md5 (asumimos que es la url original + .md5)
md5_url="${url}.md5"

echo "Verificando integridad MD5 para $filename..."

# 1. Calculamos el hash del archivo que acabamos de bajar (local)
local_md5=$(md5sum "$filepath" | awk '{print $1}')

# 2. Obtenemos el hash del servidor (remoto) SIN descargar el archivo
remote_md5=$(curl -s "$md5_url" | awk '{print $1}')

# Si curl falla o no hay md5 remoto, remote_md5 estará vacío. Controlamos eso:
if [ -z "$remote_md5" ]; then
    echo "Advertencia: No se encontró archivo .md5 remoto o falló la conexión."
else
    # 3. Comparamos
    if [ "$local_md5" == "$remote_md5" ]; then
        echo "Check MD5: CORRECTO ($local_md5)"
    else
        echo "ERROR CRÍTICO: El archivo está corrupto."
        echo "Local: $local_md5 vs Remoto: $remote_md5"
        exit 1
    fi
fi
