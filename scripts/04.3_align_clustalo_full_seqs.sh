#!/bin/bash
# Navigate to the target directory
cd "../data/processed/03_aligned_seq/" || { echo "Error: Failed to navigate to directory"; exit 1; }

# Perform a CLUSTALO alignment
echo "Running CLUSTALO for file dataset_ABC_ATP_clu_with_AAA_ATP.fasta"
clustalo --full  --thread 8 --iter=3 --infile=dataset_ABC_ATP_clu_with_AAA_ATP.fasta --outfile=dataset_ABC_ATP_full_clustalo.fasta --verbose || { echo "Align error"; exit 1; }

echo "Done! Align is complete."




