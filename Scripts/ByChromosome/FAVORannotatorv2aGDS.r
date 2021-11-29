#############################################################################
#Title:    FAVORannotator      
#Function: 
# * Build the GDS file from VCF files
# * Extract the variant sites from the GDS to obtain functional annotation.
# * Read the offline FAVOR V2 sql database and provide functional annotation.
# * Built in the functional annotation into GDS to build aGDS.
#Author:   Hufeng Zhou
#Time:     July 16th 2021 Initiall Develop May 3rd Major Revision
#############################################################################
library(gdsfmt)
library(SeqArray)
library(dplyr)
library(readr)
library(stringi)
library(stringr)
library(RPostgreSQL)
library(pryr)
#import function to query database
source('config.R')

mem_used()
#vcf.chr10.fn=as.character(commandArgs(TRUE)[1])
#gds.chr10.fn=as.character(commandArgs(TRUE)[2])
#seqVCF2GDS(vcf.fn, out.fn, header = NULL, genotype.var.name = "GT", info.import=NULL, fmt.import=NULL, ignore.chr.prefix="chr", raise.error=TRUE, verbose=TRUE)

genofile<-seqOpen(paste0("gds.chr",CHRN,".fn"), readonly = FALSE)
print("GDS built")
genofile
CHR<-seqGetData(genofile,"chromosome")
POS<-seqGetData(genofile,"position")
REF<-seqGetData(genofile,"$ref")
ALT<-seqGetData(genofile,"$alt")
#############################################################################
#Here VariantsAnno is the data frame needs to retrieve functional annotation
#It needs to be feed into the SQL
#############################################################################
VariantsAnno <- data.frame(CHR, POS, REF, ALT)
VariantsAnno$CHR <- as.character(VariantsAnno$CHR)
VariantsAnno$POS <- as.integer(VariantsAnno$POS)
VariantsAnno$REF <- as.character(VariantsAnno$REF)
VariantsAnno$ALT <- as.character(VariantsAnno$ALT)

genDelimitedVariantString <- function(inputs)  {
	quotedVariants <- dbQuoteString(ANSI(), inputs)
	collapsedVariants <- paste(quotedVariants, collapse = "),(")
	collapsedVariants <- paste0("(", collapsedVariants, ")")
	return(collapsedVariants)
}



#performs batch annotation using the offline database for the
#specified variants
batchAnnotate <- function(inputData)	{

		#parse input, silently ignoring variants which do not follow format
		variants <- paste(paste0(inputData[, 1]), inputData[, 2], inputData[, 3], inputData[, 4], sep='-')
		variants <- str_subset(variants, "^[:alnum:]+-\\d+-[:upper:]+-[:upper:]+$")
					
		#connect to database
		driver <- dbDriver("PostgreSQL")
    connection <- dbConnect(driver, dbname=paste0("DBNAME_chr",CHRN), host=paste0("HOST_chr",CHRN), port=paste0("PORT_chr",CHRN), user=USER_G, password=PASSWORD_G)
		#drop the variant table if it already exists
		variantTable <- "batch_variants"
		if(dbExistsTable(connection, variantTable))	{
			dbRemoveTable(connection, variantTable)	
		}

		#store variants in temporary table
		collapsedVariants <- genDelimitedVariantString(variants)
		query <- paste0("CREATE TEMP TABLE ", variantTable, " AS (VALUES ", collapsedVariants, ")")
		results <- data.frame()
		tryCatch({
			results <- dbGetQuery(connection, query)
		},
		error = function(e)	{
			stop("Error sending variants to database")
		},
		warning = function(w)	{
			stop("Error sending variants to database")
		})

		#retrieve data
		results <- data.frame()
		query <- paste0("SELECT offline_view.* FROM ", variantTable, " LEFT JOIN offline_view ON ", variantTable, ".column1=offline_view.variant_vcf")
		tryCatch({
			results <- dbGetQuery(connection, query)
		},
		error = function(e)	{
			stop("Error retrieving results from database")
		},
		warning = function(w)	{
		stop("Error retrieving results from database")
		})

		#clean up
		dbDisconnect(connection)

		return(results)
}
mem_used()

#############################################################################
#Query SQL database
#############################################################################

size = nrow(VariantsAnno);
VariantsAnnoTMP<-VariantsAnno[!duplicated(VariantsAnno),];
if(size > 50000000){
	VariantsBatchAnno <- data.frame();
	for(n in 1:(ceiling(size/2000000))){
		start <- (n-1)*2000000 + 1
		end <- min(n*2000000,size)
		dx<-VariantsAnnoTMP[start:end,]
		outdx<-batchAnnotate(dx)
		VariantsBatchAnno<-bind_rows(VariantsBatchAnno,outdx)
		print(paste0(("finish rounds/blocks: "),n))
	} 
	rm(dx,outdx)
	gc()
}else{
	VariantsBatchAnno<-batchAnnotate(VariantsAnnoTMP)
}
rm(VariantsAnnoTMP)
mem_used()
head(VariantsBatchAnno)

############################################
####This Variant is a searching key#########
############################################
Anno.folder <- addfolder.gdsn(index.gdsn(genofile, "annotation/info"), "FunctionalAnnotation")
#Anno.folder <- index.gdsn(genofile, "annotation/info/FunctionalAnnotation")
VariantsAnno <- dplyr::left_join(VariantsAnno,VariantsBatchAnno, by = c("CHR" = "chromosome","POS" = "position","REF" = "ref_vcf","ALT" = "alt_vcf"))
add.gdsn(Anno.folder, "FAVORannotator", val=VariantsAnno, compress="LZMA_ra", closezip=TRUE)
###Closing Up###
genofile
seqClose(genofile)
