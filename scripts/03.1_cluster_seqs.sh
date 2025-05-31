#!/bin/bash

# Navigate to the target directory
cd "../data/processed/02_clustered_seq/" || { echo "Error: Failed to navigate to directory"; exit 1; }

# For exsisting results
rm dataset_ABC_ATP_clu_rep.fasta

# 1. Creating the MMseqs2 database
echo "Step 1: Create a database..."
mmseqs createdb dataset_ABC_ATP.faa dataset_ABC_ATP || { echo "Error during database creation"; exit 1; }

# 2. Clustering with a minimum identity of 70% and with 70% coverage
echo "Шаг 2: Step 2: Clustering of sequences..."
mmseqs cluster dataset_ABC_ATP clu tmp --min-seq-id 0.7 --threads 8 || { echo "Clustering error"; exit 1; }

# 3. Extraction of cluster representatives
echo "Step 3: Extracting Cluster Representatives..."
mmseqs createsubdb clu dataset_ABC_ATP dataset_ABC_ATP_clu_rep || { echo "Error in extracting representatives"; exit 1; }

echo "Done! All steps have been completed successfully."


