[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

# **FAVORannotator**
This is an R program for performing functional annotation of whole-genome/whole-exome sequencing (WGS/WES) studies using [FAVOR](http://favor.genohub.org) backend database and build in the functional annotation data alongside with the input genotype data (VCF) to create all-in-one aGDS file. 

## Introduction

FAVORannotator is an open-source pipeline for functionally annotating and efficiently storing the genotype and variant functional annotation data of any genetic study (GWAS/WES/WGS). Functional annotation data is stored alongside with genotype data in the all-in-one aGDS file format, through using the FAVORannotator.  It facilitates downstream association analysis (Figure 1). It converts a genotype VCF input file to a GDS file, searches the variants in the GDS file using the FAVOR database for their functional annotations (in PostgreSQL), and then integrates these annotations into the GDS file to create an aGDS file. This aGDS file allows both genotype and functional annotation data to be stored in a single file (Figure 1). Furthermore, FAVORannotator can be conveniently integrated into the STAARpipeline, a rare variant association analysis tool for WGS/WES studies, to perform association analysis of large-scale genetic data.

![FAVORannotator workflow](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/figure1.png)

_Figure 1. FAVORannotator workflow. Represented in cartoon._

FAVORannotator accomplishes both high query speed and storage efficiency due to its optimized configurations and indices. Its offline nature avoids the excessive waiting time and file size restrictions of FAVOR online operation.  

It is important to know that different from other storage, the FAVORannotator backend database host on PostgreSQL is always on, always listen, and respond to queries all the time. Although FAVORannotator R program might be up and running and stops from time to time depends on the query data type and size, the FAVORannotator backend database is always on unless we specifically turn it off. We have to ensure the FAVORannotator backend database host on PostgreSQL is booted on and always running during the time of working.

Once the FAVORannotator backend database host on PostgreSQL is booted on and running. We need to tell FAVORannotator R program where the database instance is by feeding in the following identification information, e.g. DBName, Host, Port, User, and Password.

This above specialized database setting, ensure the high query speed. Here shows the detail features described above.

![FAVORannotator Tech Features](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/figure4.png)

_Figure 2. FAVORannotator Technical Feature explained._


## Obtain the database
1. Download the FAVORannotator data file from here (download [URL](http://favor.genohub.org)).
2. Decompress the downloaded data. 

## FAVORannotator two versions (SQL and CSV)

There are two versions of FAVORannotator: **SQL** and **CSV**. The postgreSQL version requires postgreSQL installation, and xsv version requires the XSV software dependencies. 

## Resource requirements

The resources utilized by the FAVORannotator R program and PostgreSQL instance are largely dependent upon the size of the input variants. 

For the FAVORannotator **SQL** version,60,000 samples of WGS variant sets were tested. The whole functional annotation finished in parallel in 1 hours using 24 computing cores (intel cascade lake with 2.9 GHz frequency). The memory consumed by each instance varies (usually within 18 GB), as there are different amounts of variants associated with each chromosome. 

For the FAVORannotator **CSV** version, 60,000 samples of WGS variant sets were tested.  The whole functional annotation finished in parallel in 1 hours using 24 computing cores (intel cascade lake with 2.9 GHz frequency). The memory consumed by each instance varies (usually within 18 GB), as there are different amounts of variants associated with each chromosome. 

## How to Use FAVORannotator

   Installing and run FAVORannotator to perform functional annotation requires only 2 major steps:

**I.	Install and prepare the back-end database (depends on different versions and systems).**

**II.	Run FAVORannotator (universal).**

This **(I) Installing and prepare the back-end database** step depends on whether the FAVORannotator is SQL version or CSV version and depends on different computing platforms. We will elaborate that more specifically in the following sections. We will first introduce how to **(II) Run the FAVORannotator** step, which is universal, no matter which versions or platforms you choose.   

## Run FAVORannotator

Once PostgreSQL database is booted up and running, backend database can be imported and then FAVORannotator can be executed as follows. 

1.	We can first create GDS file from the input VCF file. 

-	``` $ Rscript   convertVCFtoGDS.r  22 ```

2.	Now FAVORannotator is ready to run using following command:

-	``` $ Rscript   FAVORannotatorGDS.r  22 ```  


FAVORannotator divides by chromosome, import the database in the same way and run FAVORannotator as above. The only difference is config.R contains all the 22 chromosomes instances information (vcf file, gds file, database name, port, host, user, password).  For many clusters, we also provide the submitting scripts (submitJobs.sh) for submitting all 22 jobs to the cluster at the same time. This parallel computing enabled (by submitting 24 jobs according to the chromosomes) can further boost the performance.  

To simplify the parallel computing process, we also provide the submission scripts example here ([submission.sh](https://github.com/zhouhufeng/FAVORannotator/blob/main/Scripts/ByChromosome/submitJobs.sh)).

## Install and prepare the back-end database（FAVORannotator SQL version）

FAVORannotator SQL version relies upon the PostgreSQL Database Management System (DBMS) to achieve this.  PostgreSQL is a free and open-source software emphasizing extensibility and SQL compliance. It is a highly stable DBMS, backed by more than 20 years of community development. PostgreSQL is used to manage data for many web, mobile, geospatial, and analytics applications. Its advanced features, including diverse index types and configuration options, have been carefully selected for FAVORannotator so that end users do not need to worry about the implementation. 

How to use FAVORannotator will be explained from the following steps. PostgreSQL is available in most platforms. Thus, running FAVORannotator on each platform varies with the step (I) Installing and prepare the back-end database. We will first discuss the how to prepare and import backend database and all the following discussions will be elaborated.

Once PostgreSQL database is booted up and running, backend database can be imported and then FAVORannotator can be executed as follows. 

1. Once the server is running, Load the database: ```$ psql -h hostname -p port_number -U username -f your_file.sql databasename ```
   
   e.g. ```$ psql -h c02510 -p 582  -f /n/SQL/ByChr7FAVORDBxO.sql Chr7```

2. Now the PostgreSQL hosting FAVORannotator backend database is up and running it is listening for the query from FAVORannotator R program. 

3. Update the config.R file with the PostgreSQL instance information (database name, port, host, user, password):

```
USER_G <- 'userID';

PASSWORD_G <- 'secretPassWord'

vcf.fn<-"/n/location/input.vcf"

gds.fn<-"/n/location/output.gds"

DBNAME_G <- favor; 

HOST_G <- holy2c14409; 

PORT_G <- 8462; 
```


## Install PostgreSQL （FAVORannotator SQL version）

The following steps have been written for several primary scenarios in order to best account for all possibilities. Taking the widely used operating system (ubuntu) on cluster/cloud VM as an example. 


1. Install the required software on Ubuntu: ```$ sudo apt install postgresql postgresql-contrib```
2. Start and run PostgreSQL: 
 - ```$ sudo -i -u postgres ``` 
 - ```$ psql```

3. [Optional] If you want to install the huge database to external storage (Edit the configuration file).

-	The file is located at ```/etc/postgresql/12/main/postgresql.conf```
-	Change the line in file “postgresql.conf”, data_directory = 'new directory of external storage'
-	Reboot the data directory, ```$ sudo systemctl start postgresql```


### For more detailed instructions of how to use FAVORannotator in Harvard FASRC Slurm Cluster, please refer to the detailed tutorial [here](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Demos/FASRC.md). 


## Install and prepare the back-end database（FAVORannotator CSV version）

FAVORannotator (CSV version) depends on the xsv software and the **FAVOR** database in CSV format. Please install the <a href="https://github.com/BurntSushi/xsv">**xsv** software</a> and 
download the <a href="http://favor.genohub.org">**FAVOR** database CSV files</a> (under the "FAVORannotator" tab) before using the FAVORannotator (CSV version). 



## Install XSV （FAVORannotator CSV version）

The following steps have been written for several primary scenarios in order to best account for all possibilities. Taking the widely used operating system (ubuntu) on cluster/cloud VM as an example. 

Please install the <a href="https://github.com/BurntSushi/xsv">**xsv** software</a> accordingly.


## Dependencies
FAVORannotator imports R packages <a href="https://cran.r-project.org/web/packages/dplyr/index.html">dplyr</a>, <a href="https://bioconductor.org/packages/release/bioc/html/SeqArray.html">SeqArray</a>, 
<a href="https://bioconductor.org/packages/release/bioc/html/gdsfmt.html">gdsfmt</a>, 
<a href="https://cran.r-project.org/web/packages/RPostgreSQL/index.html">RPostgreSQL</a>, 
<a href="https://stringr.tidyverse.org">stringr</a>, 
<a href="https://readr.tidyverse.org">readr</a>, 
<a href="https://cran.r-project.org/web/packages/stringi/index.html">stringi</a>.
These dependencies should be installed before installing FAVORannotator.

FAVORannotator (SQL version) depends on the <a href="https://www.postgresql.org"> PostgreSQL software</a>.

FAVORannotator (CSV version) depends on the <a href="https://github.com/BurntSushi/xsv"> XSV software</a>.

## Data Availability
The whole-genome individual functional annotation data assembled from a variety of sources and the computed annotation principal components are available at the [Functional Annotation of Variant - Online Resource (FAVOR)](http://favor.genohub.org) site.
## Version
The current version is 0.0.3 (Jan 3rd, 2022).
## License
This software is licensed under GPLv3.

![GPLv3](http://www.gnu.org/graphics/gplv3-127x51.png)
[GNU General Public License, GPLv3](http://www.gnu.org/copyleft/gpl.html)
