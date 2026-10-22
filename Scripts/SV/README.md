# FAVORannotator SV: functional annotation of structural variants into aGDS

These scripts extend FAVORannotator from SNVs/indels to **structural variants (SVs)**.
Like the SNV version, they read the variants from a GDS file, annotate every variant, and store
the annotation table in the same file (`annotation/info/FunctionalAnnotationSV`), creating an SV aGDS.

The FAVOR databases on Harvard Dataverse are per-base (all possible SNVs and observed indels).
An SV spans many bases, so the pipeline **summarizes the FAVOR scores over each SV**
(maximum and mean of each score). Gene, dosage-sensitivity, population, clinical and
regulatory annotations of SVs come from public resources (GRCh38) that are
downloaded once.

## Scripts

| Script | Purpose |
|---|---|
| `config_SV.R` | Paths (resources, FAVOR database, output) and parameters |
| `SV_DownloadResources.R` | Downloads the SV annotation resources, and optionally the FAVOR Essential/Full DB from Harvard Dataverse |
| `SV_PrepareResources.R` | Converts the downloaded resources into compact `.rds` tables |
| `convertSVVCFtoGDS.R` | Builds a GDS file from an SV VCF (keeps all INFO fields and GT) |
| `FAVORannotatorSV.R` | Annotates each SV in the GDS and writes the annotation into it (aGDS) and to CSV |
| `SV_Functions.R` | Annotation functions used by `FAVORannotatorSV.R` |
| `submitJobs_SV.sh` | Submits per-chromosome annotation jobs with SLURM |

## How to run

All commands are run inside `Scripts/SV/`. The scripts need R with `gdsfmt`, `SeqArray`, `data.table`,
`GenomicRanges` and `jsonlite`. On FASRC, `module load R/4.3.1-fasrc01` has all of them.

1. Set `resource_dir`, `favor_db_path` and `output_path` in `config_SV.R`.
2. Download and prepare the resources. This is run once: about 1.8 GB is downloaded.
   ```
   Rscript SV_DownloadResources.R                  # SV resources only
   Rscript SV_DownloadResources.R Essential 1:22   # + FAVOR Essential DB (CSV) from Harvard Dataverse
   Rscript SV_PrepareResources.R
   ```
   If the FAVOR CSV database is already available (as for the CSV/Cloud FAVORannotator), point
   `favor_db_path` to it instead of downloading it again. Set `favor_db_path <- NA` to skip the FAVOR scores.
3. Build the GDS from the SV VCF:
   ```
   Rscript convertSVVCFtoGDS.R SV.chr22.vcf.gz SV.chr22.gds
   ```
4. Annotate and build the SV aGDS:
   ```
   Rscript FAVORannotatorSV.R SV.chr22.gds 22
   ```
   The chromosome argument is optional. Without it, all SVs in the GDS are annotated.
   Use it with per-chromosome GDS files, one job per chromosome (`bash submitJobs_SV.sh /path/SV.chr{CHR}.gds`).
5. Read the annotation back:
   ```r
   genofile <- seqOpen("SV.chr22.gds")
   anno <- read.gdsn(index.gdsn(genofile, "annotation/info/FunctionalAnnotationSV"))
   ```
   You can also export it with `Scripts/UTL/FAVORaGDSToText.R SV.chr22.gds out.tsv FunctionalAnnotationSV`.

## Input SV representation

SVs are read from the GDS (`chromosome`, `position`, `allele`, `annotation/id`) together with the INFO fields
`SVTYPE`, `END`, `SVLEN`, `CHR2` and `END2`/`POS2`. The field names can be changed in `config_SV.R`.
The pipeline supports:

* symbolic alleles (`<DEL>`, `<DUP>`, `<INV>`, `<INS>`, `<INS:ME:ALU>`, `<CNV>`, `<CN0>`, ...),
* breakends (`N[chr2:123[`, `BND`/`CTX`/`TRA`),
* sequence-resolved SVs without `SVTYPE`. These are typed as DEL/INS from the REF/ALT length.

SV types are normalized to DEL, DUP, CNV (multi-allelic copy-number), INV, INS, BND, CTX and CPX.
Spanning SVs (DEL/DUP/CNV/INV/CPX) are annotated over `[POS, END]`. INS/BND/CTX are annotated at the breakpoint(s),
using a ±`breakpoint_window` (50 bp) window for the region-based annotations.

## Annotation columns (`FunctionalAnnotationSV`)

One row per variant, in the variant order of the GDS file.

| Group | Columns | Source |
|---|---|---|
| Variant | `VarInfo` (chr-pos-ref-alt, as in the SNV aGDS), `sv_id`, `chromosome`, `position`, `end`, `svtype`, `svlen`, `chr2`, `end2` | input GDS |
| Gene consequence | `sv_consequence` (most severe), `genes_LOF`, `genes_COPY_GAIN`, `genes_INTRAGENIC_EXON_DUP`, `genes_PARTIAL_EXON_DUP`, `genes_INV_SPAN`, `genes_TSS_DUP`, `genes_UTR`, `genes_PROMOTER`, `genes_INTRONIC` | GENCODE v46 basic, Ensembl canonical protein-coding transcripts |
| Genes | `genes_overlapped` (all gene types), `n_genes_overlapped`, `n_protein_coding_overlapped`, `nearest_tss_gene`, `nearest_tss_distance` | GENCODE v46 |
| Dosage / constraint | `lof_max_pLI`, `lof_min_LOEUF`, `lof_max_pHaplo`, `lof_clingen_HI_genes`, `gain_max_pTriplo`, `gain_clingen_TS_genes`, `clingen_HI_regions`, `clingen_TS_regions` | gnomAD v4.1 constraint, Collins et al. 2022 (pHaplo/pTriplo), ClinGen dosage curation |
| Population | `gnomad_sv_id`, `gnomad_sv_AF`, `gnomad_sv_GRPMAX_AF`, `gnomad_sv_match` (reciprocal overlap, or breakpoint distance in bp for INS/BND) | gnomAD-SV v4.1 |
| Clinical | `clinvar_sv_n`, `clinvar_sv_id`, `clinvar_sv_clnsig`, `clinvar_sv_ro` | dbVar/ClinVar pathogenic or likely pathogenic SVs |
| Regulatory | `ccre_n`, `ccre_PLS_n`, `ccre_pELS_n`, `ccre_dELS_n`, `ccre_CTCF_n`, `ccre_other_n` | ENCODE SCREEN cCREs V4 |
| Repeats | `segdup_fraction`, `repeat_class_bp1`, `repeat_class_bp2` | UCSC genomicSuperDups, RepeatMasker |
| FAVOR | `favor_<score>_max`, `favor_<score>_mean` for aPC-Conservation, aPC-Epigenetics (active/repressed/transcription), aPC-Local-Nucleotide-Diversity, aPC-Mappability, aPC-Micro-RNA, aPC-Mutation-Density, aPC-Protein-Function, aPC-Proximity-To-Coding, aPC-Proximity-To-TSS/TES, aPC-Transcription-Factor, CADD PHRED, LINSIGHT, FATHMM-XF | FAVOR Essential/Full DB (Harvard Dataverse) |

### Gene consequence rules

These rules follow the gnomAD-SV (svtk annotate) categories. Each SV–gene pair gets its most severe consequence.

* **DEL** (and the loss side of CNV/CPX): `LOF` if it overlaps a coding exon, `UTR` if it overlaps a UTR, `INTRONIC` if it lies in the gene body only.
* **DUP**: `COPY_GAIN` if it covers the whole transcript. `INTRAGENIC_EXON_DUP` if both breakpoints are inside the transcript and coding exons are duplicated. `PARTIAL_EXON_DUP` if one breakpoint is inside and coding exons are duplicated. `TSS_DUP` if it covers the TSS only. Otherwise `UTR` or `INTRONIC`.
* **CNV**: deletion rules, plus `COPY_GAIN` for whole-gene copy-number gain.
* **INV**: `INV_SPAN` if it covers the whole transcript. `LOF` if a breakpoint is inside the transcript and coding sequence is inverted. Otherwise `UTR` or `INTRONIC`.
* **INS**: `LOF` in a coding exon, otherwise `UTR` or `INTRONIC`.
* **BND/CTX**: `LOF` if a breakpoint falls between the first and last coding base, otherwise `UTR` or `INTRONIC`.
* `PROMOTER`: the SV overlaps the 1 kb upstream of the TSS and nothing more severe applies. `INTERGENIC`: there is no consequence on any protein-coding gene.

The dosage columns summarize the genes with `LOF`/`INTRAGENIC_EXON_DUP` (`lof_*`) or `COPY_GAIN` (`gain_*`).
ClinGen regions are reported when a deletion (HI score 3) or duplication (TS score 3) covers at least 50% of the region.

### Population / clinical matching

* DEL/DUP/CNV/INV/CPX are matched to SVs of a compatible type (for example, DEL↔DEL/CNV) with reciprocal overlap ≥ `reciprocal_overlap` (0.5). The best overlap is reported.
* INS/BND/CTX are matched to the closest compatible SV within `insertion_distance` (100 bp).
* gnomAD-SV sites with FILTER `PASS` or `MULTIALLELIC` are used.

### FAVOR scores over SVs

For every base in the SV region, the FAVOR score is the maximum over the alleles at that position. The pipeline reports
the maximum and the mean over the region. SVs longer than `favor_max_span` (10 Mb) are summarized over their breakpoint
windows only. The scores are read from the CSV database files `chr{CHR}_{k}.csv`, located through
`Scripts/SQL/FAVORdatabase_chrsplit.csv`. Only the chunks overlapping SVs are read. Scores missing from the database
version in use are dropped. When a chromosome is given, only that chromosome's FAVOR files are read. The partner
breakpoint of an inter-chromosomal BND/CTX is then not included in the FAVOR summary, but it is still used for the gene
and population annotations.

Note: in the aGDS, missing character values are stored as empty strings (`""`), as in the SNV aGDS.
Missing numeric values are stored as `NA`.

## Validation and resource usage

* **Synthetic chr22 SVs** (16 SVs covering every SV class and consequence rule, for example an exonic NF2
  deletion → `LOF`, a whole-CHEK2 duplication → `COPY_GAIN`, an inversion spanning SMARCB1 → `INV_SPAN`, the 22q11.2
  DiGeorge deletion → ClinGen region ISCA-37446 and ClinVar pathogenic match): all consequences were as expected.
  The FAVOR max/mean over a 200 bp deletion matched an independent calculation from the raw FAVOR CSV rows exactly.
* **1KGP high-coverage SV calls (3,202 samples), chr22, 2,643 SVs**: 79% matched a gnomAD-SV v4.1 site (median
  reciprocal overlap ≈ 1.0). Matched allele frequencies correlate with 1KGP (Spearman ρ = 0.78). LOF SVs are rarer
  (median AF 1.6e-4 vs 6.2e-4 for intergenic SVs) and have higher FAVOR CADD maxima (44 vs 11).
* Runtime (FASRC, 1 core): resource preparation takes 2 min and 7 GB. Annotation of chr22 takes 2.7 min with
  7.6 GB MaxRSS, most of it reading the 3 FAVOR DB files (~1 min per 22 GB file; up to ~8 min under heavy storage load). Without FAVOR scores, annotation
  takes seconds. Building the chr22 GDS from the VCF takes 13 s.
