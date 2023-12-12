# Import libraries
library(tidyverse)
library(reshape2)
  
# Load the data from the CSV file
df = read.csv("../data/loans.csv")

# Drop columns "id", "date", "amount", and "payments"
df_melted <- df[, !(names(df) %in% c("id", "date", "amount", "payments"))]

# Melt the DataFrame
df_melted <- melt(df_melted, id.vars = "account_id")

# Find and drop rows with "-" in the "value" column
na_indices <- which(df_melted$value == "-")
df_melted <- df_melted[-na_indices, ]
df_melted$variable <- str_replace(df_melted$variable, 'X', '')

# Split the "variable" column into "term" and "status"
a <- strsplit(as.character(df_melted$variable), "_")
term <- sapply(a, function(x) x[1])
status <- sapply(a, function(x) x[2])
df_melted$term <- term
df_melted$status <- status

# Drop "variable" and "value" columns
df_melted <- df_melted[, !(names(df_melted) %in% c("variable", "value"))]

# Merge the melted DataFrame with the original DataFrame
df <- merge(df, df_melted, by = "account_id", all = TRUE)

# Drop rows with missing values
df <- na.omit(df)

# Drop specified columns by column index
df <- df[, -c(6:25)]

# Convert the "term" column to integers
df$term <- as.integer(df$term)

# Save the resulting DataFrame to a CSV file
write.csv(df, file = "./loans_r.csv", row.names = FALSE)