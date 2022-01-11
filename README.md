[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

# **FAVORannotator**
This is an R program for performing functional annotation of whole-genome/whole-exome sequencing (WGS/WES) studies using [FAVOR](http://favor.genohub.org) backend database and build in the functional annotation data alongside with the input genotype data (VCF) to create all-in-one aGDS file. 

## Introduction

FAVORannotator is an open-source pipeline for functionally annotating and efficiently storing the genotype and variant functional annotation data of any genetic study (GWAS/WES/WGS). Functional annotation data is stored alongside with genotype data in the all-in-one aGDS file format, through using the FAVORannotator.  It facilitates downstream association analysis (Figure 1). It converts a genotype VCF input file to a GDS file, searches the variants in the GDS file using the FAVOR database for their functional annotations (in PostgreSQL), and then integrates these annotations into the GDS file to create an aGDS file. This aGDS file allows both genotype and functional annotation data to be stored in a single file (Figure 1). Furthermore, FAVORannotator can be conveniently integrated into the STAARpipeline, a rare variant association analysis tool for WGS/WES studies, to perform association analysis of large-scale genetic data.

![FAVORannotator workflow](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/figure1.png)

_Figure 1. FAVORannotator workflow. Represented in cartoon._

FAVORannotator accomplishes both high query speed and storage efficiency due to its optimized configurations and indices. Its offline nature avoids the excessive waiting time and file size restrictions of FAVOR online operation.  

It is important to know that different from other storage, the FAVORannotator backend database host on PostgreSQL is always on, always listen, and respond to queries all the time. Although FAVORannotator R program might be up and running and stops from time to time depends on the query data type and size, the FAVORannotator backend database is always on unless we specifically turn it off. We have to ensure the FAVORannotator backend database host on PostgreSQL is booted on and always running during the time of working.

Another important question is, once the FAVORannotator backend database host on PostgreSQL is booted on and running, how can our FAVORannotator R program find the backend database to talk to and execute the query? We need to tell FAVORannotator R program where the database instance is by feeding in the following identification information, e.g. DBName, Host, Port, User, and Password.

This above specialized database setting, ensure the high query speed. Here shows the detail features described above.

![FAVORannotator Tech Features](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/figure4.png)

_Figure 2. FAVORannotator Technical Feature explained._


## FAVORannotator two versions (postgreSQL and XSV)

There are two versions of FAVORannotator: **postgreSQL** and **xsv**. The postgreSQL version requires postgreSQL installation, and xsv version requires the xsv software dependenceies. 

## Resource requirements

The resources utilized by the FAVORannotator R program and PostgreSQL instance are largely dependent upon the size of the inputted variants. 

For the FAVORannotator **postgreSQL** version,60,000 samples of WGS variant sets were tested. The whole functional annotation finished in parallel in 1 hours using 24 computing cores (intel cascade lake with 2.9 GHz frequency). The memory consumed by each instance varies (usually within 18 GB), as there are different amounts of variants associated with each chromosome. 

For the FAVORannotator **XSV** version. 

## How to Use FAVORannotator

FAVORannotator relies upon the PostgreSQL Database Management System (DBMS) to achieve this.  PostgreSQL is a free and open-source software emphasizing extensibility and SQL compliance. It is a highly stable DBMS, backed by more than 20 years of community development. PostgreSQL is used to manage data for many web, mobile, geospatial, and analytics applications. Its advanced features, including diverse index types and configuration options, have been carefully selected for FAVORannotator so that end users do not need to worry about the implementation. Installing FAVORannotator requires only 2 major steps:

**I.	Install and run PostgreSQL (depends on different systems).**

**II.	Import FAVOR database into PostgreSQL and run FAVORannotator (universal).**

How to use FAVORannotator will be explained from the above 3 main steps. PostgreSQL is available in most platforms. Thus, running FAVORannotator on each only varies with regard to the **(I)** step, while steps **(II)** remain consistent. We will first discuss the universal steps of import backend database and run FAVORannotator **(II)**. Depends on the differences of the **(I)** step, all the following discussions will be elaborated.

## Import Database into PostgreSQL and Run FAVORannotator

Once PostgreSQL database is booted up and running, backend datbase can be imported and then FAVORannotator can be executed as follows. 

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

4.	We can first create GDS file from the input VCF file. 

-	``` $ Rscript   convertVCFtoGDS.r  22 ```

5.	Now FAVORannotator is ready to run using following command:

-	``` $ Rscript   FAVORannotatorGDS.r  22 ```  


FAVORannotator divides by chromosome, import the database in the same way and run FAVORannotator as above. The only difference is config.R contains all the 22 chromosomes instances information (vcf file, gds file, database name, port, host, user, password).  For many clusters, we also provide the submitting scripts (submitJobs.sh) for submitting all 22 jobs to the cluster at the same time. This parallel computing enabled (by submitting 24 jobs according to the chromosomes) can further boost the performance.  

To simplify the parallel computing process, we also provide the submission scripts example here ([submission.sh](https://github.com/zhouhufeng/FAVORannotator/blob/main/Scripts/ByChromosome/submitJobs.sh)).


## Install PostgreSQL

The following steps have been written for several primary scenarios in order to best account for all possibilities. Taking the widely used operating system (ubuntu) on cluster/cloud VM as an example. 

### Obtain the database
1. Download the FAVORannotator data file from here (download [URL](http://favor.genohub.org)).
2. Decompress the downloaded data. 

### How to install FAVORannotator (On Linux)
3. Install the required software
4. Ubuntu: ```$ sudo apt install postgresql postgresql-contrib```
5. Start and run PostgreSQL: 
 - ```$ sudo -i -u postgres ``` 
 - ```$ psql```

6. [Optional] If you want to install the huge database to external storage (Edit the configuration file).

-	The file is located at ```/etc/postgresql/12/main/postgresql.conf```
-	Change the line in file “postgresql.conf”, data_directory = 'new directory of external storage'
-	Reboot the data directory, ```$ sudo systemctl start postgresql```


### For more detailed instructions of how to use FAVORannotator in Harvard FASRC Slurm Cluster, please refer to the detailed tutorial [here](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Demos/FASRC.md). 


## Dependencies
FAVORannotator imports R packages <a href="https://cran.r-project.org/web/packages/dplyr/index.html">dplyr</a>, <a href="https://bioconductor.org/packages/release/bioc/html/SeqArray.html">SeqArray</a>, 
<a href="https://bioconductor.org/packages/release/bioc/html/gdsfmt.html">gdsfmt</a>, 
<a href="https://cran.r-project.org/web/packages/RPostgreSQL/index.html">RPostgreSQL</a>, 
<a href="https://stringr.tidyverse.org">stringr</a>, 
<a href="https://readr.tidyverse.org">readr</a>, 
<a href="https://cran.r-project.org/web/packages/stringi/index.html">stringi</a>.
These dependencies should be installed before installing FAVORannotator.

## Data Availability
The whole-genome individual functional annotation data assembled from a variety of sources and the computed annotation principal components are available at the [Functional Annotation of Variant - Online Resource (FAVOR)](http://favor.genohub.org) site.
## Version
The current version is 0.0.2 (November 30, 2021).
## License
This software is licensed under GPLv3.

![GPLv3](http://www.gnu.org/graphics/gplv3-127x51.png)
[GNU General Public License, GPLv3](http://www.gnu.org/copyleft/gpl.html)
