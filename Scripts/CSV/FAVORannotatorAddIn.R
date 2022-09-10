args <- commandArgs(TRUE)
### mandatory

gds.file <- args[1]
print(paste0("gds.file:  ",gds.file))

chr <- as.numeric(args[2])
print(paste0("chr:  ",chr))

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
FunctionalAnnotation <- read_delim(paste0(dir_anno,"chr",chr,"/Anno_chr",chr,".csv"),delim = NULL)

dim(FunctionalAnnotation)

## open GDS
print("Before Adding Functional Annotation")
genofile <- seqOpen(gds.file, readonly = FALSE)
print("Working on Adding")
genofile
#Anno.folder <- addfolder.gdsn(index.gdsn(genofile, "annotation/info"), "FunctionalAnnotationTest1")
Anno.folder <- index.gdsn(genofile, "annotation/info")
add.gdsn(Anno.folder, "FAVORFullDBAug1st2022", val=FunctionalAnnotation, compress="LZMA_ra", closezip=TRUE)
genofile

print("Add in Functional Annotation")

seqClose(genofile)
end_time <- Sys.time()

print("time")
end_time - start_time

#system(paste0("mv ", gds.file, " ", outfile, ".gds"))

