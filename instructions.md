

##Imputation instructions:

$r = \frac{income}{wealth}$

* income comes from NIPA data
* wealth comes from financial accounts data

what are different categories?


We will want an $r$ for each category of capital income on the tax return:
* capital gains income (short and long separately)?
  * Do not capitalize these when creating wealth, because they are lumpy
* dividend income
  * `r_div = dividend_income / corp_equity`
* interest income
  * `r_int = interest_income / debt`
* Sch C income
* Partnership income
* S-corp income
* rental income
  * `r_rent = rent / total_nonfin_assets`
* royalty income
* pension income?

In addition, we'll also need to impute housing wealth.  We can do this using the amount of the mortgage interest deduction and property tax deductions for filers who itemize.
