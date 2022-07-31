rm(list=ls())
gc()
### R package
library(gdsfmt)
library(SeqArray)
library(SeqVarTools)
library(readr)

CHRN <- as.numeric(commandArgs(TRUE)[1])

### make directory
system(paste0("mkdir ",output_path,"chr",CHRN))

### chromosome number
## read info
DB_info <- read.csv(file_DBsplit,header=TRUE)
DB_info <- DB_info[DB_info$Chr==CHRN,]

## open GDS
genofile<-seqOpen(eval(parse(text = paste0("gds.chr",CHRN,".fn"))), readonly = FALSE)

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
	write.csv(VarInfo,paste0(output_path,"chr",CHRN,"/VarInfo_chr",CHRN,"_",kk,".csv"),quote=FALSE,row.names = FALSE)
}

rm(list=ls())
gc()

### anno channel (subset)
anno_colnum <- c(1,8,9:12,14,16,19,23,25:36)

### chromosome number
## annotate (seperate)
DB_info <- read.csv(file_DBsplit,header=TRUE)
chr_splitnum <- sum(DB_info$Chr==CHRN)

for(kk in 1:chr_splitnum)
{
	print(kk)
	system(paste0(xsv," join --left VarInfo ",output_path,"chr",CHRN,"/VarInfo_chr",CHRN,"_",kk,".csv variant_vcf ",DB_path,"/chr",CHRN,"_",kk,".csv > ",output_path,"chr",CHRN,"/Anno_chr",CHRN,"_",kk,".csv"))
}

## merge info
Anno <- paste0(output_path,"chr",CHRN,"/Anno_chr",CHRN,"_",seq(1:chr_splitnum),".csv ")
merge_command <- paste0(xsv," cat rows ",Anno[1])

for(kk in 2:chr_splitnum)
{
	merge_command <- paste0(merge_command,Anno[kk])
}

merge_command <- paste0(merge_command,"> ",output_path,"chr",CHRN,"/Anno_chr",CHRN,".csv")

system(merge_command)

## subset
anno_colnum_xsv <- c()
for(kk in 1:(length(anno_colnum)-1))
{
	anno_colnum_xsv <- paste0(anno_colnum_xsv,anno_colnum[kk],",")
}
anno_colnum_xsv <- paste0(anno_colnum_xsv,anno_colnum[length(anno_colnum)])

system(paste0(xsv," select ",anno_colnum_xsv," ",output_path,"chr",CHRN,"/Anno_chr",CHRN,".csv > ",output_path,"chr",CHRN,"/Anno_chr",CHRN,"_STAARpipeline.csv"))

rm(list=ls())
gc()
### read annotation data
FunctionalAnnotation <- read_csv(paste0(dir_anno,"chr",CHRN,"/",anno_file_name_1,CHRN,anno_file_name_2),
col_types=list(col_character(),col_double(),col_double(),col_double(),col_double(),
				col_double(),col_double(),col_double(),col_double(),col_double(),
				col_character(),col_character(),col_character(),col_double(),col_character(),
				col_character(),col_character(),col_character(),col_character(),col_double(),
				col_double(),col_character()))

dim(FunctionalAnnotation)

## rename colnames
colnames(FunctionalAnnotation)[2] <- "apc_conservation"
colnames(FunctionalAnnotation)[7] <- "apc_local_nucleotide_diversity"

## open GDS
genofile<-seqOpen(eval(parse(text = paste0("gds.chr",CHRN,".fn"))), readonly = FALSE)

Anno.folder <- addfolder.gdsn(index.gdsn(genofile, "annotation/info"), "FunctionalAnnotation")
add.gdsn(Anno.folder, "FunctionalAnnotation", val=FunctionalAnnotation, compress="LZMA_ra", closezip=TRUE)

seqClose(genofile)



