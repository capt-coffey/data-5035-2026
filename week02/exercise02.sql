SELECT 
    *,
    /** I am checking and highlighting Zip codes that do not contain the correct length of numbers and are therefore incorrect. 
    **/
    CASE WHEN LENGTH(ZIP) = 5 THEN 'TRUE' ELSE 'FALSE' END AS DQ_ZIP_LENGTH,
    
    /** I'm checking phone numbers present for many different special characters outside of '-' as well as the full length to highlight if the phone number values are in a stucture and state we can use more accurately. 
    **/
    CASE WHEN CONTAINS(PHONE, '(') OR CONTAINS(PHONE, ')') OR CONTAINS(PHONE, '+') OR CONTAINS(PHONE, 'x') OR CONTAINS(PHONE, '.') AND LENGTH(PHONE) > 12 THEN 'FALSE' ELSE 'TRUE' END AS DQ_PHONE_LENGTH,
    
    /** We have both null and n/a values in the Category Column. If we were data cleaning, I would either set all null to n/a or vise versa. I'm using this check to create flags around what columns have null values in the category column for easier cleaning later. 
    **/
    CASE WHEN CATEGORY IS NULL THEN 'TRUE' ELSE 'FALSE' END AS DQ_BLANK_CATEGORY,
    
    /** I noticed some incredibly high donation amounts. While I'm not sure if these are correct entries or not, what I did notice is that the VAST majority of donations amounts were in the hundreds and thousands, NOT millions. Given how so few are this high I wanted to flag them with a suspect flag for futher data review later. 
    **/
    CASE WHEN LENGTH(AMOUNT) > 6 THEN 'FALSE' ELSE 'TRUE' END AS DQ_AMOUNT_SUSPECT,

    /** The date years are obviously non-traditional. This flag is set on a row level to determine if ALL rows are incorrect, or if some cells contain a more traditional year (e.g. 1995), this would allow further QA and analysis later. 
    **/
    CASE WHEN SUBSTR(DATE_OF_BIRTH, 1, 2) = '00' THEN 'FALSE' ELSE 'TRUE' END AS DQ_DOB_YEAR_CORRECT
FROM data5035.spring26.donations

/** From this assignement I learned that there can be a wide range of quality issues spanning acrossed all columns and that there can be multiple issues within even just one column. One insight that I found is that I felt myself wanting to dig even deeper into the analysis. I mention in a few on my comments, but the using these true/false flags for further analysis down the road or data cleaning really became top of mind. It had me reflecting a bit on query work in general. From this, it's clear that your QA and cleaning queries would be different. The cleaning query would likely be even more complex. It also demonstrates another point that has come up on the textbook reading quite frequently, that being the need for cross team communication. For example, There are questions about this data that I would likely reach out to either the data source manager to question validity or structure(e.g. Year of DOB or the few incredibly high donation amounts). I may even have discussions with final stakeholders on how they might what to see this data or have it cleaned for their uses. In conclusion, this was a fun and thought provoking assignment that has me looking forward to more work along these lines as the class continues. 
**/