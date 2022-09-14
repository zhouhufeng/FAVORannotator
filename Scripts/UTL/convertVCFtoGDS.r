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
seqVCF2GDS(vcf.fn, gds.fn, header = NULL, genotype.var.name = "GT", info.import=NULL, fmt.import=NULL, ignore.chr.prefix="chr", raise.error=TRUE, verbose=TRUE)
genofile<-seqOpen(gds.fn, readonly = FALSE)
print("GDS built")

###Closing Up###
genofile
seqClose(genofile)
