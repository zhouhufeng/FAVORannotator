/* Title: Import the database into postgreSQL
 * Time: April 29th 2021
 * Author: Ted and Hufeng
 */

psql -h localhost -p portnumber -d FAVORV2

CREATE TABLE MAIN(
variant_vcf text,
chromosome text,
position text,
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
genecode_category text,
genecode_info text,
genecode_exonic_category text,
genecode_exonic_info text,
genehancer text,
linsight numeric,
metasvm_pred text,
rdhs text,
rsid text);

COPY main FROM '/n/holystore01/LABS/xlin/Lab/tarapoglou/v2/offline/offlineData.csv' CSV HEADER;

CREATE VIEW offline_view AS SELECT * FROM main;

CREATE INDEX ON main USING HASH(variant_vcf);

CREATE USER annotator WITH SUPERUSER PASSWORD 'DoMeAFAVOR';
