# Import libraries
library(reshape2)
library(tidyverse)

# Read the CSV file
df = read.csv("../data/districts.csv")

# Remove square brackets from the "unemployment_rate" and "commited_crimes" columns
df$unemployment_rate = gsub("\\[|\\]", "", df$unemployment_rate)
df$commited_crimes = gsub("\\[|\\]", "", df$commited_crimes)

# Split "unemployment_rate" and "commited_crimes" columns and create new columns
df = df %>%
  separate(unemployment_rate, c("unemployment_rate_95", "unemployment_rate_96"), sep = ",") %>%
  separate(commited_crimes, c("commited_crimes_95", "commited_crimes_96"), sep = ",")

# Save the resulting DataFrame to a CSV file
write.csv(df, file = "./district_r.csv", row.names = FALSE)