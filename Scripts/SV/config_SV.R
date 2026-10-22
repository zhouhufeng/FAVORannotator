#############################################################################
#Title:    config_SV
#Function:
# * Configuration of the FAVORannotator SV (structural variant) pipeline
# * All paths can be overwritten here; the scripts source this file.
#Author:   Hufeng Zhou
#Time:     Oct 21st 2026
#############################################################################

### directory holding the downloaded and pre-processed SV annotation resources
### (~2GB downloaded, ~1GB processed .rds; keep it off the home directory)
resource_dir <- "/n/holystore01/LABS/xlin/Lab/zhouhufeng/Works/homebak/FAVOR_SV/resources"

### FAVOR database (CSV version, Essential or Full DB from Harvard Dataverse)
### files are named chr{CHR}_{k}.csv, as extracted from the Dataverse tar.gz files
### set to NA to skip the FAVOR per-base score aggregation over each SV
favor_db_path <- "/n/holystore01/LABS/xlin/Lab/xihao_zilin/FAVORDB"

### FAVOR database split information (position range of each chr{CHR}_{k}.csv)
file_DBsplit <- "../SQL/FAVORdatabase_chrsplit.csv"

### output directory for annotation tables (CSV copy of what goes into the aGDS)
output_path <- "./SVAnnotation"

### name of the annotation node created under annotation/info in the aGDS
sv_anno_node <- "FunctionalAnnotationSV"

### GDS INFO field names (the first one found in annotation/info is used)
info_svtype <- c("SVTYPE")
info_end    <- c("END")
info_svlen  <- c("SVLEN")
info_chr2   <- c("CHR2")
info_end2   <- c("END2", "POS2")

### annotation parameters
promoter_upstream   <- 1000    # bp upstream of a TSS counted as promoter
breakpoint_window   <- 50      # bp around INS/BND breakpoints used for overlaps/FAVOR scores
reciprocal_overlap  <- 0.5     # minimal reciprocal overlap to match DEL/DUP/INV/CNV to a reference SV
insertion_distance  <- 100     # maximal distance to match INS/BND to a reference SV
favor_max_span      <- 1e7     # SVs longer than this are summarized over breakpoints only

### FAVOR per-base scores summarized (max and mean) over each SV
### (only the columns present in the selected FAVOR database are used)
favor_score_columns <- c("apc_conservation_v2", "apc_epigenetics_active", "apc_epigenetics_repressed",
                         "apc_epigenetics_transcription", "apc_local_nucleotide_diversity_v3",
                         "apc_mappability", "apc_micro_rna", "apc_mutation_density",
                         "apc_protein_function_v3", "apc_proximity_to_coding_v2",
                         "apc_proximity_to_tsstes", "apc_transcription_factor",
                         "cadd_phred", "linsight", "fathmm_xf")
