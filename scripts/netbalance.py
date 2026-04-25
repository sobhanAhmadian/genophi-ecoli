import os

import numpy as np
import pandas as pd
from dotenv import load_dotenv

load_dotenv()

data_dir = os.getenv("DATA_DIR", "data")
genophi_dir = os.path.join(data_dir, "genophi")
phage_features_path = os.path.join(genophi_dir, "phage", "presence_absence_matrix.csv")
bacteria_features_path = os.path.join(
    genophi_dir, "strain", "presence_absence_matrix.csv"
)

phage_df = pd.read_csv(phage_features_path)
phage_df = phage_df.rename(columns={"Genome": "phage"})

bacteria_df = pd.read_csv(bacteria_features_path)
bacteria_df = bacteria_df.rename(columns={"Genome": "strain"})
bacteria_df["strain"] = bacteria_df["strain"].str.upper()
bacteria_df["strain"] = bacteria_df["strain"].str.replace("_", "", regex=False)

interactions_path = os.path.join(data_dir, "interactions.csv")
idf = pd.read_csv(interactions_path)

netbalance_dir = os.path.join(data_dir, "netbalance")
os.makedirs(netbalance_dir, exist_ok=True)

# Save Strain Features
print("Saving strain features...")
strains = pd.DataFrame(pd.unique(idf["strain"]), columns=["strain"])
sf_df = strains.merge(bacteria_df, on="strain", how="left")

sf = sf_df.to_numpy()[:, 1:]

sf_path = os.path.join(data_dir, "netbalance", "strains-features.csv")
pd.DataFrame(sf).to_csv(sf_path, index=False, header=False)
pd.DataFrame(sf_df.columns[1:], columns=["feature"]).to_csv(
    os.path.join(data_dir, "netbalance", "strains-features-names.csv"),
    index=True,
)
strains.to_csv(os.path.join(netbalance_dir, "strains.csv"), index=True)

# Saving Phage Features
print("Saving phage features...")
phages = pd.DataFrame(pd.unique(idf["phage"]), columns=["phage"])
pf_df = phages.merge(phage_df, on="phage", how="left")

pf = pf_df.to_numpy()[:, 1:]

pf_path = os.path.join(data_dir, "netbalance", "phages-features.csv")
pd.DataFrame(pf).to_csv(pf_path, index=False, header=False)
pd.DataFrame(pf_df.columns[1:], columns=["feature"]).to_csv(
    os.path.join(data_dir, "netbalance", "phages-features-names.csv"),
    index=True,
)
phages.to_csv(os.path.join(netbalance_dir, "phages.csv"), index=True)

# Save interactions
print("Saving interactions...")
strain_to_idx = {s: i for i, s in enumerate(strains["strain"])}
phage_to_idx = {p: i for i, p in enumerate(phages["phage"])}

idf["strain"] = idf["strain"].map(strain_to_idx)
idf["phage"] = idf["phage"].map(phage_to_idx)
mat = idf.to_numpy()
np.savetxt(
    os.path.join(netbalance_dir, "interactions.txt"),
    mat.astype(int),
    fmt="%d",
    delimiter=",",
)
