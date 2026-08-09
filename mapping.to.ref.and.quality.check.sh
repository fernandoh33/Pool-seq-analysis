#!/bin/bash
#SBATCH --account=your-account
#SBATCH --time=2-00:00
#SBATCH --ntasks=1
#SBATCH --mem=120G
#SBATCH --cpus-per-task=60

mkdir bam.files trimmed.reads out.fastqc.raw out.fastqc.trimmed bamstats

export JAVA_TOOL_OPTIONS="-Xms256m -Xmx4g"

RAW=fastq.files
TRIMDIR=trimmed.reads
GENOME=reference/Ha412H0V3_only.17chrs.fasta
BAMDIR=bam.files
S1=_1.fq.gz
S2=_2.fq.gz

module load StdEnv/2023
module load gcc/12.3
module load fastp/0.23.4
module load samtools/1.20
module load fastqc/0.12.1
module load bamtools/2.5.2
module load bwa/0.7.18
module load qualimap/2.3

#Remove adapters, duplicates, poly Gs, and low quality bases
for i in $(cat samples);
do fastp -i $RAW/$i$S1 -I $RAW/$i$S2 -o $TRIMDIR/$i$S1 -O $TRIMDIR/$i$S2 --cut_right --dedup -h $TRIMDIR/$i'.html' -g -w 16;
done;

#Run Alignment, index, and bam statistics
for i in $(cat samples);
do bwa mem -t 60 $GENOME $TRIMDIR/$i$S1 $TRIMDIR/$i$S2|samtools view -bh|samtools sort -T tmp -@ 60 -o $BAMDIR/$i'.bam';
samtools index -@ 60 $BAMDIR/$i'.bam';
bamtools stats -in $BAMDIR/$i'.bam' > bamstats/$i'_bamstats.txt';
qualimap bamqc -bam $BAMDIR/${i}'.bam' -outdir bamstats/${i}_qualimap -outfile ${i}_qualimap_report.txt -nt 32 --java-mem-size=4G;
done;

#Run FastQC on raw and trimmed reads
for i in $(cat samples);
do fastqc $TRIMDIR/$i$S1 -o out.fastqc.raw/;
fastqc $TRIMDIR/$i$S2 -o out.fastqc.raw/;
done;

#for i in $(cat samples1);
do fastqc $TRIMDIR/$i$S1 -o out.fastqc.trimmed/;
fastqc $TRIMDIR/$i$S2 -o out.fastqc.trimmed/;
done;
