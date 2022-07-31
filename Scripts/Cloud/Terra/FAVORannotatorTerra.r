args <- commandArgs(TRUE)
### mandatory

gds.file <- args[1]
print(paste0("gds.file:  ",gds.file))

#outfile <- args[2]
#print(paste0("outfile:  ",outfile))

chr <- as.numeric(args[2])
print(paste0("chr:  ",chr))
#chr<-19

#use_compression <- args[4]
use_compression <- "Yes"
print(paste0("use_compression: ",use_compression))

##########################################################################
### Step 0 (Download FAVOR Database)
##########################################################################
URLs <- data.frame(chr = c(1:22),
                   URL = c("https://dataverse.harvard.edu/api/access/datafile/6170506",
                           "https://dataverse.harvard.edu/api/access/datafile/6170501",
                           "https://dataverse.harvard.edu/api/access/datafile/6170502",
                           "https://dataverse.harvard.edu/api/access/datafile/6170521",
                           "https://dataverse.harvard.edu/api/access/datafile/6170511",
                           "https://dataverse.harvard.edu/api/access/datafile/6170516",
                           "https://dataverse.harvard.edu/api/access/datafile/6170505",
                           "https://dataverse.harvard.edu/api/access/datafile/6170513",
                           "https://dataverse.harvard.edu/api/access/datafile/6165867",
                           "https://dataverse.harvard.edu/api/access/datafile/6170507",
                           "https://dataverse.harvard.edu/api/access/datafile/6170517",
                           "https://dataverse.harvard.edu/api/access/datafile/6170520",
                           "https://dataverse.harvard.edu/api/access/datafile/6170503",
                           "https://dataverse.harvard.edu/api/access/datafile/6170509",
                           "https://dataverse.harvard.edu/api/access/datafile/6170515",
                           "https://dataverse.harvard.edu/api/access/datafile/6170518",
                           "https://dataverse.harvard.edu/api/access/datafile/6170510",
                           "https://dataverse.harvard.edu/api/access/datafile/6170508",
                           "https://dataverse.harvard.edu/api/access/datafile/6170514",
                           "https://dataverse.harvard.edu/api/access/datafile/6170512",
                           "https://dataverse.harvard.edu/api/access/datafile/6170519",
                           "https://dataverse.harvard.edu/api/access/datafile/6170504"))

URL <- URLs[chr, "URL"]
system(paste0("wget --progress=bar:force:noscroll ", URLs[chr, "URL"]))
system(paste0("tar -xvf ", gsub(".*?([0-9]+).*", "\\1", URL)))

##########################################################################
### Step 1 (Varinfo_gds)
##########################################################################

### output
output_path <- "/cromwell_root/./"
#output_path <- "/root/./"

### make directory
system(paste0("mkdir ",output_path,"chr",chr))

### R package
library(gdsfmt)
library(SeqArray)
library(SeqVarTools)

### chromosome number
## read info
DB_info <- read.csv(url("https://raw.githubusercontent.com/xihaoli/STAARpipeline-Tutorial/main/FAVORannotator_csv/FAVORdatabase_chrsplit.csv"),header=TRUE)
DB_info <- DB_info[DB_info$Chr==chr,]

## open GDS
genofile <- seqOpen(gds.file)

genofile

CHR <- as.numeric(seqGetData(genofile, "chromosome"))
position <- as.integer(seqGetData(genofile, "position"))
REF <- as.character(seqGetData(genofile, "$ref"))
ALT <- as.character(seqGetData(genofile, "$alt"))

VarInfo_genome <- paste0(CHR,"-",position,"-",REF,"-",ALT)

seqClose(genofile)

## Generate VarInfo
for(kk in 1:dim(DB_info)[1])
{
  print(kk)

  VarInfo <- VarInfo_genome[(position>=DB_info$Start_Pos[kk])&(position<=DB_info$End_Pos[kk])]
  VarInfo <- data.frame(VarInfo)

  write.csv(VarInfo,paste0(output_path,"chr",chr,"/VarInfo_chr",chr,"_",kk,".csv"),quote=FALSE,row.names = FALSE)
}

##########################################################################
### Step 2 (Annotate)
##########################################################################

### xsv directory
#xsv <- "/cromwell_root/.cargo/bin/xsv"
xsv <- "/root/.cargo/bin/xsv"

### DB file
DB_path <- "n/holystore01/LABS/xlin/Lab/xihao_zilin/FAVORDB/"

### anno channel (subset)
anno_colnum <- c(1,8:12,15,16,19,23,25:36)

chr_splitnum <- sum(DB_info$Chr==chr)

for(kk in 1:chr_splitnum)
{
  print(kk)

  system(paste0(xsv," join --left VarInfo ",output_path,"chr",chr,"/VarInfo_chr",chr,"_",kk,".csv variant_vcf ",DB_path,"/chr",chr,"_",kk,".csv > ",output_path,"chr",chr,"/Anno_chr",chr,"_",kk,".csv"))
}

## merge info
Anno <- paste0(output_path,"chr",chr,"/Anno_chr",chr,"_",seq(1:chr_splitnum),".csv ")
merge_command <- paste0(xsv," cat rows ",Anno[1])

for(kk in 2:chr_splitnum)
{
  merge_command <- paste0(merge_command,Anno[kk])
}

merge_command <- paste0(merge_command,"> ",output_path,"chr",chr,"/Anno_chr",chr,".csv")

system(merge_command)

## subset
anno_colnum_xsv <- c()
for(kk in 1:(length(anno_colnum)-1))
{
  anno_colnum_xsv <- paste0(anno_colnum_xsv,anno_colnum[kk],",")
}
anno_colnum_xsv <- paste0(anno_colnum_xsv,anno_colnum[length(anno_colnum)])

system(paste0(xsv," select ",anno_colnum_xsv," ",output_path,"chr",chr,"/Anno_chr",chr,".csv > ",output_path,"chr",chr,"/Anno_chr",chr,"_STAARpipeline.csv"))

##########################################################################
### Step 3 (gds2agds)
##########################################################################

### annotation file
dir_anno <- "/cromwell_root/"
#dir_anno <- "/root/"
anno_file_name_1 <- "Anno_chr"
anno_file_name_2 <- "_STAARpipeline.csv"

### load required package
library(gdsfmt)
library(SeqArray)
library(SeqVarTools)
library(readr)

### read annotation data
FunctionalAnnotation <- read_csv(paste0(dir_anno,"chr",chr,"/",anno_file_name_1,chr,anno_file_name_2),
                                 col_types=list(col_character(),col_double(),col_double(),col_double(),col_double(),
                                                col_double(),col_double(),col_double(),col_double(),col_double(),
                                                col_character(),col_character(),col_character(),col_double(),col_character(),
                                                col_character(),col_character(),col_character(),col_character(),col_double(),
                                                col_double(),col_character()))

dim(FunctionalAnnotation)

## rename colnames
colnames(FunctionalAnnotation)[2] <- "apc_conservation"
colnames(FunctionalAnnotation)[7] <- "apc_local_nucleotide_diversity"
colnames(FunctionalAnnotation)[9] <- "apc_protein_function"

## open GDS
genofile <- seqOpen(gds.file, readonly = FALSE)

#Anno.folder <- addfolder.gdsn(index.gdsn(genofile, "annotation/info"), "FunctionalAnnotationTest1")
Anno.folder <- index.gdsn(genofile, "annotation/info")
if(use_compression == "YES")
{
  add.gdsn(Anno.folder, "FunctionalAnnotationJun1st2022", val=FunctionalAnnotation, compress="LZMA_ra", closezip=TRUE)
}else
{
  add.gdsn(Anno.folder, "FunctionalAnnotationJun1st2022", val=FunctionalAnnotation)
}
genofile

seqClose(genofile)

#system(paste0("mv ", gds.file, " ", outfile, ".gds"))

