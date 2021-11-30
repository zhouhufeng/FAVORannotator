# **Step-by-step tutorial of running FAVORannotator on FASRC Slurm Cluster**

**Introduction of FAVORannotator on FASRC Slurm Cluster**

FAVORannotator runs smoothly on FASRC slurm cluster. Like many other slurm cluster, FASRC has PostgreSQL installed.  And we can quickly boot up the PostgreSQL, on different nodes that vastely boost the performance and enables the parallel computing. 

1. Download the FAVORannotator data file from the FAVOR website: [http://favor.genohub.org](http://favor.genohub.org/).

2. Download the FAVORannotator data file from here **whole genome** version (download [URL](https://drive.google.com/file/d/1izzKJliuouG2pCJ6MkcXd_oxoEwzx5RQ/view?usp=sharing)) and **by chromosome** version (download [URL](https://drive.google.com/file/d/1Ccep9hmeWpIT_OH9IqS6p1MZbEonjG2z/view?usp=sharing)) or from the FAVOR website: [http://favor.genohub.org](http://favor.genohub.org/)
4. Set up the database on slurm cluster

4. Install the fasrc VPN ([https://docs.rc.fas.harvard.edu/kb/vpn-setup/](https://docs.rc.fas.harvard.edu/kb/vpn-setup/)). To connect to VPN, the Cisco AnyConnect client can be installed fromVPN portal ([https://downloads.rc.fas.harvard.edu](https://downloads.rc.fas.harvard.edu)) Note that you need to add @fasrc after your username in order to login.


5. Once the VPN has been connected, access the fasrc VDI ([https://docs.rc.fas.harvard.edu/kb/virtual-desktop/](https://docs.rc.fas.harvard.edu/kb/virtual-desktop/)). Following figure shows how the VDI interaface look like. 

![VDI Interface](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/FASRC1.jpg)

_Figure 1. VDI Interface._

7. Create a folder on fasrc where you would like to store the database ($ _mkdir /Directory/FAVORannotatorDataBase/_)

8. Then we can create a database server by 1. Click “My Interactive Sessions”; at the top. 2. Click “Postgresql db”; on the left. 3. Configure the server.
![My Interactive Sessions of postgreSQL](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/postgreSQLdb.png)

_Figure 2. My Interactive Sessions of postgreSQL._

9. The configuration of postgreSQL database server is shown through the following figure.  In the following example show in the figure 3, we input the folder directory for which we want the postgreSQL to store the database to, and also we input the database name. 
![postgreSQL configuration on VDI](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/createDBinstance.png)

_Figure 3. postgreSQL configuration on VDI._

10. The postgreSQL database server is up and running after a few minutes of the creating as shown through the following figure.  And on the page you will be able to find the assigned **host name** and the **port number**.These information is important for FAVORannotator R program to find the database instance.  In the following example show in the figure 4, the host name is holy7c04301, and the port number is 9011. 

![Active running postgreSQL database](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/runningInstance.png)

_Figure 4. Active running postgreSQL database._


















However, not all computing environments are the same. While some individual machines may have limited resources, computing clusters may grant access to abundant resources. Thus, it is important to have a version of FAVORannotator which can take advantage of the latter option. The speed of FAVORannotator can be significantly improved if its database is divided into 24 smaller databases – one for each chromosome. This is the manner in which the FAVORannotator performance version operates. By utilizing (Figure 3) more computational resources, it can run much faster than the standard version. This is especially useful when users need to have huge datasets to annotate on a local cluster, and speed its a top priority. A test on 60,000 whole genome sequencing data shows a 100X speed increase. Further differences between FAVORannotator Standard version and Performance Version are illustrated in Figures 2 and 3.

![FAVORannotator Performance Version](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/figure3.png)

_Figure 3. FAVORannotator Performance Version._

FAVORannotator is also an integral part of the STAARpipeline, as it feeds the annotated genotype file into the STAARpipeline for common and rare variant association analysis of WGS studies.

It is important to know that different from other storage, the FAVORannotator backend database host on PostgreSQL is always on, always listen, and respond to queries all the time. Although FAVORannotator R program might be up and running and stops from time to time depends on the query data type and size, the FAVORannotator backend database is always on unless we specifically turn it off. We have to ensure the FAVORannotator backend database host on PostgreSQL is booted on and always running during the time of working. 

Another important question is, once the FAVORannotator backend database host on PostgreSQL is booted on and running, how can our FAVORannotator R program find the backend database to talk to and execute the query? We need to tell FAVORannotator R program where the database instance it is by feeding in the following identification information, e.g. DBName, Host, Port, User, and Password. 

This above specialized database setting, ensure the high performance of query, and fast query speed. 
Here shows the detail features described above. 
![FAVORannotator Tech Features](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/figure4.png)

_Figure 4. FAVORannotator Technical Feature explained._

**Resource requirements**

The resources utilized by the FAVORannotator R program and PostgreSQL instance are largely dependant upon the size of the inputted variants.

For the FAVORannotator **standard version** , a test involving 3000 samples of WGS variants sets required approximately 30 GB of memory total for the database instance, and an additional 30 GB of memory for the FAVORannotator R program. The whole functional annotation completed within 24 hours.

For the FAVORannotator **performance version** , 60,000 samples of WGS variant sets were tested. The whole functional annotation finished in parallel in 10 hours using 24 computing cores (intel cascade lake with 2.9 GHz frequency). The memory consumed by each instance varies, as there are different amounts of variants associated with each chromosome. The following table lists the speed and resource consumption of each instance in the aforementioned test.

_Table 1. FAVORannotator Performance Version Resource Requirements._

![Resource Requirements](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Tables/table1.png)


**Overall Introduction of FAVORannotator and backend database**

FAVORannotator relies upon the PostgreSQL Database Management System (DBMS) to achieve its performance. PostgreSQL is a free and open-source software emphasizing extensibility and SQL compliance. It is a highly stable DBMS, backed by more than 20 years of community development. PostgreSQL is used to manage data for many web, mobile, geospatial, and analytics applications. Its advanced features, including diverse index types and configuration options, have been carefully selected for FAVORannotator so that end users do not need to worry about the implementation. Installing FAVORannotator requires only 3 steps:

I.	Install and run PostgreSQL (depends on different systems).
II.	Import FAVOR database into PostgreSQL and run FAVORannotator (universal).


How to use FAVORannotator will be explained from the above 3 main steps. PostgreSQL is available in most platforms. Thus, running FAVORannotator on each only varies with regard to the **(I)** step, while steps **(II)** remain consistent. We will first discuss the universal steps of import backend database and run FAVORannotator **(II)**. Depends on the differences of the **(I)** step, all the following discussions will be elaborated.

**Import Database into PostgreSQL and Run FAVORannotator**

Once PostgreSQL database is booted up and running, backend datbase can be imported and then FAVORannotator can be executed as follows. 

1. Once the server is running, set up the database:

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

4) Set up credentials for FAVORannotator

  1. Create a new user: _CREATE ROLE annotator LOGIN PASSWORD DoMeAFAVOR;_
  2. Allow this user to view the necessary data: _GRANT SELECT ON offline\_view TO annotator;_

-------------------**(III)** Tell FAVORannotator where to find the running database ---------------------

2. Now the PostgreSQL hosting FAVORannotator backend database is up and running it is listening for the query from FAVORannotator R program.
3. Update the config.R file with the PostgreSQL instance information (database name, port, host, user, password):

- _DBNAME\_G <- ‘favor’;_
- _HOST\_G  <- 'localhost';_
- _PORT\_G  <- 8462;_
- _USER\_G  <- 'userID';_
- _PASSWORD\_G  <- 'secretPassWord';_

4. Now FAVORannotator is ready to run using following command:

- _Rscript FAVORannotator.R Input.VCF  Output.aGDS;_

**Install PostgreSQL on different platforms**

The following steps have been written for several primary scenarios in order to best account for all possibilities.

**Installing and running FAVORannotator on Harvard&#39;s slurm cluster**

-------------------**(N)** Obtain FAVORannotator database------------------------------------------------

1. Download the FAVORannotator data file from the FAVOR website: [http://favor.genohub.org](http://favor.genohub.org/)

-------------------**(I)** PostgreSQL installation and running-----------------------------------------------

2. Set up the database on slurm cluster
3. Install the fasrc VPN ([https://docs.rc.fas.harvard.edu/kb/vpn-setup/](https://docs.rc.fas.harvard.edu/kb/vpn-setup/))
4. Access the fasrc VDI ([https://docs.rc.fas.harvard.edu/kb/virtual-desktop/](https://docs.rc.fas.harvard.edu/kb/virtual-desktop/))
5. Create a folder on fasrc where you would like to store the database (mkdir \&lt;FAVORannotator Folder\&gt;)
6. Create a database server 1. Click &quot;My Interactive Sessions&quot; at the top. 2. Click &quot;Postgresql db&quot; on the left. 3. Configure the server


-------------------**(IV)** Other helpful commands -------------------------------------------------------------

11. Exit the database&#39;s command line: \q
12. Shut down the database server: scancel --signal=INT \&lt;job id\&gt;.0 1. This command must be run outside of the database&#39;s command line

**How install FAVORannotator on Mac OSX desktop**

Functional annotation through FAVORannotator is a streamlined process.

-------------------**(N)** Obtain FAVORannotator database------------------------------------------------

1. Download the FAVORannotator data file from the FAVOR website: [http://favor.genohub.org](http://favor.genohub.org/)

-------------------**(I)** PostgreSQL installation and running-----------------------------------------------

2. Set up the database on mac OSX
3. Install the postgreSQL using postgresapp ([https://postgresapp.com](https://postgresapp.com/))
4. Start the postgreSQL using the GUI terminal

-------------------**(II)** Import FAVORv2 backend database into PostgreSQL --------------------------

5. Once the server is running, set up the database:

1) Log into the database:

  i. _/Applications/Postgres.app/Contents/Versions/13/bin/psql -p 5432 "postgres";_


-------------------**(IV)** Other helpful commands -------------------------------------------------------------

9. Exit the database&#39;s command line: \q
10. Shut down the database server: scancel --signal=INT \&lt;job id\&gt;.0 1. This command must be run outside of the database&#39;s command line

**How to install FAVORannotator on Linux Desktop/Workstations**

-------------------**(N)** Obtain FAVORannotator database------------------------------------------------

1. Download the FAVORannotator data file from the FAVOR website: [http://favor.genohub.org](http://favor.genohub.org/)

-------------------**(I)** PostgreSQL installation and running-----------------------------------------------

2. Install the required software
3. Ubuntu: 1. sudo apt-get update 2. sudo apt-get upgrade 3. sudo apt-get install r-base r-base-dev 4. sudo apt-get install postgresql
4. Edit the configuration file (optional, requires 8 GB of RAM)
  1. the file is located at /etc/postgresql/12/main/postgresql.conf
  2. uncomment and change the following variables: 1. shared\_buffers = 2GB 2. work\_mem = 1GB 3. maintenance\_work\_mem = 1GB 4. autovacuum\_work\_mem = 64MB 5. wal\_compression = on 6. log\_statement = &#39;all&#39;
  3. Start the database server: sudo pg\_ctlcluster, main start


-------------------**(III)** Tell FAVORannotator where to find the running database ---------------------

6. Now the PostgreSQL hosting FAVORannotator backend database is up and running it is listening for the query from FAVORannotator R program.
7. Update the config.R file with the PostgreSQL instance information (database name, port, host, user, password):

- _DBNAME\_G <- ‘favor’;_
- _HOST\_G  <- 'localhost';_
- _PORT\_G  <- 8462;_
- _USER\_G  <- 'userID';_
- _PASSWORD\_G  <- 'secretPassWord';_

8. Now FAVORannotator is ready to run as follows:

- _Rscript FAVORannotator.R Input.VCF Output.aGDS_

-------------------**(IV)** Other helpful commands -------------------------------------------------------------

9. Exit the database&#39;s command line: \q
10. Shut down the database server: scancel --signal=INT \&lt;job id\&gt;.0 1. This command must be run outside of the database&#39;s command line
