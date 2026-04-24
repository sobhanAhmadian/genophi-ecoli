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

df = idf.join(phage_df.set_index("phage"), on="phage", how="inner", lsuffix="phage_")
df = df.join(
    bacteria_df.set_index("strain"), on="strain", how="inner", lsuffix="bacteria_"
)

strains = pd.DataFrame(pd.unique(df["strain"]), columns=["strain"])
phages = pd.DataFrame(pd.unique(df["phage"]), columns=["phage"])
strain_to_idx = {s: i for i, s in enumerate(strains["strain"])}
phage_to_idx = {p: i for i, p in enumerate(phages["phage"])}

df["strain"] = df["strain"].map(strain_to_idx)
df["phage"] = df["phage"].map(phage_to_idx)

netbalance_dir = os.path.join(data_dir, "netbalance")
os.makedirs(netbalance_dir, exist_ok=True)

mat = df.to_numpy()[:, :3]

print("Saving data to netbalance directory...")
np.savetxt(
    os.path.join(netbalance_dir, "interactions.txt"),
    mat.astype(int),
    fmt="%d",
    delimiter=",",
)
strains.to_csv(os.path.join(netbalance_dir, "strains.csv"), index=True)
phages.to_csv(os.path.join(netbalance_dir, "phages.csv"), index=True)
df.to_csv(os.path.join(netbalance_dir, "features.csv"), index=False)
