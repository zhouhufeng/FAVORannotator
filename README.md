[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

# **FAVORannotator**
FAVORannotator is an R program for performing functional annotation of any genetic study (e.g. Whole-Genome/Whole-Exome Sequencing/Genome-Wide Association Studies) using the [FAVOR backend database](https://favor.genohub.org) to create an annotated Genomic Data Structure (aGDS) file by storing the genotype data (in VCF or GDS format) and their functional annotation data in an all-in-one file.

## Introduction

FAVORannotator is an open-source pipeline for functionally annotating and efficiently storing the genotype and variant functional annotation data of any genetic study (e.g. GWAS/WES/WGS). Functional annotation data is stored alongside with genotype data in an all-in-one aGDS file, through using the FAVORannotator. It then facilitates a wide range of functionally-informed downstream analyses (Figure 1).

FAVORannotator first converts a genotype VCF input file to a GDS file, searches the variants in the GDS file using the FAVOR database for their functional annotations, and then integrates these annotations into the GDS file to create an aGDS file. This aGDS file allows both genotype and functional annotation data to be stored in a single unified file (Figure 1). Furthermore, FAVORannotator can be conveniently integrated into [STAARpipeline](https://github.com/xihaoli/STAARpipeline), a rare variant association analysis tool, to perform association analysis of large-scale WGS/WES studies.

![FAVORannotator workflow](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/figure1.png)

_Figure 1. FAVORannotator workflow._

## Obtain the database
1. Download the FAVORannotator data file from here ([download URL](http://favor.genohub.org), under the "FAVORannotator" tab).
2. Decompress the downloaded data. 

## FAVORannotator two versions (SQL and CSV)

There are two versions of FAVORannotator: **SQL** and **CSV**. 
The postgreSQL version requires postgreSQL installation, and xsv version requires the XSV software dependencies. 

FAVORannotator accomplishes both high query speed and storage efficiency due to its optimized configurations and indices. Its offline nature avoids the excessive waiting time and file size restrictions of FAVOR online operation.

### FAVORannotator SQL version

It is important to note that the FAVORannotator SQL version PostgreSQL database differs from other storage because it needs to be running in order to be accessed. Thus, users must ensure the database is running before running annotations.

Once the FAVORannotator database is booted on and running, the following connection information must be specified for the FAVORannotator R program to access the database : DBName, Host, Port, User, and Password.

This above specialized database setting, ensure the high query speed. Here shows the detail features described above.

![FAVORannotator SQL version Tech Features](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/Figure2A.png)

_Figure 2. FAVORannotator SQL version workflow and differences highlights._

### FAVORannotator CSV version

FAVORannotator CSV version database adopts the similar strategies of slicing both database and query inputs into smaller pieces and create index with each of the smaller chucks of database so as to achieve high performance and fast query speed as the SQL version.  

Differs from SQL version, CSV version database is static, and the query depends upon the xsv software, and therefore does not need to ensure the database is running before running annotations. The CSV version database is static and have much easier way to access through xsv software rather than acquiring the details of the running postgreSQL database, therefore widen the application of FAVORannotator in case computing platform does not support postgreSQL installation. 

![FAVORannotator CSV version Tech Features](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/Figure2B.png)

_Figure 3. FAVORannotator CSV version workflow and differences highlights._

## Resource requirements

The resources utilized by the FAVORannotator R program and PostgreSQL instance are largely dependent upon the size of the input variants. 

For the both the SQL and CSV versions of FAVORannotator, 60,000 samples of WGS variant sets were tested. The whole functional annotation finished in parallel in 1 hour using 24 computing cores (Intel cascade lake with 2.9 GHz frequency). The memory consumed by each instance varies (usually within 18 GB), as there are different amounts of variants associated with each chromosome.

## How to Use FAVORannotator

   Installing and run FAVORannotator to perform functional annotation requires only 2 major steps:

**I.	Install and prepare the database (process varies between systems).**

**II.	Run FAVORannotator (universal).** 

The first step depends on whether FAVORannotator is the SQL or CSV version, and depends on different computing platforms. The following sections detail the process for major platforms. The second step (running FAVORannotator) will be detailed first, as it is consistent across platforms.

## Run FAVORannotator

Once PostgreSQL is running, the database can be imported and FAVORannotator can be executed as follows.

1.	Create GDS file from the input VCF file:

-	``` $ Rscript   convertVCFtoGDS.r  22 ```

2.	Run FAVORannotator:

-	``` $ Rscript   FAVORannotatorGDS.r  22 ```  

Scripts for submitting jobs for all chromosomes simultaneously have been provided. They use SLURM, which is supported by many high-performance clusters, and utilize parallel jobs to boost performance.

A SLURM script to simplify the process can be found here: ([submission.sh](https://github.com/zhouhufeng/FAVORannotator/blob/main/Scripts/SQL/submitJobs.sh)).

## Install and prepare the database (FAVORannotator SQL version)

The FAVORannotator SQL version relies upon the PostgreSQL Database Management System (DBMS). PostgreSQL is a free and open-source application which emphasizes extensibility and SQL compliance. It is a highly stable DBMS, backed by more than 20 years of community development. PostgreSQL is used to manage data for many web, mobile, geospatial, and analytics applications. Its advanced features, including diverse index types and configuration options, have been carefully selected for FAVORannotator so that end users do not need to worry about the implementation.

How to use FAVORannotator will be explained from the following steps. PostgreSQL is available in most platforms. Each of these platforms has a different process for installing software, which affects the first step of installing FAVORannotator.
 
Once PostgreSQL is running, the database can be imported and FAVORannotator can be executed as follows:

1. Once the server is running, Load the database: ```$ psql -h hostname -p port_number -U username -f your_file.sql databasename ```
   
   e.g. ```$ psql -h c02510 -p 582 ??-f /n/SQL/ByChr7FAVORDBxO.sql Chr7```

2. Now the PostgreSQL hosting FAVORannotator backend database is up and running it is listening for the query from FAVORannotator R program. 

3. Update the config.R file with the PostgreSQL instance information (database name, port, host, user, password):

## Install PostgreSQL (FAVORannotator SQL version)

The following steps have been written for major computing environments in order to best account for all possibilities. The following steps are for the widely used operating system (Ubuntu) on a virtual machine.

1. Install the required software:
 - ```$ sudo apt install postgresql postgresql-contrib```
2. Start and run PostgreSQL: 
 - ```$ sudo -i -u postgres``` 
 - ```$ psql```

3. [Optional] For installing the database on external storage (Edit the configuration file):
-	The file is located at ```/etc/postgresql/12/main/postgresql.conf```
-	Change the line in file ???postgresql.conf???, data_directory = 'new directory of external storage'
-	Reboot the data directory, ```$ sudo systemctl start postgresql```

### For more detailed instructions on how to use FAVORannotator (SQL version) on the Harvard FASRC Slurm Cluster, please refer to the detailed tutorial [here](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Demos/FASRC.md).

## Install and prepare the database (FAVORannotator CSV version)

**FAVORannotator** (CSV version) depends on the **xsv software** and the **FAVOR database** in CSV format. Please install the <a href="https://github.com/BurntSushi/xsv">**xsv software**</a> and 
download the <a href="http://favor.genohub.org">**FAVOR database** CSV files</a> (under the "FAVORannotator" tab) before using **FAVORannotator** (CSV version). 

## Install xsv (FAVORannotator CSV version)

The following steps have been written for major computing environments in order to best account for all possibilities. The following steps are for the widely used operating system (Ubuntu) on a virtual machine.

1. Install Rust and Cargo:
 - ```$ curl https://sh.rustup.rs -sSf | sh```
2. Source the environment: 
 - ```$ source $HOME/.cargo/env``` 
3. Install xsv using Cargo:
 - ```$ cargo install xsv```

### For more detailed instructions on how to use FAVORannotator (CSV version), please refer to the detailed tutorial [here](https://github.com/xihaoli/STAARpipeline-Tutorial/blob/main/README.md).

## Dependencies
FAVORannotator imports R packages: <a href="https://cran.r-project.org/web/packages/dplyr/index.html">dplyr</a>, <a href="https://bioconductor.org/packages/release/bioc/html/SeqArray.html">SeqArray</a>, <a href="https://bioconductor.org/packages/release/bioc/html/gdsfmt.html">gdsfmt</a>, <a href="https://cran.r-project.org/web/packages/RPostgreSQL/index.html">RPostgreSQL</a>, <a href="https://stringr.tidyverse.org">stringr</a>, <a href="https://readr.tidyverse.org">readr</a>, <a href="https://cran.r-project.org/web/packages/stringi/index.html">stringi</a>. These dependencies should be installed before running FAVORannotator.

FAVORannotator (SQL version) depends upon <a href="https://www.postgresql.org"> PostgreSQL software</a>.

FAVORannotator (CSV version) depends upon <a href="https://github.com/BurntSushi/xsv"> xsv software</a>.

## Data Availability
The whole-genome individual functional annotation data assembled from a variety of sources and the computed annotation principal components are available at the [Functional Annotation of Variant - Online Resource (FAVOR)](https://favor.genohub.org) site.

## Version
The current version is 1.0.0 (March 30th, 2022).
## License
This software is licensed under GPLv3.

![GPLv3](http://www.gnu.org/graphics/gplv3-127x51.png)
[GNU General Public License, GPLv3](http://www.gnu.org/copyleft/gpl.html)
