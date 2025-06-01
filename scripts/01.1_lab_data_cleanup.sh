# Deletion "*" in alignments to produce trimming

#for MAFFT
 awk '/^>/ {print; next} {gsub(/\*/, ""-""); print}' dataset_ABC_ATP_localpair_mafft.fasta > localpair_mafft.fasta

#for MUSCLE
 awk '/^>/ {print; next} {gsub(/\*/, ""-""); print}' new_dataset_ABC_ATP_muscle.fasta > muscle.fasta

#for CLUSTALO with flag full
awk '/^>/ {print; next} {gsub(/\*/, ""-""); print}' new_dataset_ABC_ATP_full_clustalo.fasta > full_clustalo.fasta

#for CLUSTALO with 5 iteration
awk '/^>/ {print; next} {gsub(/\*/, ""-""); print}' new_dataset_ABC_ATP_clustalo_2.fasta > clustalo_2.fasta
