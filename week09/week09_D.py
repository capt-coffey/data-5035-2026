import pandas as pd

# Create a dictionary of lists and convert to a DataFrame
# Dictionary keys become column names, lists become column values

# Customers
customers = pd.DataFrame({
    'customer_id': [1, 2, 3],           # list of customer IDs
    'email':       ['a@email.com',       # list of emails, one per customer
                    'b@email.com', 
                    'c@email.com']
})

# Campaign Sends
campaign_sends = pd.DataFrame({
    'send_id':     ['S1', 'S2', 'S3'],                          # unique send ID
    'customer_id': [1, 2, 1],                                    # links to customers
    'campaign_id': ['C1', 'C1', 'C2'],                          # links to campaign
    'send_date':   pd.to_datetime(['2024-01-01',                 # converted to datetime
                                   '2024-01-01', 
                                   '2024-02-01'])
})

# Clicks
clicks = pd.DataFrame({
    'click_id':   ['CL1'],                              # unique click ID
    'send_id':    ['S1'],                               # links back to campaign_sends
    'click_date': pd.to_datetime(['2024-01-02'])        # converted to datetime
    
#------------------------------------------------------------------------------------------------------------
## Q1 Show all campaign sends with customer emails

q1_table = customers.merge(
    campaign_sends,
    on = customer_id
    how = left
)

q1_table = q1_table[['email', 'campaign_id', 'send_date']]
print(q1_table)
