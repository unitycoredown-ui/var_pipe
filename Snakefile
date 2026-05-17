import os

DATADIR = config.get("datadir", "")

def data_path(relative_or_absolute):
    if os.path.isabs(relative_or_absolute):
        return relative_or_absolute
    return os.path.join(DATADIR, relative_or_absolute)

if os.path.exists("/usr/local/bin/gff_fix.py"):
    GFF_FIX = "/usr/local/bin/gff_fix.py"
elif os.path.exists("gff_fix.py"):
    GFF_FIX = "./gff_fix.py"
else:
    raise FileNotFoundError("gff_fix.py not found")

reads1 = data_path(config.get("reads1", "Short_1.fastq"))
reads2 = data_path(config.get("reads2", "Short_2.fastq"))
ref    = data_path(config.get("ref",    "ref_gen.fna"))
gff    = data_path(config.get("gff",    "annot.gff"))
outdir = data_path(config.get("outdir", "results"))

rule all:
    input:
        f"{outdir}/trimmed_R1.fastq",
        f"{outdir}/trimmed_R2.fastq",
        f"{outdir}/fastp_report.html",
        f"{outdir}/fastp_report.json",
        f"{outdir}/fixed.gff",
        f"{outdir}/aligned.bam",
        f"{outdir}/aligned.bam.bai",
        f"{outdir}/variants.vcf",
        f"{outdir}/ref.amb"

rule fastp_trim:
    input:
        r1 = reads1,
        r2 = reads2
    output:
        r1   = f"{outdir}/trimmed_R1.fastq",
        r2   = f"{outdir}/trimmed_R2.fastq",
        html = f"{outdir}/fastp_report.html",
        json = f"{outdir}/fastp_report.json"
    log:
        f"{outdir}/logs/fastp_trim.log"
    shell:
        "fastp -i {input.r1} -I {input.r2} "
        "-o {output.r1} -O {output.r2} "
        "-h {output.html} -j {output.json} 2> {log}"

rule bwa_index:
    input:
        ref = ref
    output:
        sentinel = f"{outdir}/ref.amb"
    params:
        prefix = lambda w, output: os.path.splitext(output.sentinel)[0]
    log:
        f"{outdir}/logs/bwa_index.log"
    shell:
        "bwa index -p {params.prefix} {input.ref} 2> {log}"

rule gff_fix:
    input:
        gff = gff
    output:
        fixed = f"{outdir}/fixed.gff"
    log:
        f"{outdir}/logs/gff_fix.log"
    shell:
        "python3 {GFF_FIX} --input {input.gff} --output {output.fixed} 2> {log}"

rule map_sort:
    input:
        r1    = f"{outdir}/trimmed_R1.fastq",
        r2    = f"{outdir}/trimmed_R2.fastq",
        ref   = ref,
        index = f"{outdir}/ref.amb"
    output:
        bam = f"{outdir}/aligned.bam",
        bai = f"{outdir}/aligned.bam.bai"
    params:
        prefix = lambda w, input: os.path.splitext(input.index)[0]
    log:
        f"{outdir}/logs/map_sort.log"
    shell:
        "bwa mem {params.prefix} {input.r1} {input.r2} 2>> {log} | "
        "samtools sort -o {output.bam} - 2>> {log} && "
        "samtools index {output.bam} {output.bai} 2>> {log}"

rule variant_calling:
    input:
        bam = f"{outdir}/aligned.bam",
        ref = ref
    output:
        vcf = f"{outdir}/variants.vcf"
    log:
        f"{outdir}/logs/variant_calling.log"
    shell:
        "bcftools mpileup -f {input.ref} {input.bam} 2> {log} | "
        "bcftools call --ploidy 1 -mv -o {output.vcf} 2>> {log}"
