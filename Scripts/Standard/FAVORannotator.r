#############################################################################
#Title:    FAVORannotator      
#Function: 
# * Build the GDS file from VCF files
# * Extract the variant sites from the GDS to obtain functional annotation.
# * Read the offline FAVOR V2 sql database and provide functional annotation.
# * Built in the functional annotation into GDS to build aGDS.
#Author:   Hufeng Zhou
#Time:     April 19th 2021
#############################################################################
library(gdsfmt)
library(SeqArray)
library(dplyr)
library(readr)
library(stringi)

#import function to query database
source('batchAnnotator.R')

vcf.fn=as.character(commandArgs(TRUE)[1])
out.fn=as.character(commandArgs(TRUE)[2])
#N=as.character(commandArgs(TRUE)[1])
#vcf.fn <- paste0("/n/location/",N,".vcf.bgz")
#out.fn <- paste0("/n/location/",N,".gds")
seqVCF2GDS(vcf.fn, out.fn, header = NULL, genotype.var.name = "GT", info.import=NULL, fmt.import=NULL, ignore.chr.prefix="chr", raise.error=TRUE, verbose=TRUE)
genofile<-seqOpen(out.fn, readonly = FALSE)
print("GDS built")
genofile
CHR<-seqGetData(genofile,"chromosome")
#CHR<-paste0("chr",seqGetData(genofile,"chromosome"))
POS<-seqGetData(genofile,"position")
REF<-seqGetData(genofile,"$ref")
ALT<-seqGetData(genofile,"$alt")
#############################################################################
#Here VariantsAnno is the data frame needs to retrieve functional annotation
#It needs to be feed into the SQL
#############################################################################
VariantsAnno <- data.frame(CHR, POS, REF, ALT)
VariantsAnno$CHR <- as.character(VariantsAnno$CHR)
#VariantsAnno$CHR <- as.integer(as.character(VariantsAnno$CHR))
#VariantsAnno$CHR <- as.integer(VariantsAnno$CHR)
VariantsAnno$POS <- as.integer(VariantsAnno$POS)
VariantsAnno$REF <- as.character(VariantsAnno$REF)
VariantsAnno$ALT <- as.character(VariantsAnno$ALT)
dim(VariantsAnno)
head(VariantsAnno)
rm(CHR,POS,REF,ALT)

VariantsBatchAnno <- data.frame(); 
size = nrow(VariantsAnno);
for(n in 1:(ceiling(size/2000000))){
	start <- (n-1)*2000000 + 1
	end <- min(n*2000000,size)
	dx<-VariantsAnno[start:end,]
	VariantsBatchAnno<-rbind(VariantsBatchAnno,batchAnnotate(dx))
	print(paste0(("finish rounds/blocks: "),n))
}

rm(VariantsAnno, dx)

#VariantsBatchAnno<-batchAnnotate(VariantsAnno)

############################################
####This Variant is a searching key#########
############################################
Anno.folder <- addfolder.gdsn(index.gdsn(genofile, "annotation/info"), "FunctionalAnnotation")
#Anno.folder <- index.gdsn(genofile, "annotation/info/FunctionalAnnotation")

#VariantsBatchAnno<-VariantsBatchAnno[!duplicated(VariantsBatchAnno),]
VariantsBatchAnno<-VariantsBatchAnno[!duplicated(VariantsBatchAnno[,c("chromosome","position","ref_vcf","alt_vcf")]),]
VariantsAnno <- dplyr::left_join(VariantsAnno,VariantsBatchAnno, by = c("CHR" = "chromosome","POS" = "position","REF" = "ref_vcf","ALT" = "alt_vcf"))
add.gdsn(Anno.folder, "OfflineV2", val=VariantsAnno.dbNSFP, compress="LZMA_ra", closezip=TRUE)

###Closing Up###
genofile
seqClose(genofile)
