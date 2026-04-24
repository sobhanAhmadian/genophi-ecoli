from dotenv import load_dotenv
import os

load_dotenv()

DATA_DIR = os.getenv("DATA_DIR")
PICARD_FIGSHARE_ID = "25941691"

configfile: "config.json"

rule all:
    input:
        f"{DATA_DIR}/netbalance/features.csv",
        f"{DATA_DIR}/netbalance/interactions.txt",
        f"{DATA_DIR}/netbalance/strains.csv",
        f"{DATA_DIR}/netbalance/phages.csv",

rule download_picard:
    output:
        expand(f"{DATA_DIR}/picard/genomes/{{genome}}.fasta", genome=config["picard"]),
    shell:
        f"""
        bash scripts/figshare-download.sh {PICARD_FIGSHARE_ID} \
            {DATA_DIR}/picard/genomes
        """


rule download_guelin:
    output:
        expand(f"{DATA_DIR}/guelin/genomes/{{genome}}.fna", genome=config["guelin"]),
    shell:
        f"""
        bash scripts/download-guelin.sh {DATA_DIR}/guelin/genomes
        """


rule download_interactions:
    output:
        f"{DATA_DIR}/interactions.csv"
    shell:
        """
        curl -o {output} \
            https://raw.githubusercontent.com/Noonanav/GenoPHI/refs/heads/main/data/interaction_matrices/ecoli_interaction_matrix.csv
        """


rule prodigal:
    input:
        f"{DATA_DIR}/picard/genomes/{{genome}}.fasta"
    output:
        faa=f"{DATA_DIR}/picard/protein-seqs/{{genome}}.faa",
    params:
        data_dir = DATA_DIR
    shell:        
        """
        prodigal -i {input} \
            -a {output.faa} \
        """
    
rule prodigal_gv:
    input:
        f"{DATA_DIR}/guelin/genomes/{{genome}}.fna"
    output:
        faa=f"{DATA_DIR}/guelin/protein-seqs/{{genome}}.faa",
    params:
        data_dir = DATA_DIR
    shell:        
        """
        prodigal-gv -i {input} \
            -a {output.faa} \
        """


rule genophi:
    input:
        expand(f"{DATA_DIR}/picard/protein-seqs/{{genome}}.faa", genome=config["picard"]),
        expand(f"{DATA_DIR}/guelin/protein-seqs/{{genome}}.faa", genome=config["guelin"]),
        f"{DATA_DIR}/interactions.csv"
    output:
        f"{DATA_DIR}/genophi/phage/presence_absence_matrix.csv",
        f"{DATA_DIR}/genophi/strain/presence_absence_matrix.csv",
    params:
        picard_dir = f"{DATA_DIR}/picard/protein-seqs",
        guelin_dir = f"{DATA_DIR}/guelin/protein-seqs",
        data_dir = DATA_DIR
    resources:
        threads=120
    shell:
        """
        genophi protein-family-workflow \
            --input_path_strain {params.picard_dir} \
            --input_path_phage {params.guelin_dir} \
            --phenotype_matrix {params.data_dir}/interactions.csv \
            --output_dir {params.data_dir}/genophi/ \
            --threads {resources.threads} \
            --num_features 100 \
            --num_runs_fs 25 \
            --num_runs_modeling 50 \
            --method rfe \
            --use_clustering \
            --cluster_method hierarchical \
            --n_clusters 20 \
            --filter_type strain \
            --use_shap
        """

rule netbalance:
    input:
        f"{DATA_DIR}/genophi/phage/presence_absence_matrix.csv",
        f"{DATA_DIR}/genophi/strain/presence_absence_matrix.csv",
    output:
        f"{DATA_DIR}/netbalance/features.csv",
        f"{DATA_DIR}/netbalance/interactions.txt",
        f"{DATA_DIR}/netbalance/strains.csv",
        f"{DATA_DIR}/netbalance/phages.csv",
    shell:
        """
        python scripts/netbalance.py
        """