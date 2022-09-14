[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

# **FAVORannotator**
FAVORannotator is an R program for performing functional annotation of any genetic study (e.g. Whole-Genome/Whole-Exome Sequencing/Genome-Wide Association Studies) using the [FAVOR backend database](https://favor.genohub.org) to create an annotated Genomic Data Structure (aGDS) file by storing the genotype data (in VCF or GDS format) and their functional annotation data in an all-in-one file.

## 1.Introduction

FAVORannotator is an open-source pipeline for functionally annotating and efficiently storing the genotype and variant functional annotation data of any genetic study (e.g. GWAS/WES/WGS). Functional annotation data is stored alongside with genotype data in an all-in-one aGDS file, through using the FAVORannotator. It then facilitates a wide range of functionally-informed downstream analyses (Figure 1).

FAVORannotator first converts a genotype VCF input file to a GDS file, searches the variants in the GDS file using the FAVOR database for their functional annotations, and then integrates these annotations into the GDS file to create an aGDS file. This aGDS file allows both genotype and functional annotation data to be stored in a single unified file (Figure 1). Furthermore, FAVORannotator can be conveniently integrated into [STAARpipeline](https://github.com/xihaoli/STAARpipeline), a rare variant association analysis tool, to perform association analysis of large-scale WGS/WES studies.

![FAVORannotator workflow](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/figure1.png)

_Figure 1. FAVORannotator workflow._

## 2. FAVORannotator differnt versions (SQL, CSV and Cloud Versions)

There are three main versions of FAVORannotator: **SQL**, **CSV** and **Cloud**. 

All the versions of FAVORannotator requires the same set of R libraries. The postgreSQL version requires postgreSQL installation, and CSV version requires the XSV software dependencies, Cloud version also requires the XSV software dependencies. 

All the FAVORannotator versions produced identical results and have similar performance, they only differ on the computing environments where FAVORannotator is deployed. Users can choose the different versions of FAVORannotator according to their computing platforms and use cases.   

FAVORannotator accomplishes both high query speed and storage efficiency due to its optimized configurations and indices. Its offline nature avoids the excessive waiting time and file size restrictions of FAVOR online operation.

### 2.1 FAVORannotator SQL version

It is important to note that the FAVORannotator SQL version PostgreSQL database differs from other storage because it needs to be running in order to be accessed. Thus, users must ensure the database is running before running annotations.

Once the FAVORannotator database is booted on and running, the following connection information must be specified for the FAVORannotator R program to access the database : DBName, Host, Port, User, and Password.

This above specialized database setting, ensure the high query speed. Here shows the detail features described above.

![FAVORannotator SQL version Tech Features](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/Figure2A.png)

_Figure 2. FAVORannotator SQL version workflow and differences highlights._

### 2.2 FAVORannotator CSV version

FAVORannotator CSV version database adopts the similar strategies of slicing both database and query inputs into smaller pieces and create index with each of the smaller chucks of database so as to achieve high performance and fast query speed as the SQL version.  

Differs from SQL version, CSV version database is static, and the query depends upon the xsv software, and therefore does not need to ensure the database is running before running annotations. The CSV version database is static and have much easier way to access through xsv software rather than acquiring the details of the running postgreSQL database, therefore widen the application of FAVORannotator in case computing platform does not support postgreSQL installation. 

![FAVORannotator CSV version Tech Features](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/Figure2B.png)

_Figure 3. FAVORannotator CSV version workflow and differences highlights._

### 2.3 FAVORannotator Cloud version

FAVORannotator Cloud version develop based on the CSV version (no pre-install database) adopts the similar strategies of slicing both database and query inputs into smaller pieces and create index with each of the smaller chucks of database so as to achieve high performance and fast query speed as the SQL/CSV version. But the FAVORannotator Cloud version download the FAVOR databases (Full Databaseor Essential Database) on the fly, requires no pre-install FAVOR database on the computing platform.   

Cloud version database download from ([FAVOR on Harvard Database](https://dataverse.harvard.edu/dataverse/favor) when FAVORannotator is executed, and after the download finishes, database is decompressed. The downloaded database is CSV version, which is static, and the query depends upon the xsv software therefore requires minimal dependencies and running database management systems.

![FAVORannotator Cloud version Tech Features](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/Figure2C.png)

_Figure 4. FAVORannotator Cloud version workflow and differences highlights._


## 3. Obtain the FAVOR Database
### 3.1 Obtain the database through direct downloading
1. Download the FAVORannotator data file from here ([download URL](http://favor.genohub.org), under the "FAVORannotator" tab).
2. Decompress the downloaded data.
3. Move the decompressedd database to the location, and update location info on '''config.R'''.

### 3.2 FAVOR databases host on Harvard Dataverse
FAVOR databases (Essential Database and Full Database) are hosting on ([Harvard Database](https://dataverse.harvard.edu/dataverse/favor)).


![FAVORannotator Cloud version Tech Features](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/HarvardDataVerse.png)

_Figure 5. FAVOR Databases on Harvard Dataverse (both Essential Database and Full Database)._


### 3.3 FAVOR Essential Database
([FAVOR Essential Database](https://doi.org/10.7910/DVN/1VGTJI)) containing 20 essential annotation scores. This FAVOR Essential Database is comprised of a collection of essential annotation scores for all possible SNVs (8,812,917,339) and observed indels (79,997,898) in Build GRCh38/hg38.

### 3.4 FAVOR Full Database
([FAVOR Full Database](https://doi.org/10.7910/DVN/KFUBKG)) containing 160 essential annotation scores. This FAVOR Full Database is comprised of a collection of full annotation scores for all possible SNVs (8,812,917,339) and observed indels (79,997,898) in Build GRCh38/hg38.


## 4. Resource requirements

The resources utilized by the FAVORannotator R program and PostgreSQL instance are largely dependent upon the size of the input variants. 

For the both the SQL and CSV versions of FAVORannotator, 60,000 samples of WGS variant sets were tested. The whole functional annotation finished in parallel in 1 hour using 24 computing cores (Intel cascade lake with 2.9 GHz frequency). The memory consumed by each instance varies (usually within 18 GB), as there are different amounts of variants associated with each chromosome.

## 5. Resource requirements

The resources utilized by the FAVORannotator R program and PostgreSQL instance are largely dependent upon the size of the input variants. 

For the both the SQL and CSV versions of FAVORannotator, 60,000 samples of WGS variant sets were tested. The whole functional annotation finished in parallel in 1 hour using 24 computing cores (Intel cascade lake with 2.9 GHz frequency). The memory consumed by each instance varies (usually within 18 GB), as there are different amounts of variants associated with each chromosome.



## 6. How to Use FAVORannotator

### 6.1 SQL/CSV versions

Installing and run FAVORannotator to perform functional annotation requires only 2 major steps:

**I.	Install software dependencies and prepare the database (process varies between systems).**

**II.	Run FAVORannotator (CSV or SQL versions).** 

The first step depends on whether FAVORannotator is the SQL or CSV version, and depends on different computing platforms. The following sections detail the process for major platforms. The second step (running FAVORannotator) will be detailed first, as it is consistent across platforms.


### 6.2 No pre-install databases version
There are a few user cases where download the database and configuration can be difficult, we simply the FAVORannotator by including the downloading, decompression, update config.R, include database location and output location all into the FAOVRannotator (no pre-install database version), users only need to put the R scripts in to the directory with enough storage and run the program. 

**I. Install software dependencies.**

**II. Run FAOVRannotator (no pre-install database version).**

### 6.3 Cloud version
Based on the FAOVRannotator (no pre-install database version), we develop the FAOVRannotator cloud-native app, in the cloud platform like Terra and DNAnexus, or on the virtual machines of Google Cloud Platform (GCP), Amazon Web Services (AWS), Microsoft Azure. With the dockerized images and workflow languages, FAVORannotator can be executed through the user-friendly and drag-and-drop graphical interface, with no scripting nor programming skills required from the users. 


![FAVORannotator Versions](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/versions.png)

_Figure 6. FAVORannotator Different Versions._


## 7. SQL version
### 7.1 Run FAVORannotator SQL version

Once PostgreSQL is running, the database can be imported and FAVORannotator can be executed as follows. Please find the R scripts in the ```Scripts/SQL/``` folder.

**Important: Before run FAVORannotator SQL version, please update the file locations and database info on the ```config.R``` file. FAVORannotator relies on the file locations and database info for the annotation.**

1.	Create GDS file from the input VCF file:

-	``` $ Rscript   convertVCFtoGDS.r  chrnumber ```

2.	Run FAVORannotator:

-	``` $ Rscript   FAVORannotatorv2aGDS.r  chrnumber ```  

chrnumber are the numeric number indicating which chromosome this database is reading from, chrnumber can be 1, 2, ..., 22. 

Scripts for submitting jobs for all chromosomes simultaneously have been provided. They use SLURM, which is supported by many high-performance clusters, and utilize parallel jobs to boost performance.

A SLURM script to simplify the process can be found here: ([submission.sh](https://github.com/zhouhufeng/FAVORannotator/blob/main/Scripts/SQL/submitJobs.sh)).

### 7.2 Install and prepare the database for SQL version

The FAVORannotator SQL version relies upon the PostgreSQL Database Management System (DBMS). PostgreSQL is a free and open-source application which emphasizes extensibility and SQL compliance. It is a highly stable DBMS, backed by more than 20 years of community development. PostgreSQL is used to manage data for many web, mobile, geospatial, and analytics applications. Its advanced features, including diverse index types and configuration options, have been carefully selected for FAVORannotator so that end users do not need to worry about the implementation.

How to use FAVORannotator will be explained from the following steps. PostgreSQL is available in most platforms. Each of these platforms has a different process for installing software, which affects the first step of installing FAVORannotator.
 
Once PostgreSQL is running, the database can be imported and FAVORannotator can be executed as follows:

1. Once the server is running, Load the database: ```$ psql -h hostname -p port_number -U username -f your_file.sql databasename ```
   
   e.g. ```$ psql -h c02510 -p 582  -f /n/SQL/ByChr7FAVORDBxO.sql Chr7```

2. Now the PostgreSQL hosting FAVORannotator backend database is up and running it is listening for the query from FAVORannotator R program. 

3. Update the config.R file with the PostgreSQL instance information (database name, port, host, user, password):

### 7.3 Install PostgreSQL (FAVORannotator SQL version)

The following steps have been written for major computing environments in order to best account for all possibilities. The following steps are for the widely used operating system (Ubuntu) on a virtual machine.

1. Install the required software:
 - ```$ sudo apt install postgresql postgresql-contrib```
2. Start and run PostgreSQL: 
 - ```$ sudo -i -u postgres``` 
 - ```$ psql```

3. [Optional] For installing the database on external storage (Edit the configuration file):
-	The file is located at ```/etc/postgresql/12/main/postgresql.conf```
-	Change the line in file “postgresql.conf”, data_directory = 'new directory of external storage'
-	Reboot the data directory, ```$ sudo systemctl start postgresql```

** For more detailed instructions on how to use FAVORannotator (SQL version) on the Harvard FASRC Slurm Cluster, please refer to the detailed tutorial [here](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Demos/FASRC.md).**


## 8. CSV version

### 8.1 Run FAVORannotator CSV version

Once CSV database is downloaded and decompressed, the database is readable by FAVORannotator can be executed as follows. Please find the R scripts in the ```Scripts/CSV/``` folder.

**Important: Before run FAVORannotator CSV version, please update the file locations and database info on the ```config.R``` file. FAVORannotator relies on the file locations and database info for the annotation.**

1.	Create GDS file from the input VCF file:

-	``` $ Rscript   convertVCFtoGDS.r  chrnumber ```

2.	Run FAVORannotator:

-	``` $ Rscript   FAVORannotatorv2aGDS.r chrnumber ```  

Scripts for submitting jobs for all chromosomes simultaneously have been provided. They use SLURM, which is supported by many high-performance clusters, and utilize parallel jobs to boost performance.

A SLURM script to simplify the process can be found here: ([submission.sh](https://github.com/zhouhufeng/FAVORannotator/blob/main/Scripts/SQL/submitJobs.sh)).

chrnumber are the numeric number indicating which chromosome this database is reading from, chrnumber can be 1, 2, ..., 22. 

### 8.2 Install and prepare the database for CSV version

**FAVORannotator** (CSV version) depends on the **xsv software** and the **FAVOR database** in CSV format. Please install the <a href="https://github.com/BurntSushi/xsv">**xsv software**</a> and 
download the <a href="http://favor.genohub.org">**FAVOR database** CSV files</a> (under the "FAVORannotator" tab) before using **FAVORannotator** (CSV version). 

### 8.3 Install xsv (FAVORannotator CSV version)

The following steps have been written for major computing environments in order to best account for all possibilities. The following steps are for the widely used operating system (Ubuntu) on a virtual machine.

1. Install Rust and Cargo:
 - ```$ curl https://sh.rustup.rs -sSf | sh```
2. Source the environment: 
 - ```$ source $HOME/.cargo/env``` 
3. Install xsv using Cargo:
 - ```$ cargo install xsv```



## 9 No pre-install databases version

### 9.1 Install xsv (No need to pre-install database but xsv need to be installed)

The following steps have been written for major computing environments in order to best account for all possibilities. The following steps are for the widely used operating system (Ubuntu) on a virtual machine.

1. Install Rust and Cargo:
 - ```$ curl https://sh.rustup.rs -sSf | sh```
2. Source the environment: 
 - ```$ source $HOME/.cargo/env``` 
3. Install xsv using Cargo:
 - ```$ cargo install xsv```



### 9.2 Run FAVORannotator no pre-install databases version

FAVOR database can be downloaded on the fly and decompressed automatically in the scripts, this version of FAVORannotator will remove the burden of download the backend database and update the ```config.R```. The database is downloaded and decompressed automatically and is readable by FAVORannotator can be executed as follows.

Please find the R scripts in the ```Scripts/SQL/``` folder.

**Important: This version of FAVORannotator no pre-install version does not need to update ```config.R``` file. This version of FAVORannotator directly download FAVORdatabase (Full or Essential versions) from the Harvard Dataverse to the default file locations and database info for the annotation. Just put the FAVORannotator script in the directory with ample storage all the database and index and intermediate files will be generated in the directory.**

1.	Create GDS file from the input VCF file:

-	``` $ Rscript   convertVCFtoGDS.r  input.vcf output.gds ```

2.	Run FAVORannotator for the FAVOR Essential Database:

-	``` $ Rscript   FAVORannotatorCSVEssentialDB.R  output.gds chrnumber ```  

3.	Run FAVORannotator for the FAVOR Full Database:

-	``` $ Rscript   FAVORannotatorCSVFullDB.R  output.gds chrnumber ```  

chrnumber are the numeric number indicating which chromosome this database is reading from, chrnumber can be 1, 2, ..., 22. 

Scripts for submitting jobs for all chromosomes simultaneously have been provided. They use SLURM, which is supported by many high-performance clusters, and utilize parallel jobs to boost performance.

A SLURM script to simplify the process can be found here: ([submission.sh](https://github.com/zhouhufeng/FAVORannotator/blob/main/Scripts/SQL/submitJobs.sh)).


## 10. Cloud Version
### 10.1 Run FAVORannotator Cloud Version

For Cloud environment, we simplified the process of database set up and remove the configration files. FAVOR database can be downloaded on the fly and decompressed automatically in the scripts, this version of FAVORannotator will remove the burden of download the backend database and update the ```config.R```. The database is downloaded and decompressed automatically and is capable of seamless integration to the workflow languages of the cloud platform. It currently works for cloud platforms like Terra, DNAnexus, etc. This tutorial uses Terra as an example to illustrate the functional annotation process. 

Please find the R scripts in the ```Scripts/Cloud/``` folder.

**Important: This version of FAVORannotator based on the no pre-install version does not need ```config.R``` file. This version of FAVORannotator directly download FAVORdatabase (Full or Essential versions) from the Harvard Dataverse to the default file locations and database info for the annotation. Just put the FAVORannotator script in the directory with ample storage all the database and index and intermediate files will be generated in the directory. These database files and intermediate files in the working directories will be removed in most cloud platforms.**

1.	Create GDS file from the input VCF file:

-	``` $ Rscript   convertVCFtoGDS.r  input.vcf output.gds ```

2.1	Run FAVORannotator for the FAVOR Essential Database:

-	``` $ Rscript FAVORannotatorTerraEssentialDB.R  output.gds chrnumber ```  

2.2.	Run FAVORannotator for the FAVOR Essential Database workflow:

-	``` $ java -jar cromwell-30.2.jar run FAVORannotatorEssentialDB.wdl --inputs file.json ```  


3.1	Run FAVORannotator for the FAVOR Full Database:

-	``` $ Rscript FAVORannotatorTerraEssentialDB.R  output.gds chrnumber ```  

chrnumber are the numeric number indicating which chromosome this database is reading from, chrnumber can be 1, 2, ..., 22. 

3.2.	Run FAVORannotator for the FAVOR Full Database workflow:

-	``` $ java -jar cromwell-30.2.jar run FAVORannotatorFullDB.wdl --inputs file.json ```  




![FAVORannotator Cloud Version](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/FAVORannotatorOnTerra.png)

_Figure 7. FAVORannotator Cloud Native Workflow on Terra._

## 11. Other Functions and Utilities

### 11.1 Convert VCF to aGDS

The following functions have been written for the purpose of converting VCF files to GDS/aGDS files. Please find the R scripts in the ```Scripts/UTL/``` folder. 

1. If users wish to convert VCF files that only contain genotype data into GDS files for the following annoation process:
 - ```$ Rscript convertVCFtoGDS.r input.vcf output.agds```


2. If users wish to convert Variant List that does not contain genotype data into GDS files for the following annoation process, after formatting the varaint list into the same VCF format, following R scripts can generate the empty GDS file that do not have genotype data just the varaint info:
 - ```$ Rscript convertVCFtoGDS.r inputVariantList.vcf output.agds```

3. If users already annotated VCF files using SpnEff,BCFTools, VarNote, Vcfanno and just wish to use aGDS for the following analysis, running the followign R script to convert annotated VCF files into aGDS file
 - ```$ Rscript convertVCFtoGDS.r annotated.vcf output.agds```



### 11.2 Add In Functional Annotations to aGDS
1. If users have external annotation sources or annotation in text tables that containing varaint sets, this function will be able to add in the new functional annotations into the new node of aGDS files:
 - ```$ Rscript FAVORannotatorAddIn.R input.agds AnnotationFile.tsv``` 


### 11.3 Extract Variant Functional Annotation to Text Tables from aGDS

1. If users prefer to have the Variant Functional Annotation results write into Text Tables, this Rscripts will be able to extract the functional annotation from aGDS and write into the text tables:
 - ```$ Rscript FAVORaGDSToText.R annotated.agds AnnotationTextTable.tsv```



## 12 Demo Using Real Example (1000 Genomes Project Data)

The following steps are the demo of how to FAVORannotato through using real genotype data from 1000 Genomes Project. From the step of obtaining the genotype data to the end point of creating aGDS are illustrated here below in the step by step process. 


### 12.1 Download the 1000G VCF

* If users can use command line below to obtain the ([1000G](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7059836/)) from the FTP ([1000 Genomes official website](http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/release/20190312_biallelic_SNV_and_INDEL/)), for the following process.
* Change the directory:
- ```$ cd ../../Data/TestData/1000G/ ``` 
* Download VCF to the directory (chr22):
- ```$ wget http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/release/20190312_biallelic_SNV_and_INDEL/ALL.chr22.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz ```
* Additionally if download chr1:
-``` $ wget http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/release/20190312_biallelic_SNV_and_INDEL/ALL.chr22.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz```


### 12.2 Convert VCF to GDS (chr22)

* Users can use command line below to convert the VCF to GDS.
* Change the directory:
- ```$ cd ../../../Scripts/UTL ``` 
* Run program to create GDS:
- ```$ Rscript convertVCFtoGDS.r ../../Data/TestData/Input/ALL.chr22.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz ../../Data/1000G/All.chr22.27022019.GRCh38.phased.gds ```
* And you will get the following output on terminal:
- ```
Tue Sep 13 09:41:36 2022
Variant Call Format (VCF) Import:
    file(s):
    ALL.chr22.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz (176.9M)
    file format: VCFv4.3
    the number of sets of chromosomes (ploidy): 2
    the number of samples: 2,548
    genotype storage: bit2
    compression method: LZMA_RA
    # of samples: 2548
Output:
    ../../Data/1000G/All.chr22.27022019.GRCh38.phased.gds
Parsing ALL.chr22.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz:
+ genotype/data   { Bit2 2x2548x1059079 LZMA_ra(1.98%), 25.5M }
Digests:
    sample.id  [md5: cc8afb576aed4d02012126932df7cad6]
    variant.id  [md5: 7c017d53094de68d314b6ad6d5731cee]
    position  [md5: 661ae4bc37d222bc242b379ac5b4103c]
    chromosome  [md5: 0f71906ff5f7af239ab447459e0fd340]
    allele  [md5: e03733491972cf350905736dc3ba7897]
    genotype  [md5: 310a491df81e5e5d015cfd8b0534c343]
    phase  [md5: feef32f42a2bebbf7e8aca22a385acef]
    annotation/id  [md5: af0e6be931baefc61425e7d80e8a7d6c]
    annotation/qual  [md5: de3d57a832d4552c0b92a592f0c30ab3]
    annotation/filter  [md5: 12aa343d303c14e0e724b2c3ac634d59]
    annotation/info/AF  [md5: 08ba51bd9a4fe4c8d65124d906d651be]
    annotation/info/AC  [md5: f50cf8580f617f21755b775c998a79a7]
    annotation/info/NS  [md5: 3f8d2c2fe9b610e0407b63069cdcca19]
    annotation/info/AN  [md5: 66dc16416504683004b60bf1259370d3]
    annotation/info/EAS_AF  [md5: 6268475df4da4ecfe85ff45a31985bf2]
    annotation/info/EUR_AF  [md5: 11f69a8880a343f916f428d428ee0e3e]
    annotation/info/AFR_AF  [md5: cde11169e2c527e079563326ec5eb603]
    annotation/info/AMR_AF  [md5: d85787dac3642db9f70cb05a9f22248a]
    annotation/info/SAS_AF  [md5: 70bb72b5bf8b850a68da314769c6b09d]
    annotation/info/VT  [md5: f7172d73a09bf45b641029eb2bde879e]
    annotation/info/EX_TARGET  [md5: 401261c4071060a74aa7994bdce29065]
    annotation/info/DP  [md5: 47cd81d4a60b61552a300cb09fa0a2cf]
Done.
[1] "GDS built"
Object of class SeqVarGDSClass
Tue Sep 13 09:44:39 2022
Optimize the access efficiency ...
Clean up the fragments of GDS file:
    open the file ../../Data/1000G/All.chr22.27022019.GRCh38.phased.gds (31.9M)
    # of fragments: 795
    save to ../../Data/1000G/All.chr22.27022019.GRCh38.phased.gds.tmp
    rename ../../Data/1000G/All.chr22.27022019.GRCh38.phased.gds.tmp (31.9M, reduced: 8.2K)
    # of fragments: 92
Object of class SeqVarGDSClass
File: ./Data/1000G/All.chr22.27022019.GRCh38.phased.gds (31.9M)
+    [  ] *
|--+ description   [  ] *
|--+ sample.id   { Str8 2548 LZMA_ra(7.84%), 1.6K } *
|--+ variant.id   { Int32 1059079 LZMA_ra(6.20%), 256.6K } *
|--+ position   { Int32 1059079 LZMA_ra(27.0%), 1.1M } *
|--+ chromosome   { Str8 1059079 LZMA_ra(0.02%), 617B } *
|--+ allele   { Str8 1059079 LZMA_ra(15.4%), 665.6K } *
|--+ genotype   [  ] *
|  |--+ data   { Bit2 2x2548x1059079 LZMA_ra(1.98%), 25.5M } *
|  |--+ extra.index   { Int32 3x0 LZMA_ra, 18B } *
|  \--+ extra   { Int16 0 LZMA_ra, 18B }
|--+ phase   [  ]
|  |--+ data   { Bit1 2548x1059079 LZMA_ra(0.01%), 48.1K } *
|  |--+ extra.index   { Int32 3x0 LZMA_ra, 18B } *
|  \--+ extra   { Bit1 0 LZMA_ra, 18B }
|--+ annotation   [  ]
|  |--+ id   { Str8 1059079 LZMA_ra(0.03%), 305B } *
|  |--+ qual   { Float32 1059079 LZMA_ra(0.02%), 777B } *
|  |--+ filter   { Int32,factor 1059079 LZMA_ra(0.02%), 777B } *
|  |--+ info   [  ]
|  |  |--+ AF   { Float32 1059079 LZMA_ra(7.72%), 319.6K } *
|  |  |--+ AC   { Int32 1059079 LZMA_ra(19.0%), 788.0K } *
|  |  |--+ NS   { Int32 1059079 LZMA_ra(0.02%), 777B } *
|  |  |--+ AN   { Int32 1059079 LZMA_ra(0.02%), 777B } *
|  |  |--+ EAS_AF   { Float32 1059079 LZMA_ra(5.73%), 237.2K } *
|  |  |--+ EUR_AF   { Float32 1059079 LZMA_ra(6.18%), 255.7K } *
|  |  |--+ AFR_AF   { Float32 1059079 LZMA_ra(8.56%), 354.1K } *
|  |  |--+ AMR_AF   { Float32 1059079 LZMA_ra(6.70%), 277.2K } *
|  |  |--+ SAS_AF   { Float32 1059079 LZMA_ra(6.45%), 266.8K } *
|  |  |--+ VT   { Str8 1059079 LZMA_ra(2.06%), 88.0K } *
|  |  |--+ EX_TARGET   { Bit1 1059079 LZMA_ra(6.62%), 8.6K } *
|  |  \--+ DP   { Int32 1059079 LZMA_ra(45.0%), 1.8M } *
|  \--+ format   [  ]
\--+ sample.annotation   [  ]

```


### 12.3 Annotate GDS using FAVORannotator to create aGDS (no pre-install version)

* Users can use following command to annotate GDS using FAVORannotator to create aGDS .
* Change the directory:
- ```$ cd ../../Data/1000G/ ``` 
* Copy FAVORannotator program to the current directory:
- ```$ cp ../../../Scripts/CSV/FAVORannotatorCSVEssentialDB.R .``` 
- ```$ cp ../../../Scripts/CSV/FAVORannotatorCSVFullDB.R . ``` 
* Run program to annotate GDS using FAVORannotator reading FAVOR Essential Database to create aGDS(chr22):
- ```$ Rscript FAVORannotatorCSVEssentialDB.R All.chr22.27022019.GRCh38.phased.gds 22 ```
* And you will get the following output on terminal:
- ```$ ```


* Run program to annotate GDS using FAVORannotator reading FAVOR Full Database to create aGDS(chr22):
- ```$ Rscript FAVORannotatorCSVFullDB.R All.chr22.27022019.GRCh38.phased.gds 22 ```
* And you will get the following output on terminal:
- ```$ ```








## 13 Dependencies
FAVORannotator imports R packages: <a href="https://cran.r-project.org/web/packages/dplyr/index.html">dplyr</a>, <a href="https://bioconductor.org/packages/release/bioc/html/SeqArray.html">SeqArray</a>, <a href="https://bioconductor.org/packages/release/bioc/html/gdsfmt.html">gdsfmt</a>, <a href="https://cran.r-project.org/web/packages/RPostgreSQL/index.html">RPostgreSQL</a>, <a href="https://stringr.tidyverse.org">stringr</a>, <a href="https://readr.tidyverse.org">readr</a>, <a href="https://cran.r-project.org/web/packages/stringi/index.html">stringi</a>. These dependencies should be installed before running FAVORannotator.

FAVORannotator (SQL version) depends upon <a href="https://www.postgresql.org"> PostgreSQL software</a>.

FAVORannotator (CSV version) depends upon <a href="https://github.com/BurntSushi/xsv"> xsv software</a>.

## Data Availability
The whole-genome individual functional annotation data assembled from a variety of sources and the computed annotation principal components are available at the [Functional Annotation of Variant - Online Resource (FAVOR)](https://favor.genohub.org) site.

## Version
The current version is 1.1.1 (August 30th, 2022).
## License
This software is licensed under GPLv3.

![GPLv3](http://www.gnu.org/graphics/gplv3-127x51.png)
[GNU General Public License, GPLv3](http://www.gnu.org/copyleft/gpl.html)
