* This file to be deleted.
* Replace this check by the construction of CPS files with top 10% from the small files.

mat drop _all
foreach year of numlist 1962/2014 {
  use $diroutput/cpsindiv/cpsmar`year'indiv.dta, clear
  total inctotal [iw = marsupwt]  // fiscal income
  matrix b = e(b)									// ... and saves result in 1x1 matrix
  local indiv_tot_fisc = b[1,1]
  total ptotval [iw = marsupwt]   // money income
  matrix b = e(b)									// ... and saves result in 1x1 matrix
  local indiv_tot_money = b[1,1]

  use $diroutput/cpstaxunit/indiv_variables/cpsmar`year'.dta, clear
  total inctotal [iw = marsupwt]  // fiscal income
  matrix b = e(b)									// ... and saves result in 1x1 matrix
  local taxunit_tot_fisc = b[1,1]
  total ptotval [iw = dweght]
  matrix b = e(b)
  local taxunit_tot_money = b[1,1]

  qui mat total_inc`year'  = (`year', `indiv_tot_fisc', `taxunit_tot_fisc', `indiv_tot_money', `taxunit_tot_money')
  qui mat total_inc  = (nullmat(total_inc)  \ total_inc`year')
}
clear
matname total_inc year total_fiscinc_indiv total_fiscinc_taxunit total_money_indiv total_money_taxunit, columns(1..5) explicit
svmat total_inc, names(col)
gen pct_diff_fisc = (total_fiscinc_indiv - total_fiscinc_taxunit)/total_fiscinc_indiv
gen pct_diff_money = (total_money_indiv - total_money_taxunit)/total_money_indiv
qui compress
export excel using "$diroutput/temp/cps/total_inc_cps.xlsx", first(var) replace
