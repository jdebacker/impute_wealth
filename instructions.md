

##Imputation instructions:

$r = \frac{income}{wealth}$

* income comes from NIPA data
* wealth comes from FRB Financial Accounts Data

what are different categories?


We will want an $r$ for each category of capital income on the tax return:
* capital gains income (short and long separately)?
  * Do not capitalize these when creating wealth, because they are lumpy
* dividend income
  * `r_div = dividend_income / corp_equity`
* interest income
  * `r_int = interest_income / debt`
* Sch C income
  * Financial Accounts have "proprieters' equity in noncorporate businesses", but how attribute this between sole proprietorships and partnerships?
  * NIPA data has income from noncorporate businesses - but again, how do Saez and Zucman partition this between sole proprietorships and partnerships?
* Partnership income
  * See above about how separate non-corporate balance sheet and income statment items across different noncorporate entities
* S-corp income
  * Financial Accounts have "corporate equity", but how attribute this between C corporatiosn and S corporations?
  * NIPA data has income from corporate businesses - but again, how do Saez and Zucman partition this between C corporatiosn and S corporations
* rental income
  * `r_rent = rent / total_nonfin_assets`
* royalty income
  * What is the source for royalty producing assets?
  * For royalty income?
  * Neither of these are obvious in the NIPA or FA data...
* pension income?
  * FA tables breakout "pension entitlements", but what else goes into the total assets in pensions?
  * What exact items from the NIPA are used for pension income?
  * How are public pensions like Social Security handled?
  * SZ say that unfunded pension benefits are excluded.  How are these identified?

In addition, we'll also need to impute housing wealth.  We can do this using the amount of the mortgage interest deduction and property tax deductions for filers who itemize.
