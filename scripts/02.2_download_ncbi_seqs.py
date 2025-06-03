from Bio import Entrez
import time 

Entrez.email = "your_adress"  

# Specify the path to your ID file
# File path  
# file_path = 'data/raw/psi_blast/hit_table_Ea59_Lambda.txt'
# file_path = 'data/raw/psi_blast/hit_table_HEC-01A_ECOR46.txt'
# file_path = 'data/raw/psi_blast/hit_table_IbfA.txt'
# file_path = 'data/raw/psi_blast/hit_table_NsnB_ECOR37.txt'
# file_path = 'data/raw/psi_blast/hit_table_PtuA_Slividans.txt'
file_path = 'data/raw/psi_blast/hit_table_PD-T4_4A_ECOR58.txt
# file_path = 'data/raw/psi_blast/hit_table_old.txt'
# file_path = 'data/raw/psi_blast/hit_table_old_vibrio.txt'
# file_path = 'data/raw/psi_blast/special_case/hit_table_JetC_ECOR67_from_1338_to_1445.txt'
# A list to store all id's
protein_ids = []

#Reading a file and extracting identifiers
with open(file_path, 'r') as file:
    for line in file:
        if not line.startswith('#'):
            parts = line.split()
            if len(parts) > 1:
                protein_ids.append(parts[1])  # Second column with ID

# Use all identifiers  
all_ids = protein_ids

# Open the file for writing
with open("hit_table_PD-T4_4A_ECOR58_all.fasta", "w") as fasta_file:
    # NCBI API Rate Limiting Notice:
    # NCBI enforces a limit of 3 requests per second (0.34s delay between requests).
    # Exceeding this may cause:
    # - HTTP 429 "Too Many Requests" errors
    # - Temporary IP block
    # Using 1s delay for reliability
    
    for protein_id in all_ids:
        try:
            # Request to NCBI
            handle = Entrez.efetch(db="protein", id=protein_id, rettype="fasta", retmode="text")
            fasta_data = handle.read()
            handle.close()
            fasta_file.write(fasta_data)
            print(f"ID data {protein_id} successfully recorded.")
            
            # Conservative delay to avoid NCBI rate limiting
            time.sleep(1)  # Using 1s delay instead of minimum 0.34s for safety
        except Exception as e:
            print(f"Error when requesting ID {protein_id}: {e}")

print("FASTA file successfully created!")


