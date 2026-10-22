#############################################################################
#Title:    SV_DownloadResources
#Function:
# * Download the functional annotation resources used for SV annotation
# * (gene models, gene dosage sensitivity/constraint, population SV
# *  frequencies, clinical SVs, regulatory elements and repeats).
# * Optionally download the FAVOR database (CSV) of chromosomes from
# * Harvard Dataverse, which provides the per-base FAVOR scores
# * summarized over each SV.
#Usage:
# * Rscript SV_DownloadResources.R                    # SV resources only
# * Rscript SV_DownloadResources.R Essential 22       # + FAVOR Essential DB chr22
# * Rscript SV_DownloadResources.R Full 1:22          # + FAVOR Full DB chr1-22
#Author:   Hufeng Zhou
#Time:     Oct 21st 2026
#############################################################################

args <- commandArgs(TRUE)

favor_db <- if(length(args) >= 1) args[1] else NA
favor_chr <- if(length(args) >= 2) eval(parse(text = args[2])) else NULL

library(jsonlite)
source("config_SV.R")

raw_dir <- file.path(resource_dir, "raw")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

##########################################################################
### Step 1 (SV annotation resources, GRCh38)
##########################################################################
URLs <- c(
  ## GENCODE gene models (genes, transcripts, exons, CDS, UTR)
  gencode       = "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_46/gencode.v46.basic.annotation.gtf.gz",
  ## gnomAD v4.1 gene constraint (pLI, LOEUF)
  gnomad_constraint = "https://storage.googleapis.com/gcp-public-data--gnomad/release/4.1/constraint/gnomad.v4.1.constraint_metrics.tsv",
  ## ClinGen dosage sensitivity curation (haploinsufficiency/triplosensitivity)
  clingen_gene   = "https://ftp.clinicalgenome.org/ClinGen_gene_curation_list_GRCh38.tsv",
  clingen_region = "https://ftp.clinicalgenome.org/ClinGen_region_curation_list_GRCh38.tsv",
  ## Collins et al. 2022 (Cell) pHaplo/pTriplo dosage sensitivity scores
  rcnv_dosage   = "https://zenodo.org/records/6347673/files/Collins_rCNV_2022.dosage_sensitivity_scores.tsv.gz",
  ## gnomAD-SV v4.1 population SV frequencies
  gnomad_sv     = "https://storage.googleapis.com/gcp-public-data--gnomad/release/4.1/genome_sv/gnomad.v4.1.sv.sites.bed.gz",
  ## dbVar/ClinVar clinical pathogenic or likely pathogenic SVs
  dbvar_patho   = "https://ftp.ncbi.nlm.nih.gov/pub/dbVar/data/Homo_sapiens/by_assembly/GRCh38/vcf/GRCh38.variant_call.clinical.pathogenic_or_likely_pathogenic.vcf.gz",
  ## ENCODE SCREEN cCREs (Registry V4)
  encode_ccre   = "https://downloads.wenglab.org/Registry-V4/GRCh38-cCREs.bed",
  ## UCSC segmental duplications and RepeatMasker
  segdup        = "https://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/genomicSuperDups.txt.gz",
  rmsk          = "https://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/rmsk.txt.gz"
)

for(kk in seq_along(URLs))
{
  dest <- file.path(raw_dir, basename(URLs[kk]))
  print(paste0("Downloading ", names(URLs)[kk], ": ", URLs[kk]))
  status <- system(paste0("wget -q -c -O ", dest, " ", URLs[kk]))
  if(status != 0) stop(paste0("Download failed: ", URLs[kk]))
}

write.csv(data.frame(resource = names(URLs), url = URLs, file = basename(URLs),
                     downloaded = as.character(Sys.Date())),
          file.path(resource_dir, "resource_versions.csv"), row.names = FALSE, quote = FALSE)

##########################################################################
### Step 2 (Optional: FAVOR database from Harvard Dataverse)
##########################################################################
if(!is.na(favor_db))
{
  doi <- switch(favor_db,
                Essential = "doi:10.7910/DVN/1VGTJI",
                Full      = "doi:10.7910/DVN/KFUBKG",
                stop("FAVOR database should be Essential or Full"))
  if(is.null(favor_chr)) favor_chr <- 1:22
  if(is.na(favor_db_path)) stop("Please set favor_db_path in config_SV.R")
  dir.create(favor_db_path, recursive = TRUE, showWarnings = FALSE)

  ## list the files of the dataset through the Dataverse API
  ds <- fromJSON(paste0("https://dataverse.harvard.edu/api/datasets/:persistentId/?persistentId=", doi))
  files <- data.frame(label = ds$data$latestVersion$files$label,
                      id = ds$data$latestVersion$files$dataFile$id,
                      size = ds$data$latestVersion$files$dataFile$filesize)

  for(chr in favor_chr)
  {
    pattern <- paste0("^(chr|FAVOR\\.FullDB\\.Chr)", chr, "\\.tar\\.gz$")
    fl <- files[grepl(pattern, files$label), ]
    if(nrow(fl) != 1) stop(paste0("Could not find FAVOR ", favor_db, " DB file of chr", chr))
    print(paste0("Downloading FAVOR ", favor_db, " DB chr", chr, " (", round(fl$size/1e9, 1), " GB)"))
    dest <- file.path(favor_db_path, fl$label)
    system(paste0("wget -q -c -O ", dest, " https://dataverse.harvard.edu/api/access/datafile/", fl$id))
    ## extract chr{CHR}_{k}.csv into favor_db_path, then remove the archive
    system(paste0("tar -xzf ", dest, " -C ", favor_db_path, " --transform='s#.*/##' && rm ", dest))
  }
}

print("Download finished")
