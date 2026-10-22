#############################################################################
#Title:    FAVORannotatorSV
#Function:
# * Build the aGDS file of structural variants (SVs) through performing
# * functional annotation of each SV in the GDS file, and storing the
# * annotation table in annotation/info/FunctionalAnnotationSV.
# * Annotations: SV type/size, gene consequences (GENCODE), dosage
# * sensitivity/constraint of affected genes (ClinGen, pHaplo/pTriplo,
# * gnomAD pLI/LOEUF), population frequency (gnomAD-SV), clinical SVs
# * (ClinVar/dbVar), regulatory elements (ENCODE cCREs), segmental
# * duplications/repeats, and FAVOR per-base scores (Harvard Dataverse
# * FAVOR database) summarized over each SV.
#Usage:
# * Rscript FAVORannotatorSV.R input.gds [chr]
# *   chr: optional, annotate only the SVs on this chromosome
#Author:   Hufeng Zhou
#Time:     Oct 21st 2026
#############################################################################

args <- commandArgs(TRUE)
### mandatory
gds.file <- args[1]
print(paste0("gds.file:  ", gds.file))

### optional
chr <- if(length(args) >= 2) sub("^chr", "", args[2]) else NA
print(paste0("chr:  ", chr))

### R package
suppressPackageStartupMessages({
  library(gdsfmt)
  library(SeqArray)
  library(data.table)
  library(GenomicRanges)
})
source("config_SV.R")
source("SV_Functions.R")

start_time <- Sys.time()
dir.create(output_path, recursive = TRUE, showWarnings = FALSE)
cfg <- list(info_svtype = info_svtype, info_end = info_end, info_svlen = info_svlen,
            info_chr2 = info_chr2, info_end2 = info_end2)

##########################################################################
### Step 1 (Read SVs from GDS)
##########################################################################
genofile <- seqOpen(gds.file, readonly = FALSE)
genofile

sv <- read_sv_gds(genofile, cfg)
print(paste0("SVs in GDS: ", nrow(sv)))
print(table(sv$svtype))

## annotate a single chromosome only (other variants are left as NA)
sv_all <- sv[, .(row, VarInfo)]
if(!is.na(chr)) sv <- sv[chromosome == chr]
print(paste0("SVs annotated: ", nrow(sv)))

##########################################################################
### Step 2 (Load annotation resources)
##########################################################################
load_res <- function(name) readRDS(file.path(resource_dir, paste0(name, ".rds")))
res <- list(tx = load_res("gencode_canonical_tx"), tx_parts = load_res("gencode_canonical_tx_parts"))
genes <- load_res("gencode_genes")

regions <- sv_regions(sv, breakpoint_window)

##########################################################################
### Step 3 (Annotate)
##########################################################################
print("Annotating gene consequences")
gc_pairs <- annotate_gene_consequence(sv, res, promoter_upstream)
anno <- list(sv[, !"VarInfo"],
             summarize_gene_consequence(sv, gc_pairs),
             annotate_gene_overlap(sv, regions, genes))

print("Annotating gene dosage sensitivity")
anno[[length(anno) + 1]] <- annotate_dosage(sv, gc_pairs, load_res("gene_dosage"), load_res("clingen_region"))

print("Annotating population frequency (gnomAD-SV)")
anno[[length(anno) + 1]] <- annotate_population(sv, load_res("gnomad_sv"), reciprocal_overlap, insertion_distance)

print("Annotating clinical SVs (ClinVar/dbVar)")
anno[[length(anno) + 1]] <- annotate_clinical(sv, load_res("clinical_sv"), reciprocal_overlap)

print("Annotating regulatory elements and repeats")
anno[[length(anno) + 1]] <- annotate_regulatory(sv, regions, load_res("encode_ccre"))
anno[[length(anno) + 1]] <- annotate_repeats(sv, regions, load_res("segdup"), load_res("rmsk"))

if(!is.na(favor_db_path))
{
  print("Summarizing FAVOR scores over SVs")
  DB_info <- read.csv(file_DBsplit, header = TRUE)
  favor_regions <- sv_regions(sv, breakpoint_window, favor_max_span)
  ## per-chromosome jobs only read the FAVOR database of their own chromosome
  ## (the partner breakpoint of an inter-chromosomal BND/CTX is skipped)
  if(!is.na(chr)) { sel_chr <- chr; favor_regions <- favor_regions[chr == sel_chr] }
  anno[[length(anno) + 1]] <- annotate_favor(sv, favor_regions, favor_db_path, DB_info, favor_score_columns)
}

FunctionalAnnotationSV <- Reduce(function(x, y) merge(x, y, by = "row", all.x = TRUE, sort = FALSE), anno)
## one row per variant, in the variant order of the GDS file
FunctionalAnnotationSV <- merge(sv_all, FunctionalAnnotationSV, by = "row", all.x = TRUE)
setorder(FunctionalAnnotationSV, row)
FunctionalAnnotationSV[, row := NULL]
dim(FunctionalAnnotationSV)

out.file <- file.path(output_path, paste0(sub("\\.[^.]*$", "", basename(gds.file)),
                                          if(!is.na(chr)) paste0("_chr", chr), "_SVAnnotation.csv"))
fwrite(FunctionalAnnotationSV, out.file)
print(paste0("Annotation table: ", out.file))

##########################################################################
### Step 4 (gds2agds)
##########################################################################
Anno.folder <- index.gdsn(genofile, "annotation/info")
add.gdsn(Anno.folder, sv_anno_node, val = as.data.frame(FunctionalAnnotationSV),
         compress = "LZMA_ra", closezip = TRUE, replace = TRUE)

genofile

seqClose(genofile)

end_time <- Sys.time()

print("time")
end_time - start_time
