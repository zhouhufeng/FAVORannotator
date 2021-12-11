#############################################################################
#Title:    convertVCFtoGDS      
#Function: 
# * Build the GDS file from VCF files
#Author:   Hufeng Zhou
#Time:     Nov 27th 2021
#############################################################################
library(gdsfmt)
library(SeqArray)

#import configuration file
source('config.R')

#vcf.chr10.fn=as.character(commandArgs(TRUE)[1])
#gds.chr10.fn=as.character(commandArgs(TRUE)[2])
CHRN=as.character(commandArgs(TRUE)[1])
seqVCF2GDS(eval(parse(text = paste0("vcf.chr",CHRN,".fn"))), eval(parse(text = paste0("gds.chr",CHRN,".fn"))), header = NULL, genotype.var.name = "GT", info.import=NULL, fmt.import=NULL, ignore.chr.prefix="chr", raise.error=TRUE, verbose=TRUE)
genofile<-seqOpen(eval(parse(text = paste0("gds.chr",CHRN,".fn"))), readonly = FALSE)
print("GDS built")

###Closing Up###
genofile
seqClose(genofile)
