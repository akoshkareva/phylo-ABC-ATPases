# phylo_ABC_ATPases


# Characterization of ABC ATPases associated with immune function in prokaryotes.

**Authors**  
- Natalya Kichigina
- Alena Koshkareva

**Supervisors**  
- Oksana Kotovskaya (Skolkovo Institute of Science and Technology)

 ### Repository structure
```
📁 phylo-ABC-ATPases/
├── 📄 README.md 
├── 📄 environment.yml 
├── 📁 data/
│   ├── 📁 raw/
│   │   ├── 📁 articles/
│   │   ├── 📁 from_lab/
│   │   ├── 📁 psi_blast/ 
│   │   │   └── 📁 special_case/
│   └── 📁 processed/
│       ├── 📁 01_fasta_seq/
│       ├── 📁 02_clustered_seq/  
│       ├── 📁 03_aligned_seq/  
│       ├── 📁 04_trimmed_seq/
│       └── 📁 05_seq_for_tree/ 
├── 📁 results/
│   ├── 📁 trees/  
│   │   └── 📄 fasttree.nwk  
│   │    
│   │    
│   ├── 📁 alphafold_models/ 
│   └── 📄 result_sources_ID.csv
└── 📁 scripts/
    ├── 📄 01.1_lab_data_cleanup.sh   
    ├── 📄 01.2_csv_to_fasta_PARIS.ipynb
    ├── 📄 02.2_download_ncbi_seqs.ipynb 
    ├── 📄 03.1_cluster_seqs.sh 
    ├── 📄 03.2_cluster_seqs.sh 
    ├── 📄 04_align_seqs.sh  
    ├── 📄 05.1_filter_walker_a&b.ipynb
    ├── 📄 05.2_statistics_number_seq_by_source.ipynb
    ├── 📄 07.2_draw_tree.R
    └── 📄 09_alphafold_web.md  
```

### Introduction

 ATPases are widespread enzymes that use the energy of ATP hydrolysis to change conformation. These conformational changes are usually transferred to additional domains in proteins to perform some function in the cell. For example, ABC ATPases perform a transmembrane transport function and SMC ATPases are involved in maintaining chromosome organisation. ABC ATP-ases are a group of ATPases that have two conserved domains Walker A and Walker B and lack a domain called the arginine finger. 
A portion of ABC ATP-ases have immune functions in prokaryotes. In recent years, a large number of ABC ATPases have been discovered in the field of bacterial immunity that are associated with the response to phage infection (AriA in Paris and others). 
And in this project, we would like to establish phylogenetic relationships between different groups of immune ABC ATPases to better understand the evolutionary processes in this group of ATPases.


### Data
Data. The data were obtained from three sources: firstly, literature data with already known sequences of immune ABC ATPases, secondly, protein sequences from immune proteins of bacteria known to harbour ABC-ATPase domains (e.g. PrrC, RloC). GenBank Database. predicted with PADLOC v.2.0.0. available in the National Centre for Biotechnology Information (NCBI) database, and the last source homologues of proteins studied experimentally using the Position Specific Iterated BLAST web. The final size of the assembled dataset was about 50 thousand sequences.

### workflow
1 step.
The entire protein dataset was then clustered at 70% similarity and 70% minimum coverage using MMseqs2 (17.b804f)

2 step. 
The resulting sequences were aligned using Clustal Omega (v.1.2.4)

3 step.
Alignment trimming using the ClipKIT(2.3.0)

4 step.
Filtering for the presence of two domain areas: Walker A, Walker B


5 step.

Tree construction by the FastTree(2.1.11) program (maximum-likelihood NNIs).