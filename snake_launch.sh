snakemake \
  --executor kubernetes \
  --container-image var_pipe \
  --default-resources mem_mb=8096 threads=4 \
  --jobs 4 \
  --shared-fs-usage input-output \
  --default-storage-provider fs \
  --default-storage-prefix "$HOME/snakemake/" \