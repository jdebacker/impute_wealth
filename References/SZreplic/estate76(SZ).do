* program to be disclosed that produced estate76.xls for file AppendixTables(OtherEstimates).xls
* uses the estate77.dta file from NBER available at http://users.nber.org/~taxsim/estate-tax/74-77/
* file links estate tax returns filed in 1977 [80\% are 1976 deaths with some 1975, 1977 deaths as well] to individual income tax returns in 1974 (and 1969). 1974 has more details and is closer to death so will be used here
* notes: program estate.do in same directory has more details and more tests

clear all
set mem 500m

use estate77.dta, clear
* keep only estate tax filers
keep if mse!=.
gen filer=(type74!=.)
gen married=(type74==2) if filer==1

* dividend yield is div74/stocke [not that stocke includes closely held business but can condition on chbcde==5 to eliminate cases with closely held business]
* mse=1 are estates for married decedents, type74=2 are individual tax returns married joint filers in 1974

* wealth defined as gross estate net of debts
gen wealth=tgetaxe-debtmte

* number of adult deaths (age 24+) in 1976: 1.8511m from Piketty-Saez NBER WP Table C2
* current sample represents 200K estates [more than 10% of 1.85m deaths in 1976] and about 150K linked to IRS tax returns
* hence reasonable to assume that estates cover the full distribution of dividends and interest
local aggdeath=1851100
gen one=1
sum one [w=wgt] 
local numestate=r(sum_w)
display `numestate'
sum one [w=wgt] if filer==1

* income components, 100 of dividend excluded for singles, 200 for married, see doc estate77.pdf, page 44 in pdf
* small dividends less than 100 (200 if married) are not visible
gen div=div74
replace div=div+100 if div74>0 & married==0
replace div=div+200 if div74>0 & married==1
gen interest=int74

* wealth components, suffix _w
gen div_w=stocke
gen div_wf=div_w+stock_ge
* we exclude slbe (state and local bonds) because interest is tax exempt and not reported in int74
gen interest_w=ofbe+fsbe+cfbe+mne+cashe
gen interest_wf=interest_w+ofb_ge+fsb_ge+cfb_ge+mn_ge+cash_ge
gen muni_w=slbe

gen weight=round(100*wgt)
foreach var of varlist wealth {
cumul `var' [w=weight], gen(rank`var')
replace rank`var'=1-(1-rank`var')*`numestate'/`aggdeath'
}

* analyzing dividend concentration vs corp stock concentration

foreach var of varlist div interest div_w interest_w muni_w {
cumul `var' [w=weight] if filer==1 & married==0, gen(rank`var')
replace rank`var'=1-(1-rank`var')*`numestate'/`aggdeath'
}

* dropping the outlier case $800m in stocks but only 2.2K in dividends
drop if rankdiv_w==1

* table of yields of dividend and interest by wealth class and dividend concentration
matrix table = J(7,14,0)

local jj=0
foreach ii of numlist .9 .95 .99 .995 .999 .9999 .9 {
local jj=`jj'+1
matrix table[`jj',1]=`ii' 
}
local jj=0
foreach ii of numlist  .95 .99 .995 .999 .9999 1.001 1.001 {
local jj=`jj'+1
matrix table[`jj',2]=`ii' 
}

foreach jj of numlist 1/7 {
	local kk=1
	quietly sum wealth [w=wgt] if rankwealth>=table[`jj',1] & rankwealth<table[`jj',2] & filer==1 & married==0
	local totwealth=r(mean)
	matrix table[`jj',3]=r(N)
	matrix table[`jj',4]=r(min)
	foreach var of varlist div interest {	
	quietly sum `var' [w=wgt] if rankwealth>=table[`jj',1] & rankwealth<table[`jj',2] & filer==1 & married==0
	local num=r(mean)
	quietly sum `var'_w [w=wgt] if rankwealth>=table[`jj',1] & rankwealth<table[`jj',2] & filer==1 & married==0
	local den=r(mean)
	matrix table[`jj',4+`kk']=`den'/`totwealth'
	matrix table[`jj',4+`kk'+1]=`num'/`den' 
	* sum `var'_wf [w=wgt] if rankwealth>=table[`jj',1] & rankwealth<table[`jj',2] & filer==1 & married==0
	* local den=r(mean)
	* matrix table[`jj',4+`kk'+2]=`num'/`den'
	local kk=`kk'+2
	}
	* calculating div, div_w, interest, interest_w top wealth shares
	local ii=0
	foreach var of varlist div interest {
	quietly sum `var' [w=wgt] if filer==1 & married==0  
	local agg_inc=r(mean)*r(sum_w)
	quietly sum `var'_w [w=wgt] if filer==1 & married==0  
	local agg_wealth=r(mean)*r(sum_w)
	quietly sum `var' [w=wgt] if rank`var'>=table[`jj',1] & rank`var'<table[`jj',2]  & filer==1 & married==0 
	local tot_inc=r(mean)*r(sum_w)
	* display `tot_inc'/`agg_inc'
	matrix table[`jj',9+`ii']=`tot_inc'/`agg_inc'
	quietly sum `var'_w [w=wgt] if rank`var'_w>=table[`jj',1] & rank`var'_w<table[`jj',2] & filer==1 & married==0 
	local tot_wealth=r(mean)*r(sum_w)
	* display `tot_wealth'/`agg_wealth'
	matrix table[`jj',10+`ii']=`tot_wealth'/`agg_wealth'
	local ii=`ii'+2
	}
	* muni wealth concentration
	quietly sum muni_w if filer==1 & married==0  [w=wgt] 
	local agg_muni=r(mean)*r(sum_w)
	quietly sum muni_w [w=wgt] if rankmuni_w>=table[`jj',1] & rankmuni_w<table[`jj',2]  & filer==1 & married==0 
	local top_muni=r(mean)*r(sum_w)
	quietly sum wealth [w=wgt] if rankmuni_w>=table[`jj',1] & rankmuni_w<table[`jj',2]  & filer==1 & married==0 
	local top_wealth=r(mean)*r(sum_w)
	* display `tot_inc'/`agg_inc'
	matrix table[`jj',13]=`top_muni'/`agg_muni'
	matrix table[`jj',14]=`top_muni'/`top_wealth'
}

matrix list table


svmat table
keep table* 
drop if table1==.
rename table1 perc_min
rename table2 perc_max
rename table3 num_obs
rename table4 wealth_min
rename table5 share_stocks
rename table6 div_yield
rename table7 share_fixedclaim
rename table8 interest_yield
rename table9 div_share
rename table10 divw_share
rename table11 interest_share
rename table12 interestw_share
rename table13 muniw_share
rename table14 share_munis

outsheet using estate76.xls, replace 
* notes about each variable output available in excel sheet estate76 of the Appendix(OtherEstimates).xslx file


