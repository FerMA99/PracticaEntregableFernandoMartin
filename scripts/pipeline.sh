
# 1. PREPARACIÓN Y DESCARGA DE LAS MUESTRAS

echo "Descargando muestras..."

wget -N -i data/urls -P data/

echo "Descargando contaminantes..."
CONTAMINANTS_URL="https://tdido.eu/tmp/contaminants.fasta.gz"
# Descarga a la carpeta 'res', descomprime y filtra
bash scripts/download.sh "$CONTAMINANTS_URL" res yes "small nuclear"

echo "Indexando contaminantes..."

bash scripts/index.sh res/contaminants.fasta res/contaminants_idx


# 2. PROCESAMIENTO MERGE Y CUTADAPT

# Identificamos las muestras 
SAMPLE_IDS="C57BL_6NJ SPRET_EiJ"

# Merge
echo "Fusionando archivos fastq..."
for sid in $SAMPLE_IDS
do
    # Definimos cuál es el archivo que esperamos que se cree
    merged_file="out/merged/${sid}.fastq.gz"
    
    # Comprobamos si ya existe
    if [ -f "$merged_file" ]; then
        echo "El archivo fusionado para $sid ya existe. Saltando paso..."
    else
        # Si NO existe, llamamos al script auxiliar
        bash scripts/merge_fastqs.sh data out/merged "$sid"
    fi
done

mkdir -p out/trimmed
mkdir -p log/cutadapt  

# Cutadapt
echo "Ejecutando Cutadapt..."

for sid in $SAMPLE_IDS
do
    input_file="out/merged/${sid}.fastq.gz"
    output_file="out/trimmed/${sid}.trimmed.fastq.gz"
    
    # Comprobamos si el archivo de salida existe
    if [ -f "$output_file" ]; then
        echo "Aviso: El archivo $output_file ya existe. Saltando paso..."
    else
        # Si no existe, ejecutamos el comando
        cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed \
            -o "$output_file" "$input_file" > log/cutadapt/${sid}.log
    fi
done


# 3. ALINEAMIENTO con STAR


echo "Ejecutando STAR..."

# Buscamos archivos que terminen en .trimmed.fastq.gz
for fname in out/trimmed/*.trimmed.fastq.gz
do
    sid=$(basename "$fname" .trimmed.fastq.gz)
    
    mkdir -p out/star/$sid

    output_expected="out/star/$sid/Unmapped.out.mate1"

    # COMPROBACIÓN DE SI YA EXISTE EL ARCHIVO
    if [ -f "$output_expected" ]; then
        echo "La muestra $sid ya ha sido procesada por STAR. Saltando paso..."
    else
        echo "Ejecutando STAR para $sid..."
   
	 STAR --runThreadN 4 --genomeDir res/contaminants_idx \
		 --outReadsUnmapped Fastx --readFilesIn "$fname" \
       		 --readFilesCommand gunzip -c --outFileNamePrefix out/star/$sid/
   fi	
done 


# 4. GENERACIÓN DEL REPORTE FINAL (LOG)


echo "Generando reporte final..."
LOG_FILE="log/pipeline.log" 
echo "Pipeline Report" > $LOG_FILE

for sid in $SAMPLE_IDS
do
    echo "--------------------------------" >> $LOG_FILE
    echo "Sample: $sid" >> $LOG_FILE
    
    echo "--- Cutadapt ---" >> $LOG_FILE
    grep "Reads with adapters" log/cutadapt/${sid}.log >> $LOG_FILE
    grep "Total basepairs" log/cutadapt/${sid}.log >> $LOG_FILE
    
    echo "--- STAR ---" >> $LOG_FILE
    grep "Uniquely mapped reads %" out/star/${sid}/Log.final.out >> $LOG_FILE
    grep "% of reads mapped to multiple loci" out/star/${sid}/Log.final.out >> $LOG_FILE
    grep "% of reads mapped to too many loci" out/star/${sid}/Log.final.out >> $LOG_FILE
done

echo "Done! Pipeline finished completely."

