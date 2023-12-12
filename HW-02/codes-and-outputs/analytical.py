# Import libraries
import pandas as pd
import numpy as np

# Read the CSV files
loans = pd.read_csv("loans_py.csv")
accounts = pd.read_csv("../data/accounts.csv")
cards = pd.read_csv("../data/cards.csv")
districts = pd.read_csv("../data/districts.csv")
links = pd.read_csv("../data/links.csv")
transactions = pd.read_csv("../data/transactions.csv")

# Rename columns in dataframes
accounts = accounts.rename(columns = {"id":"account_id"})
accounts = accounts.rename(columns = {"date":"open_date"})
districts = districts.rename(columns = {"id":"district_id"})

# Add "district_name" column
accounts = accounts.merge(districts.loc[:,["district_id","name"]], how='outer')
accounts = accounts.rename(columns = {"name":"district_name"})
accounts = accounts.drop(columns="district_id", axis=1)

# Add "loan_amount","loan_payments","loan_term","loan_status","loan_default" column
loans = loans.drop(columns=["id","date"], axis=1)
default = []
status = []
for i in loans["status"]:
    if i == "A":
        status.append("expired")
        default.append(False)
    if i == "B":
        status.append("expired")
        default.append(True)
    if i == "C":
        status.append("current")
        default.append(False)
    if i == "D":
        status.append("current")
        default.append(False)
loans["status"] = status
loans["defualt"] = default
loans = loans.rename(columns={"amount":"loan_amount","payments":"loan_payments","term":"loan_term","status":"loan_status","defualt":"loan_default"})
accounts = accounts.merge(loans, how='outer')

# Add "loan" column
for i in accounts.index:
    if accounts.loc[i,"loan_amount"].is_integer():
        accounts.loc[i,"loan"] = True
    else:
        accounts.loc[i,"loan"] = False

# Initialize dataframes for merging
links = links.drop(columns = "id")
cards = cards.drop(columns = ["id","type"])
cards = cards.rename(columns={"link_id":"client_id"})

# Add "num_customer" column
clients = links.merge(cards, how="outer")
num_customers = pd.crosstab(index = clients["account_id"], columns="num_customers").reset_index()
accounts = accounts.merge(num_customers, how='outer')

# Add "credit_cards" column
credit_cards = pd.crosstab(index = clients.dropna(subset=['issue_date'])["account_id"], columns="credit_cards").reset_index()
accounts = accounts.merge(credit_cards, how='outer')
accounts['credit_cards'] = accounts['credit_cards'].fillna(0)

withdraw = transactions[transactions["type"]=="debit"]
payments = withdraw[withdraw["method"]=="credit card"]
# Loop through each account_id
for i in transactions["account_id"].unique():
    # Add "min_balance" and "max_balance" columns
    min_balance = transactions[transactions["account_id"]==i]["balance"].min()
    max_balance = transactions[transactions["account_id"]==i]["balance"].max()
    accounts.loc[accounts["account_id"]==i,"max_balance"] = max_balance
    accounts.loc[accounts["account_id"]==i,"min_balance"] = min_balance
    
    # Add "min_withdrawal" and "max_withdrawal" columns
    min_amount = withdraw[withdraw["account_id"]==i]["amount"].min()
    max_amount = withdraw[withdraw["account_id"]==i]["amount"].max()
    accounts.loc[accounts["account_id"]==i,"max_withdrawal"] = max_amount
    accounts.loc[accounts["account_id"]==i,"min_withdrawal"] = min_amount

    # Add "cc_payments" column
    accounts.loc[accounts["account_id"]==i,"cc_payments"] = len(payments[payments["account_id"]==i])

# Make dataframe tidy
accounts = accounts[['account_id', 'district_name', 'open_date', 'statement_frequency','num_customers','credit_cards', 'loan', 'loan_amount','loan_payments', 'loan_term', 'loan_status', 'loan_default','max_withdrawal', 'min_withdrawal', 'cc_payments', 'max_balance', 'min_balance']]
accounts = accounts.sort_values(by='account_id', ascending=True)

# Save the resulting DataFrame to a CSV file
accounts.to_csv("./analytical_py.csv", index=False)