> STAR Genome Index #Preparing STAR genome index length 27
STAR --runMode genomeGenerate --runThreadN 8 --genomeDir genome_index_27 --genomeFastaFiles c_elegans_chromosome_1.fasta c_elegans_chromosome_2.fasta c_elegans_chromosome_3.fasta c_elegans_chromosome_4.fasta c_elegans_chromosome_5.fasta c_elegans_chromosome_MT.fasta c_elegans_chromosome_X.fasta  --sjdbGTFfile  genomic.gtf --sjdbOverhang 27 

> STAR Alignment #Aligning both forward and reverse reads against genome index
STAR --genomeDir ../../genome_index_27/ --readFilesIn [SRR...].fastq.gz [SRR...].fastq.gz --readFilesCommand zcat --outSAMtype BAM SortedByCoordinate --quantMode GeneCounts --runThreadN 8 --alignIntronMax 10000 --outFilterMatchNmin 18

> #wget to obtain datasets from the European Nucleotide Archive (ENA) Database
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR202/014/SRR20206814/[SRR...].fastq.gz &
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR202/014/SRR20206814/[SRR...].fastq.gz &
