rm(list=ls())
gc()
### R package
library(gdsfmt)
library(SeqArray)
library(readr)
source('config.R')

CHRN <- as.numeric(commandArgs(TRUE)[1])

### make directory
system(paste0("mkdir ",output_path,"/chr",CHRN))
start_time<-Sys.time()

### chromosome number
## read info
DB_info <- read.csv(file_DBsplit,header=TRUE)
chr_splitnum <- sum(DB_info$Chr==CHRN)
DB_info_chr <- DB_info[DB_info$Chr==CHRN,]

## open GDS
genofile<-seqOpen(eval(parse(text = paste0("gds.chr",CHRN,".fn"))), readonly = FALSE)

CHR <- as.numeric(seqGetData(genofile, "chromosome"))
position <- as.integer(seqGetData(genofile, "position"))
REF <- as.character(seqGetData(genofile, "$ref"))
ALT <- as.character(seqGetData(genofile, "$alt"))

VarInfo_genome <- paste0(CHR,"-",position,"-",REF,"-",ALT)

## Generate VarInfo
for(kk in 1:dim(DB_info_chr)[1])
{
	print(kk)
	VarInfo <- VarInfo_genome[(position>=DB_info_chr$Start_Pos[kk])&(position<=DB_info_chr$End_Pos[kk])]
	VarInfo <- data.frame(VarInfo)
	write.csv(VarInfo,paste0(output_path,"/chr",CHRN,"/VarInfo_chr",CHRN,"_",kk,".csv"),quote=FALSE,row.names = FALSE)
}
gc()

for(kk in 1:chr_splitnum)
{
	print(kk)
	system(paste0(xsv," join --left VarInfo ",output_path,"/chr",CHRN,"/VarInfo_chr",CHRN,"_",kk,".csv variant_vcf ",DB_path,"/chr",CHRN,"_",kk,".csv > ",output_path,"/chr",CHRN,"/Anno_chr",CHRN,"_",kk,".csv"))
}

## merge info
Anno <- paste0(output_path,"/chr",CHRN,"/Anno_chr",CHRN,"_",seq(1:chr_splitnum),".csv ")
merge_command <- paste0(xsv," cat rows ",Anno[1])

for(kk in 2:chr_splitnum)
{
	merge_command <- paste0(merge_command,Anno[kk])
}

merge_command <- paste0(merge_command,"> ",output_path,"/chr",CHRN,"/Anno_chr",CHRN,".csv")
system(merge_command)

gc()
### read annotation data
FunctionalAnnotation <- read_csv(paste0(output_path,"/chr",CHRN,"/Anno_chr",CHRN,".csv"))

dim(FunctionalAnnotation)


## open GDS
Anno.folder <- addfolder.gdsn(index.gdsn(genofile, "annotation/info"), "FunctionalAnnotation")
add.gdsn(Anno.folder, "FunctionalAnnotation", val=FunctionalAnnotation, compress="LZMA_ra", closezip=TRUE)
genofile

seqClose(genofile)
end_time<-Sys.time()

print("time:")
end_time - start_time
