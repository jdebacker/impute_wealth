* Program called by build_small.do
* Micro-matching imputations of missing variables in various small files

* first attempt using nnmatch
* year1 is the year of small file with missing variable
* year0 is the year of small file to be used for imputation
* varmiss is the variable missing in year1 to be imputed
* varmatch is the match variable including the missing variable (we impute after matching based on the ratio varmiss/varmatch)
* varmatch0 are additional match variables, typically agi

/*
global directmatch "/Users/zucman/Dropbox/SaezZucman2014/build_usdina/Data/irs_small"
global year1=74
global year0=73
local varmiss "mortded"
local varmatch "intded"
local varmatch0 "agi"
*/

local varmiss $varmiss
local varmatch $varmatch 
local varmatch0 $varmatch0

* do imputation only if global impute set to 1
if $impute==1 {
use "$dirsmall/small$year1.dta", clear
sum `varmatch0' [w=dweght]
local tot_match0=r(mean)
sum `varmatch' [w=dweght]
local tot_match=r(mean)
keep id `varmiss' `varmatch' `varmatch0' 
keep if `varmatch'!=0
gen missing=1
save "$dirsmall/aux.dta", replace
use "$dirsmall/small$year0.dta", clear
sum `varmatch0' [w=dweght]
local tot_match0_0=r(mean)
sum `varmatch' [w=dweght]
local tot_match_0=r(mean)
* renormalizing variables for difference in means across years [remove if matching across data in same year like SCF-PUF]
replace `varmatch'=`varmatch'*`tot_match'/`tot_match_0'
replace `varmatch0'=`varmatch0'*`tot_match0'/`tot_match0_0'

keep id `varmiss' `varmatch' `varmatch0' 
keep if `varmatch'!=0
gen missing=0
append using "$dirsmall/aux.dta"
save "$dirsmall/aux.dta", replace
gen `varmiss'_old=`varmiss'
set seed 1000
gen rand=uniform()
*keep if rand<=.1
gen numbering=_n
* `varmatch' and `varmatch0' are the variables upon which to match, idm1 is the number _n variable matching in the other group
teffects nnmatch (rand `varmatch' `varmatch0') (missing), gen(idm)

save "$dirsmall/aux.dta", replace
count
keep if missing==1
drop numbering
rename idm1 numbering
cap drop idm*
sort numbering
rename `varmatch' `varmatch'_1
rename `varmatch0' `varmatch0'_1
drop rand `varmiss'
save "$dirsmall/aux1.dta", replace
count

use "$dirsmall/aux.dta", clear
keep if missing==0
drop idm*
rename `varmatch0' `varmatch0'_0
rename `varmatch' `varmatch'_0
keep `varmatch'_0 `varmatch0'_0 `varmiss' numbering 
sort numbering
save "$dirsmall/aux0.dta", replace
count

use "$dirsmall/aux1.dta", clear
merge m:1 numbering using "$dirsmall/aux0.dta"
keep if _merge==3
drop _merge
order  `varmatch0'_1 `varmatch'_1 `varmatch0'_0 `varmatch'_0 `varmiss'
reg `varmatch0'_0 `varmatch0'_1
reg `varmatch'_0 `varmatch'_1
gen `varmiss'_imputed=`varmiss'
* use ratio for imputation whenever reasonable
replace `varmiss'_imputed=round(`varmiss'*`varmatch'_1/`varmatch'_0) if abs(`varmatch'_1/`varmatch'_0)<=1.5
keep id `varmiss'_imputed
sort id 
saveold "$dirsmall/small$year1`varmiss'_supp.dta", replace
}

* addendum 3/2016 to resave the files into old STATA format to make them work at IRS
use "$root/output/small/small$year1`varmiss'_supp.dta", clear
saveold "$root/output/small/small$year1`varmiss'_supp.dta", replace

* do merge regardless of value of global impute
use "$dirsmall/small$year1.dta", clear
sort id
merge 1:1 id using "$root/output/small/small$year1`varmiss'_supp.dta"
drop _merge
replace `varmiss'_impute=0 if `varmiss'_impute==.
order `varmiss'_impute `varmiss'
sum `varmiss'_impute [w=dweght]
local tot_impute=r(mean)
sum `varmiss' [w=dweght]
local tot_old=r(mean)
display `tot_old'/`tot_impute'
replace `varmiss'_impute=round(`varmiss'_impute*`tot_old'/`tot_impute')
sum `varmiss'_impute `varmiss' [w=dweght]
drop `varmiss'
rename `varmiss'_impute `varmiss'
sort id
* re-order data
order $vartot
saveold "$dirsmall/small$year1.dta", replace










