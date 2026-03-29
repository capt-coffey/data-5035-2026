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
})
    
#------------------------------------------------------------------------------------------------------------
## Q1 Show all campaign sends with customer emails

# Step 1: left join customers to campaign_sends on customer_id
# keeps all sends, bringing in the matching customer email
q1_table = campaign_sends.merge(
    customers,
    on='customer_id',
    how='left'
# Step 2: select only the columns needed for the final output
)[['email', 'campaign_id', 'send_date']]

print(f'Question 1: \n {q1_table}\n')

#-------------------------------------------------------------------------------------------------------------
## Q2 Identify whether each campaign send resulted in a click

# Step 1: left join campaign_sends to clicks on send_id
# keeps all sends, matches clicks where available (NULL if no click)
q2_table = campaign_sends.merge(
    clicks,
    on='send_id',
    how='left'
)

# Step 2: create a new boolean column by checking if click_id is not null
# maps True/False to 'TRUE'/'FALSE' text values
q2_table['is_clicked'] = q2_table['click_id'].notna().map({True: 'TRUE', False: 'FALSE'})

# Step 3: select only the columns needed for the final output
q2_table = q2_table[['send_id', 'is_clicked']]

print(f'Question 2: \n {q2_table}\n')

#-------------------------------------------------------------------------------------------------------------
## Q3 Show all customers and any campaigns they received

# Step 1: left join customers to campaign_sends on customer_id
# keeps all customers, even without sends. 
q3_table = customers.merge(
    campaign_sends,
    on='customer_id',
    how='left'
)[['email', 'campaign_id']]

print(f'Question 3: \n {q3_table}\n')

#-------------------------------------------------------------------------------------------------------------
## Q4 Find campaign sends that were never clicked

# Step 1: left join  to campaign_sends on customer_id
q4_table = campaign_sends.merge(
    clicks,
    on='send_id',
    how='left'
)

# Step 2: only keep campaigns that were never clicked. Then only keep the send_id column. 
q4_table = q4_table[q4_table['click_id'].isna()][['send_id']]

print(f'Question 4: \n {q4_table}\n')


#-------------------------------------------------------------------------------------------------------------
## Q5 Find customers who have never received a campaign

# Step 1: left join customers to campaign_sends
q5_table = customers.merge(
    campaign_sends,
    on='customer_id',
    how='left'
)

# Step 2: only keep customer emails who have never recieved a campaign send.  
q5_table = q5_table[q5_table['campaign_id'].isna()][['email']]

print(f'Question 5: \n {q5_table}\n')
