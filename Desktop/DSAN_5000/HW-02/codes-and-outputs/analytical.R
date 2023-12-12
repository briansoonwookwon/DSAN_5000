# Import libraries
library(tidyverse)
library(reshape2)

# Read the CSV files
loans = read.csv("loans_r.csv")
accounts = read.csv("../data/accounts.csv")
cards = read.csv("../data/cards.csv")
districts = read.csv("../data/districts.csv")
links = read.csv("../data/links.csv")
transactions = read.csv("../data/transactions.csv")

# Rename columns in dataframes
names(accounts)[names(accounts) == "id"] = "account_id"
names(accounts)[names(accounts) == "date"] = "open_date"
names(districts)[names(districts) == "id"] = "district_id"

# Merge the 'districts' dataframe with the 'accounts' dataframe
accounts = merge(accounts, districts[, c("district_id", "name")], by.x = "district_id", by.y = "district_id", all = TRUE)

# Rename the merged column to 'district_name'
names(accounts)[names(accounts) == "name"] = "district_name"

# Drop the 'district_id' column
accounts = accounts[, !(names(accounts) %in% c("district_id"))]

# Drop columns "id" and "date" from the 'loans' dataframe
loans = loans[, !(names(loans) %in% c("id", "date"))]

# Create empty vectors to store "status" and "default" values
status = vector("character", length = nrow(loans))
default = vector("logical", length = nrow(loans))

# Iterate through the "status" column and populate "status" and "default" vectors
for (i in 1:nrow(loans)) {
  if (loans$status[i] == "A" ){
    status[i] = "expired"
    default[i] = FALSE
  }  else if (loans$status[i] == "B"){
    status[i] = "expired"
    default[i] = TRUE    
  } else if (loans$status[i] == "C" || loans$status[i] == "D") {
    status[i] = "current"
    default[i] = FALSE
  }
}

# Replace the "status" and "default" columns in the 'loans' dataframe
loans$status = status
loans$loan_default = default

# Rename columns
colnames(loans) = c("account_id","loan_amount", "loan_payments", "loan_term", "loan_status", "loan_default")

# Merge loans and accounts dataframe
accounts = merge(accounts, loans, all = TRUE)

# Create a new column 'loan' in the 'accounts' dataframe
accounts$loan = NA
for (i in 1:nrow(accounts)) {
  if (is.na(accounts$loan_amount[i])) {
    accounts$loan[i] = FALSE
  } else {
    accounts$loan[i] = TRUE
  }
}

# Drop the "id" column from the 'links' dataframe
links = links[, !(names(links) %in% c("id"))]

# Drop the "id" and "type" columns from the 'cards' dataframe
cards = cards[, !(names(cards) %in% c("id", "type"))]

# Rename the "link_id" column to "client_id" in the 'cards' dataframe
colnames(cards)[colnames(cards) == "link_id"] = "client_id"

# Merge the 'links' and 'cards' dataframes 
a = merge(links, cards, all = TRUE)

# Create a cross-tabulation to count the number of customers per account_id
b = table(a$account_id)

# Convert the result to a dataframe and reset the index
b = as.data.frame(b)
names(b) = c("account_id", "num_customers")

# Add 'num_customers' column by merging the 'accounts' dataframe with the 'b' dataframe
accounts = merge(accounts, b, by = "account_id", all = TRUE)

# Create a subset of 'a' dataframe and count the number of credit cards per account_id
c = table(a[!is.na(a$issue_date), "account_id"])

# Convert the result to a dataframe and reset the index
c = as.data.frame(c)
names(c) = c("account_id", "credit_cards")

# Add 'credit_cards' column by merging the 'accounts' dataframe with the 'c' dataframe
accounts = merge(accounts, c, by = "account_id", all = TRUE)

# Replace missing values in the 'credit_cards' column with 0
accounts$credit_cards[is.na(accounts$credit_cards)] = 0

# Initialize columns
accounts$max_balance = NA
accounts$min_balance = NA
accounts$max_withdrawal = NA
accounts$min_withdrawal = NA

# Create a subset of 'transactions' dataframe for debit transactions
withdraw = transactions %>% filter(type == "debit")

# Iterate through unique account IDs in 'transactions'
for (i in unique(transactions$account_id)) {
  # Calculate the max and min balances for the current account ID
  min_balance = min(transactions$balance[transactions$account_id == i])
  max_balance = max(transactions$balance[transactions$account_id == i])
  
  # Update the 'accounts' dataframe with max and min balances
  accounts$max_balance[accounts$account_id == i] = max_balance
  accounts$min_balance[accounts$account_id == i] = min_balance

  # Calculate the max and min withdrawal amounts for the current account ID
  min_withdrawal = min(withdraw$amount[withdraw$account_id == i])
  max_withdrawal = max(withdraw$amount[withdraw$account_id == i])
  
  # Update the 'accounts' dataframe with max and min withdrawal amounts
  accounts$max_withdrawal[accounts$account_id == i] = max_withdrawal
  accounts$min_withdrawal[accounts$account_id == i] = min_withdrawal
}

# Create a subset of 'withdraw' dataframe for transactions with "credit card" method
payments = withdraw[withdraw$method == "credit card", ]

# Initialize a column for credit card payments in the 'accounts' dataframe
accounts$cc_payments = 0

# Iterate through unique account IDs in 'transactions'
for (i in unique(transactions$account_id)) {
  # Count the number of credit card payments for the current account ID
  num_cc_payments = sum(payments$account_id == i)
  
  # Update the 'accounts' dataframe with the number of credit card payments
  accounts$cc_payments[accounts$account_id == i] = num_cc_payments
}

# Reorder the columns
accounts = accounts %>%
  select('account_id', 'district_name', 'open_date', 'statement_frequency','num_customers','credit_cards', 'loan', 'loan_amount','loan_payments', 'loan_term', 'loan_status', 'loan_default','max_withdrawal', 'min_withdrawal', 'cc_payments', 'max_balance', 'min_balance')

# Save the resulting dataframe to a CSV file
write.csv(accounts, file = "./analytical_r.csv", row.names = FALSE)