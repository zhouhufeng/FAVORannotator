#!/bin/bash
#############################################################################
# Submit the FAVORannotator SV pipeline for per-chromosome SV GDS files
# Usage: bash submitJobs_SV.sh /path/to/SV.chr{CHR}.gds
#        ({CHR} is replaced by 1..22; GDS files are built by convertSVVCFtoGDS.R)
# Run SV_DownloadResources.R and SV_PrepareResources.R once beforehand.
#
# Job sizing measured on 1KGP chr22 (2,643 SVs, 3,202 samples, 3 FAVOR DB files):
#   2.7 min, 7.6 GB MaxRSS, single-threaded. Reading one FAVOR DB file
#   (chr{CHR}_{k}.csv, ~22 GB) took 1-8.5 min depending on storage load, so the time limit is set
#   from the number of FAVOR DB files of each chromosome.
#############################################################################
GDS_PATTERN=$1
DB_SPLIT=../SQL/FAVORdatabase_chrsplit.csv

for CHR in $(seq 1 22); do
  GDS=${GDS_PATTERN//\{CHR\}/$CHR}
  NFILE=$(awk -F, -v c=$CHR '$1==c' $DB_SPLIT | wc -l)
  MINUTES=$(( NFILE * 6 + 10 ))
  sbatch -J SVanno_chr${CHR} -p shared -c 1 -t ${MINUTES} --mem=24G -o SVanno_chr${CHR}.%j.log \
    --wrap="module load R/4.3.1-fasrc01; Rscript FAVORannotatorSV.R ${GDS} ${CHR}"
done
