#!/bin/bash
# Navigate to the target directory
cd "../data/processed/03_aligned_seq/" || { echo "Error: Failed to navigate to directory"; exit 1; }

# Perform a MAFFT alignment
echo "Running MAFFT for file ..."
mafft --localpair --thread 8 dataset_ABC_ATP_clu_and_AAA_ATP.fasta > dataset_ABC_ATP_localpair_mafft.fasta || { echo "Align error"; exit 1; }

echo "Done! Align is complete."
