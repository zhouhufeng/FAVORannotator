###############################################################
#Title:    CreateGDSfromVCF      
#Function: Create GDS from VCF files.
#Author:   Hufeng Zhou
#Time:     April 19th 2021
###############################################################

library("SeqArray")
sessionInfo(package = "SeqArray")
N=as.character(commandArgs(TRUE)[1])
vcf.fn <- paste0("/n/location/",N,".vcf.bgz")
out.fn <- paste0("/n/location/",N,".gds")
seqVCF2GDS(vcf.fn, out.fn, header = NULL, genotype.var.name = "GT", info.import=NULL, fmt.import=NULL, ignore.chr.prefix="chr", raise.error=TRUE, verbose=TRUE)
