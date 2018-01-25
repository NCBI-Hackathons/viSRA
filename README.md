# viSRA
**v**isualization of **SRA**: This tool takes SRR-Gene alignments from deSRA (https://github.com/NCBI-Hackathons/deSRA) and uses them as input to the MicroArrayPipeline's analysis and visualization modules.

## Introduction
The future of biomedical research depends on the ability to rapidly access and analyze Next-Generation Sequencing (NGS) data stored at the NCBI’s Sequence Read Archive (SRA). NGS provides an unprecedented level of resolution, allowing researchers to ask previously unanswerable questions such as how cancer pathogenesis might be mediated by very small changes in gene expression.


With ~3 million records currently stored in the SRA database, and submissions growing exponentially, the SRA collection represents a treasure-trove of data to be mined by academia and industry. The information contained in a single SRA dataset is equivalent to hundreds of in vitro experiments worth of work, potentially saving thousands of dollars and research hours.


Here we present viSRA, a tool for visualizing RNA-seq data from SRA datasets on the fly. There are a variety of tools to analyize and visualize microarray data, and these can be leveraged to accelerate development of feature rich RNA-Seq tools. viSRA facilitates the interrogation of SRA datasets for differential gene expression via dockerized pipeline. viSRA makes it easy for biologists to perform pathway enrichment analyses and to interrogate which genes are differentially expressed between experiments. viSRA benefits greatly from previous work on deSRA and the MicroArrayPipeline


![alt text](https://user-images.githubusercontent.com/12971527/32574712-ff0dbfb8-c49f-11e7-8404-1e209a51c5c0.png "Overview Diagram")

## What's the problem?
The NCBI Sequence Read Archive (SRA) provides NGS data along with sample and project metadata (NCBI Resource Coordinators 2017). As part of the International Nucleotide Sequence Database Collaboration, the SRA supports access to data from a wide variety of experimental types and sequencing instruments. Unfortunaltely, it can be time-consuming and difficult to access and analyze the data, especially if you want to quickly develop meaningful hypotheses. viSRA bridges this gap between advanced bioinformatic data and users.

## Why should we solve it?
The amount of NGS data stored in the Sequence Read Archive (SRA) data-base is growing rapidly. However, many researchers who are interested in this data do not have experience with the tools necessary to analyze it effectively. viSRA increases the utility and return on investment of NGS projects by making the data more accessible to a wider range of individuals.

# What is viSRA?
viSRA is a tool to compare two sets of NGS data for differences in gene expression. For example, if the user is interested in how gene expression varies in the liver after treatment for HCV, they may be interested in looking at a BioProject record that links the runs for a relevant experiment, such as https://www.ncbi.nlm.nih.gov/bioproject/328986. From that page, you can select the link for SRA experiments, then view the results in SRA Run Selector, which displays a table including the SRA run accessions and treatment conditions,  https://www.ncbi.nlm.nih.gov/sra?linkname=bioproject_sra_all&from_uid=328986. You will also need at least one Entrez Gene name to search against the SRA datsets.

# Workflow

## Software workflow diagram
![alt text](https://github.com/NCBI-Hackathons/viSRA/blob/master/workFlow_viSRA.jpg "Overview Diagram")

## Build BLAST database  
The first step to running the tool is to build BLAST databases for each of the input genes. Building the databases this way allows for rapid querying of only those databases that are relevent to your query, and allows for parallelization, thus increasing the programs speed. The accession, start & stop positions, and gene ID are pulled from ref_GRCh38.p7_top_level.gff3. Based on those positions, a bash script retrieves the sequences in FASTA format and saves each as an individual BLAST database in the active Docker server.

## Magic BLAST  
MagicBLAST is run iteratively for each gene, once for the treatment runs and once for the experiment runs.
The general format for running the magicBLAST command is:  
`magicblast -sra <accession> -db <database_name>`
See more at https://ncbi.github.io/magicblast/

## Comparison of gene expression  
MagicBLAST produces a SAM file, which is processed by separate scripts in Docker encoding samtools commands. The SAM file is converted to a BAM file, which is sorted and indexed, and used to generate a pileup. TPM is calculated for the pileups generated from the experimental runs and the control runs, and a volcano plot is used to display the log2 of the TPM ratios.

# Installation and Setup

## Installing viSRA from Github
`git clone https://github.com/NCBI-Hackathons/viSRA`

`docker build -t biocontainers/desra deSRA/`

## Preparing the database
Creates a working directory `data`
Creates a BLAST DB for each human gene
```
docker run -it -v `pwd`/data:/data biocontainers/desra desra_pre-process.sh -d /data/blastdb
```

## Creating database for a selected number of genes

Create a file into the `data` directory with the list of genes to process (Gene name per line). Let's name the file `gene_name.txt`

Create the database using:

```
docker run -it -v `pwd`/data:/data biocontainers/desra desra_pre-process.sh -d /data/blastdb -g /data/gene_name.txt
```

This command will create a folder `/data/blastdb/ref_GRCh38.p7_top_level`, inside that folder will be a folder per gene including the gene fasta sequence and the blast db.

A gene can have multiple copies in the genome. In this case each copy sequence is included in the database. The database name follows this format: `GeneName_GeneID_StarPos_EndPos.fasta`

For the gene `A1CF` these are the files created into the directory `/data/blastdb/ref_GRCh38.p7_top_level/A1CF/`:

```
A1CF_29974_50799409_50885681.fasta
A1CF_29974_50799409_50885681.nhr
A1CF_29974_50799409_50885681.nin
A1CF_29974_50799409_50885681.nog
A1CF_29974_50799409_50885681.nsd
A1CF_29974_50799409_50885681.nsi
A1CF_29974_50799409_50885681.nsq
```

## Processing a list of gene vs two lists of SRA accessions

We've developed a main script `desra_main.sh` to process a list of genes vs two lists of SRA accessions (condition 1 and condition 2). This script is also designed to process the jobs submitted by the website. Therefore, it required special working folder.

This kind of jobs should be executed in directory inside `data/jobs` creating a folder with an unique identifier that will be used as `job_id`. For example, create a folder `data/jobs/00001/`.

Inside this directory creates three files named: `gene_name`, `sra_cond1` and `sra_cond2`. Each files should have an id per line.

Run this command to process the data:

```
docker run -it -v `pwd`/data:/data biocontainers/desra desra_main.sh -d /data/blastdb/ref_GRCh38.p7_top_level -j 00001 -e r78v10a07@gmail.com -t 4
```

Please, note that `-t 4` will run magicblast with 4 threads. Adapt this command to your host resources.

This command will create two files for each gene-srr combination:

```
A1CF_29974_50799409_50885681.bam
A1CF_29974_50799409_50885681.bam.bai
```

## Running the docker image for the website
Execute this command for the website app. It will be available in the host port 8000

```
docker run -d -p 8000:8000 -v `pwd`/data:/data biocontainers/desra /home/biodocker/bin/docker_entry.sh
```

# Future Development Plans

# Project team  

deSRA team:   
John Garner  
Mingzhang Yang  
Eneida Hatcher  
Anna-Leigh Brown  
Peter Meric  
Roberto Vera Alvarez  
Ryan Connor  
Nora Husain  
Aynex Mercado  

GUI team:  
Kristin Valdez  
Robert Guthridge  
Ryan Connor  
Luli Zou
