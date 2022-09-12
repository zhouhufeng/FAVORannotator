#############################################################################
#Title:    FAVORannotatorAddIn      
#Function: 
# * Add in additional functional annotation into the aGDS file
#Author:   Hufeng Zhou
#Time:     Aug 27th 2022
#############################################################################

args <- commandArgs(TRUE)
### mandatory

gds.file <- args[1]
print(paste0("gds.file:  ",gds.file))

anno.file <- args[2]
print(paste0("anno.file:  ",anno.file))


start_time <- Sys.time()
use_compression <- "Yes"
print(paste0("use_compression: ",use_compression))

### annotation file
dir_anno <- "./"

### load required package
library(gdsfmt)
library(SeqArray)
library(readr)

### read annotation data
#FunctionalAnnotation <- read_csv(paste0(dir_anno,"chr",chr,"/Anno_chr",chr,".csv"))
FunctionalAnnotation <- read_delim(anno.file,delim = NULL)

dim(FunctionalAnnotation)

## open GDS
print("Before Adding Functional Annotation")
genofile <- seqOpen(gds.file, readonly = FALSE)
print("Working on Adding")
genofile

Anno.folder <- index.gdsn(genofile, "annotation/info")
add.gdsn(Anno.folder, "NewAnnotation", val=FunctionalAnnotation, compress="LZMA_ra", closezip=TRUE)

genofile

print("Add in Functional Annotation")

seqClose(genofile)
end_time <- Sys.time()

print("time")
end_time - start_time

