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
- ```$ for fl in ukb23156_c19_b*_v1.vcf.gz; do  bcftools annotate -x ^FORMAT/GT $fl --threads 12 -Oz -o ./CVCF/$fl &; done```
##### Input: All the raw VCF files ** ukb23156_c19_b0_v1.vcf.gz, ukb23156_c19_b2_v1.vcf.gz,..., ukb23156_c19_b64_v1.vcf.gz**
##### Output: The cleaned VCF files in the folder **./CVCF/** that within which has the same file name, but the FORMAT fields only contain GT. 

Note: This is computationally intensive, each smaller file is one multi-core instance, and multiple instances can be run in parallel to speed up the process. 

#### Step 2: Concat the smaller VCFs (sliced by variants) within each study into one VCF file. [Benchmark in UKBB 200k WES 24 mins] 
##### Script: 
- ```$ bcftools concat --threads 12 ./CVCF/ukb23156_c19_b*_v1.vcf.gz -Oz -o ./ConcatVCF/ukb23156_c19_c12.vcf.gz```
##### Input: All the cleaned VCF files in the folder **./CVCF/** with the VCF files name: ** ukb23156_c19_b0_v1.vcf.gz, ukb23156_c19_b2_v1.vcf.gz,..., ukb23156_c19_b64_v1.vcf.gz**
##### Output: The concatenated VCF files in the folder **./ConcatVCF/ukb23156_c19_c12.vcf.gz** that is the results of all the input VCFs concatenated by rows into one big VCF that has the same columns. 

Note: This is computationally intensive, multi-core function enabled to speed up the process. Concat is only for VCFs has same samples [columns] just need to concat the variants [rows], if VCF is sliced by samples, you should refer to the following steps using the merge function. 

#### Step 3: Break the multi-allelic sites into multiple rows of all the VCFs of each study.
##### Script: 
- ```$ bcftools norm -m -any --threads 12 ./ConcatVCF/ukb23156_c19_c12.vcf.gz -Oz -o ./ConcatVCF/ukb23156_c19_c12.bk.vcf.gz```
##### Input: The VCF file contains multi-allelic sites ** ukb23156_c19_c12.vcf.gz **
##### Output: The VCF file has multi-allelic sites break into multiple lines ** ukb23156_c19_c12.bk.vcf.gz**. 

Note: multi-allelic sites cause issues for the following analysis, we usually break them into multiple rows in the preprocessing steps. 

#### Step 4: Normalize (left) the broken multi-allelic VCFs.
##### Script: 
- ```$ bcftools norm -f --threads 12 hg38.p13.fa ./ConcatVCF/ukb23156_c19_c12.bk.vcf.gz -Oz -o ./ConcatVCF/ukb23156_c19_c12.bk.nm.vcf.gz```
##### Input: The VCF file has multi-allelic sites break into multiple lines ** ukb23156_c19_c12.bk.vcf.gz**, and the reference genome fasta file **hg38.p13.fa**.
##### Output: The left-normalized VCF file has multi-allelic sites break into multiple lines ** ukb23156_c19_c12.bk.nm.vcf.gz**. 

Note: left-normalization is critical for the indels to have the correct and most commonly accepted formats and representation.

#### Step 5: Index VCFs.
##### Script: 
- ```$ bcftools index ./ConcatVCF/ukb23156_c19_c12.bk.nm.vcf.gz```
##### Input: The VCF file needs index ** ukb23156_c19_c12.bk.nm.vcf.gz **
##### Output: The VCF file index file ** ukb23156_c19_c12.bk.nm.vcf.gz.csi ** 

Note: Many processes needs indexed VCFs, e.g. view range, merge, etc. 

#### Step 6: Sliced the Normalized VCFs into each chromosome [if needed].
##### Script: 
- ```$ bcftools view -r chr19 ./ConcatVCF/ukb23156_c12.bk.nm.vcf.gz -Oz -o ./ConcatVCF/ukb23156_c19_c12.bk.nm.vcf.gz```
##### Input: The VCF file contains all chromosomes ** ukb23156_c12.bk.nm.vcf.gz **
##### Output: The VCF file that only has chr19 (chosen chromosome or range) ** ukb23156_c19_c12.bk.nm.vcf.gz**. 

Note: Sliced VCF will have many advantages in computing performance.

#### Step 7: Merge the Normalized VCFs (sliced by different samples) of each study into one VCF (per chromosome).
##### Script: 
- ```$ bcftools merge -m all --threads 6 ./DifferentStudies/ukbb*.bk.nm.vcf.gz -Oz -o ./MergedVCF/ukbb.merged.bk.nm.vcf.gz```
##### Input: The VCF files has same set of Variants (rows) but different samples (columns) ** /DifferentStudies/ukbb*.bk.nm.vcf.gz **
##### Output: One big VCF file has same set of variants (rows) now with all the samples (columns) **./MergedVCF/ukbb.merged.bk.nm.vcf.gz**. 

Note:This is computationally intensive multi-core option enabled. merge function only for VCFs with same set of variants (rows) merging different samples (columns) together.  


#### Step 8: Convert the merged VCFs per chromosomes into GDSs (per chromosome) [Benchmarked using UKBB 200k WES chr19 VCF takes 72 mins].
##### Script: 
- ```$ Rscripts ./convertVCFtoGDS.r ./MergedVCF/ukbb.merged.bk.nm.vcf.gz ./MergedGDS/ukbb.merged.bk.nm.gds```
Script: <a href="https://github.com/zhouhufeng/FAVORannotator/blob/main/Scripts/UTL/convertVCFtoGDS.r">**convertVCFtoGDS.r**</a>
##### Input: The preprocessed VCF file,**ukbb.merged.bk.nm.vcf.gz**.
##### Output: The generated GDS file **ukbb.merged.bk.nm.gds**. 

Note: This is computationally intensive multi-core option enabled, by default it is 12 core,parallel=10, users can modify based on computing platforms. Since this multi-core convertVCFtoGDS.r involes 3 steps: (1)count variants, (2)generate smaller GDS intermediate files, (3)merge intermediate files into one GDS. Only Step (2) is running in parallel R sessions. Therefore, small VCF file (<10GB) will not see significant computing time reduce with too many cores(>10 cores). We recommend, small VCF file (<10GB) parallel=6, medium VCF file (10GB~50GB) parallel=12,large VCF file (>50GB) parallel=32.

