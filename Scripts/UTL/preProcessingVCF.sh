#Fixed Headers [make sure all fields are defined in header].
#Remove Duplicated VCFs [Make sure there is no duplicated VCF files].

#Remove FORMAT variables but only keep GT  [multi-core]
for fl in ukb23156_c19_b*_v1.vcf.gz; do  bcftools annotate -x ^FORMAT/GT $fl --threads 12 -Oz -o ./CVCF/$fl &; done

#Concat the smaller VCFs (sliced by variants) within each study into one VCF file  [24 mins]
bcftools concat --threads 12 ./CVCF/ukb23156_c19_b*_v1.vcf.gz -Oz -o ./ConcatVCF/ukb23156_c19_c12.vcf.gz

#Break the multi-allelic sites into multiple rows of all the VCFs of each study [Indexed VCFs].
bcftools norm -m -any --threads 12 ./ConcatVCF/ukb23156_c19_c12.vcf.gz -Oz -o ./ConcatVCF/ukb23156_c19_c12.bk.vcf.gz

#Normalize (left) the broken multi-allelic VCFs  [Indexed VCFs].
bcftools norm -f --threads 12 hg38.p13.fa ./ConcatVCF/ukb23156_c19_c12.bk.vcf.gz -Oz -o ./ConcatVCF/ukb23156_c19_c12.bk.nm.vcf.gz

#Indexed cleaned VCFs
bcftools index ./ConcatVCF/ukb23156_c19_c12.bk.nm.vcf.gz

#Sliced the Normalized VCFs into each chromosome.  [Indexed VCFs]
bcftools view -r chr19 ./ConcatVCF/ukb23156_c12.bk.nm.vcf.gz -Oz -o ./ConcatVCF/ukb23156_c19_c12.bk.nm.vcf.gz

#Merge the Normalized VCFs (sliced by different samples) of each study into one VCF (per chromosome).
bcftools  merge -m all --threads 6 ./DifferentStudies/ukbb*.bk.nm.vcf.gz -Oz -o ./MergedVCF/ukbb.merged.bk.nm.vcf.gz

#Convert the merged VCFs per chromosomes into GDSs (per chromosome) [72 mins]. 
Rscripts ./convertVCFtoGDS.r ./MergedVCF/ukbb.merged.bk.nm.vcf.gz ./MergedGDS/ukbb.merged.bk.nm.gds
