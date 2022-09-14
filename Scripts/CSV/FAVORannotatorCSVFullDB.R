#############################################################################
#Title:    FAVORannotatorCSVFullDB      
#Function: 
# * Build the aGDS file thorugh performing functional annotation, 
# * without pre-install the FAVOR Full Database, download database on the fly.
#Author:   Hufeng Zhou
#Time:     Sept 27th 2022
#############################################################################


args <- commandArgs(TRUE)
### mandatory

gds.file <- args[1]
print(paste0("gds.file:  ",gds.file))

#outfile <- args[2]
#print(paste0("outfile:  ",outfile))

chr <- as.numeric(args[2])
print(paste0("chr:  ",chr))
#chr<-19

use_compression <- "Yes"
print(paste0("use_compression: ",use_compression))

### output
output_path <- "./"

### make directory
system(paste0("mkdir ",output_path,"chr",chr))

### annotation file
dir_anno <- "./"


### load required package
library(gdsfmt)
library(SeqArray)
library(readr)


### chromosome number
## read info
DB_info <- read.csv(url("https://raw.githubusercontent.com/zhouhufeng/FAVORannotator/main/Scripts/SQL/FAVORdatabase_chrsplit.csv"),header=TRUE)
DB_info <- DB_info[DB_info$Chr==chr,]

### DB file
DB_path <- "./"

### xsv directory
xsv <- "~/.cargo/bin/xsv"




##########################################################################
### Step 0 (Download FAVOR Database)
##########################################################################
URLs <- data.frame(chr = c(1:22),
                   URL = c("https://dataverse.harvard.edu/api/access/datafile/6380374",  #1
                           "https://dataverse.harvard.edu/api/access/datafile/6380471",  #2
                           "https://dataverse.harvard.edu/api/access/datafile/6380732",  #3
                           "https://dataverse.harvard.edu/api/access/datafile/6381512",  #4
                           "https://dataverse.harvard.edu/api/access/datafile/6381457",  #5
                           "https://dataverse.harvard.edu/api/access/datafile/6381327",  #6
                           "https://dataverse.harvard.edu/api/access/datafile/6384125",  #7
                           "https://dataverse.harvard.edu/api/access/datafile/6382573",  #8
                           "https://dataverse.harvard.edu/api/access/datafile/6384268",  #9
                           "https://dataverse.harvard.edu/api/access/datafile/6380273",  #10
                           "https://dataverse.harvard.edu/api/access/datafile/6384154",  #11
                           "https://dataverse.harvard.edu/api/access/datafile/6384198",  #12
                           "https://dataverse.harvard.edu/api/access/datafile/6388366",  #13
                           "https://dataverse.harvard.edu/api/access/datafile/6388406",  #14
                           "https://dataverse.harvard.edu/api/access/datafile/6388427",  #15
                           "https://dataverse.harvard.edu/api/access/datafile/6388551",  #16
                           "https://dataverse.harvard.edu/api/access/datafile/6388894",  #17
                           "https://dataverse.harvard.edu/api/access/datafile/6376523",  #18
                           "https://dataverse.harvard.edu/api/access/datafile/6376522",  #19
                           "https://dataverse.harvard.edu/api/access/datafile/6376521",  #20
                           "https://dataverse.harvard.edu/api/access/datafile/6358305",  #21
                           "https://dataverse.harvard.edu/api/access/datafile/6358299")) #22

URL <- URLs[chr, "URL"]
system(paste0("wget --progress=bar:force:noscroll ", URLs[chr, "URL"]))
system(paste0("tar -xvf ", gsub(".*?([0-9]+).*", "\\1", URL)))

##########################################################################
### Step 1 (Varinfo_gds)
##########################################################################

## open GDS
genofile <- seqOpen(gds.file, readonly = FALSE)

genofile

CHR <- as.numeric(seqGetData(genofile, "chromosome"))
position <- as.integer(seqGetData(genofile, "position"))
REF <- as.character(seqGetData(genofile, "$ref"))
ALT <- as.character(seqGetData(genofile, "$alt"))

VarInfo_genome <- paste0(CHR,"-",position,"-",REF,"-",ALT)

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
start_time <- Sys.time()
chr_splitnum <- sum(DB_info$Chr==chr)

for(kk in 1:chr_splitnum)
{
  print(kk)
	#system(paste0(xsv," index ",DB_path,"/chr",chr,"_",kk,".csv))
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

##########################################################################
### Step 3 (gds2agds)
##########################################################################
### read annotation data
FunctionalAnnotation <- read_csv(paste0(dir_anno,"chr",chr,"/Anno_chr",chr,".csv"))
dim(FunctionalAnnotation)

Anno.folder <- index.gdsn(genofile, "annotation/info")
add.gdsn(Anno.folder, "FAVORFullDBAug1st2022", val=FunctionalAnnotation, compress="LZMA_ra", closezip=TRUE)
genofile

seqClose(genofile)
end_time <- Sys.time()

print("time")
end_time - start_time

#system(paste0("mv ", gds.file, " ", outfile, ".gds"))

