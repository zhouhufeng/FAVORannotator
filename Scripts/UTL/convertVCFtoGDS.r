#############################################################################
#Title:    convertVCFtoGDS      
#Function: 
# * Build the GDS file from VCF files
#Author:   Hufeng Zhou
#Time:     Aug 27th 2022
#############################################################################
library(gdsfmt)
library(SeqArray)

vcf.fn=as.character(commandArgs(TRUE)[1])
gds.fn=as.character(commandArgs(TRUE)[2])
seqVCF2GDS(vcf.fn, gds.fn, parallel=10)
genofile<-seqOpen(gds.fn, readonly = FALSE)
print("GDS built")

###Closing Up###
genofile
seqClose(genofile)
