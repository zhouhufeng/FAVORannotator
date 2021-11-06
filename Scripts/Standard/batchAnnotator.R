#############################################################################
#
#Author: Theodore Arapoglou
#Time: April 23rd 2021
#############################################################################

library(RPostgreSQL)
library(stringr)

#import variables from configuration file
source('config.R')

#generates a DB safe, delimited string of variants from a list
genDelimitedVariantString <- function(inputs)  {
	
	#protect against sql injections
	quotedVariants <- dbQuoteString(ANSI(), inputs)
	
	#query information from db
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
	connection <- dbConnect(driver, dbname=DBNAME_G, host=HOST_G, port=PORT_G, user=USER_G, password=PASSWORD_G)

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
