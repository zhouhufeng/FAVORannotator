[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

# **FAVORannotator**
This is an R program for performing functional annotation of whole-genome/whole-exome sequencing (WGS/WES) studies using [FAVOR](http://favor.genohub.org) backend database.

## Introduction

FAVORannotator is an open-source pipeline for functionally annotating and efficiently storing the genotype and variant functional annotation data of any genetic study (GWAS/WES/WGS). This data is stored in the all-in-one aGDS file format using the FAVOR PostgreSQL database to facilitate downstream association analysis (Figure 1). It converts a genotype VCF input file to a GDS file, searches the variants in the GDS file using the FAVOR database for their functional annotations (stored using PostgreSQL), and then integrates these annotations into the GDS file to create an aGDS file. This aGDS file allows both genotype and functional annotation data to be stored in a single file (Figure 1). Furthermore, FAVORannotator can be conveniently integrated into the STAARpipeline, a rare variant association analysis tool for WGS/WES studies, to perform association analysis of large-scale genetic data.

![FAVORannotator workflow](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/figure1.png)

_Figure 1. FAVORannotator workflow. Represented in cartoon._

FAVORannotator accomplishes both high by chromosome speed and storage efficiency due to its optimized configurations and indices. Its offline nature avoids the waiting time and file size restrictions necessary for online operation.  
It is important to know that different from other storage, the FAVORannotator backend database host on PostgreSQL is always on, always listen, and respond to queries all the time. Although FAVORannotator R program might be up and running and stops from time to time depends on the query data type and size, the FAVORannotator backend database is always on unless we specifically turn it off. We have to ensure the FAVORannotator backend database host on PostgreSQL is booted on and always running during the time of working.
Another important question is, once the FAVORannotator backend database host on PostgreSQL is booted on and running, how can our FAVORannotator R program find the backend database to talk to and execute the query? We need to tell FAVORannotator R program where the database instance it is by feeding in the following identification information, e.g. DBName, Host, Port, User, and Password.
This above specialized database setting, ensure the high by chromosome of query, and fast query speed. Here shows the detail features described above.

![FAVORannotator Tech Features](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/figure4.png)

_Figure 2. FAVORannotator Technical Feature explained._


## FAVORannotator two versions (whole genome and by chromosome)

There are two versions of FAVORannotator: **whole genome** and **by chromosome**. The whole genome version (Figure 2) requires limited computational resources and works using modest computing hardware. This is especially useful when users need to have a stable local access of FAVORannotator for frequent functional annotation of large-scale variant sets while lacking powerful computing hardware. 

![FAVORannotator Version](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/versions1.png)

_Figure 3. FAVORannotator Different Versions._

However, not all computing environments are the same. While some individual machines may have limited resources, computing clusters may grant access to abundant resources. Thus, it is important to have a version of FAVORannotator which can take advantage of the latter option. The speed of FAVORannotator can be significantly improved if its database is divided into 24 smaller databases – one for each chromosome. This is the way the FAVORannotator by chromosome version operates. By utilizing (Figure 3) more computational resources, it can run much faster than the whole genome version. This is especially useful when users need to have huge datasets to annotate on a local cluster and speed it’s a top priority.  A test on 60,000 whole genome sequencing data shows a 100X speed increase. Further differences between FAVORannotator Whole Genome version and By Chromosome version are illustrated in Figures 3. FAVORannotator is also an integral part of the STAARpipeline, as it feeds the annotated genotype file into the STAARpipeline for common and rare variant association analysis of WGS studies. 

## Resource requirements

The resources utilized by the FAVORannotator R program and PostgreSQL instance are largely dependent upon the size of the inputted variants. 

For the FAVORannotator **whole genome** version, a test involving 3000 samples of WGS variants sets required approximately 30 GB of memory total for the database instance, and an additional 30 GB of memory for the FAVORannotator R program. The whole functional annotation completed within 24 hours. 

For the FAVORannotator **by chromosome** version, 60,000 samples of WGS variant sets were tested. The whole functional annotation finished in parallel in 10 hours using 24 computing cores (intel cascade lake with 2.9 GHz frequency). The memory consumed by each instance varies, as there are different amounts of variants associated with each chromosome. 

## How to Use FAVORannotator

FAVORannotator relies upon the PostgreSQL Database Management System (DBMS) to achieve its by chromosome.  PostgreSQL is a free and open-source software emphasizing extensibility and SQL compliance. It is a highly stable DBMS, backed by more than 20 years of community development. PostgreSQL is used to manage data for many web, mobile, geospatial, and analytics applications. Its advanced features, including diverse index types and configuration options, have been carefully selected for FAVORannotator so that end users do not need to worry about the implementation. Installing FAVORannotator requires only 2 major steps:

**I.	Install and run PostgreSQL (depends on different systems).**

**II.	Import FAVOR database into PostgreSQL and run FAVORannotator (universal).**

How to use FAVORannotator will be explained from the above 3 main steps. PostgreSQL is available in most platforms. Thus, running FAVORannotator on each only varies with regard to the **(I)** step, while steps **(II)** remain consistent. We will first discuss the universal steps of import backend database and run FAVORannotator **(II)**. Depends on the differences of the **(I)** step, all the following discussions will be elaborated.

## Import Database into PostgreSQL and Run FAVORannotator

Once PostgreSQL database is booted up and running, backend datbase can be imported and then FAVORannotator can be executed as follows. 

1. Once the server is running, set up the database:

1) Load the postgres module

  i. On fasrc, the command is: ```$ module load postgresql/12.2-fasrc01```

2) Log into the database: ```$ psql -h hostname -p port -d databasename;```

  ii. e.g. ```$ psql -h holy2c14409 -p 8462 -d favor```

3) Create the table

  iii. 
```
CREATE TABLE MAIN(
variant_vcf text,
chromosome text,
position integer,
ref_vcf text,
alt_vcf text,
apc_conservation numeric,
apc_conservation_v2 numeric,
apc_epigenetics numeric,
apc_epigenetics_active numeric,
apc_epigenetics_repressed numeric,
apc_epigenetics_transcription numeric,
apc_local_nucleotide_diversity numeric,
apc_local_nucleotide_diversity_v2 numeric,
apc_local_nucleotide_diversity_v3 numeric,
apc_mappability numeric,
apc_micro_rna numeric,
apc_mutation_density numeric,
apc_protein_function numeric,
apc_proximity_to_coding numeric,
apc_proximity_to_coding_v2 numeric,
apc_proximity_to_tsstes numeric,
apc_transcription_factor numeric,
cadd_phred numeric,
cage text,
fathmm_xf numeric,
genecode_comprehensive_category text,
genecode_comprehensive_info text,
genecode_comprehensive_exonic_info text,
genecode_comprehensive_exonic_category text,
genehancer text,
linsight numeric,
metasvm_pred text,
rdhs text,
rsid text);
```

iv. Load the data: ```COPY main FROM 'offlineData.csv' CSV HEADER;``` This command can take several hours to complete, up to a day.


v. Create the index: ```CREATE INDEX ON main USING HASH(variant\_vcf);``` This command can take several hours to complete, up to a day.
	

vi. Create the view: ```CREATE VIEW offline_view AS SELECT * FROM main;```


2. Now the PostgreSQL hosting FAVORannotator backend database is up and running it is listening for the query from FAVORannotator R program. 

3. Update the config.R file with the PostgreSQL instance information (database name, port, host, user, password):

```
•	USER_G <- 'userID';

•	PASSWORD_G <- 'secretPassWord'

•	vcf.fn<-"/n/location/input.vcf"

•	gds.fn<-"/n/location/output.gds"

•	DBNAME_G <- favor; 

•	HOST_G <- holy2c14409; 

•	PORT_G <- 8462; 
```

4.	We can first create GDS file from the input VCF file. 

•	``` $ Rscript   convertVCFtoGDS.r ```  

5.	Now FAVORannotator is ready to run using following command:

•	``` $ Rscript   FAVORannotatorGDS.r ```    


If using the FAVORannotator by chromosome version, import the database in the same way and run FAVORannotator exactly as above. The only difference is config.R contains all the 22 chromosomes instances information (vcf file, gds file, database name, port, host, user, password).  For many clusters, we also provide the submitting scripts (submitJobs.sh) for submitting all 22 jobs to the cluster at the same time. For by chromosome versions, the R scripts needs to feed in the chromosome number and the above command turns into following.  

•	``` $ Rscript   convertVCFtoGDS.r  22 ```

•	``` $ Rscript   FAVORannotatorGDS.r  22 ```

To simplify the parallel computing process, we also provide the submission scripts example here ([submission.sh](https://github.com/zhouhufeng/FAVORannotator/blob/main/Scripts/ByChromosome/submitJobs.sh)).


## Install PostgreSQL

The following steps have been written for several primary scenarios in order to best account for all possibilities. Taking the widely used operating system (ubuntu) on cluster/cloud VM as an example. 
### Obtain the database
1. Download the FAVORannotator data file from here **whole genome** version (download [URL](https://drive.google.com/file/d/1izzKJliuouG2pCJ6MkcXd_oxoEwzx5RQ/view?usp=sharing)) and **by chromosome** version (download [URL](https://drive.google.com/file/d/1Ccep9hmeWpIT_OH9IqS6p1MZbEonjG2z/view?usp=sharing)) or from the FAVOR website: [http://favor.genohub.org](http://favor.genohub.org/)
2. Decompress the downloaded data. 

### How to install FAVORannotator (On Linux)
3. Install the required software
4. Ubuntu: 1.	```$ sudo apt install postgresql postgresql-contrib```
5. Start and run PostgreSQL: 
 - ```1.	$sudo -i -u postgres ``` 
 - ```2.	$psql```

6. [Optional] If you want to install the huge database to external storage (Edit the configuration file).
	•	The file is located at /etc/postgresql/12/main/postgresql.conf
	•	Change the line in file “postgresql.conf”, data_directory = 'new directory of external storage'
	•	Reboot the data directory, $ sudo systemctl start postgresql

### Installing and running FAVORannotator on FASRC slurm cluster
3. Set up the database on slurm cluster
4. Install the fasrc VPN ([https://docs.rc.fas.harvard.edu/kb/vpn-setup/](https://docs.rc.fas.harvard.edu/kb/vpn-setup/))
5. Access the fasrc VDI ([https://docs.rc.fas.harvard.edu/kb/virtual-desktop/](https://docs.rc.fas.harvard.edu/kb/virtual-desktop/))
6. Create a folder on fasrc where you would like to store the database (mkdir \&lt;FAVORannotator Folder\&gt;)
7. Create a database server 1. Click “My Interactive Sessions”; at the top. 2. Click “Postgresql db”; on the left. 3. Configure the server

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
