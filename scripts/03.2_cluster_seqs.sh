#!/bin/bash

# Navigate to the target directory
cd "../data/processed/02_clustered_seq/" || { echo "Error: Failed to navigate to directory"; exit 1; }

# Convert representatives to FASTA format
echo "Step 1: Convert to FASTA..."
mmseqs convert2fasta dataset_ABC_ATP_clu_rep dataset_ABC_ATP_clu_rep.fasta || { echo "Error during conversion to FASTA"; exit 1; }
echo "The task has been successfully completed.The results are saved in the file dataset_ABC_ATP_clu_rep.fasta"

