import pandas as pd

from tqdm import tqdm
import os

import pandas as pd
from dotenv import load_dotenv

load_dotenv()

data_dir = os.getenv("DATA_DIR", "data")
netbalance_dir = os.path.join(data_dir, "netbalance")


# Phage
pfn = pd.read_csv(
    os.path.join(netbalance_dir, "phages-features-names.csv"), index_col=0
)
pfn["phage"] = pfn["feature"].str.rsplit("_", n=1).str[0]

all_annotations = []
num_features = pfn.shape[0]
num_features_with_annotations = 0
for phage, cds in tqdm(pfn[["phage", "feature"]].values, total=num_features):
    annotations_path = os.path.join(
        data_dir, "guelin", "annotations", phage, f"{phage}.emapper.annotations"
    )
    annotations = pd.read_csv(
        annotations_path, sep="\t", skiprows=4, skipfooter=3, engine="python"
    )
    cds_annotations = annotations[annotations["#query"] == cds]
    if cds_annotations.empty:
        all_annotations.append([cds] + ["-"] * (annotations.shape[1] - 1))
    else:
        all_annotations.append(cds_annotations.iloc[0].tolist())
        num_features_with_annotations += 1
    header = annotations.columns.tolist()

ann_df = pd.DataFrame(all_annotations, columns=header)
print(f"Annotated {num_features_with_annotations} out of {num_features} features.")

ann_df.to_csv(
    os.path.join(netbalance_dir, "phages-features-annotations.csv"), index=False
)


# Bacteria
sfn = pd.read_csv(
    os.path.join(netbalance_dir, "strains-features-names.csv"), index_col=0
)
sfn["strain"] = sfn["feature"].str.split("::", n=1).str[0]
sfn["cds"] = sfn["feature"].str.split("::", n=1).str[1]

all_annotations = []
num_features = sfn.shape[0]
num_features_with_annotations = 0
for strain, cds in tqdm(sfn[["strain", "cds"]].values, total=num_features):
    annotations_path = os.path.join(
        data_dir, "picard", "annotations", strain, f"{strain}.emapper.annotations"
    )
    annotations = pd.read_csv(
        annotations_path, sep="\t", skiprows=4, skipfooter=3, engine="python"
    )
    cds_annotations = annotations[annotations["#query"] == cds]
    if cds_annotations.empty:
        all_annotations.append([cds] + ["-"] * (annotations.shape[1] - 1))
    else:
        all_annotations.append(cds_annotations.iloc[0].tolist())
        num_features_with_annotations += 1
    header = annotations.columns.tolist()

ann_df = pd.DataFrame(all_annotations, columns=header)
print(f"Annotated {num_features_with_annotations} out of {num_features} features.")

ann_df.to_csv(
    os.path.join(netbalance_dir, "strains-features-annotations.csv"), index=False
)
