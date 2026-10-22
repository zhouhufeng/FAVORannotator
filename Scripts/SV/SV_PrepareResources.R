#############################################################################
#Title:    SV_PrepareResources
#Function:
# * Pre-process the downloaded SV annotation resources (SV_DownloadResources.R)
# * into compact .rds tables used by FAVORannotatorSV.R.
# * Chromosome names are stored without the "chr" prefix (as in the GDS files
# * built with ignore.chr.prefix="chr") and all coordinates are 1-based, closed.
#Usage:
# * Rscript SV_PrepareResources.R
#Author:   Hufeng Zhou
#Time:     Oct 21st 2026
#############################################################################

library(data.table)
source("config_SV.R")

raw_dir <- file.path(resource_dir, "raw")
setDTthreads(0)

strip_chr <- function(x) sub("^chr", "", x)
main_chr <- c(1:22, "X", "Y")
raw <- function(f) file.path(raw_dir, f)
save_res <- function(x, name)
{
  saveRDS(x, file.path(resource_dir, paste0(name, ".rds")))
  print(paste0(name, ": ", nrow(x), " rows"))
}

##########################################################################
### GENCODE: canonical transcripts with exon, CDS and UTR structures
##########################################################################
gtf <- fread(cmd = paste0("zcat ", raw("gencode.v46.basic.annotation.gtf.gz"), " | grep -v '^#'"),
             sep = "\t", header = FALSE, quote = "", col.names = c("chr","source","feature","start","end","score","strand","frame","attr"))
gtf <- gtf[feature %in% c("gene","transcript","exon","CDS","UTR")]
gtf[, chr := strip_chr(chr)]
gtf <- gtf[chr %in% main_chr]

get_attr <- function(attr, key)
{
  m <- regmatches(attr, regexpr(paste0(key, ' "[^"]+"'), attr))
  out <- rep(NA_character_, length(attr))
  out[grepl(paste0(key, ' "'), attr)] <- sub(paste0(key, ' "([^"]+)"'), "\\1", m)
  out
}
gtf[, gene_id := sub("\\..*", "", get_attr(attr, "gene_id"))]
gtf[, gene_name := get_attr(attr, "gene_name")]
gtf[, gene_type := get_attr(attr, "gene_type")]
gtf[feature != "gene", transcript_id := get_attr(attr, "transcript_id")]
gtf[feature != "gene", canonical := grepl('tag "Ensembl_canonical"', attr, fixed = TRUE)]

## genes (all gene types): used for overlapping genes and nearest TSS
genes <- gtf[feature == "gene", .(chr, start, end, strand, gene_id, gene_name, gene_type)]
genes[, tss := ifelse(strand == "+", start, end)]
save_res(genes, "gencode_genes")

## canonical transcripts of protein-coding genes: used for SV consequences
tx <- gtf[feature == "transcript" & canonical & gene_type == "protein_coding",
          .(chr, start, end, strand, gene_id, gene_name, transcript_id)]
tx <- tx[!duplicated(gene_id)]
cds_range <- gtf[feature == "CDS" & transcript_id %in% tx$transcript_id,
                 .(cds_start = min(start), cds_end = max(end)), by = transcript_id]
tx <- merge(tx, cds_range, by = "transcript_id")
save_res(tx, "gencode_canonical_tx")

tx_parts <- gtf[feature %in% c("exon","CDS","UTR") & transcript_id %in% tx$transcript_id,
                .(chr, start, end, feature, transcript_id)]
save_res(tx_parts, "gencode_canonical_tx_parts")
rm(gtf); gc()

##########################################################################
### Gene dosage sensitivity and constraint (joined to genes by id/symbol)
##########################################################################
## gnomAD v4.1 constraint: one MANE Select (else canonical) transcript per Ensembl gene
cons <- fread(raw("gnomad.v4.1.constraint_metrics.tsv"),
              select = c("gene","gene_id","canonical","mane_select","lof.pLI","lof.oe_ci.upper"))
cons <- cons[grepl("^ENSG", gene_id)]
setorder(cons, gene_id, -mane_select, -canonical)
cons <- cons[!duplicated(gene_id), .(gene_id, gnomad_pLI = `lof.pLI`, gnomad_LOEUF = `lof.oe_ci.upper`)]

## ClinGen gene dosage (score 3 = sufficient evidence, 30 = autosomal recessive, 40 = unlikely)
clingen_gene <- fread(raw("ClinGen_gene_curation_list_GRCh38.tsv"), skip = "#Gene Symbol", sep = "\t", fill = TRUE)
setnames(clingen_gene, 1, "Gene Symbol")
clingen_gene <- clingen_gene[, .(gene_name = `Gene Symbol`,
                                 clingen_HI = suppressWarnings(as.numeric(`Haploinsufficiency Score`)),
                                 clingen_TS = suppressWarnings(as.numeric(`Triplosensitivity Score`)))]

## Collins et al. 2022 pHaplo/pTriplo
rcnv <- fread(cmd = paste0("zcat ", raw("Collins_rCNV_2022.dosage_sensitivity_scores.tsv.gz")))
setnames(rcnv, c("gene_name","pHaplo","pTriplo"))

gene_dosage <- merge(genes[gene_type == "protein_coding", .(gene_id, gene_name)], cons, by = "gene_id", all.x = TRUE)
gene_dosage <- merge(gene_dosage, clingen_gene[!duplicated(gene_name)], by = "gene_name", all.x = TRUE)
gene_dosage <- merge(gene_dosage, rcnv[!duplicated(gene_name)], by = "gene_name", all.x = TRUE)
save_res(gene_dosage, "gene_dosage")

## ClinGen recurrent CNV regions
clingen_region <- fread(raw("ClinGen_region_curation_list_GRCh38.tsv"), skip = "#ISCA ID", sep = "\t", fill = TRUE)
setnames(clingen_region, 1, "ISCA ID")
clingen_region <- clingen_region[grepl("^chr[0-9XY]+:[0-9]+-[0-9]+$", `Genomic Location`)]
clingen_region[, c("chr","start","end") := tstrsplit(`Genomic Location`, "[:-]")]
clingen_region <- clingen_region[, .(chr = strip_chr(chr), start = as.integer(start), end = as.integer(end),
                                     region_id = `ISCA ID`, region_name = `ISCA Region Name`,
                                     clingen_HI = suppressWarnings(as.numeric(`Haploinsufficiency Score`)),
                                     clingen_TS = suppressWarnings(as.numeric(`Triplosensitivity Score`)))]
save_res(clingen_region, "clingen_region")

##########################################################################
### gnomAD-SV v4.1 population frequencies
##########################################################################
gnomad_sv <- fread(cmd = paste0("zcat ", raw("gnomad.v4.1.sv.sites.bed.gz")),
                   select = c("#chrom","start","end","name","svtype","CHR2","END2","SVLEN","AF","GRPMAX_AF","FILTER"))
setnames(gnomad_sv, c("chr","start","end","gnomad_sv_id","svtype","chr2","end2","svlen","AF","GRPMAX_AF","FILTER"))
gnomad_sv <- gnomad_sv[FILTER %in% c("PASS","MULTIALLELIC")]
gnomad_sv[, `:=`(chr = strip_chr(chr), chr2 = strip_chr(chr2), start = start + 1L)]
gnomad_sv[, `:=`(AF = suppressWarnings(as.numeric(AF)), GRPMAX_AF = suppressWarnings(as.numeric(GRPMAX_AF)),
                 end2 = suppressWarnings(as.integer(end2)))]
save_res(gnomad_sv, "gnomad_sv")

##########################################################################
### dbVar/ClinVar clinical pathogenic or likely pathogenic SVs
##########################################################################
dbvar <- fread(cmd = paste0("zcat ", raw("GRCh38.variant_call.clinical.pathogenic_or_likely_pathogenic.vcf.gz"),
                            " | grep -v '^##'"), sep = "\t", select = c(1:3, 8), quote = "")
setnames(dbvar, c("chr","pos","sv_id","info"))
info_get <- function(info, key) sub(paste0(".*(^|;)", key, "=([^;]*).*"), "\\2",
                                    ifelse(grepl(paste0("(^|;)", key, "="), info), info, paste0(key, "=")))
dbvar <- dbvar[, .(chr = strip_chr(as.character(chr)), start = pos,
                   end = suppressWarnings(as.integer(info_get(info, "END"))),
                   svtype = info_get(info, "SVTYPE"), clinvar_sv_id = sv_id,
                   clnsig = gsub('"', "", info_get(info, "CLNSIG")))]
dbvar[is.na(end), end := start]
save_res(dbvar, "clinical_sv")

##########################################################################
### ENCODE cCREs, segmental duplications and repeats
##########################################################################
ccre <- fread(raw("GRCh38-cCREs.bed"), header = FALSE, select = c(1:3, 6), col.names = c("chr","start","end","ccre_class"))
ccre[, `:=`(chr = strip_chr(chr), start = start + 1L)]
save_res(ccre[chr %in% main_chr], "encode_ccre")

segdup <- fread(cmd = paste0("zcat ", raw("genomicSuperDups.txt.gz")), header = FALSE, select = 2:4,
                col.names = c("chr","start","end"))
segdup[, `:=`(chr = strip_chr(chr), start = start + 1L)]
save_res(segdup[chr %in% main_chr], "segdup")

rmsk <- fread(cmd = paste0("zcat ", raw("rmsk.txt.gz")), header = FALSE, select = c(6:8, 12),
              col.names = c("chr","start","end","repeat_class"))
rmsk[, `:=`(chr = strip_chr(chr), start = start + 1L)]
save_res(rmsk[chr %in% main_chr], "rmsk")

print("Resources prepared")
