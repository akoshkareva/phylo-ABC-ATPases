#!/bin/bash
# Navigate to the target directory
cd "../data/processed/03_aligned_seq/" || { echo "Error: Failed to navigate to directory"; exit 1; }

# Perform a CLUSTALO alignment
echo "Running CLUSTALO for file dataset_ABC_ATP_clu_with_AAA_ATP.fasta"
clustalo --thread 8 --iter=5 --infile=dataset_ABC_ATP_clu_with_AAA_ATP.fasta --outfile=dataset_ABC_ATP_clustalo_2.fasta --verbose || { echo "Align error"; exit 1; }

echo "Done! Align is complete."
