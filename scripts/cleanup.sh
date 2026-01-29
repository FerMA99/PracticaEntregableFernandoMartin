# Función de ayuda para mostrar uso
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "Uso: bash scripts/cleanup.sh [datos] [recursos] [salida] [registros]"
    echo "Si no se dan argumentos, SE BORRA TODO."
    exit 0
fi

# Si el número de argumentos  es 0, definimos targets como TODO
if [ $# -eq 0 ]; then
    echo "Sin argumentos: Modo limpieza TOTAL activado."
    targets="datos recursos salida registros"
else
    # Si hay argumentos, usamos todos los que se pasaron 
    targets="$@"
fi

# Iteramos sobre cada objetivo solicitado
for target in $targets
do
    case $target in
        "datos"|"data")
            echo "Borrando carpeta data/..."
            rm -rf data/
            ;;
        "recursos"|"res")
            echo "Borrando carpeta res/..."
            rm -rf res/
            ;;
        "salida"|"out")
            echo "Borrando carpeta out/..."
            rm -rf out/
            ;;
        "registros"|"log"|"logs")
            echo "Borrando carpeta log/..."
            rm -rf log/
            rm -f Log.out  # Borra logs sueltos de STAR si los hubiera
            ;;
        *)
            echo "Aviso: Argumento '$target' desconocido. Ignorando."
            ;;
    esac
done

echo "Limpieza completada."
