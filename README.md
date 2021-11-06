# **FAVORannotator Tutorial**

**Introduction of FAVORannotator**

FAVORannotator is an open-source pipeline for functionally annotating and efficiently storing the genotype and variant functional annotation data of any genetic study (GWAS/WES/WGS). This data is stored in the all-in-one aGDS file format using the FAVOR PostgreSQL database to facilitate downstream association analysis (Figure 1). It converts a genotype VCF input file to a GDS file, searches the variants in the GDS file using the FAVOR database for their functional annotations (stored using PostgreSQL), and then integrates these annotations into the GDS file to create an aGDS file. This aGDS file allows both genotype and functional annotation data to be stored in a single file (Figure 1). Furthermore, FAVORannotator can be conveniently integrated into the STAARpipeline, a rare variant association analysis tool for WGS/WES studies, to perform association analysis of large-scale genetic data.

![FAVORannotator workflow](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/figure1.png)

_Figure 1. FAVORannotator workflow. Represented in cartoon._

FAVORannotator accomplishes both high performance speed and storage efficiency due to its optimized configurations and indices. Its offline nature avoids the waiting time and file size restrictions necessary for online operation.

**Standard version and performance version of FAVORannotator**

There are two versions of FAVORannotator: **standard,** and **performance**. The standard version (Figure 2) requires limited computational resources and works using modest computing hardware. This is especially useful when users need to have a stable local access of FAVORannotator for frequent functional annotation of large-scale variant sets while lacking powerful computing hardware.

![FAVORannotator Standard Version](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/figure2.png)

_Figure 2. FAVORannotator Standard Version._

However, not all computing environments are the same. While some individual machines may have limited resources, computing clusters may grant access to abundant resources. Thus, it is important to have a version of FAVORannotator which can take advantage of the latter option. The speed of FAVORannotator can be significantly improved if its database is divided into 24 smaller databases – one for each chromosome. This is the manner in which the FAVORannotator performance version operates. By utilizing (Figure 3) more computational resources, it can run much faster than the standard version. This is especially useful when users need to have huge datasets to annotate on a local cluster, and speed its a top priority. A test on 60,000 whole genome sequencing data shows a 100X speed increase. Further differences between FAVORannotator Standard version and Performance Version are illustrated in Figures 2 and 3.

![FAVORannotator Performance Version](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Figures/figure3.png)

_Figure 3. FAVORannotator Performance Version._

FAVORannotator is also an integral part of the STAARpipeline, as it feeds the annotated genotype file into the STAARpipeline for common and rare variant association analysis of WGS studies.

**Resource requirements**

The resources utilized by the FAVORannotator R program and PostgreSQL instance are largely dependant upon the size of the inputted variants.

For the FAVORannotator **standard version** , a test involving 3000 samples of WGS variants sets required approximately 30 GB of memory total for the database instance, and an additional 30 GB of memory for the FAVORannotator R program. The whole functional annotation completed within 24 hours.

For the FAVORannotator **performance version** , 60,000 samples of WGS variant sets were tested. The whole functional annotation finished in parallel in 10 hours using 24 computing cores (intel cascade lake with 2.9 GHz frequency) and a total of 2.5 Tb memory. The memory consumed by each instance varies, as there are different amounts of variants associated with each chromosome. The following table lists the speed and resource consumption of each instance in the aforementioned test.

_Table 1. FAVORannotator Performance Version Resource Requirements._

![Resource Requirements](https://github.com/zhouhufeng/FAVORannotator/blob/main/Docs/Tutorial/Tables/table%201.png)


**Basics of PostgreSQL**

FAVORannotator relies upon the PostgreSQL Database Management System (DBMS) to achieve its performance. PostgreSQL is a free and open-source software emphasizing extensibility and SQL compliance. It is a highly stable DBMS, backed by more than 20 years of community development. PostgreSQL is used to manage data for many web, mobile, geospatial, and analytics applications. Its advanced features, including diverse index types and configuration options, have been carefully selected for FAVORannotator so that end users do not need to worry about the implementation. Installing FAVORannotator requires only 3 steps:

1. Install and run PostgreSQL.
2. Import FAVORv2 data into PostgreSQL.
3. Tell FAVORannotator where to find the running database.

How to use FAVORannotator will be explained from the above 3 main steps. PostgreSQL is available in most platforms. Thus, running FAVORannotator on each only varies with regard to the **(I)** step, while steps **(II)** and **(III)** remain consistent. Depends on the differences of the **(I)** step, all the following discussions will be elaborated.

**Run FAVORannotator locally (on different platforms)**

The following steps have been written for several primary scenarios in order to best account for all possibilities.

**Installing and running FAVORannotator on Harvard&#39;s slurm cluster**

-------------------**(N)** Obtain FAVORannotator database------------------------------------------------

1. Download the FAVORannotator data file from the FAVOR website: [http://favor.genohub.org](http://favor.genohub.org/)

-------------------**(I)** PostgreSQL installation and running-----------------------------------------------

1. Set up the database on slurm cluster
2. Install the fasrc VPN ([https://docs.rc.fas.harvard.edu/kb/vpn-setup/](https://docs.rc.fas.harvard.edu/kb/vpn-setup/))
3. Access the fasrc VDI ([https://docs.rc.fas.harvard.edu/kb/virtual-desktop/](https://docs.rc.fas.harvard.edu/kb/virtual-desktop/))
4. Create a folder on fasrc where you would like to store the database (mkdir \&lt;FAVORannotator Folder\&gt;)
5. Create a database server 1. Click &quot;My Interactive Sessions&quot; at the top. 2. Click &quot;Postgresql db&quot; on the left. 3. Configure the server

-------------------**(II)** Import FAVORv2 backend database into PostgreSQL --------------------------

1. Once the server is running, set up the database:

1) Load the postgres module

  1. On fasrc, the command is: _module load postgresql/12.2-fasrc01_

2) Log into the database: psql -h hostname -p port -d databasename;

  1. eg_: psql -h holy2c14409 -p 8462 -d favor_

3) Create the table

  1. _CREATE TABLE main (variant\_vcf text, chromosome text, position integer, ref\_vcf text, alt\_vcf text, cage text, genecode\_category text, genecode\_info text, genecode\_exonic\_category text, genecode\_exonic\_info text, genehancer text, cadd\_phred numeric, fathmm\_xf\_coding numeric, fathmm\_xf\_noncoding numeric, hs text, apc\_epigenetics numeric, apc\_conservation numeric, apc\_protein\_function numeric, apc\_local\_nucleotide\_diversity numeric, apc\_proximity\_to\_coding numeric, apc\_mutation\_density numeric, apc\_transcription\_factor numeric, apc\_proximity\_to\_tsstes numeric, apc\_micro\_rna numeric, apc\_epigenetics\_active numeric, apc\_epigenetics\_repressed numeric, apc\_epigenetics\_transcription numeric, apc\_conservation\_v2 numeric, apc\_local\_nucleotide\_diversity\_v2 numeric, apc\_proximity\_to\_coding\_v2 numeric);_
  2. Load the data: _COPY main FROM &#39;\&lt;path to file\&gt;/offlineData.csv&#39; CSV HEADER;_ This command can take several hours to complete, up to a day.
  3. Create the index: _CREATE INDEX ON main USING HASH(variant\_vcf);_ This command can take several hours to complete, up to a day.
  4. Create the view: _CREATE VIEW offline\_view AS SELECT \* FROM main_;

4) Set up credentials for FAVORannotator

  1. Create a new user: _CREATE ROLE annotator LOGIN PASSWORD &#39;DoMeAFAVOR&#39;;_
  2. Allow this user to view the necessary data: _GRANT SELECT ON offline\_view TO annotator;_

-------------------**(III)** Tell FAVORannotator where to find the running database ---------------------

1. Now the PostgreSQL hosting FAVORannotator backend database is up and running it is listening for the query from FAVORannotator R program.
2. Update the config.R file with the PostgreSQL instance information (database name, port, host, user, password):

- _DBNAME\_G <- ‘favor’;_
- _HOST\_G  <- holy2c14409;_
- _PORT\_G  <- 8462;_
- _USER\_G  <- userID;_
- _PASSWORD\_G  <- secretPassWord;_

1. Now FAVORannotator is ready to run using following command:

- _Rscript FAVORannotator.R Input.VCF  Output.aGDS;_

-------------------**(IV)**Other helpful commands -------------------------------------------------------------

1. Exit the database&#39;s command line: \q
2. Shut down the database server: scancel --signal=INT \&lt;job id\&gt;.0 1. This command must be run outside of the database&#39;s command line

**How install FAVORannotator on Mac OSX desktop**

Functional annotation through FAVORannotator is a streamlined process.

-------------------**(N)** Obtain FAVORannotator database------------------------------------------------

1. Download the FAVORannotator data file from the FAVOR website: [http://favor.genohub.org](http://favor.genohub.org/)

-------------------**(I)** PostgreSQL installation and running-----------------------------------------------

1. Set up the database on mac OSX
2. Install the postgreSQL using postgresapp ([https://postgresapp.com](https://postgresapp.com/))
3. Start the postgreSQL using the GUI terminal

-------------------**(II)** Import FAVORv2 backend database into PostgreSQL --------------------------

1. Once the server is running, set up the database:

1) Log into the database:

  1. _/Applications/Postgres.app/Contents/Versions/13/bin/psql -p5432 &quot;postgres&quot;_

2) Create the table

  1. _CREATE TABLE main (variant\_vcf text, chromosome text, position integer, ref\_vcf text, alt\_vcf text, cage text, genecode\_category text, genecode\_info text, genecode\_exonic\_category text, genecode\_exonic\_info text, genehancer text, cadd\_phred numeric, fathmm\_xf\_coding numeric, fathmm\_xf\_noncoding numeric, hs text, apc\_epigenetics numeric, apc\_conservation numeric, apc\_protein\_function numeric, apc\_local\_nucleotide\_diversity numeric, apc\_proximity\_to\_coding numeric, apc\_mutation\_density numeric, apc\_transcription\_factor numeric, apc\_proximity\_to\_tsstes numeric, apc\_micro\_rna numeric, apc\_epigenetics\_active numeric, apc\_epigenetics\_repressed numeric, apc\_epigenetics\_transcription numeric, apc\_conservation\_v2 numeric, apc\_local\_nucleotide\_diversity\_v2 numeric, apc\_proximity\_to\_coding\_v2 numeric);_

3) Load the data:

  1. _COPY main FROM &#39;\&lt;path to file\&gt;/offlineData.csv&#39; CSV HEADER_; This command can take several hours to complete, up to a day

4) Create the index: _CREATE INDEX ON main USING HASH(variant\_vcf);_ This command can take several hours to complete, up to a day

5) Create the view: _CREATE VIEW offline\_view AS SELECT \* FROM_ main;

6) Set up credentials for FAVORannotator

  1. Create a new user: _CREATE ROLE annotator LOGIN PASSWORD &#39;DoMeAFAVOR&#39;;_
  2. Allow this user to view the necessary data: _GRANT SELECT ON offline\_view TO annotator;_

-------------------**(III)** Tell FAVORannotator where to find the running database ---------------------

1. Now the PostgreSQL hosting FAVORannotator backend database is up and running it is listening for the query from FAVORannotator R program.
2. Update the config.R file with the PostgreSQL instance information (database name, port, host, user, password):

- _DBNAME\_G \&lt;- favor;_
- _HOST\_G \&lt;- &#39;localhost&#39;;_
- _PORT\_G \&lt;- 8462;_
- _USER\_G \&lt;- &#39;userID&#39;;_
- _PASSWORD\_G \&lt;- &#39;secretePassWord&#39;_

1. Now FAVORannotator is ready to run as follows:

- _Rscript FAVORannotator.R Input.VCF Output.aGDS_

-------------------**(IV)**Other helpful commands -------------------------------------------------------------

1. Exit the database&#39;s command line: \q
2. Shut down the database server: scancel --signal=INT \&lt;job id\&gt;.0 1. This command must be run outside of the database&#39;s command line

**How to install FAVORannotator on Linux Desktop/Workstations**

-------------------**(N)** Obtain FAVORannotator database------------------------------------------------

1. Download the FAVORannotator data file from the FAVOR website: [http://favor.genohub.org](http://favor.genohub.org/)

-------------------**(I)** PostgreSQL installation and running-----------------------------------------------

1. Install the required software
2. Ubuntu: 1. sudo apt-get update 2. sudo apt-get upgrade 3. sudo apt-get install r-base r-base-dev 4. sudo apt-get install postgresql
3. Edit the configuration file (optional, requires 8 GB of RAM)
  1. the file is located at /etc/postgresql/12/main/postgresql.conf
  2. uncomment and change the following variables: 1. shared\_buffers = 2GB 2. work\_mem = 1GB 3. maintenance\_work\_mem = 1GB 4. autovacuum\_work\_mem = 64MB 5. wal\_compression = on 6. log\_statement = &#39;all&#39;
  3. Start the database server: sudo pg\_ctlcluster, main start

-------------------**(II)** Import FAVORv2 backend database into PostgreSQL --------------------------

1. Once the server is running, set up the database:

1) Log into the database: psql -h \&lt;host name\&gt; -p \&lt;port\&gt; -d \&lt;database name\&gt;

  1. eg_: psql -h holy2c14409 -p 8462 -d favor_

2) Create the table

  1. _CREATE TABLE main (variant\_vcf text, chromosome text, position integer, ref\_vcf text, alt\_vcf text, cage text, genecode\_category text, genecode\_info text, genecode\_exonic\_category text, genecode\_exonic\_info text, genehancer text, cadd\_phred numeric, fathmm\_xf\_coding numeric, fathmm\_xf\_noncoding numeric, hs text, apc\_epigenetics numeric, apc\_conservation numeric, apc\_protein\_function numeric, apc\_local\_nucleotide\_diversity numeric, apc\_proximity\_to\_coding numeric, apc\_mutation\_density numeric, apc\_transcription\_factor numeric, apc\_proximity\_to\_tsstes numeric, apc\_micro\_rna numeric, apc\_epigenetics\_active numeric, apc\_epigenetics\_repressed numeric, apc\_epigenetics\_transcription numeric, apc\_conservation\_v2 numeric, apc\_local\_nucleotide\_diversity\_v2 numeric, apc\_proximity\_to\_coding\_v2 numeric);_
  2. Load the data: _COPY main FROM &#39;\&lt;path to file\&gt;/offlineData.csv&#39; CSV HEADER;_ This command can take several hours to complete, up to a day.
  3. Create the index: _CREATE INDEX ON main USING HASH(variant\_vcf);_ This command can take several hours to complete, up to a day.
  4. Create the view: _CREATE VIEW offline\_view AS SELECT \* FROM main_;

3) Set up credentials for FAVORannotator

  1. Create a new user: _CREATE ROLE annotator LOGIN PASSWORD &#39;DoMeAFAVOR&#39;;_
  2. Allow this user to view the necessary data: _GRANT SELECT ON offline\_view TO annotator;_

-------------------**(III)** Tell FAVORannotator where to find the running database ---------------------

1. Now the PostgreSQL hosting FAVORannotator backend database is up and running it is listening for the query from FAVORannotator R program.
2. Update the config.R file with the PostgreSQL instance information (database name, port, host, user, password):

- _DBNAME\_G \&lt;- favor;_
- _HOST\_G \&lt;- &#39;localhost&#39;;_
- _PORT\_G \&lt;- 8462;_
- _USER\_G \&lt;- &#39;userID&#39;;_
- _PASSWORD\_G \&lt;- &#39;secretPassWord&#39;_

1. Now FAVORannotator is ready to run as follows:

- _Rscript FAVORannotator.R Input.VCF Output.aGDS_

-------------------**(IV)**Other helpful commands -------------------------------------------------------------

1. Exit the database&#39;s command line: \q
2. Shut down the database server: scancel --signal=INT \&lt;job id\&gt;.0 1. This command must be run outside of the database&#39;s command line
