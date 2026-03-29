# ============================================================
# Scenario D: Campaign Sends & Clicks
# Approach: Uses pandas .merge() to replicate SQL join patterns
# including LEFT JOINs for optional matches, a derived boolean
# column to flag clicks, and anti-join patterns to identify
# customers and sends with no matching records.
# Tables: customers, campaign_sends, clicks
# ============================================================

import pandas as pd

# ============================================================
# Create base tables
# Each table is built as a dictionary of lists and converted
# to a DataFrame. Dictionary keys become column names,
# lists become column values. All lists must be the same length.
# ============================================================

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

# ============================================================
# Q1: Show all campaign sends with customer emails
# Join type: LEFT JOIN (campaign_sends as base)
# Assumption: All sends are returned with their matching
# customer email; how='left' preserves all sends even if
# a customer record were missing
# ============================================================

q1_table = campaign_sends.merge(
    customers,
    on='customer_id',
    how='left'
)[['email', 'campaign_id', 'send_date']]

print(f'Question 1: \n {q1_table}\n')

# ============================================================
# Q2: Identify whether each campaign send resulted in a click
# Join type: LEFT JOIN (campaign_sends as base)
# Assumption: All sends are returned; is_clicked is TRUE if a
# matching click record exists, FALSE if not
# ============================================================

# Step 1: left join clicks to campaign_sends on send_id
# keeps all sends, matches clicks where available (None if no click)
q2_table = campaign_sends.merge(
    clicks,
    on='send_id',
    how='left'
)

# Step 2: create a new boolean column by checking if click_id is not null
# maps True/False to 'TRUE'/'FALSE' text values
q2_table['clicked'] = q2_table['click_id'].notna().map({True: 'TRUE', False: 'FALSE'})

# Step 3: select only the columns needed for the final output
q2_table = q2_table[['send_id', 'clicked']]

print(f'Question 2: \n {q2_table}\n')

# ============================================================
# Q3: Show all customers and any campaigns they received
# Join type: LEFT JOIN (customers as base)
# Assumption: All customers are returned; customer 3 will
# appear with a NULL campaign_id as they received no sends
# ============================================================

q3_table = customers.merge(
    campaign_sends,
    on='customer_id',
    how='left'
)[['email', 'campaign_id']]

print(f'Question 3: \n {q3_table}\n')

# ============================================================
# Q4: Find campaign sends that were never clicked
# Join type: LEFT JOIN (anti-join pattern)
# Assumption: Sends with no matching click record are returned;
# None in click_id after the LEFT JOIN indicates no click
# ============================================================

# Step 1: left join clicks to campaign_sends on send_id
# keeps all sends, matches clicks where available (None if no click)
q4_table = campaign_sends.merge(
    clicks,
    on='send_id',
    how='left'
)

# Step 2: filter to sends with no click match, then select only send_id
q4_table = q4_table[q4_table['click_id'].isna()][['send_id']]

print(f'Question 4: \n {q4_table}\n')

# ============================================================
# Q5: Find customers who have never received a campaign
# Join type: LEFT JOIN (anti-join pattern)
# Assumption: Customers with no matching send record are returned;
# None in campaign_id after the LEFT JOIN indicates no send
# ============================================================

# Step 1: left join customers to campaign_sends on customer_id
q5_table = customers.merge(
    campaign_sends,
    on='customer_id',
    how='left'
)

# Step 2: filter to customers with no matching send, then select only email
q5_table = q5_table[q5_table['campaign_id'].isna()][['email']]

print(f'Question 5: \n {q5_table}\n')