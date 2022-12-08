# **Step-by-step tutorial of turning raw VCFs into well-organized aGDS files**
This is a tutorial for (1) preprocessing VCFs (2) generate GDS file from the preprocessed VCFs, with high priority in computing performance and speed. 


### Preprocessing file using BCFtools.
#### Prerequisites:
**BCFTools** (version 1.16) Please install the <a href="https://samtools.github.io/bcftools/">**BCFTools**</a>.

#### Step 0: Check up for errors and inconsistencies.
The following steps are important for the successful execution of BCFTools, the raw VCF files needs strictly follows the VCF format standard v4.2.
1. Fixed Headers [make sure all fields are defined in header].  
2. Remove Duplicated VCFs [Make sure there is no duplicated VCF files]. Otherwise duplicated entries will cause issues for the following steps.

Note: Most of the raw VCFs has issues with the header files that needs to be fixed, without this step BCFTools will not be able to process these VCF files. 

#### Step 1: Remove other FORMAT variables but only keep GT  [multi-core].
##### Script: 
- ```$ bcftools annotate -x ^FORMAT/GT ukb23156_c19_c12.vcf.gz  -Oz -o ./CVCF/ukb23156_c19_c12.vcf.gz ```
##### Input: All the raw VCF files ** ukb23156_c19_b0_v1.vcf.gz, ukb23156_c19_b2_v1.vcf.gz,..., ukb23156_c19_b64_v1.vcf.gz**
##### Output: The cleaned VCF files in the folder **./CVCF/** that within which has the same file name, but the FORMAT fields only contain GT. 

Note: This is computationally intensive, each smaller file is one multi-core instance, and multiple instances can be run in parallel to speed up the process. 
Finish 64 VCF processing in 12 core parallel, 
Finish 64 VCF processing in 32 core parallel,

#### Step 2: Break the multi-allelic sites into multiple rows of all the VCFs of each study.
##### Script: 
- ```$ bcftools norm -m -any  ./ConcatVCF/ukb23156_c19_c12.vcf.gz -Oz -o ./ConcatVCF/ukb23156_c19_c12.bk.vcf.gz```
##### Input: The VCF file contains multi-allelic sites ** ukb23156_c19_c12.vcf.gz **
##### Output: The VCF file has multi-allelic sites break into multiple lines ** ukb23156_c19_c12.bk.vcf.gz**. 

Note: multi-allelic sites cause issues for the following analysis, we usually break them into multiple rows in the preprocessing steps. 
Finish 64 VCF processing in 12 core parallel, 
Finish 64 VCF processing in 32 core parallel,

#### Step 3: Concat the smaller VCFs (sliced by variants) within each study into one VCF file. [Benchmark in UKBB 200k WES 24 mins] 
##### Script: 
- ```$ bcftools concat --threads 12 ./CVCF/ukb23156_c19_b*_v1.vcf.gz -Oz -o ./ConcatVCF/ukb23156_c19_c12.vcf.gz```
##### Input: All the cleaned VCF files in the folder **./CVCF/** with the VCF files name: ** ukb23156_c19_b0_v1.vcf.gz, ukb23156_c19_b2_v1.vcf.gz,..., ukb23156_c19_b64_v1.vcf.gz**
##### Output: The concatenated VCF files in the folder **./ConcatVCF/ukb23156_c19_c12.vcf.gz** that is the results of all the input VCFs concatenated by rows into one big VCF that has the same columns. 

Note: This is computationally intensive, multi-core function enabled to speed up the process. Concat is only for VCFs has same samples [columns] just need to concat the variants [rows], if VCF is sliced by samples, you should refer to the following steps using the merge function. 
Finish concat 64 VCF processing in 12 core parallel,24 mins 
Finish concat 64 VCF processing in 32 core parallel,20 mins



#### Step 3: Convert the merged VCFs per chromosomes into GDSs (per chromosome) [Benchmarked using UKBB 200k WES chr19 VCF takes 72 mins].
##### Script: 
- ```$ Rscripts ./convertVCFtoGDS.r ./MergedVCF/ukbb.merged.bk.nm.vcf.gz ./MergedGDS/ukbb.merged.bk.nm.gds```
Script: <a href="https://github.com/zhouhufeng/FAVORannotator/blob/main/Scripts/UTL/convertVCFtoGDS.r">**convertVCFtoGDS.r**</a>
##### Input: The preprocessed VCF file,**ukbb.merged.bk.nm.vcf.gz**.
##### Output: The generated GDS file **ukbb.merged.bk.nm.gds**. 

Note: This is computationally intensive multi-core option enabled, by default it is 12 core,parallel=10, users can modify based on computing platforms. Since this multi-core convertVCFtoGDS.r involes 3 steps: (1)count variants, (2)generate smaller GDS intermediate files, (3)merge intermediate files into one GDS. Only Step (2) is running in parallel R sessions. Therefore, small VCF file (<10GB) will not see significant computing time reduce with too many cores(>10 cores). We recommend, small VCF file (<10GB) parallel=6, medium VCF file (10GB~50GB) parallel=12,large VCF file (>50GB) parallel=32.
Finish VCF to GDS processing in 12 core parallel, 90 mins
Finish VCF to GDS processing in 32 core parallel, 72 mins







#### Step additional: Index VCFs.
##### Script: 
- ```$ bcftools index ./ConcatVCF/ukb23156_c19_c12.bk.nm.vcf.gz```
##### Input: The VCF file needs index ** ukb23156_c19_c12.bk.nm.vcf.gz **
##### Output: The VCF file index file ** ukb23156_c19_c12.bk.nm.vcf.gz.csi ** 

Note: Many processes needs indexed VCFs, e.g. view range, merge, etc. 

#### Step additional: Normalize (left) the broken multi-allelic VCFs.
##### Script: 
- ```$ bcftools norm -f --threads 12 hg38.p13.fa ./ConcatVCF/ukb23156_c19_c12.bk.vcf.gz -Oz -o ./ConcatVCF/ukb23156_c19_c12.bk.nm.vcf.gz```
##### Input: The VCF file has multi-allelic sites break into multiple lines ** ukb23156_c19_c12.bk.vcf.gz**, and the reference genome fasta file **hg38.p13.fa**.
##### Output: The left-normalized VCF file has multi-allelic sites break into multiple lines ** ukb23156_c19_c12.bk.nm.vcf.gz**. 

Note: left-normalization is critical for the indels to have the correct and most commonly accepted formats and representation.


