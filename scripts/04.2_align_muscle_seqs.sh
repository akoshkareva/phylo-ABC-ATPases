#!/bin/bash
# Navigate to the target directory
cd "../data/processed/03_aligned_seq/" || { echo "Error: Failed to navigate to directory"; exit 1; }

# Perform a MUSCLE alignment
echo "Running MUSCLE for file dataset_ABC_ATP_with_AAA_ATP"
muscle -super5 dataset_ABC_ATP_with_AAA_ATP.fasta -output dataset_ABC_ATP_muscle.fasta -threads 8 || { echo "Align error"; exit 1; }
echo "Running MUSCLE for file dataset_ABC_ATP_clu_with_AAA_ATP.fasta"
muscle -super5 dataset_ABC_ATP_clu_with_AAA_ATP.fasta -output dataset_ABC_ATP_muscle.fasta -threads 8 || { echo "Align error"; exit 1; }

echo "Done! Align is complete."



