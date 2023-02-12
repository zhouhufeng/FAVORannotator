#############################################################################
#Title:    convertVCFtoGDS      
#Function: 
# * Build the GDS file from VCF files
#Author:   Hufeng Zhou
#Time:     Aug 27th 2022
#############################################################################
library(gdsfmt)
library(SeqArray)

gds.fn=as.character(commandArgs(TRUE)[1])
vcf.fn=as.character(commandArgs(TRUE)[2])
#seqVCF2GDS(vcf.fn, gds.fn, parallel=10)
genofile<-seqOpen(gds.fn, readonly = FALSE)

###Closing Up###
genofile
seqClose(genofile)

###Write Out###
seqGDS2VCF(gds.fn,vcf.fn)
print("GDS built")

