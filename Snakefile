from dotenv import load_dotenv
import os

load_dotenv()

DATA_DIR = os.getenv("DATA_DIR")
PICARD_FIGSHARE_ID = "25941691"
EGGNOG_DATA_DIR = os.getenv("EGGNOG_DATA_DIR")

configfile: "config.json"

rule all:
    input:
        f"{DATA_DIR}/netbalance/phages-features-annotations.csv",
        f"{DATA_DIR}/netbalance/strains-features-annotations.csv",
        f"{DATA_DIR}/netbalance/interactions.txt",
        f"{DATA_DIR}/netbalance/strains.csv",
        f"{DATA_DIR}/netbalance/strains-features.csv",
        f"{DATA_DIR}/netbalance/strains-features-names.csv",
        f"{DATA_DIR}/netbalance/phages.csv",
        f"{DATA_DIR}/netbalance/phages-features.csv",
        f"{DATA_DIR}/netbalance/phages-features-names.csv",

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
        f"{DATA_DIR}/netbalance/interactions.txt",
        f"{DATA_DIR}/netbalance/strains.csv",
        f"{DATA_DIR}/netbalance/strains-features.csv",
        f"{DATA_DIR}/netbalance/strains-features-names.csv",
        f"{DATA_DIR}/netbalance/phages.csv",
        f"{DATA_DIR}/netbalance/phages-features.csv",
        f"{DATA_DIR}/netbalance/phages-features-names.csv",
    shell:
        """
        python scripts/netbalance.py
        """


rule download_eggnog:
    output:
        f"{EGGNOG_DATA_DIR}/eggnog.db",
        f"{EGGNOG_DATA_DIR}/eggnog.taxa.db",
        f"{EGGNOG_DATA_DIR}/eggnog_proteins.dmnd",
    shell:
        f"""
        python scripts/download-eggnog-data.py --data_dir {EGGNOG_DATA_DIR} -y
        """

rule eggnog:
    input:
        f"{EGGNOG_DATA_DIR}/eggnog.db",
        f"{EGGNOG_DATA_DIR}/eggnog.taxa.db",
        f"{EGGNOG_DATA_DIR}/eggnog_proteins.dmnd",
        faa=f"{DATA_DIR}/{{collection}}/protein-seqs/{{genome}}.faa",
    output:
        f"{DATA_DIR}/{{collection}}/annotations/{{genome}}/{{genome}}.emapper.hits",
        f"{DATA_DIR}/{{collection}}/annotations/{{genome}}/{{genome}}.emapper.seed_orthologs",
        f"{DATA_DIR}/{{collection}}/annotations/{{genome}}/{{genome}}.emapper.annotations",
    params:
        data_dir = DATA_DIR,
        eggnog_data_dir = EGGNOG_DATA_DIR
    shell:
        """
        mkdir -p {params.data_dir}/tmp

        emapper.py \
            -m diamond \
            -i {input.faa} \
            --data_dir {params.eggnog_data_dir} \
            -o {wildcards.genome} \
            --output_dir {params.data_dir}/{wildcards.collection}/annotations/{wildcards.genome} \
            --temp_dir {params.data_dir}/tmp \
        """


rule annotate_features:
    input:
        expand(f"{DATA_DIR}/guelin/annotations/{{phage}}/{{phage}}.emapper.annotations", phage=config["guelin"]),
        expand(f"{DATA_DIR}/picard/annotations/{{strain}}/{{strain}}.emapper.annotations", strain=config["picard"]),
    output:
        f"{DATA_DIR}/netbalance/phages-features-annotations.csv",
        f"{DATA_DIR}/netbalance/strains-features-annotations.csv",
    shell:
        """
        python scripts/annotate-features.py
        """