# This script should merge all files from a given sample (the sample id is
# provided in the third argument ($3)) into a single file, which should be
# stored in the output directory specified by the second argument ($2).
#
# The directory containing the samples is indicated by the first argument ($1).


# Asignamos los argumentos a variables legibles
input_dir=$1
output_dir=$2
sample_id=$3

# Creamos el directorio de salida si no existe
mkdir -p "$output_dir"

echo "Fusionando archivos para la muestra: $sample_id..."

cat "${input_dir}/${sample_id}"*.fastq.gz > "${output_dir}/${sample_id}.fastq.gz"
