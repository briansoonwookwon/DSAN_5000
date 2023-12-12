# Import packages
import pandas as pd
import numpy as np

# Load the data from the CSV file
df = pd.read_csv("../data/loans.csv")

# Melt the DataFrame
df_melted = df.drop(columns=["id","date","amount","payments"], axis=1).melt(id_vars=["account_id"])

# Find and drop rows with "-" in the "value" column
na_indices = []
for i in df_melted.index:
    if df_melted.loc[i,"value"] == "-":
        na_indices.append(i)
df_melted = df_melted.drop(na_indices)

# Split the "variable" column into "term" and "status"
a = df_melted['variable'].str.split("_")
term = [inner_list[0] for inner_list in a]
status = [inner_list[1] for inner_list in a]
df_melted["term"] = term
df_melted["status"] = status

# Drop "variable" and "value" columns
df_melted.drop(columns=["variable","value"])

# Merge the melted DataFrame with the original DataFrame
df = df.merge(df_melted, how='outer')

# Drop rows with missing values
df = df.dropna()

# Drop specified columns by column index
df = df.drop(df.columns[[number for number in range(5, 27)]], axis=1)

# Convert the "term" column to integers
df = df.astype({'term': int})

# Save the resulting DataFrame to a CSV file
df.to_csv("./loans_py.csv", index=False)