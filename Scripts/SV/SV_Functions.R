#############################################################################
#Title:    SV_Functions
#Function:
# * Functions used by FAVORannotatorSV.R to functionally annotate
# * structural variants (SVs) stored in a GDS file.
#Author:   Hufeng Zhou
#Time:     Oct 21st 2026
#############################################################################

suppressPackageStartupMessages({
  library(data.table)
  library(GenomicRanges)
})

strip_chr <- function(x) sub("^chr", "", as.character(x))

make_gr <- function(chr, start, end)
{
  GRanges(chr, IRanges(as.integer(start), pmax(as.integer(end), as.integer(start))))
}

collapse_unique <- function(x)
{
  x <- unique(x[!is.na(x) & x != ""])
  if(length(x) == 0) NA_character_ else paste(x, collapse = ",")
}

##########################################################################
### Read SVs from the GDS file
##########################################################################
read_info_field <- function(genofile, names, n)
{
  for(nm in names)
  {
    node <- paste0("annotation/info/", nm)
    if(!is.null(index.gdsn(genofile, node, silent = TRUE)))
    {
      x <- seqGetData(genofile, node, .tolist = TRUE)
      if(is.list(x))
      {
        x <- vapply(x, function(v) if(length(v)) as.character(v[1]) else NA_character_, "")
      }
      return(x)
    }
  }
  rep(NA, n)
}

## SV class used for annotation rules
normalize_svtype <- function(x)
{
  x <- toupper(sub(":.*", "", x))
  x[x %in% c("MCNV","CN0","CN1","CN2","CN3","CN4")] <- "CNV"
  x[grepl("^CN[0-9]+$", x)] <- "CNV"
  x[x %in% c("TRA","TRANS")] <- "CTX"
  x[x %in% c("DUP_TANDEM","TANDEM","DUP_INTERSPERSED")] <- "DUP"
  x
}

read_sv_gds <- function(genofile, cfg)
{
  chr <- strip_chr(seqGetData(genofile, "chromosome"))
  pos <- as.integer(seqGetData(genofile, "position"))
  allele <- seqGetData(genofile, "allele")
  ref <- sub(",.*", "", allele)
  alt <- sub("^[^,]*,?", "", allele)
  alt1 <- sub(",.*", "", alt)
  n <- length(pos)

  svtype <- as.character(read_info_field(genofile, cfg$info_svtype, n))
  end <- suppressWarnings(as.integer(read_info_field(genofile, cfg$info_end, n)))
  svlen <- suppressWarnings(abs(as.numeric(read_info_field(genofile, cfg$info_svlen, n))))
  chr2 <- strip_chr(read_info_field(genofile, cfg$info_chr2, n))
  end2 <- suppressWarnings(as.integer(read_info_field(genofile, cfg$info_end2, n)))

  ## SV type from the ALT allele when SVTYPE is missing
  symbolic <- grepl("^<.*>$", alt1)
  breakend <- grepl("[][]", alt1)
  len_diff <- nchar(alt1) - nchar(ref)
  type_alt <- ifelse(symbolic, sub("^<([^>]+)>$", "\\1", alt1),
              ifelse(breakend, "BND",
              ifelse(len_diff < 0, "DEL", ifelse(len_diff > 0, "INS", "CPX"))))
  svtype <- ifelse(is.na(svtype) | svtype == "", type_alt, svtype)
  svtype <- normalize_svtype(svtype)

  ## second breakpoint of breakends from the ALT allele, e.g. N[chr2:12345[
  bnd_pos <- regmatches(alt1, regexpr("[^][]+:[0-9]+", alt1))
  has_bnd <- grepl("[^][]+:[0-9]+", alt1)
  chr2[has_bnd & is.na(chr2)] <- strip_chr(sub(":.*", "", bnd_pos[is.na(chr2[has_bnd])]))
  end2[has_bnd & is.na(end2)] <- as.integer(sub(".*:", "", bnd_pos[is.na(end2[has_bnd])]))

  ## end position and length
  point <- svtype %in% c("INS","BND","CTX")
  seq_resolved <- !symbolic & !breakend
  end <- ifelse(!is.na(end) & !point, end,
         ifelse(point, pos,
         ifelse(seq_resolved, pos + nchar(ref) - 1L,
         ifelse(!is.na(svlen), pos + as.integer(svlen), pos))))
  end <- pmax(end, pos)
  svlen <- ifelse(!is.na(svlen), svlen,
           ifelse(seq_resolved, abs(len_diff), ifelse(point, NA, end - pos)))
  ## breakends have no length (e.g. SVLEN=-1 in GATK-SV)
  svlen[svtype %in% c("BND","CTX")] <- NA
  ## BND/CTX on the same chromosome without CHR2
  chr2[point & svtype != "INS" & is.na(chr2) & !is.na(end2)] <- chr[point & svtype != "INS" & is.na(chr2) & !is.na(end2)]

  data.table(row = seq_len(n),
             VarInfo = paste0(chr, "-", pos, "-", ref, "-", alt),
             sv_id = seqGetData(genofile, "annotation/id"),
             chromosome = chr, position = pos, end = as.integer(end),
             svtype = svtype, svlen = svlen,
             chr2 = ifelse(point & svtype != "INS", chr2, NA_character_),
             end2 = ifelse(point & svtype != "INS", end2, NA_integer_))
}

## intervals used for region-based annotations: the SV span, or a window
## around each breakpoint for insertions and breakends
sv_regions <- function(sv, window, max_span = Inf)
{
  point <- sv$svtype %in% c("INS","BND","CTX")
  long <- !point & (sv$end - sv$position + 1) > max_span
  span <- sv[!point & !long, .(row, chr = chromosome, start = position, end)]
  bp1 <- sv[point | long, .(row, chr = chromosome, start = position - window, end = position + window)]
  bp2 <- sv[long, .(row, chr = chromosome, start = end - window, end = end + window)]
  bp3 <- sv[point & !is.na(chr2) & !is.na(end2), .(row, chr = chr2, start = end2 - window, end = end2 + window)]
  out <- rbind(span, bp1, bp2, bp3)
  out[, start := pmax(start, 1L)]
  out
}

##########################################################################
### Gene consequences (canonical protein-coding transcripts, GENCODE)
##########################################################################
consequence_levels <- c("LOF","COPY_GAIN","INTRAGENIC_EXON_DUP","PARTIAL_EXON_DUP","INV_SPAN",
                        "TSS_DUP","UTR","PROMOTER","INTRONIC")

annotate_gene_consequence <- function(sv, res, promoter_upstream)
{
  tx <- res$tx
  parts <- res$tx_parts

  ## query intervals and the rule class applied to each
  point <- sv$svtype %in% c("INS","BND","CTX")
  cls <- fcase(sv$svtype == "DEL", "DEL", sv$svtype == "DUP", "DUP", sv$svtype == "INV", "INV",
               sv$svtype == "INS", "INS", sv$svtype %in% c("BND","CTX"), "BND",
               sv$svtype == "CNV", "DEL", default = "DEL")
  q <- data.table(row = sv$row, chr = sv$chromosome, s = sv$position,
                  e = ifelse(point, sv$position, sv$end), cls = cls)
  ## multi-allelic CNVs: deletion rules plus whole-gene copy gain
  q <- rbind(q, q[sv$svtype == "CNV"][, cls := "DUPCG"])
  ## second breakpoint of breakends
  q <- rbind(q, sv[point & svtype != "INS" & !is.na(chr2) & !is.na(end2),
                   .(row, chr = chr2, s = end2, e = end2, cls = "BND")])
  q[, qid := .I]

  ## transcripts extended by their promoter
  tx[, `:=`(tid = .I, tss = ifelse(strand == "+", start, end))]
  tx[, `:=`(prom_s = ifelse(strand == "+", start - promoter_upstream, end + 1L),
            prom_e = ifelse(strand == "+", start - 1L, end + promoter_upstream))]
  tx_ext <- make_gr(tx$chr, pmin(tx$start, tx$prom_s), pmax(tx$end, tx$prom_e))
  q_gr <- make_gr(q$chr, q$s, q$e)

  hit <- findOverlaps(q_gr, tx_ext)
  if(length(hit) == 0) return(data.table(row = integer(0), gene_id = character(0), gene_name = character(0),
                                         consequence = character(0)))
  P <- data.table(qid = queryHits(hit), tid = subjectHits(hit))
  P <- cbind(P, q[P$qid, .(row, s, e, cls)], tx[P$tid, .(gene_id, gene_name, transcript_id, start, end,
                                                          tss, prom_s, prom_e, cds_start, cds_end)])

  ## overlap with coding/UTR/exon segments of the same transcript
  part_hit <- function(feat)
  {
    pp <- parts[feature == feat]
    h <- findOverlaps(q_gr, make_gr(pp$chr, pp$start, pp$end))
    unique(paste(queryHits(h), pp$transcript_id[subjectHits(h)]))
  }
  key <- paste(P$qid, P$transcript_id)
  P[, ov_cds := key %in% part_hit("CDS")]
  P[, ov_utr := key %in% part_hit("UTR")]

  P[, `:=`(in_body = s <= end & e >= start,
           s_in = s >= start & s <= end, e_in = e >= start & e <= end,
           covers = s <= start & e >= end,
           covers_tss = s <= tss & e >= tss,
           ov_prom = s <= prom_e & e >= prom_s,
           bp_in_cds_range = (s >= cds_start & s <= cds_end) | (e >= cds_start & e <= cds_end))]

  P[, consequence := fcase(
    ## deletions (and losses of CNVs/complex SVs)
    cls == "DEL" & ov_cds, "LOF",
    cls == "DEL" & ov_utr, "UTR",
    cls == "DEL" & in_body, "INTRONIC",
    ## duplications
    cls %in% c("DUP","DUPCG") & covers, "COPY_GAIN",
    cls == "DUPCG", NA_character_,
    cls == "DUP" & s_in & e_in & ov_cds, "INTRAGENIC_EXON_DUP",
    cls == "DUP" & (s_in | e_in) & ov_cds, "PARTIAL_EXON_DUP",
    cls == "DUP" & covers_tss, "TSS_DUP",
    cls == "DUP" & ov_utr, "UTR",
    cls == "DUP" & in_body, "INTRONIC",
    ## inversions
    cls == "INV" & covers, "INV_SPAN",
    cls == "INV" & (s_in | e_in) & ov_cds, "LOF",
    cls == "INV" & (s_in | e_in) & ov_utr, "UTR",
    cls == "INV" & (s_in | e_in), "INTRONIC",
    ## insertions and breakends (single breakpoints)
    cls == "INS" & ov_cds, "LOF",
    cls == "BND" & (ov_cds | bp_in_cds_range), "LOF",
    cls %in% c("INS","BND") & ov_utr, "UTR",
    cls %in% c("INS","BND") & in_body, "INTRONIC",
    ## promoter
    ov_prom, "PROMOTER",
    default = NA_character_)]

  P <- P[!is.na(consequence)]
  P[, rank := match(consequence, consequence_levels)]
  ## one (most severe) consequence per SV and gene; CNVs keep both the loss and the gain consequence
  P[, gain := cls == "DUPCG"]
  setorder(P, row, gene_id, rank)
  unique(P[, .(row, gene_id, gene_name, consequence, gain)], by = c("row","gene_id","gain"))[, gain := NULL][]
}

summarize_gene_consequence <- function(sv, gc)
{
  out <- data.table(row = sv$row)
  for(cq in consequence_levels)
  {
    tmp <- gc[consequence == cq, .(genes = collapse_unique(gene_name)), by = row]
    out[tmp, (paste0("genes_", cq)) := i.genes, on = "row"]
    if(!(paste0("genes_", cq) %in% names(out))) out[, (paste0("genes_", cq)) := NA_character_]
  }
  top <- gc[, .(sv_consequence = consequence_levels[min(match(consequence, consequence_levels))]), by = row]
  out[top, sv_consequence := i.sv_consequence, on = "row"]
  out[is.na(sv_consequence), sv_consequence := "INTERGENIC"]
  setcolorder(out, c("row","sv_consequence"))
  out
}

## all overlapped genes (any gene type) and the nearest protein-coding TSS
annotate_gene_overlap <- function(sv, regions, genes)
{
  g_gr <- make_gr(genes$chr, genes$start, genes$end)
  r_gr <- make_gr(regions$chr, regions$start, regions$end)
  h <- findOverlaps(r_gr, g_gr)
  ov <- data.table(row = regions$row[queryHits(h)], gene_name = genes$gene_name[subjectHits(h)],
                   gene_type = genes$gene_type[subjectHits(h)])
  out <- data.table(row = sv$row)
  tmp <- ov[, .(genes_overlapped = collapse_unique(gene_name), n_genes_overlapped = uniqueN(gene_name),
                n_protein_coding_overlapped = uniqueN(gene_name[gene_type == "protein_coding"])), by = row]
  out[tmp, `:=`(genes_overlapped = i.genes_overlapped, n_genes_overlapped = i.n_genes_overlapped,
                n_protein_coding_overlapped = i.n_protein_coding_overlapped), on = "row"]
  out[is.na(n_genes_overlapped), `:=`(n_genes_overlapped = 0L, n_protein_coding_overlapped = 0L)]

  pc <- genes[gene_type == "protein_coding"]
  tss_gr <- make_gr(pc$chr, pc$tss, pc$tss)
  sv_gr <- make_gr(sv$chromosome, sv$position, sv$end)
  d <- suppressWarnings(distanceToNearest(sv_gr, tss_gr, ignore.strand = TRUE))
  out[queryHits(d), `:=`(nearest_tss_gene = pc$gene_name[subjectHits(d)], nearest_tss_distance = mcols(d)$distance)]
  if(!("nearest_tss_gene" %in% names(out))) out[, `:=`(nearest_tss_gene = NA_character_, nearest_tss_distance = NA_integer_)]
  out
}

##########################################################################
### Dosage sensitivity / constraint of the affected genes
##########################################################################
max_na <- function(x) if(all(is.na(x))) NA_real_ else max(x, na.rm = TRUE)
min_na <- function(x) if(all(is.na(x))) NA_real_ else min(x, na.rm = TRUE)

annotate_dosage <- function(sv, gc, gene_dosage, clingen_region)
{
  out <- data.table(row = sv$row)
  lof <- merge(gc[consequence %in% c("LOF","INTRAGENIC_EXON_DUP")], gene_dosage[, !"gene_name"], by = "gene_id")
  gain <- merge(gc[consequence == "COPY_GAIN"], gene_dosage[, !"gene_name"], by = "gene_id")

  tmp <- lof[, .(lof_max_pLI = max_na(gnomad_pLI), lof_min_LOEUF = min_na(gnomad_LOEUF),
                 lof_max_pHaplo = max_na(pHaplo),
                 lof_clingen_HI_genes = collapse_unique(gene_name[which(clingen_HI == 3)])), by = row]
  out <- merge(out, tmp, by = "row", all.x = TRUE)
  tmp <- gain[, .(gain_max_pTriplo = max_na(pTriplo),
                  gain_clingen_TS_genes = collapse_unique(gene_name[which(clingen_TS == 3)])), by = row]
  out <- merge(out, tmp, by = "row", all.x = TRUE)

  ## ClinGen dosage sensitive regions covered (>=50% of the region) by losses/gains
  span <- sv[!(svtype %in% c("INS","BND","CTX"))]
  h <- findOverlaps(make_gr(span$chromosome, span$position, span$end),
                    make_gr(clingen_region$chr, clingen_region$start, clingen_region$end))
  if(length(h) > 0)
  {
    ov <- data.table(row = span$row[queryHits(h)], svtype = span$svtype[queryHits(h)],
                     clingen_region[subjectHits(h)],
                     s = span$position[queryHits(h)], e = span$end[queryHits(h)])
    ov <- ov[(pmin(e, end) - pmax(s, start) + 1) / (end - start + 1) >= 0.5]
    tmp <- ov[, .(clingen_HI_regions = collapse_unique(region_id[svtype %in% c("DEL","CNV") & clingen_HI %in% 3]),
                  clingen_TS_regions = collapse_unique(region_id[svtype %in% c("DUP","CNV") & clingen_TS %in% 3])),
              by = row]
    out <- merge(out, tmp, by = "row", all.x = TRUE)
  }
  for(nm in c("clingen_HI_regions","clingen_TS_regions")) if(!(nm %in% names(out))) out[, (nm) := NA_character_]
  out
}

##########################################################################
### Match SVs to reference SV call sets (population/clinical)
##########################################################################
compatible_types <- list(DEL = c("DEL","CNV"), DUP = c("DUP","CNV"), CNV = c("DEL","DUP","CNV"),
                         INV = c("INV","CPX"), CPX = c("CPX","INV"), INS = c("INS"),
                         BND = c("BND","CTX"), CTX = c("CTX","BND"))

## returns all matched pairs (row, ref index, score) where score is the
## reciprocal overlap for spanning SVs, or the breakpoint distance for INS/BND
match_reference_sv <- function(sv, ref, min_ro, max_dist)
{
  ref_type <- normalize_svtype(ref$svtype)
  out <- list()
  for(tp in intersect(names(compatible_types), unique(sv$svtype)))
  {
    q <- sv[svtype == tp]
    r_idx <- which(ref_type %in% compatible_types[[tp]])
    if(nrow(q) == 0 || length(r_idx) == 0) next
    r <- ref[r_idx]
    if(tp %in% c("INS","BND","CTX"))
    {
      h <- findOverlaps(make_gr(q$chromosome, pmax(q$position - max_dist, 1L), q$position + max_dist),
                        make_gr(r$chr, r$start, r$start))
      m <- data.table(row = q$row[queryHits(h)], ref = r_idx[subjectHits(h)],
                      score = -abs(q$position[queryHits(h)] - r$start[subjectHits(h)]))
    }else
    {
      h <- findOverlaps(make_gr(q$chromosome, q$position, q$end), make_gr(r$chr, r$start, r$end))
      qs <- q$position[queryHits(h)]; qe <- q$end[queryHits(h)]
      rs <- r$start[subjectHits(h)]; re <- r$end[subjectHits(h)]
      ro <- (pmin(qe, re) - pmax(qs, rs) + 1) / pmax(qe - qs + 1, re - rs + 1)
      m <- data.table(row = q$row[queryHits(h)], ref = r_idx[subjectHits(h)], score = ro)[score >= min_ro]
    }
    out[[tp]] <- m
  }
  m <- rbindlist(out)
  if(nrow(m) == 0) m <- data.table(row = integer(0), ref = integer(0), score = numeric(0))
  m
}

annotate_population <- function(sv, gnomad_sv, min_ro, max_dist)
{
  m <- match_reference_sv(sv, gnomad_sv, min_ro, max_dist)
  setorder(m, row, -score)
  best <- m[!duplicated(row)]
  best <- best[, .(row, gnomad_sv_id = gnomad_sv$gnomad_sv_id[ref], gnomad_sv_AF = gnomad_sv$AF[ref],
                   gnomad_sv_GRPMAX_AF = gnomad_sv$GRPMAX_AF[ref],
                   ## reciprocal overlap (DEL/DUP/INV/CNV/CPX) or breakpoint distance in bp (INS/BND/CTX)
                   gnomad_sv_match = ifelse(sv$svtype[match(row, sv$row)] %in% c("INS","BND","CTX"),
                                            -score, round(score, 4)))]
  merge(data.table(row = sv$row), best, by = "row", all.x = TRUE)
}

annotate_clinical <- function(sv, clinical_sv, min_ro)
{
  span <- sv[svtype %in% c("DEL","DUP","CNV","INV","CPX")]
  m <- match_reference_sv(span, clinical_sv, min_ro, 0)
  setorder(m, row, -score)
  out <- data.table(row = sv$row)
  tmp <- m[, .(clinvar_sv_n = .N, clinvar_sv_id = clinical_sv$clinvar_sv_id[ref[1]],
               clinvar_sv_clnsig = clinical_sv$clnsig[ref[1]], clinvar_sv_ro = round(score[1], 4)), by = row]
  out <- merge(out, tmp, by = "row", all.x = TRUE)
  if(!("clinvar_sv_n" %in% names(out)))
    out[, `:=`(clinvar_sv_n = NA_integer_, clinvar_sv_id = NA_character_, clinvar_sv_clnsig = NA_character_, clinvar_sv_ro = NA_real_)]
  out[is.na(clinvar_sv_n), clinvar_sv_n := 0L]
  out
}

##########################################################################
### Regulatory elements, segmental duplications and repeats
##########################################################################
annotate_regulatory <- function(sv, regions, ccre)
{
  h <- findOverlaps(make_gr(regions$chr, regions$start, regions$end), make_gr(ccre$chr, ccre$start, ccre$end))
  ov <- unique(data.table(row = regions$row[queryHits(h)], id = subjectHits(h), cls = ccre$ccre_class[subjectHits(h)]))
  tmp <- ov[, .(ccre_n = .N, ccre_PLS_n = sum(cls == "PLS"), ccre_pELS_n = sum(cls == "pELS"),
                ccre_dELS_n = sum(cls == "dELS"), ccre_CTCF_n = sum(grepl("CTCF", cls)),
                ccre_other_n = sum(!(cls %in% c("PLS","pELS","dELS")) & !grepl("CTCF", cls))), by = row]
  out <- merge(data.table(row = sv$row), tmp, by = "row", all.x = TRUE)
  cols <- c("ccre_n","ccre_PLS_n","ccre_pELS_n","ccre_dELS_n","ccre_CTCF_n","ccre_other_n")
  for(nm in cols) { if(!(nm %in% names(out))) out[, (nm) := 0L]; out[is.na(get(nm)), (nm) := 0L] }
  out
}

annotate_repeats <- function(sv, regions, segdup, rmsk)
{
  ## fraction of the SV region covered by segmental duplications
  sd_gr <- reduce(make_gr(segdup$chr, segdup$start, segdup$end))
  r_gr <- make_gr(regions$chr, regions$start, regions$end)
  h <- findOverlaps(r_gr, sd_gr)
  ovw <- width(pintersect(r_gr[queryHits(h)], sd_gr[subjectHits(h)]))
  tmp <- data.table(row = regions$row[queryHits(h)], w = ovw)[, .(w = sum(w)), by = row]
  tot <- data.table(row = regions$row, w = width(r_gr))[, .(tot = sum(w)), by = row]
  out <- merge(data.table(row = sv$row), tot, by = "row", all.x = TRUE)
  out[tmp, segdup_fraction := round(pmin(i.w / tot, 1), 4), on = "row"]
  out[is.na(segdup_fraction), segdup_fraction := 0]
  out[, tot := NULL]

  ## repeat class at the breakpoints
  rm_gr <- make_gr(rmsk$chr, rmsk$start, rmsk$end)
  bp_class <- function(chr, pos)
  {
    ok <- !is.na(chr) & !is.na(pos)
    res <- rep(NA_character_, length(pos))
    if(!any(ok)) return(res)
    h <- findOverlaps(make_gr(chr[ok], pos[ok], pos[ok]), rm_gr)
    cl <- data.table(i = which(ok)[queryHits(h)], cls = rmsk$repeat_class[subjectHits(h)])[, .(cls = collapse_unique(cls)), by = i]
    res[cl$i] <- cl$cls
    res
  }
  point <- sv$svtype %in% c("INS","BND","CTX")
  out[, repeat_class_bp1 := bp_class(sv$chromosome, sv$position)]
  out[, repeat_class_bp2 := bp_class(ifelse(point, sv$chr2, sv$chromosome), ifelse(point, sv$end2, sv$end))]
  out
}

##########################################################################
### FAVOR per-base scores summarized (max/mean) over each SV region
##########################################################################
range_max <- function(v, bm, i1, i2, B)
{
  out <- rep(NA_real_, length(i1))
  b1 <- (i1 - 1L) %/% B + 1L
  b2 <- (i2 - 1L) %/% B + 1L
  for(j in which(i2 >= i1))
  {
    if(b2[j] - b1[j] <= 1L)
    {
      x <- v[i1[j]:i2[j]]
    }else
    {
      x <- c(v[i1[j]:(b1[j]*B)], bm[(b1[j]+1L):(b2[j]-1L)], v[((b2[j]-1L)*B+1L):i2[j]])
    }
    out[j] <- suppressWarnings(max(x, na.rm = TRUE))
  }
  out[is.infinite(out)] <- NA_real_
  out
}

annotate_favor <- function(sv, regions, favor_db_path, DB_info, score_cols, B = 4096L)
{
  out <- data.table(row = sv$row)
  acc <- list()
  for(cur_chr in intersect(unique(regions$chr), as.character(unique(DB_info$Chr))))
  {
    q <- regions[chr == cur_chr]
    db_chr <- DB_info[as.character(DB_info$Chr) == cur_chr, ]
    sums <- cnts <- matrix(0, nrow(q), length(score_cols), dimnames = list(NULL, score_cols))
    maxs <- matrix(NA_real_, nrow(q), length(score_cols), dimnames = list(NULL, score_cols))

    for(kk in seq_len(nrow(db_chr)))
    {
      qi <- which(q$end >= db_chr$Start_Pos[kk] & q$start <= db_chr$End_Pos[kk])
      if(length(qi) == 0) next
      f <- file.path(favor_db_path, paste0("chr", cur_chr, "_", db_chr$File_No[kk], ".csv"))
      if(!file.exists(f)) { warning(paste0("FAVOR database file not found: ", f)); next }
      cols <- intersect(score_cols, names(fread(f, nrows = 0)))
      print(paste0("Reading FAVOR scores: ", f, " (", length(qi), " SV regions)"))
      db <- fread(f, select = c("position", cols), showProgress = FALSE)
      ## one value per position: maximum over the alleles at the position
      db <- suppressWarnings(db[, lapply(.SD, max, na.rm = TRUE), by = position, .SDcols = cols])
      setorder(db, position)
      pos <- db$position
      i1 <- findInterval(q$start[qi] - 1L, pos) + 1L
      i2 <- findInterval(q$end[qi], pos)
      for(cc in cols)
      {
        v <- db[[cc]]
        v[is.infinite(v)] <- NA_real_
        cs <- c(0, cumsum(fifelse(is.na(v), 0, v)))
        cn <- c(0, cumsum(!is.na(v)))
        sums[qi, cc] <- sums[qi, cc] + ifelse(i2 >= i1, cs[i2 + 1L] - cs[i1], 0)
        cnts[qi, cc] <- cnts[qi, cc] + ifelse(i2 >= i1, cn[i2 + 1L] - cn[i1], 0)
        nb <- ceiling(length(v) / B)
        bm <- suppressWarnings(apply(matrix(c(v, rep(NA_real_, nb * B - length(v))), nrow = B), 2, max, na.rm = TRUE))
        maxs[qi, cc] <- pmax(maxs[qi, cc], range_max(v, bm, i1, i2, B), na.rm = TRUE)
      }
      rm(db, v, cs, cn, bm); gc()
    }
    acc[[cur_chr]] <- data.table(row = q$row, sums = sums, cnts = cnts, maxs = maxs)
  }
  if(length(acc) == 0) return(out)
  acc <- rbindlist(acc)
  ## combine the regions (breakpoints) of each SV
  agg <- merge(acc[, lapply(.SD, sum), by = row, .SDcols = patterns("^(sums|cnts)\\.")],
               acc[, lapply(.SD, max_na), by = row, .SDcols = patterns("^maxs\\.")], by = "row")
  res <- data.table(row = agg$row)
  for(cc in score_cols)
  {
    res[, (paste0("favor_", cc, "_max")) := agg[[paste0("maxs.", cc)]]]
    res[, (paste0("favor_", cc, "_mean")) := fifelse(agg[[paste0("cnts.", cc)]] > 0,
                                                    agg[[paste0("sums.", cc)]] / agg[[paste0("cnts.", cc)]], NA_real_)]
  }
  ## drop scores missing from the FAVOR database version used
  keep <- names(res)[vapply(res, function(x) !all(is.na(x)), TRUE)]
  merge(out, res[, ..keep], by = "row", all.x = TRUE)
}
