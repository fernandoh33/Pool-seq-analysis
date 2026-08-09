#!/bin/bash
#SBATCH --account=your-account
#SBATCH --time=1-12:00
#SBATCH --ntasks=1
#SBATCH --mem=50G
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32

#I have installed the software in the clusters and run it locally

module purge
module load StdEnv/2023
module load gcc/13.3

REF=reference/Ha412H0V3_only.17chrs.fasta

#Calculating allele frequencies using grenedalf is very simple though is very important the post-estimation filtering for MAF and total read counts
#For filtering is important to know the number of pools (samples) and the mean coverage across samples as the expected count is n samples * mean coverage
for chr in $(cat all.chrs);
do ~/grenedalf/bin/grenedalf frequency --sam-path sunflower.pools.WGS/bam.files --sam-min-map-qual 20 --sam-min-base-qual 30 \
 --filter-region $chr --write-sample-alt-freq --write-total-counts --write-total-read-depth --separator-char tab --threads 32 \
 --allow-file-overwriting --filter-region $chr --file-prefix out.pools.af.$chr --reference-genome-fasta $REF;
done; 

#The output is a file for each chromosome with rows being SNPs and columns are samples plus 
CHROM	POS	REF	ALT	Sample1.FREQ Sample2.FREQ Sample3.FREQ TOTAL.REF_CNT	TOTAL.ALT_CNT	TOTAL.DEPTH

#Thus, for each chromosome the filter would be:
#maxnan represent the max missing data we tolerate, in this case 13 is the 30% of total samples, which is 43, so the snps stays if we have reads in at least 30 samples
#because we have ALT counts and TOTAL counts, we can estimate minimum allele frequencies for each snp, note the minor allele could be the ALT or the REF [maf=($48<$49 ? $48 : $49)/$50]
#so the three filters are: max-missing = 0.3; read counts > 100 and < 1000 (the numbers depend on coverage), and maf > 0.05 
awk -v maxnan=13 '
NR==1 {
    print $0, "MAF"
    next
}
{
    n=0
    for(i=1;i<=NF;i++)
        if($i=="nan") n++

    if($50>100 && $50<1000 && n<maxnan) {
        maf=($48<$49 ? $48 : $49)/$50
        print $0, maf
    }
}' out.pools.af.Ha412HOv3Chr01frequency.csv |
awk '$51>0.05' > filtered.pools.af.Ha412HOv3Chr01.txt
