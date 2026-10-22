#############################################################################
#Title:    convertSVVCFtoGDS
#Function:
# * Build the GDS file from a structural variant (SV) VCF file.
# * All INFO fields are kept (SVTYPE, END, SVLEN, CHR2, END2 are used for
# * annotation); only the GT FORMAT field is imported by default.
# * SV callers often declare INFO fields with a wrong Number (e.g. Number=1
# * for a list), so all non-Flag INFO fields are imported as Number=".".
#Usage:
# * Rscript convertSVVCFtoGDS.R input.vcf.gz output.gds [ncores]
#Author:   Hufeng Zhou
#Time:     Oct 21st 2026
#############################################################################
library(gdsfmt)
library(SeqArray)

args <- commandArgs(TRUE)
### mandatory

vcf.file <- args[1]
print(paste0("vcf.file:  ",vcf.file))

gds.file <- args[2]
print(paste0("gds.file:  ",gds.file))

ncores <- if(length(args) >= 3) as.integer(args[3]) else 1L
print(paste0("ncores:  ",ncores))

header <- seqVCF_Header(vcf.file)
header$info$Number[header$info$Type != "Flag"] <- "."

seqVCF2GDS(vcf.file, gds.file, header = header, genotype.var.name = "GT", info.import=NULL, fmt.import="GT",
           ignore.chr.prefix="chr", raise.error=TRUE, parallel=ncores, verbose=TRUE)
genofile<-seqOpen(gds.file, readonly = FALSE)
print("GDS built")

###Closing Up###
genofile
seqClose(genofile)
