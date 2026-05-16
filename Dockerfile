FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    bwa \
    samtools \
    bcftools \
    fastp \
    python3 \
    && rm -rf /var/lib/apt/lists/*

COPY gff_fix.py /usr/local/bin/gff_fix.py
RUN chmod +x /usr/local/bin/gff_fix.py
COPY pipeline.sh /usr/local/bin/pipeline.sh
RUN chmod +x /usr/local/bin/pipeline.sh

WORKDIR /data
ENTRYPOINT ["pipeline.sh"]