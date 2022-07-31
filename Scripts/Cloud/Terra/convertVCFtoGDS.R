#############################################################################
#Title:    convertVCFtoGDS      
#Function: 
# * Build the GDS file from VCF files
#Author:   Hufeng Zhou
#Time:     Nov 27th 2021
#############################################################################
library(gdsfmt)
library(SeqArray)

args <- commandArgs(TRUE)
### mandatory

vcf.file <- args[1]
print(paste0("gds.file:  ",gds.file))

gds.file <- args[2]
print(paste0("gds.file:  ",gds.file))

seqVCF2GDS(vcf.file, gds.file, header = NULL, genotype.var.name = "GT", info.import=NULL, fmt.import=NULL, ignore.chr.prefix="chr", raise.error=TRUE, verbose=TRUE)
genofile<-seqOpen(gds.file, readonly = FALSE)
print("GDS built")

###Closing Up###
genofile
seqClose(genofile)
