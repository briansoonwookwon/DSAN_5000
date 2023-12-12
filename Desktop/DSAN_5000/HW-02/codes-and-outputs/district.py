# Import libraries
import pandas as pd
import numpy as np

# Read the CSV file
df = pd.read_csv("../data/districts.csv")

# Remove square brackets from the "unemployment_rate" and "commited_crimes" columns
df['unemployment_rate'] = df['unemployment_rate'].str.replace('[', '')
df['unemployment_rate'] = df['unemployment_rate'].str.replace(']', '')
df['commited_crimes'] = df['commited_crimes'].str.replace('[', '')
df['commited_crimes'] = df['commited_crimes'].str.replace(']', '')

# Split "unemployment_rate" column and create new columns
a = df['unemployment_rate'].str.split(",")
unemployment_rate_95 = [inner_list[0] for inner_list in a]
unemployment_rate_96 = [inner_list[1] for inner_list in a]
df["unemployment_rate_95"] = unemployment_rate_95
df["unemployment_rate_96"] = unemployment_rate_96
df = df.replace("[","")

# Split "commited_crimes" column and create new columns
b = df['commited_crimes'].str.split(",")
commited_crimes_95 = [inner_list[0] for inner_list in b]
commited_crimes_96 = [inner_list[1] for inner_list in b]
df["commited_crimes_95"] = commited_crimes_95
df["commited_crimes_96"] = commited_crimes_96
df = df.replace("[","")

# Drop unnecessary columns
df = df.drop(df.columns[[12,13]], axis=1)

# Save the resulting DataFrame to a CSV file
df.to_csv("./district_py.csv", index=False)
