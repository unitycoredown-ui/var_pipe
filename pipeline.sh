#!/bin/bash
set -euo pipefail

show_help() {
    cat << EOF

Обязательные параметры:
  -1    Файл с прямыми прочтениями (FASTQ)
  -2    Файл с обратными прочтениями (FASTQ)
  -r    Референсный геном (FASTA)
  -g    Аннотация генома (GFF)
  -o    Папка для сохранения результатов

Пример запуска через Docker:
  docker run --rm \\
      -v full/path/to/data:/data \\
      var_pipe \\
      -1 /data/Short_1.fastq \\
      -2 /data/Short_2.fastq \\
      -r /data/ref_gen.fna \\
      -g /data/annot.gff \\
      -o /data/results

Примечание: все пути должны начинаться с /data/).
EOF
    exit 1
}

# Проверка на --help или -h
if [[ $# -eq 0 ]]; then
    show_help
fi
for arg in "$@"; do
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
        show_help
    fi
done

# Парсинг аргументов
while getopts "1:2:r:g:o:h" opt; do
    case $opt in
        1) reads1="$OPTARG" ;;
        2) reads2="$OPTARG" ;;
        r) ref="$OPTARG" ;;
        g) gff="$OPTARG" ;;
        o) outdir="$OPTARG" ;;
        h) show_help ;;
        *) show_help ;;
    esac
done

if [ -z "${reads1:-}" ] || [ -z "${reads2:-}" ] || [ -z "${ref:-}" ] || [ -z "${gff:-}" ] || [ -z "${outdir:-}" ]; then
    usage
fi

for f in "$reads1" "$reads2" "$ref" "$gff"; do
    if [ ! -f "$f" ]; then
        echo "ERROR: File $f not found" >&2
        exit 1
    fi
done

mkdir -p "$outdir"
cd "$outdir"

echo "[1/7] Тримминг чтений"
fastp -i "$reads1" -I "$reads2" \
      -o trimmed_R1.fastq -O trimmed_R2.fastq \
      -h fastp_report.html -j fastp_report.json

echo "[2/7] Индексация"
bwa index "$ref"

echo "[3/7] Исправление аннотации"
python3 /usr/local/bin/gff_fix.py --input "$gff" --output fixed.gff

echo "[4/7] Картирование + сортировка..."
bwa mem "$ref" trimmed_R1.fastq trimmed_R2.fastq | \
    samtools sort -o aligned.bam -

samtools index aligned.bam

echo "[5/7] Вызов вариантов"
bcftools mpileup -f "$ref" aligned.bam | \
    bcftools call --ploidy 1 -mv -o variants.vcf

echo "=== Готово! Результаты в $outdir ==="