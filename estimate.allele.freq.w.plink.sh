#To test whether pool-seq produces reliable allele frequency estimates, I estimate allele frequencies for the same populations using dd-RAD for individual samples
#First I extracted the ALT allele from the vcf and paste it to a file used in plink
bcftools query -f '%CHROM %POS %ALT\n' gbs.totem.field.depth4to150.maf0.01.noindels.miss0.7.vcf.gz |awk '{print$1":"$2"\t"$3}' > ALT
#Then the estimates of alternative allele frequencies 
plink --vcf gbs.totem.field.depth4to150.maf0.01.noindels.miss0.7.vcf.gz --allow-extra-chr --freq --within pop.for.plink --out sunflower.gbs.af --set-missing-var-ids @:# --a2-allele ALT
