# **Step-by-step tutorial of running FAVORannotator on FASRC Slurm Cluster**

##

## FAVORannotator runs smoothly on FASRC slurm cluster. Like many other slurm cluster, FASRC has PostgreSQL installed.  And we can quickly boot up the PostgreSQL, on different nodes that vastly boost the performance and enables the parallel computing. 

## 1. Download the FAVORannotator data file from the FAVOR website: [http://favor.genohub.org](http://favor.genohub.org/).

## 2. Download the FAVORannotator data file from here **whole genome** version (download [URL](https://drive.google.com/file/d/1izzKJliuouG2pCJ6MkcXd_oxoEwzx5RQ/view?usp=sharing)) and **by chromosome** version (download [URL](https://drive.google.com/file/d/1Ccep9hmeWpIT_OH9IqS6p1MZbEonjG2z/view?usp=sharing)) or from the FAVOR website: [http://favor.genohub.org](http://favor.genohub.org/)
## 3. Set up the database on slurm cluster

## 4. Install the fasrc VPN ([https://docs.rc.fas.harvard.edu/kb/vpn-setup/](https://docs.rc.fas.harvard.edu/kb/vpn-setup/)). To connect to VPN, the Cisco AnyConnect client can be installed fromVPN portal ([https://downloads.rc.fas.harvard.edu](https://downloads.rc.fas.harvard.edu)) Note that you need to add @fasrc after your username in order to login.


## 5. Once the VPN has been connected, access the fasrc VDI ([https://docs.rc.fas.harvard.edu/kb/virtual-desktop/](https://docs.rc.fas.harvard.edu/kb/virtual-desktop/)). Following figure shows how the VDI interaface look like. 

![VDI Interface](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/FASRC1.jpg)

_Figure 1. VDI Interface._

## 7. Create a folder on fasrc where you would like to store the database ($ _mkdir /Directory/FAVORannotatorDataBase/_)

## 8. Then we can create a database server by 1. Click “My Interactive Sessions”; at the top. 2. Click “Postgresql db”; on the left. 3. Configure the server.
![My Interactive Sessions of postgreSQL](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/postgreSQLdb.png)

_Figure 2. My Interactive Sessions of postgreSQL._

## 9. The configuration of postgreSQL database server is shown through the following figure.  In the following example show in the figure 3, we input the folder directory for which we want the postgreSQL to store the database to, and also we input the database name. 
![postgreSQL configuration on VDI](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/createDBinstance.png)

_Figure 3. postgreSQL configuration on VDI._

## 10. The postgreSQL database server is up and running after a few minutes of the creating as shown through the following figure.  And on the page you will be able to find the assigned **host name** and the **port number**.These information is important for FAVORannotator R program to find the database instance.  In the following example show in the figure 4, the host name is holy7c04301, and the port number is 9011. 

![Active running postgreSQL database](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/runningInstance.png)

_Figure 4. Active running postgreSQL database._

## 11. Through the above configuration and booting up postgreSQL through VDI, we now know the following information of the running backend database host on the postgreSQL. DBName from step 9, Host and Port from step 10, and User and Password is your FASRC user name and password. These information can be input in the config.R file. 


## 12.  Once config.R file is updated, if the database has already been imported then FAVORannotator is ready to run. If it is the first to boot up the database instance, we can import the database in the following commands. 



## **Import Database into PostgreSQL and Run FAVORannotator**

Once PostgreSQL database is booted up and running, backend datbase can be imported and then FAVORannotator can be executed as follows. 

### 1. Once the server is running, set up the database:

1) Load the postgres module

  i. On fasrc, the command is: _module load postgresql/12.2-fasrc01_

2) Log into the database: psql -h hostname -p port -d databasename;

  ii. eg_: psql -h holy2c14409 -p 8462 -d favor_

3) Create the table

  iii. _CREATE TABLE MAIN(
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
rsid text);_

iv. Load the data: _COPY main FROM path to file/offlineData.csv; CSV HEADER;_ This command can take several hours to complete, up to a day.

v. Create the index: _CREATE INDEX ON main USING HASH(variant\_vcf);_ This command can take several hours to complete, up to a day.

vi. Create the view: _CREATE VIEW offline\_view AS SELECT \* FROM main_;

### 2. Now the PostgreSQL hosting FAVORannotator backend database is up and running it is listening for the query from FAVORannotator R program. 
### 3. Update the config.R file with the PostgreSQL instance information (database name, port, host, user, password):

•	USER_G <- 'userID';
•	PASSWORD_G <- 'secretPassWord'
•	vcf.fn<-"/n/location/input.vcf"
•	gds.fn<-"/n/location/output.gds"
•	DBNAME_G <- favor; 
•	HOST_G <- holy2c14409; 
•	PORT_G <- 8462; 

### 4.	We can first create GDS file from the input VCF file. 
•	$ Rscript   convertVCFtoGDS.r  

### 5.	Now FAVORannotator is ready to run using following command:
•	$ Rscript   FAVORannotatorGDS.r     

### If using the FAVORannotator by chromosome version, import the database in the same way and run FAVORannotator exactly as above. The only difference is config.R contains all the 22 chromosomes instances information (vcf file, gds file, database name, port, host, user, password).  For many clusters, we also provide the submitting scripts (submitJobs.sh) for submitting all 22 jobs to the cluster at the same time. For by chromosome versions, the R scripts needs to feed in the chromosome number and the above command turns into following.  
•	$ Rscript   convertVCFtoGDS.r  22
•	$ Rscript   FAVORannotatorGDS.r     22
### To simplify the parallel computing process, we also provide the submission scripts example here ([submission.sh](https://github.com/zhouhufeng/FAVORannotator/blob/main/Scripts/ByChromosome/submitJobs.sh)).

If interested in learning more about how to run FAVORannotator on FASRC slurm cluster, we have also prepared the recorded live demonstration here. 
[![Recorded Live Demo](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/LiveDemo.png)](https://youtu.be/_FRQLsFY4qI)
