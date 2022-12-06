#############################################################################
#Title:    convertVCFtoGDS      
#Function: 
# * Build the GDS file from BCF files
#Author:   Hufeng Zhou
#Time:     Aug 27th 2022
# This only runs on single core, therefore very slow.
#############################################################################
library(gdsfmt)
library(SeqArray)

vcf.fn=as.character(commandArgs(TRUE)[1])
gds.fn=as.character(commandArgs(TRUE)[2])
seqBCF2GDS(vcf.fn, gds.fn, storage.option="LZMA_RA", bcftools="bcftools")
genofile<-seqOpen(gds.fn, readonly = FALSE)
print("GDS built")

###Closing Up###
genofile
seqClose(genofile)
