* Do file that plots all DINA results

 * external full PUF data
if $online == 0 {
	global diroutsheet "$root/output/ToExcel"
	global dirgraph	   "$diroutput/graphs"
	global diroutexcel "$root/DINA(distrib)External.xlsx"
	cap mkdir $dirgraph
	local last = $endyear
}	

* internal IRS data, $online manually changed in runusdina.do
if $online == -1 {
	global diroutsheet "$root/output/ToExcelInternal"
	global dirgraph	   "$diroutput/graphsInternal"
	global diroutexcel "$root/DINA(distrib).xlsx"
	cap mkdir $dirgraph
	local last = $endyear
}

* online small PUF data
if $online == 1 & $calibweight != 1 {
	global diroutsheet "$root/output/ToExcelonline"
	global dirgraph	   "$diroutput/graphsOnline"
	global diroutexcel "$root/DINA(distrib)Online.xlsx"
	cap mkdir $dirgraph
	local last = $endyear
}	


* online small PUF data with calibrated weights
if $online == 1 & $calibweight == 1 {
	global diroutsheet "$root/output/ToExcelonlinecal"
	global dirgraph	   "$diroutput/graphsOnlinecal"
	global diroutexcel "$root/DINA(distrib)Onlinecal.xlsx"
	cap mkdir $dirgraph
	local last = $endyear
}	



local population "indiv equal taxu  working male female" // oldwgt
local variable "fiinc fninc fainc fkinc flinc ptinc pkinc plinc diinc princ peinc poinc hweal"
*local agebin "20 35 45 55 65 75 99"
local agebin "99"

****************************************************************************************************************************************************************
*
* CREATE DATASET WITH YEARS IN ROW AND SHARES, THRESHOLDS, AND AVERAGES IN COLUMN
*
****************************************************************************************************************************************************************



* Deflators to compute real values
	insheet using "$parameters", clear names
		keep if yr<=`last'
		keep yr nideflator
		rename yr c1
	saveold $dirgraph/datagraph.dta, replace


* Bring Excel results 
	foreach pop of local population {
		foreach inc of local variable {
			foreach stat in compo  thres sh  { 
				foreach age of local agebin {
					capture {
						import excel "$diroutsheet/`stat'`inc'`pop'`age'.xlsx", first clear
							if "`stat'" == "compo" | "`stat'" == "sh" {
								foreach var of varlist *0 { // create *8 = bottom 50, *9 = bottom 90, and *10 = middle 40
									local j =substr("`var'",1,length("`var'")-1)
									gen `j'8 = `j'0 - `j'1
									gen `j'9 = `j'0 - `j'2
									gen `j'10 = `j'9 - `j'8									
								}								
								ds c1, not
								foreach var of varlist `r(varlist)' {
									rename `var' sh`var'`pop'`age'
								}	
							}
							if "`stat'" == "thres"  {
								if "`inc'" == "hweal" keep  c1 n total `inc'nokg* // only threshwealnokg is meaningful for wealth
								if "`inc'" == "hweal" rename `inc'nokg* `inc'*	
								keep c1 n total `inc'1  // keep median only for now
								rename `inc'1 thres`inc'1`pop'`age'
							}
						cap rename total m`inc'`pop'`age'
						cap rename n 	 p`inc'`pop'`age'
						merge 1:1 c1 using $dirgraph/datagraph.dta, update
						drop _merge
						saveold $dirgraph/datagraph.dta, replace
					}
				}	
			}
		}	
	}

* Smoothing shares and averages 1967-1978 (as in Saez-Zucman: real estate in small files is bumpy)
	use "$dirgraph/datagraph.dta", clear
	sort c1
	foreach var of varlist sh*  {
		qui replace `var' = (`var' + 0.5 * (`var'[_n-1] + `var'[_n+1])) / 2 if (c1 >= 1967 & c1 <= 1978) 
	}
	saveold $dirgraph/datagraph.dta, replace


* Create averages in avg`var'`i'`pop'`age' format 
	foreach pop of local population {
		foreach var of local variable {
				foreach age of local agebin {
					forval i = 0/10 {
						quietly {
						if `i' == 0 cap gen avg`var'`i'`pop'`age' = sh`var'`i'`pop'`age' * m`var'`pop'`age' / (1 * p`var'`pop'`age')
						if `i' == 1 cap gen avg`var'`i'`pop'`age' = sh`var'`i'`pop'`age' * m`var'`pop'`age' / (0.5 * p`var'`pop'`age')
						if `i' == 2 cap gen avg`var'`i'`pop'`age' = sh`var'`i'`pop'`age' * m`var'`pop'`age' / (0.1 * p`var'`pop'`age')
						if `i' == 3 cap gen avg`var'`i'`pop'`age' = sh`var'`i'`pop'`age' * m`var'`pop'`age' / (0.05 * p`var'`pop'`age')
						if `i' == 4 cap gen avg`var'`i'`pop'`age' = sh`var'`i'`pop'`age' * m`var'`pop'`age' / (0.01 * p`var'`pop'`age')
						if `i' == 5 cap gen avg`var'`i'`pop'`age' = sh`var'`i'`pop'`age' * m`var'`pop'`age' / (0.005 * p`var'`pop'`age')
						if `i' == 6 cap gen avg`var'`i'`pop'`age' = sh`var'`i'`pop'`age' * m`var'`pop'`age' / (0.001 * p`var'`pop'`age')
						if `i' == 7 cap gen avg`var'`i'`pop'`age' = sh`var'`i'`pop'`age' * m`var'`pop'`age' / (0.0001 * p`var'`pop'`age')
						if `i' == 8 cap gen avg`var'`i'`pop'`age' = sh`var'`i'`pop'`age' * m`var'`pop'`age' / (0.5 * p`var'`pop'`age')
						if `i' == 9 cap gen avg`var'`i'`pop'`age' = sh`var'`i'`pop'`age' * m`var'`pop'`age' / (0.9 * p`var'`pop'`age')
						if `i' == 10 cap gen avg`var'`i'`pop'`age' = sh`var'`i'`pop'`age' * m`var'`pop'`age' / (0.4 * p`var'`pop'`age')
						}
					}
				}
			}
		}	
	saveold $dirgraph/datagraph.dta, replace


* Bring pre-62 series
	use $dirgraph/datagraph.dta, clear
	rename c1 year
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta", update
	drop _merge
	saveold $dirgraph/datagraph.dta, replace

/*
* Replaces piksaez recomputed series by true piketty-saez (to be improved using fnps...)		
	use "$diroutput/pre62/pre62comp.dta", clear
	keep year shfn* shfi*
	*rename year c1
	cap mkdir "$dirgraph/temp"
	save "$dirgraph/temp/ps.dta", replace
	use "$dirgraph/datagraph.dta", clear
	merge 1:1 year using "$dirgraph/temp/ps.dta", update replace 
	drop _merge
	saveold $dirgraph/datagraph.dta, replace
*/


* Label variables
	forval i = 0/10 {
		foreach pop of local population {
			foreach inc of local variable {
				foreach stat in sh  thres   {
					foreach age of local agebin {
						if "`inc'" == "fainc" cap label variable `stat'`inc'`i'`pop'`age' "Personal factor"
						if "`inc'" == "princ" cap label variable `stat'`inc'`i'`pop'`age' "Pre-tax"
						if "`inc'" == "ptinc" cap label variable `stat'`inc'`i'`pop'`age' "Personal post-pension"
						if "`inc'" == "peinc" cap label variable `stat'`inc'`i'`pop'`age' "Post-pension"
						if "`inc'" == "diinc" cap label variable `stat'`inc'`i'`pop'`age' "Personal disposable"
						if "`inc'" == "poinc" cap label variable `stat'`inc'`i'`pop'`age' "Post-tax"
						if "`inc'" == "fiinc" cap label variable `stat'`inc'`i'`pop'`age' "Fiscal income (with KG)"
						if "`inc'" == "fninc" cap label variable `stat'`inc'`i'`pop'`age' "Fiscal income (no KG)"
						if "`inc'" == "fnps"  cap label variable `stat'`inc'`i'`pop'`age' "Fiscal income (Piketty-Saez)"
						if "`inc'" == "hweal" cap label variable `stat'`inc'`i'`pop'`age' "Wealth"
						if "`inc'" == "hweal" cap label variable `stat'`inc'nokg`i'`pop'`age' "Wealth (KG not capitalized)"
					}	
				}
			}	
		}	
	}	

* Compute real values
	foreach var of varlist avg* thres* {
		cap replace `var' = `var' * nideflator
	}

cap format avg*  %12.0fc
cap format thres*  %12.0fc	
sort year
foreach var of varlist _all {
		replace `var' = 0.5 * (`var'[_n-1] + `var'[_n+1]) if (year == 1963 | year == 1965) & `var' == . 
	}	

keep if year>=1913	
saveold $dirgraph/datagraph.dta, replace

*/


****************************************************************************************************************************************************************
*
* GRAPHS
*
****************************************************************************************************************************************************************
/*

********************************************************************************
* Wealth
********************************************************************************

cap graph drop _all
use "$dirgraph/datagraph.dta", clear

cap mkdir "$dirgraph/wealth"
cap mkdir "$dirgraph/factork"

* All ages
	foreach pop in indiv taxu working oldwgt { 
		forval i = 1/10 {
			
			if "`pop'" == "indiv"   local popdes = "Adult individuals (20+)"
			if "`pop'" == "taxu"    local popdes = "Tax units"
			if "`pop'" == "oldwgt"  local popdes = "Tax units (old weights)"
			if "`pop'" == "equal"   local popdes = "Adult individuals (20+), equal split among spouses"
			if "`pop'" == "working" local popdes = "Working-age adult individuals (20-65)"	
			if "`pop'" == "male"	local popdes = "Adult men (20+)"
			if "`pop'" == "female"	local popdes = "Adult women (20+)"
			
			if `i'==1 {
				local group  "Top 50%"
				local first = 1962
				local axis yla(0 "0%" 0.2 "20%" 0.4 "40%" 0.6 "60%" 0.8 "80%" 1 "100%", glcolor(gs10) glwidth(medthin) glpattern(dot))
			}

			if `i'==2 {
				local group  "Top 10%"
				local first = 1917
				local axis yla(.6 "60%" .65 "65%" .7 "70%" .75 "75%" .8 "80%" .85 "85%" .9 "90%", glcolor(gs10) glwidth(medthin) glpattern(dot))
			}

			if `i'==3 {
				local group  "Top 5%"
				local first = 1917
				local axis yla(.45 "45%" .5 "50%" .55 "55%" .6 "60%" .65 "65%" .7 "70%" .75 "75%" .8 "80%", glcolor(gs10) glwidth(medthin) glpattern(dot))
			}	

			if `i'==4 {
				local group  "Top 1%"
				local first = 1917
				local axis yla(.2 "20%" .25 "25%" .3 "30%" .35 "35%" .4 "40%" .45 "45%" .5 "50%", glcolor(gs10) glwidth(medthin) glpattern(dot))
				*local axis yla(.2 "20%" .25 "25%" .3 "30%" .35 "35%" .4 "40%", glcolor(gs10) glwidth(medthin) glpattern(dot))

			}

			if `i'==5  {
				local group  "Top 0.5%"
				local first = 1917
				local axis yla(0 "0%" .05 "5%" .1 "10%" .15 "15%" .2 "20%" .25 "25%" .3 "30%" .35 "35%" .4 "40%", glcolor(gs10) glwidth(medthin) glpattern(dot))
			}

			if `i'==6  {
				local group  "Top 0.1%"
				local first = 1917
				local axis yla(0 "0%" .05 "5%" .1 "10%" .15 "15%" .2 "20%" .25 "25%", glcolor(gs10) glwidth(medthin) glpattern(dot))
			}	

			if `i'==7 {
				local group  "Top 0.01%"
				local first = 1917
				local axis yla(0 "0%" .02 "2%" .04 "4%" .06 "6%" .08 "8%" .1 "10%" .12 "12%", glcolor(gs10) glwidth(medthin) glpattern(dot))
			}
				
			if `i'==8 {
				local group  "Bottom 50%"	
				local first = 1962
				local axis yla(-0.2 "-20%" 0 "0%" 0.2 "20%" 0.4 "40%" 0.6 "60%" 0.8 "80%" 1 "100%", glcolor(gs10) glwidth(medthin) glpattern(dot))
			}

			if `i'==9 {
				local group  "Bottom 90%"
				local first = 1917	
				local axis yla(0 "0%" .05 "5%" .1 "10%" .15 "15%" .2 "20%" .25 "25%" .3 "30%" .35 "35%" .4 "40%", glcolor(gs10) glwidth(medthin) glpattern(dot))
			}
				
			if `i'==10 {
				 local group "P50-P90"	
				 local first = 1962
				 local axis yla(0 "0%" .05 "5%" .1 "10%" .15 "15%" .2 "20%" .25 "25%" .3 "30%" .35 "35%" .4 "40%", glcolor(gs10) glwidth(medthin) glpattern(dot))
			}

			if "`pop'" == "working" local first = 1962
			local first2 = `first' - 2

				twoway connected shhweal`i'`pop'99 year if year>=`first', ///
				lcolor(black) mfcolor(black) mlcolor(black) ///
				ytitle("Share of total wealth", height(5)) `axis' ///
				xtitle("") xla(`first2'(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
				graphregion(color(white)) plotregion(margin(zero)) ///
				title("`group' wealth share", color(black))  ///
				note("Population: `popdes'")  ///
				name(shwealth`i'`pop') 
				graph export $dirgraph/wealth/shwealth`i'`pop'.pdf, name(shwealth`i'`pop') replace

				local first = 1962
				local first2 = 1960
				cap twoway connected shfkinc`i'`pop'99 year if year>=`first', ///
				lcolor(black) mfcolor(black) mlcolor(black) ///
				ytitle("Share of total factor capital income", height(5)) `axis' ///
				xtitle("") xla(`first2'(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
				graphregion(color(white)) plotregion(margin(zero)) ///
				title("`group' factor capital income share", color(black))  ///
				note("Population: `popdes'")  ///
				name(shfkinc`i'`pop') 
				cap graph export $dirgraph/factork/shfkinc`i'`pop'.pdf, name(shfkinc`i'`pop') replace
				cap graph drop shfkinc`i'`pop'	

			
		}
	}



********************************************************************************
* Factor income, pretax income, post-tax income
********************************************************************************

cap graph drop _all
use "$dirgraph/datagraph.dta", clear

cap mkdir "$dirgraph/factor"
cap mkdir "$dirgraph/factorl"
cap mkdir "$dirgraph/pretax"
cap mkdir "$dirgraph/posttax"
cap mkdir "$dirgraph/factormatch"
cap mkdir "$dirgraph/pretaxmatch"
cap mkdir "$dirgraph/posttaxmatch"

* All ages
	foreach pop in indiv equal taxu working male female  { 
	cap graph drop _all
		forval i = 1/10 {

			if "`pop'" == "indiv"   local popdes = "Adult individuals (20+)"
			if "`pop'" == "taxu"    local popdes = "Tax units"
			if "`pop'" == "oldwgt"  local popdes = "Tax units (old weights)"
			if "`pop'" == "equal"   local popdes = "Adult individuals (20+), equal split among spouses"
			if "`pop'" == "working" local popdes = "Working-age adult individuals (20-65)"	
			if "`pop'" == "male"	local popdes = "Adult men (20+)"
			if "`pop'" == "female"	local popdes = "Adult women (20+)"
			
			if `i'==1 {
				local group  "Top 50%"
				local first = 1962
				local axis yla(0.8 "80%" .85 "85%" .9 "90%" .95 "95%" 1 "100%", glcolor(gs10) glwidth(medthin) glpattern(dot))
			}

			if `i'==2 {
				local group  "Top 10%"
				local first = 1917
				local axis yla(.35 "35%" .4 "40%" .45 "45%" .5 "50%" .55 "55%", glcolor(gs10) glwidth(medthin) glpattern(dot))
			}

			if `i'==3 {
				local group  "Top 5%"
				local first = 1917
				local axis yla(.25 "25%" .3 "30%" .35 "35%" .4 "40%" .45 "45%", glcolor(gs10) glwidth(medthin) glpattern(dot))
			}	

			if `i'==4 {
				local group  "Top 1%"
				local first = 1917
				local axis yla(0 "0%" .05 "5%" .1 "10%" .15 "15%" .2 "20%" .25 "25%", glcolor(gs10) glwidth(medthin) glpattern(dot))
			*local axis yla(0 "0%" .02 "2%" .04 "4%" .06 "6%" .08 "8%" .1 "10%" .12 "12%" .14 "14%" .16 "16%", glcolor(gs10) glwidth(medthin) glpattern(dot))
			}

			if `i'==5  {
				local group  "Top 0.5%"
				local first = 1917
				local axis yla(0 "0%" .05 "5%" .1 "10%" .15 "15%" .2 "20%", glcolor(gs10) glwidth(medthin) glpattern(dot))
			}

			if `i'==6  {
				local group  "Top 0.1%"
				local first = 1917
				local axis yla(0 "0%" .02 "2%" .04 "4%" .06 "6%" .08 "8%" .1 "10%" .12 "12%", glcolor(gs10) glwidth(medthin) glpattern(dot))
			}	

			if `i'==7 {
				local group  "Top 0.01%"
				local first = 1917
				local axis yla(0 "0%" .01 "1%" .02 "2%" .03 "3%" .04 "4%" .05 "5%" .06 "6%", glcolor(gs10) glwidth(medthin) glpattern(dot))
			}
				
			if `i'==8 {
				local group  "Bottom 50%"	
				local first = 1962
				local axis yla(0 "0%" .05 "5%" .1 "10%" .15 "15%" .2 "20%", glcolor(gs10) glwidth(medthin) glpattern(dot))
			}

			if `i'==9 {
				local group  "Bottom 90%"
				local first = 1917	
				local axis yla(.45 "45%" .5 "50%" .55 "55%" .6 "60%" .65 "65%", glcolor(gs10) glwidth(medthin) glpattern(dot))
			}
				
			if `i'==10 {
				 local group "P50-P90"	
				 local first = 1962
				 local axis yla(.3 "30%" .35 "35%" .4 "40%" .45 "45%" .5 "50%" .55 "55%" .6 "60%", glcolor(gs10) glwidth(medthin) glpattern(dot))
			}

			if "`pop'" == "working" | "`pop'" == "male" | "`pop'" == "female" {
				local first = 1962
			}
			local first2 = `first' - 2

				twoway connected shfainc`i'`pop'99 year if year>=`first', ///
				lcolor(black) mfcolor(black) mlcolor(black) ///
				ytitle("Share of total factor income", height(5)) `axis' ///
				xtitle("") xla(`first2'(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
				graphregion(color(white)) plotregion(margin(zero)) ///
				title("`group' factor income share", color(black))  ///
				note("Population: `popdes'")  ///
				name(shfainc`i'`pop') 
				graph export $dirgraph/factor/shfainc`i'`pop'.pdf, name(shfainc`i'`pop') replace
				cap graph drop shfainc`i'`pop'							

				twoway connected shptinc`i'`pop'99 year if year>=`first', ///
				lcolor(black) mfcolor(black) mlcolor(black) ///
				ytitle("Share of total pre-tax income", height(5)) `axis' ///
				xtitle("") xla(`first2'(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
				graphregion(color(white)) plotregion(margin(zero)) ///
				title("`group' pre-tax income share", color(black))  ///
				note("Population: `popdes'")  ///
				name(shptinc`i'`pop') 
				graph export $dirgraph/pretax/shptinc`i'`pop'.pdf, name(shptinc`i'`pop') replace
				cap graph drop shptinc`i'`pop'

				twoway connected shdiinc`i'`pop'99 year if year>=`first', ///
				lcolor(black) mfcolor(black) mlcolor(black) ///
				ytitle("Share of total disposable income", height(5)) `axis' ///
				xtitle("") xla(`first2'(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
				graphregion(color(white)) plotregion(margin(zero)) ///
				title("`group' disposable income share", color(black))  ///
				note("Population: `popdes'")  ///
				name(shdiinc`i'`pop') 
				graph export $dirgraph/posttax/shdiinc`i'`pop'.pdf, name(shdiinc`i'`pop') replace
				cap graph drop shdiinc`i'`pop'			

				twoway connected shprinc`i'`pop'99 year if year>=`first', ///
				lcolor(black) mfcolor(black) mlcolor(black) ///
				ytitle("Share of total factor income (matching NI)", height(5)) `axis' ///
				xtitle("") xla(`first2'(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
				graphregion(color(white)) plotregion(margin(zero)) ///
				title("`group' factor income share", color(black))  ///
				note("Population: `popdes'")  ///
				name(shprinc`i'`pop') 
				graph export $dirgraph/factormatch/shprinc`i'`pop'.pdf, name(shprinc`i'`pop') replace
				cap graph drop shprinc`i'`pop'	

				twoway connected shpeinc`i'`pop'99 year if year>=`first', ///
				lcolor(black) mfcolor(black) mlcolor(black) ///
				ytitle("Share of total pre-tax income (matching NI)", height(5)) `axis' ///
				xtitle("") xla(`first2'(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
				graphregion(color(white)) plotregion(margin(zero)) ///
				title("`group' pre-tax income share", color(black))  ///
				note("Population: `popdes'")  ///
				name(shpeinc`i'`pop') 
				graph export $dirgraph/pretaxmatch/shpeinc`i'`pop'.pdf, name(shpeinc`i'`pop') replace
				cap graph drop shpeinc`i'`pop'	

				twoway connected shpoinc`i'`pop'99 year if year>=`first', ///
				lcolor(black) mfcolor(black) mlcolor(black) ///
				ytitle("Share of total post-tax income (matching NI)", height(5)) `axis' ///
				xtitle("") xla(`first2'(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
				graphregion(color(white)) plotregion(margin(zero)) ///
				title("`group' post-tax income share", color(black))  ///
				note("Population: `popdes'")  ///
				name(shpoinc`i'`pop') 
				graph export $dirgraph/posttaxmatch/shpoinc`i'`pop'.pdf, name(shpoinc`i'`pop') replace
				cap graph drop shpoinc`i'`pop'		

				local first = 1962
				local first2 = 1960
				cap twoway connected shflinc`i'`pop'99 year if year>=`first', ///
				lcolor(black) mfcolor(black) mlcolor(black) ///
				ytitle("Share of total factor labor income", height(5)) `axis' ///
				xtitle("") xla(`first2'(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
				graphregion(color(white)) plotregion(margin(zero)) ///
				title("`group' factor labor income share", color(black))  ///
				note("Population: `popdes'")  ///
				name(shflinc`i'`pop') 
				cap graph export $dirgraph/factorl/shflinc`i'`pop'.pdf, name(shflinc`i'`pop') replace
				cap graph drop shflinc`i'`pop'	

		}
	}


********************************************************************************
* Pre vs. post-tax top shares on same graph
********************************************************************************


cap graph drop _all
use "$dirgraph/datagraph.dta", clear

* All ages
	foreach pop in indiv equal taxu working male female  { 
		if "`pop'" == "indiv"   local popdes = "Adult individuals (20+)"
		if "`pop'" == "taxu"    local popdes = "Tax units"
		if "`pop'" == "oldwgt"  local popdes = "Tax units (old weights)"
		if "`pop'" == "equal"   local popdes = "Adult individuals (20+), equal split among spouses"
		if "`pop'" == "working" local popdes = "Working-age adult individuals (20-65)"	
		if "`pop'" == "male"	local popdes = "Adult men (20+)"
		if "`pop'" == "female"	local popdes = "Adult women (20+)"
	*	forval i = 1/10 { 
			forval i = 3/4 { 
			foreach var of varlist shpoinc`i'`pop'99 shprinc`i'`pop'99 {
			}  			
			if `i'==1 {
				local first = 1962
				local group  "Top 50%"
				su shprinc`i'`pop'99 if year>=1964 & year<=1970 , meanonly
				local max = r(max)*1.02
				local lab1  text(`max' 1964 "Pre-tax", place(e)) legend(off)
				su shpoinc`i'`pop'99 if year>=2000 & year<=2005 , meanonly
				local min = r(min)*0.98
				local lab2  text(`min' 2000 "Post-tax", place(e)) 
				local axis yla(.75(.05)1)
			}	
			if `i'==2 {
				local first = 1917
				local group  "Top 10%" 
				su shprinc`i'`pop'99 if year>=1964 & year<=1970 , meanonly
				local max = r(max)*1.04
				local lab1  text(`max' 1964 "Pre-tax", place(e)) legend(off)
				su shpoinc`i'`pop'99 if year>=2000 & year<=2005 , meanonly
				local min = r(min)*0.96
				local lab2  text(`min' 2000 "Post-tax", place(e)) 
				local axis yla(.3(.05).55)
			}	
			if `i'==3 {
				local first = 1917
				local group  "Top 5%" 
				su shprinc`i'`pop'99 if year>=1964 & year<=1970 , meanonly
				local max = r(max)*1.04
				local lab1  text(`max' 1964 "Pre-tax", place(e)) legend(off)
				su shpoinc`i'`pop'99 if year>=2000 & year<=2005 , meanonly
				local min = r(min)*0.96
				local lab2  text(`min' 2000 "Post-tax", place(e)) 
				local axis yla(.2(.05).45)
			}	
			if `i'==4 {
				local first = 1917
				local group  "Top 1%" 
				su shprinc`i'`pop'99 if year>=1964 & year<=1970 , meanonly
				local max = r(max)*1.1
				local lab1  text(`max' 1964 "Pre-tax", place(e)) legend(off)
				su shpoinc`i'`pop'99 if year>=2000 & year<=2005 , meanonly
				local min = r(min)*0.9
				local lab2  text(`min' 2000 "Post-tax", place(e)) 
				local axis yla(.0(.05).22)
			}	
			if `i'==5 {
				local first = 1917
				local group  "Top 0.5%" 
				su shprinc`i'`pop'99 if year>=1964 & year<=1970 , meanonly
				local max = r(max)*1.1
				local lab1  text(`max' 1964 "Pre-tax", place(e)) legend(off)
				su shpoinc`i'`pop'99 if year>=2000 & year<=2005 , meanonly
				local min = r(min)*0.9
				local lab2  text(`min' 2000 "Post-tax", place(e)) 
				local axis yla(.0(.05).2)
			}	
			if `i'==6 {
				local first = 1917
				local group  "Top 0.1%" 
				su shprinc`i'`pop'99 if year>=1964 & year<=1970 , meanonly
				local max = r(max)*1.15
				local lab1  text(`max' 1964 "Pre-tax", place(e)) legend(off)
				su shpoinc`i'`pop'99 if year>=2000 & year<=2005 , meanonly
				local min = r(min)*0.85
				local lab2  text(`min' 2000 "Post-tax", place(e)) 
				local axis yla(.0(.02).12)
			}	
			if `i'==7 {
				local first = 1917
				local group  "Top 0.01%" 
				su shprinc`i'`pop'99 if year>=1964 & year<=1970 , meanonly
				local max = r(max)*1.15
				local lab1  text(`max' 1964 "Pre-tax", place(e)) legend(off)
				su shpoinc`i'`pop'99 if year>=2000 & year<=2005 , meanonly
				local min = r(min)*0.85
				local lab2  text(`min' 2000 "Post-tax", place(e)) 
				local axis yla(.0(.01).05)
				} 
			if `i'==8 {
				local first = 1962
				local group  "Bottom 50%" 
				su shprinc`i'`pop'99 if year>=1964 & year<=1970 , meanonly
				local min = r(min)*0.85
				local lab1  text(`min' 1964 "Pre-tax", place(e)) legend(off)
				su shpoinc`i'`pop'99 if year>=2000 & year<=2005 , meanonly
				local max = r(max)*1.15
				local lab2  text(`max' 2000 "Post-tax", place(e)) 
				local axis yla(.0(.05).25)
			}	
			if `i'==9 {
				local first = 1917
				local group  "Bottom 90%" 
				su shprinc`i'`pop'99 if year>=1964 & year<=1970 , meanonly
				local min = r(min)*0.97
				local lab1  text(`min' 1964 "Pre-tax", place(e)) legend(off)
				su shpoinc`i'`pop'99 if year>=2000 & year<=2005 , meanonly
				local max = r(max)*1.03
				local lab2  text(`max' 2000 "Post-tax", place(e)) 
				local axis yla(.45(.05).7)
			}	
			if `i'==10 {
				local first = 1962
				local group  "P50-90" 
				local lab1 legend(cols(1) pos(2) ring(0) region(lcolor(none)))
				local lab2 ""
				local axis "yla(.3(.05).55)"
			}
			
		if "`pop'" == "working" | "`pop'" == "male"  | "`pop'" == "female" {
			local first = 1962
		}
		local first2 = `first' - 2

			twoway connected shpoinc`i'`pop'99 shpeinc`i'`pop'99 year if year>=`first', ///
			`lab1' `lab2' `axis' ///
			ytitle("Share of total income", height(5)) ///
			xtitle("") xla(`first2'(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
			graphregion(color(white)) plotregion(margin(zero)) ///
			title("`group' national income share", color(black)) ///
			note("Population: `popdes'")  ///
			name(sh`i'`pop') 

			cap mkdir "$dirgraph/preVpost"
			graph export $dirgraph/preVpost/sh`i'`pop'.pdf, name(sh`i'`pop') replace
			cap graph drop sh`i'`pop'
		}
	}



* Comparison top shares equal split vs couple vs. tax unit top shares on same graph
	foreach var of varlist _all {
		if substr("`var'", -7, .)=="indiv99"   label variable `var'  "Individual"
		if substr("`var'", -6, .)=="taxu99"    label variable `var'  "Tax unit"
		if substr("`var'", -7, .)=="equal99"   label variable `var'  "Equal split"
		if substr("`var'", -9, .)=="working99" label variable `var'  "Working-age"
		if substr("`var'", -6, .)=="male99"    label variable `var'  "Male"
		if substr("`var'", -8, .)=="female99"  label variable `var'  "Female"
	}
	foreach inc in princ poinc {
	if "`inc'" == "princ" local prepost = "pre-tax"
	if "`inc'" == "poinc" local prepost = "post-tax"	
		forval i = 1/10 {
			if `i'==1 local group  "Top 50%" 
			if `i'==2 local group  "Top 10%"
			if `i'==3 local group  "Top 5%"
			if `i'==4 local group  "Top 1%"
			if `i'==5 local group  "Top 0.5%"
			if `i'==6 local group  "Top 0.1%"
			if `i'==7 local group  "Top 0.01%"
			if `i'==8 local group  "Bottom 50%"	
			if `i'==9 local group  "Bottom 90%"	
			if `i'==10 local group "P50-P90"
			foreach var of varlist sh`inc'`i'indiv99 sh`inc'`i'equal99 sh`inc'`i'taxu99 {
				local lab: variable label `var'
			}
		local first = 1917
		if `i'==1 | `i'==8 | `i'==10 local first = 1962
		local first2 = `first' - 2	

			twoway connected sh`inc'`i'indiv99 sh`inc'`i'equal99 sh`inc'`i'taxu99 year if year>=`first', ///
			ytitle("Share of total income",  height(5)) ///
			xtitle("") xla(`first2'(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
			graphregion(color(white)) plotregion(margin(zero)) ///
			title("`group' `prepost' shares", color(black)) legend(cols(3)) ///
			name(equalVindiv`inc'`i') 
			cap mkdir "$dirgraph/indivVtaxu"
			graph export $dirgraph/indivVtaxu/equalVindiv`inc'`i'.pdf, name(equalVindiv`inc'`i') replace
			cap graph drop equalVindiv`inc'`i'

			twoway connected sh`inc'`i'indiv99 sh`inc'`i'taxu99 year if year>=`first', ///
			ytitle("Share of total income",  height(5)) ///
			xtitle("") xla(`first2'(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
			graphregion(color(white)) plotregion(margin(zero)) ///
			title("`group' `prepost' shares", color(black)) legend(cols(3)) ///
			name(indiVtaxu`inc'`i') 
			cap mkdir "$dirgraph/indivVtaxu"
			graph export $dirgraph/indivVtaxu/indiVtaxu`inc'`i'.pdf, name(indiVtaxu`inc'`i') replace
			cap graph drop indiVtaxu`inc'`i'

			twoway connected sh`inc'`i'indiv99 sh`inc'`i'equal99 year if year>=`first', ///
			ytitle("Share of total income",  height(5)) ///
			xtitle("") xla(`first2'(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
			graphregion(color(white)) plotregion(margin(zero)) ///
			title("`group' `prepost' shares", color(black)) legend(cols(3)) ///
			name(indiVequal`inc'`i') 
			cap mkdir "$dirgraph/indivVtaxu"
			graph export $dirgraph/indivVtaxu/indiVequal`inc'`i'.pdf, name(indiVequal`inc'`i') replace
			cap graph drop indiVequal`inc'`i'

		}
	}	



use "$dirgraph/datagraph.dta", clear
* Comparison of top shares for all income concepts
	forval i = 1/10 {
		if `i'==1 local group  "Top 50%"
		if `i'==2 {
			local group  "Top 10%"
			local axis yla(.3 .35  .4  .45  .5 .55)
		}
		if `i'==3  {
			local group  "Top 5%"
			local axis ""
		}	
		if `i'==4 local group  "Top 1%"
		if `i'==5 local group  "Top 0.5%"
		if `i'==6 local group  "Top 0.1%"
		if `i'==7 local group  "Top 0.01%"
		if `i'==8 local group  "Bottom 50%"	
		if `i'==9 local group  "Bottom 90%"	
		if `i'==10 local group "P50-P90"

		local first = 1917
		if `i'==1 | `i'==8 | `i'==10 local first = 1962
		local first2 = `first' - 2	

			label variable shprinc`i'indiv99 "Factor tax income (matching NI)"
			label variable shfainc`i'indiv99 "Factor tax income"
			label variable shpeinc`i'indiv99 "Pre-tax income (matching NI)"	
			label variable shptinc`i'indiv99 "Pre-tax income"
			label variable shpoinc`i'indiv99 "Post-tax income (matching NI)"
			label variable shdiinc`i'indiv99 "Post-tax income"

			twoway connected shprinc`i'indiv99 shfainc`i'indiv99  shpeinc`i'indiv99  shptinc`i'indiv99 shpoinc`i'indiv99 shdiinc`i'indiv99  year if year>=`first', ///
			ytitle("Share of total income") ///
			xtitle("") xla(`first2'(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
			graphregion(color(white)) plotregion(margin(zero)) ///
			note("Population: Adult individuals (20+)")  ///
			title("`group' shares") legend(rows(3) cols(2)) ///
			name(sh`i'comparison)  
			graph export $dirgraph/preVpost/6concepts`i'.pdf, name(sh`i'comparison) replace
			cap graph drop sh`i'comparison

			label variable shfiinc`i'taxu99  "Fiscal income, tax units"
			label variable shfiinc`i'indiv99 "Fiscal income , adults"
			label variable shprinc`i'indiv99 "Pre-tax income, adults"
			label variable shprinc`i'male99 	"Pre-tax income, men"
			label variable shprinc`i'female99 	"Pre-tax income, women"


			twoway connected shprinc`i'indiv99  year if year>=`first' & year<=2013, ///
			ytitle("Share of total income",  height(5)) ///
			xtitle("") xla(`first2'(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) `axis' ///
			graphregion(color(white)) plotregion(margin(zero)) ///
			title("`group' pre-tax income share", color(black)) legend(rows(2) cols(2) region(lcolor(none))) ///
			name(onepiksaez`i')  
			cap mkdir "$dirgraph/preVpost"
			graph export "$dirgraph/preVpost/onepiksaez`i'.pdf", name(onepiksaez`i') replace
			cap graph drop onepiksaez`i'

			twoway connected  shprinc`i'indiv99 shfiinc`i'taxu99 year if year>=`first' & year<=2013, ///
			ytitle("Share of total income",  height(5)) ///
			xtitle("") xla(`first2'(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
			graphregion(color(white)) plotregion(margin(zero)) ///
			title("`group' income shares", color(black)) legend(rows(2) cols(2) region(lcolor(none))) ///
			name(twopiksaez`i')  
			cap mkdir "$dirgraph/preVpost"
			graph export "$dirgraph/preVpost/twopiksaez`i'.pdf", name(twopiksaez`i') replace
			cap graph drop twopiksaez`i'

			twoway connected shprinc`i'indiv99 shfiinc`i'taxu99 shfiinc`i'indiv99   year if year>=`first' & year<=2013, ///
			ytitle("Share of total income",  height(5)) ///
			xtitle("") xla(`first2'(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
			graphregion(color(white)) plotregion(margin(zero)) ///
			title("`group' income shares", color(black)) legend(rows(2) cols(2) region(lcolor(none))) ///
			name(threepiksaez`i')  
			cap mkdir "$dirgraph/preVpost"
			graph export "$dirgraph/preVpost/threepiksaez`i'.pdf", name(threepiksaez`i') replace
			cap graph drop threepiksaez`i'


			twoway connected shprinc`i'indiv99 shprinc`i'male99 shprinc`i'female99   year if year>=1962 & year<=2013, ///
			ytitle("Share of total income",  height(5)) ///
			xtitle("") xla(1960(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
			graphregion(color(white)) plotregion(margin(zero)) ///
			title("`group' income shares", color(black)) legend(rows(2) cols(2)  region(lcolor(none))) ///
			name(shmenwomen`i')  
			cap mkdir "$dirgraph/preVpost"
			graph export "$dirgraph/pretax/shmenwomen`i'.pdf", name(shmenwomen`i') replace
			cap graph drop shmenwomen`i'			
	
	}



* Pre vs. post shares by age group
	keep if year>=1979
	foreach age of numlist 20 35 45 55 65 75 {
		foreach pop in indiv male female {
			if "`pop'" == "indiv"  {
				local popdes   "Individuals"
				} 
			if "`pop'" == "male"  {
				local popdes  "Men" 
			}	
			if "`pop'" == "female"	{
				local popdes  "Women"
			}	
			if `age' == 20	{
				local agedes = "aged 20-34"
			}	
			if `age' == 35	{
				local agedes = "aged 35-44"
			}		
			if `age' == 45  {
				local agedes = "aged 45-54"
			}	
			if `age' == 55	{
				local agedes = "aged 55-64"	
			}		
			if `age' == 65	{
				local agedes = "aged 65-74"	
			}		
			if `age' == 75	{
				local agedes = "aged 75+"	
			}	
			forval i = 1/10 {
				if `i'==1 {
					local group  "Top 50%"
					su shprinc`i'`pop'`age' if year>=1983 & year<=1989 , meanonly
					local max = r(max)*1.02
					local lab1  text(`max' 1983 "Pre-tax", place(e)) legend(off)
					su shpoinc`i'`pop'`age' if year>=2000 & year<=2005 , meanonly
					local min = r(min)*0.98
					local lab2  text(`min' 2000 "Post-tax", place(e)) 
					local axis yla(.75(.05)1)
				}	
				if `i'==2 {
					local group  "Top 10%" 
					su shprinc`i'`pop'`age' if year>=1983 & year<=1989 , meanonly
					local max = r(max)*1.04
					local lab1  text(`max' 1983 "Pre-tax", place(e)) legend(off)
					su shpoinc`i'`pop'`age' if year>=2000 & year<=2005 , meanonly
					local min = r(min)*0.96
					local lab2  text(`min' 2000 "Post-tax", place(e)) 
					local axis yla(.3(.05).55)
				}	
				if `i'==3 {
					local group  "Top 5%" 
					su shprinc`i'`pop'`age' if year>=1983 & year<=1989 , meanonly
					local max = r(max)*1.04
					local lab1  text(`max' 1983 "Pre-tax", place(e)) legend(off)
					su shpoinc`i'`pop'`age' if year>=2000 & year<=2005 , meanonly
					local min = r(min)*0.96
					local lab2  text(`min' 2000 "Post-tax", place(e)) 
					local axis yla(.2(.05).45)
				}	
				if `i'==4 {
					local group  "Top 1%" 
					su shprinc`i'`pop'`age' if year>=1983 & year<=1989 , meanonly
					local max = r(max)*1.1
					local lab1  text(`max' 1983 "Pre-tax", place(e)) legend(off)
					su shpoinc`i'`pop'`age' if year>=2000 & year<=2005 , meanonly
					local min = r(min)*0.9
					local lab2  text(`min' 2000 "Post-tax", place(e)) 
					local axis yla(.0(.05).25)
				}	
				if `i'==5 {
					local group  "Top 0.5%" 
					su shprinc`i'`pop'`age' if year>=1983 & year<=1989 , meanonly
					local max = r(max)*1.1
					local lab1  text(`max' 1983 "Pre-tax", place(e)) legend(off)
					su shpoinc`i'`pop'`age' if year>=2000 & year<=2005 , meanonly
					local min = r(min)*0.9
					local lab2  text(`min' 2000 "Post-tax", place(e)) 
					local axis yla(.0(.05).2)
				}	
				if `i'==6 {
					local group  "Top 0.1%" 
					su shprinc`i'`pop'`age' if year>=1983 & year<=1989 , meanonly
					local max = r(max)*1.15
					local lab1  text(`max' 1983 "Pre-tax", place(e)) legend(off)
					su shpoinc`i'`pop'`age' if year>=2000 & year<=2005 , meanonly
					local min = r(min)*0.85
					local lab2  text(`min' 2000 "Post-tax", place(e)) 
					local axis yla(.0(.02).12)
				}	
				if `i'==7 {
					local group  "Top 0.01%" 
					su shprinc`i'`pop'`age' if year>=1983 & year<=1989 , meanonly
					local max = r(max)*1.15
					local lab1  text(`max' 1983 "Pre-tax", place(e)) legend(off)
					su shpoinc`i'`pop'`age' if year>=2000 & year<=2005 , meanonly
					local min = r(min)*0.85
					local lab2  text(`min' 2000 "Post-tax", place(e)) 
					local axis yla(.0(.02).08)
					} 
				if `i'==8 {
					local group  "Bottom 50%" 
					su shprinc`i'`pop'`age' if year>=1983 & year<=1989 , meanonly
					local min = r(min)*0.85
					local lab1  text(`min' 1983 "Pre-tax", place(e)) legend(off)
					su shpoinc`i'`pop'`age' if year>=2000 & year<=2005 , meanonly
					local max = r(max)*1.15
					local lab2  text(`max' 2000 "Post-tax", place(e)) 
					local axis yla(.0(.05).25)
				}	
				if `i'==9 {
					local group  "Bottom 90%" 
					su shprinc`i'`pop'`age' if year>=1983 & year<=1989 , meanonly
					local min = r(min)*0.97
					local lab1  text(`min' 1983 "Pre-tax", place(e)) legend(off)
					su shpoinc`i'`pop'`age' if year>=2000 & year<=2005 , meanonly
					local max = r(max)*1.03
					local lab2  text(`max' 2000 "Post-tax", place(e)) 
					local axis yla(.45(.05).7)
				}	
				if `i'==10 {
					local group  "P50-90" 
					local lab1 legend(cols(1) pos(2) ring(0) region(lcolor(none)))
					local lab2 ""
					local axis "yla(.3(.05).55)"
				}
				
				cap graph drop sh`i'`pop'`age'
				twoway connected shpoinc`i'`pop'`age' shprinc`i'`pop'`age' year, ///
				`lab1' `lab2' `axis' xla(1979(5)2015) ///
				ytitle("Share of total income", height(5)) ///
				xtitle("") xla(1979(3)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
				graphregion(color(white))  plotregion(margin(zero)) ///
				title("`group' national income share", color(black)) ///
				note("Population: `popdes' `agedes'")  ///
				name(sh`i'`pop'`age')  

				cap mkdir "$dirgraph/preVpost/zbyage"
				graph export $dirgraph/preVpost/zbyage/sh`i'`pop'`age'.pdf, name(sh`i'`pop'`age') replace
				cap graph drop sh`i'`pop'`age'
			}
		}
	}

********************************************************************************
* Pre vs. post-tax average real income
********************************************************************************


use "$dirgraph/datagraph.dta", clear
cap graph drop _all

* All ages	
	cap graph drop _all
	foreach pop in indiv equal taxu working male female  { // oldwgt to be added
		if "`pop'" == "indiv"   local popdes = "Adult individuals (20+)"
		if "`pop'" == "taxu"    local popdes = "Tax units"
		if "`pop'" == "oldwgt"  local popdes = "Tax units (old weights)"
		if "`pop'" == "equal"   local popdes = "Adult individuals (20+), equal split among spouses"
		if "`pop'" == "working" local popdes = "Working-age adult individuals (20-65)"
		if "`pop'" == "male"	local popdes = "Adult men (20+)"
		if "`pop'" == "female"	local popdes = "Adult women (20+)"
		forval i = 0/10 {
			if `i'==0 local group  "Population"
			if `i'==1 local group  "Top 50%"
			if `i'==2 local group  "Top 10%"
			if `i'==3 local group  "Top 5%"
			if `i'==4 local group  "Top 1%"
			if `i'==5 local group  "Top 0.5%"
			if `i'==6 local group  "Top 0.1%"
			if `i'==7 local group  "Top 0.01%"
			if `i'==8 local group  "Bottom 50%"	
			if `i'==9 local group  "Bottom 90%"	
			if `i'==10 local group "P50-P90"	
			local options
			foreach var of varlist avgpoinc`i'`pop'99 avgprinc`i'`pop'99 {
				local lab: variable label `var'
				if substr("`var'", 4, 2)=="po" {
				    su `var' if year>=1980 & year<=1985 , meanonly
				    local max = r(max)*1.1
				    local min = r(min)*0.9
				    if `i' < 8  local options `options' text(`min' 1980 "`lab'", place(e))
				    if `i' >= 8  local options `options' text(`max' 1980 "`lab'", place(e))
			    }
			    if substr("`var'", 4, 2)=="pr" {
			    	su `var' if year>=2000 & year<=2005 , meanonly
			    	local max = r(max)
			    	local min = r(min)*0.9
			    	if `i' < 8 local options `options' text(`max' 1998 "`lab'", place(e))
			    	if `i' >= 8  local options `options' text(`min' 2000 "`lab'", place(e))
			    } 
			    if `i' == 0 & "`pop'" != "working" local options ""	
			}
			if `i' == 10 local options ""
			*di `"`options'"'
			cap graph drop avg`i'`pop'
			twoway connected avgpoinc`i'`pop'99 avgprinc`i'`pop'99 year, ///
			`options' ///
			ytitle("Average real income ($2012)") ///
			xtitle("") ///
			graphregion(color(white)) ///
			title("`group' average income") ///
			note("Population: `popdes'")  ///
			name(avg`i'`pop')  ///
			legend(off)

			cap mkdir "$dirgraph/avg_allage"
			graph export $dirgraph/avg_allage/avg`i'`pop'.pdf, name(avg`i'`pop') replace
		}
	}

* By age group
	cap graph drop _all
	keep if year>=1979
	foreach age of numlist 20 35 45 55 65 75 {
		foreach pop in indiv male female {
			if "`pop'" == "indiv"   {
				local popdes = "Individuals"
			}  
			if "`pop'" == "male"	{
				local popdes = "Men"
			}
			if "`pop'" == "female"	{
				local popdes = "Women"
			}
			if `age' == 20	{
				local agedes = "aged 20-34"
			}	
			if `age' == 35	{
				local agedes = "aged 35-44"
			}		
			if `age' == 45  {
				local agedes = "aged 45-54"
			}	
			if `age' == 55	{
				local agedes = "aged 55-64"	
			}		
			if `age' == 65	{
				local agedes = "aged 65-74"	
			}		
			if `age' == 75	{
				local agedes = "aged 75+"	
			}			
			forval i = 0/10 {
				if `i'==0 local group  "Population"
				if `i'==1 local group  "Top 50%"
				if `i'==2 local group  "Top 10%"
				if `i'==3 local group  "Top 5%"
				if `i'==4 local group  "Top 1%"
				if `i'==5 local group  "Top 0.5%"
				if `i'==6 local group  "Top 0.1%"
				if `i'==7 local group  "Top 0.01%"
				if `i'==8 local group  "Bottom 50%"	
				if `i'==9 local group  "Bottom 90%"	
				if `i'==10 local group "P50-P90"	
				local options
				foreach var of varlist avgpoinc`i'`pop'`age' avgprinc`i'`pop'`age' {
					local lab: variable label `var'
					if substr("`var'", 4, 2)=="po" {
					    su `var' if year>=1980 & year<=1985 , meanonly
					    local max = r(max)*1.1
					    local min = r(min)*0.9
					    if `i' < 8  local options `options' text(`min' 1980 "`lab'", place(e))
					    if `i' >= 8  local options `options' text(`max' 1980 "`lab'", place(e))
				    }
				    if substr("`var'", 4, 2)=="pr" {
				    	su `var' if year>=2000 & year<=2005 , meanonly
				    	local max = r(max)
				    	local min = r(min)*0.9
				    	if `i' < 8 local options `options' text(`max' 1998 "`lab'", place(e))
				    	if `i' >= 8  local options `options' text(`min' 2000 "`lab'", place(e))
				    } 
				    *if `i' == 0 & "`pop'" != "working" local options ""	
				}
				*if `i' == 10 local options ""
				*di `"`options'"'
				cap graph drop avg`i'`pop'`age'
				twoway connected avgpoinc`i'`pop'`age' avgprinc`i'`pop'`age' year, ///
				ytitle("Average real income ($2012)") ///
				xtitle("") xla(1975(5)2015) ///
				graphregion(color(white)) ///
				title("`group' average income") ///
				note("Population: `popdes' `agedes'")  ///
				name(avg`i'`pop'`age') 
				
				* `options' ///
				*legend(off)

				cap mkdir "$dirgraph/avg_`age'"			
				graph export $dirgraph/avg_`age'/avg`i'`pop'`age'.pdf, name(avg`i'`pop'`age') replace
			}
		}
	}

********************************************************************************
* Growth. Base year = 100
********************************************************************************

cap mkdir "$dirgraph/growth"
use "$dirgraph/datagraph.dta", clear


* All ages	
	keep if year>=1946
	local n = 1
	cap drop g*
	foreach var of varlist avg* {
		local base`var' = `var'[_n]
		gen g`var' = 100 * `var' / `base`var''
	}
	foreach var of varlist gavg* {
		if substr("`var'",5,5) == "princ" label variable `var' "Pre-tax"
		if substr("`var'",5,5) == "poinc" label variable `var' "Post-tax"
	}
	format gavg*  %4.0fc
	
	*foreach pop in indiv equal taxu working male female {
	foreach pop in indiv equal taxu  {
		if "`pop'" == "indiv" {
		   local popdes = "Adult individuals (20+)"
		}
		if "`pop'" == "taxu"   { 
			local popdes = "Tax units"
		}	
		if "`pop'" == "oldwgt" {
			local popdes = "Tax units (old weights)"
		}
		if "`pop'" == "equal"  {
			local popdes = "Adult individuals (20+), equal split among spouses"
		}
		if "`pop'" == "working" {
			local popdes = "Working-age adult individuals (20-65)"	
		}
		if "`pop'" == "male"	{
			local popdes = "Adult men (20+)"
		}
		if "`pop'" == "female"	{
			local popdes = "Adult women (20+)"	
		}
		forval i = 0/10 {
			if `i'==0 local group  "Average"
			if `i'==1 local group  "Top 50%"
			if `i'==2 local group  "Top 10%"
			if `i'==3 local group  "Top 5%"
			if `i'==4 local group  "Top 1%"
			if `i'==5 local group  "Top 0.5%"
			if `i'==6 local group  "Top 0.1%"
			if `i'==7 local group  "Top 0.01%"
			if `i'==8 local group  "Bottom 50%"	
			if `i'==9 local group  "Bottom 90%"	
			if `i'==10 local group "P50-P90"
			label variable gavgprinc0indiv99 "All adults"

			twoway connected gavgpoinc`i'`pop'99 gavgprinc`i'`pop'99 gavgprinc0indiv99 year, ///
			ytitle("Average real income (1946 = 100)", height(5)) ///
			xtitle("") xla(1945(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
			graphregion(color(white)) plotregion(margin(zero)) ///
			title("`group' income growth", color(black)) ///
			note("Population: `popdes'")  legend(cols(1) pos(10) ring(0) region(lcolor(none))) ///
			name(growth`i'`pop')

			graph export $dirgraph/growth/growth`i'`pop'.pdf, name(growth`i'`pop') replace
			cap graph drop growth`i'`pop'
		}
	}



* By age group
	cap graph drop _all
	keep if year>=1979
	local n = 1
	foreach var of varlist avg* {
		local base`var' = `var'[_n]
		cap drop g`var'
		gen g`var' = 100 * `var' / `base`var''
	}
	foreach var of varlist gavg* {
		if substr("`var'",5,5) == "princ" label variable `var' "Pre-tax"
		if substr("`var'",5,5) == "poinc" label variable `var' "Post-tax"
	}
	format gavg*  %4.0fc

	foreach age of numlist 20 35 45 55 65 75 {	
		foreach pop in indiv male female {
			if "`pop'" == "indiv"   {
				local popdes = "Individuals"
			}  
			if "`pop'" == "male"	{
				local popdes = "Men"
			}
			if "`pop'" == "female"	{
				local popdes = "Women"
			}
			if `age' == 20	{
				local agedes = "aged 20-34"
			}	
			if `age' == 35	{
				local agedes = "aged 35-44"
			}		
			if `age' == 45  {
				local agedes = "aged 45-54"
			}	
			if `age' == 55	{
				local agedes = "aged 55-64"	
			}		
			if `age' == 65	{
				local agedes = "aged 65-74"	
			}		
			if `age' == 75	{
				local agedes = "aged 75+"	
			}		
			forval i = 0/10 {
				if `i'==0 local group  "Average"
				if `i'==1 local group  "Top 50%"
				if `i'==2 local group  "Top 10%"
				if `i'==3 local group  "Top 5%"
				if `i'==4 local group  "Top 1%"
				if `i'==5 local group  "Top 0.5%"
				if `i'==6 local group  "Top 0.1%"
				if `i'==7 local group  "Top 0.01%"
				if `i'==8 local group  "Bottom 50%"	
				if `i'==9 local group  "Bottom 90%"	
				if `i'==10 local group "P50-P90"
				label variable gavgprinc0indiv99 "All adults"
				cap graph drop growth`i'`pop'`age'
				twoway connected gavgpoinc`i'`pop'`age' gavgprinc`i'`pop'`age' gavgprinc0indiv99 year, ///
				ytitle("Average real income (1979 = 100)", height(5)) ///
				xtitle("") xla(1979(3)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot))  ///
				graphregion(color(white)) plotregion(margin(zero)) ///
				title("`group' income growth", color(black)) ///
				note("Population: `popdes' `agedes'")  ///
				name(growth`i'`pop'`age') legend(cols(1) pos(10) ring(0) region(lcolor(none)))

				cap mkdir "$dirgraph/growth/zbyage"
				graph export $dirgraph/growth/zbyage/growth`i'`pop'`age'.pdf, name(growth`i'`pop'`age') replace
			}
		}
	}

********************************************************************************
* Median income 
********************************************************************************

use "$dirgraph/datagraph.dta", clear
cap graph drop _all

* Pre-tax vs. post-tax median income all age	
	cap graph drop _all
	foreach pop in indiv equal taxu working male female  {
		if "`pop'" == "indiv" {
		   local popdes = "adult individuals"
		}
		if "`pop'" == "taxu"   { 
			local popdes = "tax units"
		}	
		if "`pop'" == "oldwgt" {
			local popdes = "tax units (old weights)"
		}
		if "`pop'" == "equal"  {
			local popdes = "adults, equal split among spouses"
		}
		if "`pop'" == "working" {
			local popdes = "working-age adults"	
		}
		if "`pop'" == "male"	{
			local popdes = "men"
		}
		if "`pop'" == "female"	{
			local popdes = "women"	
		}
		*label variable threspoinc1`pop' "Median post-tax income"
		*label variable thresprinc1`pop' "Median pre-tax income"
		local options
			foreach var of varlist threspoinc1`pop'99 thresprinc1`pop'99 {
				local lab: variable label `var'
				if substr("`var'", 6, 2)=="po" {
				    su `var' if year>=2009, meanonly
				    local max = r(min)*0.98
				    local options `options' text(`max' 2009 "`lab'", place(e))
			    }
			    if substr("`var'", 6, 2)=="pr" {
			    	su `var' if year>=1990 & year<=1995 , meanonly
			    	local min = r(min)*0.96
					local options `options' text(`min' 1990 "`lab'", place(e))
			    } 
			}
		twoway connected threspoinc1`pop'99 thresprinc1`pop'99 year if year>=1962, ///
		`options' legend(off) ///
		ytitle("Real median income (2012$)") ///
		xtitle("") xla(1960(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
		graphregion(color(white)) plotregion(margin(zero)) ///
		title("Median real income, `popdes'") ///
		name(median`pop') 

			cap mkdir "$dirgraph/median"
			graph export $dirgraph/median/median`pop'.pdf, name(median`pop') replace
	}



* Pre-tax median income all vs. men vs. women
	use "$dirgraph/datagraph.dta", clear
	cap graph drop _all

		cap graph drop _all
			label variable thresprinc1indiv99  "Adults"
			label variable thresprinc1male99   "Men"
			label variable thresprinc1female99 "Women"
			* local options
			* 	foreach var of varlist threspoinc1`pop'99 thresprinc1`pop'99 {
			* 		local lab: variable label `var'
			* 		if substr("`var'", 6, 2)=="po" {
			* 		    su `var' if year>=2009, meanonly
			* 		    local max = r(min)*0.98
			* 		    local options `options' text(`max' 2009 "`lab'", place(e))
			* 	    }
			* 	    if substr("`var'", 6, 2)=="pr" {
			* 	    	su `var' if year>=1990 & year<=1995 , meanonly
			* 	    	local min = r(min)*0.96
			* 			local options `options' text(`min' 1990 "`lab'", place(e))
			* 	    } 
			* 	}
			twoway connected thresprinc1indiv99 thresprinc1male99 thresprinc1female99 year if year>=1962, ///
			`options' legend(cols(3) rows(1)) ///
			ytitle("Real median income (2012$)",  height(5)) ///
			xtitle("") xla(1960(5)2015, angle(90) grid glcolor(gs10) glwidth(medthin) glpattern(dot)) ///
			graphregion(color(white)) plotregion(margin(zero)) ///
			title("Median pre-tax real income", color(black)) ///
			name(med_menwomen) 

				cap mkdir "$dirgraph/median"
				graph export $dirgraph/median/med_menwomen.pdf, name(med_menwomen) replace
	


* Pre-tax vs. post-tax median income by age group
	cap graph drop _all
	keep if year>=1979
	foreach age of numlist 20 35 45 55 65 75 {	
		foreach pop in indiv male female {
			if "`pop'" == "indiv"   {
				local popdes = "Individuals"
			}  
			if "`pop'" == "male"	{
				local popdes = "Men"
			}
			if "`pop'" == "female"	{
				local popdes = "Women"
			}
			if `age' == 20	{
				local agedes = "aged 20-34"
			}	
			if `age' == 35	{
				local agedes = "aged 35-44"
			}		
			if `age' == 45  {
				local agedes = "aged 45-54"
			}	
			if `age' == 55	{
				local agedes = "aged 55-64"	
			}		
			if `age' == 65	{
				local agedes = "aged 65-74"	
			}		
			if `age' == 75	{
				local agedes = "aged 75+"	
			}		
			local options
			foreach var of varlist threspoinc1`pop'`age' thresprinc1`pop'`age' {
				local lab: variable label `var'
				if substr("`var'", 6, 2)=="po" {
				    su `var' if year>=2000, meanonly
				    local max = r(max)
				    local options `options' text(`max' 2000 "`lab'", place(e))
			    }
			    if substr("`var'", 6, 2)=="pr" {
			    	su `var' if year>=1990 & year<=1995 , meanonly
			    	local min = r(min)*0.96
					local options `options' text(`min' 1990 "`lab'", place(e))
			    } 
			}
		twoway connected threspoinc1`pop'`age' thresprinc1`pop'`age' year, ///
			`options' legend(off) ///
			ytitle("Real income (2012$)") ///
			xtitle("") xla(1975(5)2015) ///
			graphregion(color(white)) ///
			title("Median real income") ///
			note("Population: `popdes' `agedes'")  ///
			name(median`pop'`age') 

			cap mkdir "$dirgraph/median/zbyage"
			graph export $dirgraph/median/zbyage/median`pop'`age'.pdf, name(median`pop'`age') replace
	}
}

* Comparison median CPS vs. median DINA (all age)
	cap graph drop _all
	import excel "$diroutput/temp/cps/med_comparison.xlsx", first clear
	merge 1:1 year using $dirgraph/datagraph.dta
	drop _merge
	saveold $dirgraph/datagraph.dta, replace
	import excel "$diroutput/temp/cps/med_comparisontaxu.xlsx", first clear
	merge 1:1 year using $dirgraph/datagraph.dta
	drop _merge
	saveold $dirgraph/datagraph.dta, replace
	replace med_wag_dina = med_wag_dina * nideflator
		label variable med_wag_dina "DINA"
	replace med_wag_cps  = med_wag_cps  * nideflator
		label variable med_wag_cps "CPS"	
	replace med_inc_ps = med_inc_ps * nideflator
		label variable med_inc_ps "DINA"		
	replace med_inc_cps  = med_inc_cps  * nideflator
		label variable med_inc_cps "CPS"

	replace med_wag_dinataxu = med_wag_dinataxu * nideflator
		label variable med_wag_dinataxu "DINA"
	replace med_wag_cpstaxu  = med_wag_cpstaxu  * nideflator
		label variable med_wag_cpstaxu "CPS"	
	replace med_inc_pstaxu = med_inc_pstaxu * nideflator
		label variable med_inc_pstaxu "DINA"		
	replace med_inc_cpstaxu  = med_inc_cpstaxu  * nideflator
		label variable med_inc_cpstaxu "CPS"

	twoway connected med_wag_dina med_wag_cps year, ///
		ytitle("Real income (2012$)") ///
		xtitle("") ///
		graphregion(color(white)) ///
		title("Median real wage: CPS vs. DINA") ///
		note("Population: Adult individuals (20+) with wages above 15% of average wage")  ///
		name(medwage_cps) 
		graph export $dirgraph/median/medwage_cps.pdf, name(medwage_cps) replace

	twoway connected med_inc_ps med_inc_cps year if year>1962, ///
		ytitle("Real income (2012$)") ///
		xtitle("") ///
		graphregion(color(white)) ///
		title("Median real taxable market income: CPS vs. DINA") ///
		note("Population: Adult individuals (20+)")  ///
		name(medinc_cps) 
		graph export $dirgraph/median/medinc_cps.pdf, name(medinc_cps) replace

	twoway connected med_wag_dinataxu med_wag_cpstaxu year, ///
		ytitle("Real income (2012$)") ///
		xtitle("") ///
		graphregion(color(white)) ///
		title("Median real wage: CPS vs. DINA") ///
		note("Population: Tax units")  ///
		name(medwage_cpstaxu) 
		graph export $dirgraph/median/medwage_cpstaxu.pdf, name(medwage_cpstaxu) replace

	twoway connected med_inc_pstaxu med_inc_cpstaxu year if year>1962, ///
		ytitle("Real income (2012$)") ///
		xtitle("") ///
		graphregion(color(white)) ///
		title("Median real taxable market income: CPS vs. DINA") ///
		note("Population: Tax units")  ///
		name(medinc_cpstaxu) 
		graph export $dirgraph/median/medinc_cpstaxu.pdf, name(medinc_cpstaxu) replace


********************************************************************************
* Gender and gender x age gap
********************************************************************************




use "$dirgraph/datagraph.dta", clear
keep if year>=1979
cap graph drop _all

	foreach age of numlist 20 35 45 55 65 75 {	
		foreach pop in indiv male female {
			foreach y in fiinc fninc fnps fainc ptinc diinc princ peinc poinc hweal  {
				gen relative`y'`pop'`age' = avg`y'0`pop'`age' / avg`y'0`pop'99
			}
		}
	}

* Average income by age x gender relative to average income in total pop
	graph drop _all
	foreach age of numlist 20 35 45 55 65 75 {	
		foreach pop in indiv male female {
			if "`pop'" == "indiv"   {
				local popdes = "Individuals"
			}  
			if "`pop'" == "male"	{
				local popdes = "Men"
			}
			if "`pop'" == "female"	{
				local popdes = "Women"
			}
			if `age' == 20	{
				local agedes = "aged 20-34"
			}	
			if `age' == 35	{
				local agedes = "aged 35-44"
			}		
			if `age' == 45  {
				local agedes = "aged 45-54"
			}	
			if `age' == 55	{
				local agedes = "aged 55-64"	
			}		
			if `age' == 65	{
				local agedes = "aged 65-74"	
			}		
			if `age' == 75	{
				local agedes = "aged 75+"	
			}	
			label variable relativeprinc`pop'`age' "Pre-tax income"	
			label variable relativepeinc`pop'`age' "Post-pension income"	
			label variable relativepoinc`pop'`age' "Post-tax income"	
			label variable relativehweal`pop'`age' "Wealth"		
			twoway connected relativeprinc`pop'`age' relativepeinc`pop'`age' relativepoinc`pop'`age' relativehweal`pop'`age'  year, ///
			ytitle("% of income (or wealth) of entire population") ///
			xtitle("") xla(1975(5)2015) ///
			graphregion(color(white)) ///
			note("Reference Population: All adult `popdes' (20+).")  ///
			title("Average income (or wealth) of `popdes' `agedes'") legend(cols(2) rows(3)) ///
			name(agegap`pop'`age')  

			cap mkdir "$dirgraph/gendergap"
			graph export $dirgraph/gendergap/agegap`pop'`age'.pdf, name(agegap`pop'`age') replace	
		}
	}



* Gender gap
	use "$dirgraph/datagraph.dta", clear
	*keep if year>=1979
	cap graph drop _all

	foreach pop in male female {
		*foreach age of numlist 20 35 45 55 65 75 99 {	
		foreach age of numlist  99 {	
			foreach y in fiinc fninc  fainc flinc fkinc ptinc diinc princ peinc poinc hweal  { // fnps
				gen gap_`y'`pop'`age'   = avg`y'0`pop'`age'   / avg`y'0indiv`age'
			}
		}
	}

	*foreach age of numlist 20 35 45 55 65 75 99 {	
	foreach age of numlist 99 {		
		foreach y in flinc fkinc princ peinc poinc hweal  {
			if `age' == 20	{
				local agedes = "aged 20-34"
				local startyear = 1975	
			}	
			if `age' == 35	{
				local agedes = "aged 35-44"
				local startyear = 1975	
			}		
			if `age' == 45  {
				local agedes = "aged 45-54"
				local startyear = 1975	
			}	
			if `age' == 55	{
				local agedes = "aged 55-64"	
				local startyear = 1975	
			}		
			if `age' == 65	{
				local agedes = "aged 65-74"	
				local startyear = 1975	
			}		
			if `age' == 75	{
				local agedes = "aged 75+"	
				local startyear = 1975
			}
			if `age' == 99	{
				local agedes = "aged 20+"
				local startyear = 1960	
			}	
			if "`y'" == "princ"	{
				local vardes = "Average pre-tax income"	
			}		
			if "`y'" == "flinc"	{
				local vardes = "Average factor labor income"	
			}	
			if "`y'" == "fkinc"	{
				local vardes = "Average factor capital income"	
			}							
			if "`y'" == "peinc"	{
				local vardes = "Average post-pension income"	
			}
			if "`y'" == "poinc"	{
				local vardes = "Average post-tax income"	
			}
			if "`y'" == "hweal"	{
				local vardes = "Average wealth"	
			}														
			label variable gap_`y'male`age' "`vardes' of men `agedes'"	
			label variable gap_`y'female`age' "`vardes' of women `agedes'"		
			twoway connected gap_`y'male`age' gap_`y'female`age'  year if year>=`startyear', ///
			ytitle("% of entire population") ///
			xtitle("") xla(`startyear'(5)2015) yla(0.4 "40%" 0.6 "60%" 0.8 "80%" 1 "100%" 1.2 "120%" 1.4 "140%" 1.6 "160%") ///
			graphregion(color(white)) ///
			note("Reference Population: All adults `agedes'.")  ///
			title("Gender gap among adults `agedes'") legend(cols(2) rows(3)) ///
			name(gendergap`y'`age')  

			cap mkdir "$dirgraph/gendergap"
			graph export $dirgraph/gendergap/gendergap`y'`age'.pdf, name(gendergap`y'`age') replace	
		}
	}

* Fraction female in top groups 
	local variable "fiinc fninc fainc flinc fkinc ptinc plinc pkinc diinc princ peinc poinc hweal"
	foreach var of local variable {
			if "`var'" == "fainc" local name "Factor income"
			if "`var'" == "flinc" local name "Factor labor income"
			if "`var'" == "fkinc" local name "Factor capital income"
			if "`var'" == "princ" local name "Pre-tax income"
			if "`var'" == "ptinc" local name "Post-tax income"
			if "`var'" == "plinc" local name "Post-tax labor income"
			if "`var'" == "pkinc" local name "Post-tax capital income"
			if "`var'" == "peinc" local name "Post-pension income"
			if "`var'" == "diinc" local name "Personal disposable income"
			if "`var'" == "poinc" local name "Post-tax income"
			if "`var'" == "fiinc" local name "Fiscal income"
			if "`var'" == "fninc" local name "Fiscal income (no KG)"
			if "`var'" == "hweal" local name "Wealth"
		import excel "$diroutsheet/fracfemale_`var'.xlsx", first clear
		rename c1 year
		forval i = 0/10 {
			if `i'==0 local group  "full population"
			if `i'==1 local group  "top 50%"
			if `i'==2 local group  "top 10%"
			if `i'==3 local group  "top 5%"
			if `i'==4 local group  "top 1%"
			if `i'==5 local group  "top 0.5%"
			if `i'==6 local group  "top 0.1%"
			if `i'==7 local group  "top 0.01%"
			if `i'==8 local group  "bottom 50%"	
			if `i'==9 local group  "bottom 90%"	
			if `i'==10 local group "P50-P90"
			twoway connected frac`i' year, ///
				ytitle("Fraction of women") ///
				xtitle("") ///
				graphregion(color(white)) ///
				title("Percentage of women in the `group'") ///
				note("Variable: `name'")  ///
				name(fracfemale`var'`i') 
				graph export $dirgraph/gendergap/fracfemale_`var'`i'.pdf, name(fracfemale`var'`i') replace
		}
	}				



********************************************************************************
* Age-wealth and age-income profiles
********************************************************************************

cap mkdir "$dirgraph/ageprofile"
cap graph drop _all

* Age bins	
	local variable "fiinc fninc fainc flinc fkinc ptinc plinc pkinc diinc princ peinc poinc hweal"
	foreach yr of  numlist 1979/`last' { 
		import excel "$diroutsheet/agerangeprofile_`yr'.xlsx", first clear
		foreach var of local variable {

			if "`var'" == "fainc" local lbl`var' "Factor income"
			if "`var'" == "flinc" local lbl`var' "Factor labor income"
			if "`var'" == "fkinc" local lbl`var' "Factor capital income"
			if "`var'" == "princ" local lbl`var' "Pre-tax income"
			if "`var'" == "ptinc" local lbl`var' "Post-tax income"
			if "`var'" == "plinc" local lbl`var' "Post-tax labor income"
			if "`var'" == "pkinc" local lbl`var' "Post-tax capital income"
			if "`var'" == "peinc" local lbl`var' "Post-pension income"
			if "`var'" == "diinc" local lbl`var' "Personal disposable income"
			if "`var'" == "poinc" local lbl`var' "Post-tax income"
			if "`var'" == "fiinc" local lbl`var' "Fiscal income"
			if "`var'" == "fninc" local lbl`var' "Fiscal income (no KG)"
			if "`var'" == "hweal" local lbl`var' "Wealth"

			local ylabel "yla(0.6 "60%" 0.8 "80%" 1 "100%" 1.2 "120%" 1.4 "140%")"
			if "`var'" == "hweal" | "`var'" == "fkinc" | "`var'" == "pkinc" {
				local ylabel "yla(0 "0%" .5 "50%" 1 "100%" 1.5 "150%" 2 "200%" )"
			}	
			if "`var'" == "flinc" local ylabel "yla(0 "0%" .2 "20%" 0.4 "40%" 0.6 "60%" .8 "80%" 1 "100%" 1.2 "120%" 1.4 "140%" )"
			
			twoway connected `var' agerange, ///
			ytitle("% of average `lbl`var'' ") `ylabel' ///
			xtitle("Age") xla(20 "20-34" 35 "35-44" 45 "45-54" 55 "55-64" 65 "65-74" 75 "75+") ///
			graphregion(color(white)) ///
			note("")  ///
			title("`lbl`var'' by age group in `yr'") legend(cols(2) rows(3)) ///
			name(profile`var'`yr')  
			graph export $dirgraph/ageprofile/agerange_`var'`yr'.pdf, name(profile`var'`yr') replace	
			graph drop profile`var'`yr'
		}
	}	


* Exact age	
	cap graph drop _all
	local variable "fiinc fninc fainc flinc fkinc ptinc plinc pkinc diinc princ peinc poinc hweal"
	foreach yr of  numlist 1979/`last' { 
		import excel "$diroutsheet/ageprofile_`yr'.xlsx", first clear
		foreach var of local variable {

			if "`var'" == "fainc" local lbl`var' "Factor income"
			if "`var'" == "flinc" local lbl`var' "Factor labor income"
			if "`var'" == "fkinc" local lbl`var' "Factor capital income"
			if "`var'" == "princ" local lbl`var' "Pre-tax income"
			if "`var'" == "ptinc" local lbl`var' "Post-tax income"
			if "`var'" == "plinc" local lbl`var' "Post-tax labor income"
			if "`var'" == "pkinc" local lbl`var' "Post-tax capital income"
			if "`var'" == "peinc" local lbl`var' "Post-pension income"
			if "`var'" == "diinc" local lbl`var' "Personal disposable income"
			if "`var'" == "poinc" local lbl`var' "Post-tax income"
			if "`var'" == "fiinc" local lbl`var' "Fiscal income"
			if "`var'" == "fninc" local lbl`var' "Fiscal income (no KG)"
			if "`var'" == "hweal" local lbl`var' "Wealth"
			
			local ylabel "yla(0.6 "60%" 0.8 "80%" 1 "100%" 1.2 "120%" 1.4 "140%")"
			if "`var'" == "hweal" | "`var'" == "fkinc" | "`var'" == "pkinc" {
				local ylabel "yla(0 "0%" .5 "50%" 1 "100%" 1.5 "150%" 2 "200%" )"
			}	
			if "`var'" == "flinc" local ylabel "yla(0 "0%" .2 "20%" 0.4 "40%" 0.6 "60%" .8 "80%" 1 "100%" 1.2 "120%" 1.4 "140%" )"
			
			su `var' if age>=80 & age<85
				replace `var' = r(mean) if age>=80 & age<85
			su `var' if age>=85 
				replace `var' = r(mean) if age>=85	
			twoway connected `var' age, ///
			ytitle("% of average `lbl`var'' ") `ylabel' ///
			xtitle("Age") ///
			graphregion(color(white)) ///
			note("")  ///
			title("`lbl`var'' by age group in `yr'") legend(cols(2) rows(3)) ///
			name(age_`var'`yr')  
			graph export $dirgraph/ageprofile/age_`var'`yr'.pdf, name(age_`var'`yr') replace	
			graph drop age_`var'`yr'
		}	
		
	}	


*/

********************************************************************************
* Export Excel series to DINA(distrib) for graphs there
********************************************************************************

* Update June 20 to export equal split as benchmark

* Export compo of top factor income shares 
	use "$dirgraph/datagraph.dta", clear
	*keep year shfa*indiv99 shpr*indiv99 
	keep year shfa*equal99 shpr*equal99 
	order year *0* *1* *2* *3* *4* *5* *6* *7* *8* *9* *10*
	rename sh*equal99 *
	forval i=0/10 { // define components, starting from components of factor income and adjusting to match national income
		gen fahou`i' = fahoumain`i' + fahourent`i' + famor`i'
		drop fahoumain`i'  fahourent`i'  famor`i'
		gen faint`i' = fafix`i' + fanmo`i' 
		drop fafix`i'  fanmo`i' 
		foreach var in faequ faint fahou fabus fapen faemp famil {
			replace `var'`i' = `var'`i' * prfai`i' / fainc`i'
		}
		replace faint`i' = faint`i' + prnpi`i' + prgov`i' 
		*egen princ`i' = rsum(faequ`i' faint`i' fahou`i' fabus`i' fapen`i' faemp`i' famil`i'), missing
	}

	drop prnpi* prgov* fainc* prfai*
	order year  princ0 faequ0 faint0 fahou0 fabus0 fapen0 faemp0 famil0 ///
				princ1 faequ1 faint1 fahou1 fabus1 fapen1 faemp1 famil1 /// 
				princ2 faequ2 faint2 fahou2 fabus2 fapen2 faemp2 famil2 ///
				princ3 faequ3 faint3 fahou3 fabus3 fapen3 faemp3 famil3 /// 
				princ4 faequ4 faint4 fahou4 fabus4 fapen4 faemp4 famil4 /// 
				princ5 faequ5 faint5 fahou5 fabus5 fapen5 faemp5 famil5 /// 
				princ6 faequ6 faint6 fahou6 fabus6 fapen6 faemp6 famil6 ///
				princ7 faequ7 faint7 fahou7 fabus7 fapen7 faemp7 famil7 ///
				princ8 faequ8  faint8  fahou8  fabus8  fapen8  faemp8  famil8 ///
				princ9 faequ9  faint9  fahou9  fabus9  fapen9  faemp9  famil9 ///
				princ10 faequ10 faint10 fahou10 fabus10 fapen10 faemp10 famil10
	export excel using  "$diroutexcel", first(var) sheetreplace sheet(compoprinc) 


* Export real average factor income, different populations
	use "$dirgraph/datagraph.dta", clear
	keep year avgprinc*99
	rename *99 *
	cap drop avgprinc0equal 
	cap drop *oldwgt
* order year  avgprinc0indiv 				  avgprinc0working avgprinc0male avgprinc0female avgprinc0taxu ///
* 			avgprinc1indiv avgprinc1equal avgprinc1working avgprinc1male avgprinc1female avgprinc1taxu /// 
* 			avgprinc2indiv avgprinc2equal avgprinc2working avgprinc2male avgprinc2female avgprinc2taxu /// 
* 			avgprinc3indiv avgprinc3equal avgprinc3working avgprinc3male avgprinc3female avgprinc3taxu /// 
* 			avgprinc4indiv avgprinc4equal avgprinc4working avgprinc4male avgprinc4female avgprinc4taxu /// 
* 			avgprinc5indiv avgprinc5equal avgprinc5working avgprinc5male avgprinc5female avgprinc5taxu /// 
* 			avgprinc6indiv avgprinc6equal avgprinc6working avgprinc6male avgprinc6female avgprinc6taxu /// 
* 			avgprinc7indiv avgprinc7equal avgprinc7working avgprinc7male avgprinc7female avgprinc7taxu /// 
* 			avgprinc8indiv avgprinc8equal avgprinc8working avgprinc8male avgprinc8female avgprinc8taxu /// 
* 			avgprinc9indiv avgprinc9equal avgprinc9working avgprinc9male avgprinc9female avgprinc9taxu /// 
* 			avgprinc10indiv avgprinc10equal avgprinc10working avgprinc10male avgprinc10female avgprinc10taxu 
* 	export excel using  "$diroutexcel", first(var) sheetreplace sheet(avgprinc)
order year   			   avgprinc0indiv  avgprinc0working avgprinc0male avgprinc0female avgprinc0taxu ///
			avgprinc1equal avgprinc1indiv  avgprinc1working avgprinc1male avgprinc1female avgprinc1taxu /// 
			avgprinc2equal avgprinc2indiv  avgprinc2working avgprinc2male avgprinc2female avgprinc2taxu /// 
			avgprinc3equal avgprinc3indiv  avgprinc3working avgprinc3male avgprinc3female avgprinc3taxu /// 
			avgprinc4equal avgprinc4indiv  avgprinc4working avgprinc4male avgprinc4female avgprinc4taxu /// 
			avgprinc5equal avgprinc5indiv  avgprinc5working avgprinc5male avgprinc5female avgprinc5taxu /// 
			avgprinc6equal avgprinc6indiv  avgprinc6working avgprinc6male avgprinc6female avgprinc6taxu /// 
			avgprinc7equal avgprinc7indiv  avgprinc7working avgprinc7male avgprinc7female avgprinc7taxu /// 
			avgprinc8equal avgprinc8indiv  avgprinc8working avgprinc8male avgprinc8female avgprinc8taxu /// 
			avgprinc9equal avgprinc9indiv  avgprinc9working avgprinc9male avgprinc9female avgprinc9taxu /// 
			avgprinc10equal avgprinc10indiv avgprinc10working avgprinc10male avgprinc10female avgprinc10taxu 
	export excel using  "$diroutexcel", first(var) sheetreplace sheet(avgprinc)



* Export median factor income, diff pop
 	use "$dirgraph/datagraph.dta", clear
	keep year thresprinc1*99
	rename *99 *
	* order year  thresprinc1indiv thresprinc1equal thresprinc1working thresprinc1male thresprinc1female thresprinc1taxu
	order year  thresprinc1equal thresprinc1indiv thresprinc1working thresprinc1male thresprinc1female thresprinc1taxu 
	export excel using  "$diroutexcel", first(var) sheetreplace sheet(medprinc)

	
* Top factor capital income (ranked by Yk) and factor labor income (ranked by Yl) shares
* Removed March 2017 to avoid having multiple series of yk and yl
 * 	use "$dirgraph/datagraph.dta", clear
	* keep year shfkinc*equal99 shflinc*equal99
	* rename *99 *
	* * order year shfkinc9indiv shfkinc8indiv  shfkinc10indiv  shfkinc2indiv  shfkinc3indiv  shfkinc4indiv  shfkinc5indiv  shfkinc6indiv  shfkinc7indiv ///
	* * 		   shflinc9indiv shflinc8indiv  shflinc10indiv  shflinc2indiv  shflinc3indiv  shflinc4indiv  shflinc5indiv  shflinc6indiv  shflinc7indiv 
	* order year shfkinc9equal shfkinc8equal  shfkinc10equal  shfkinc2equal  shfkinc3equal  shfkinc4equal  shfkinc5equal  shfkinc6equal  shfkinc7equal ///
	*  		   shflinc9equal shflinc8equal  shflinc10equal  shflinc2equal  shflinc3equal  shflinc4equal  shflinc5equal  shflinc6equal  shflinc7equal 	
	* export excel using  "$diroutexcel", first(var) sheetreplace sheet(shfkfl)

	
* Export compo of top pre-tax income shares 
	use "$dirgraph/datagraph.dta", clear
	keep year shpt*equal99 shpe*equal99 
	order year *0* *1* *2* *3* *4* *5* *6* *7* *8* *9* *10*
	rename sh*equal99 *
	forval i=0/10 { // define components, starting from components of pre-tax income and adjusting to match national income
		gen pthou`i' = pthoumain`i' + pthourent`i' + ptmor`i'
		drop pthoumain`i'  pthourent`i'  ptmor`i'
		gen ptint`i' = ptfix`i' + ptnmo`i' 
		drop ptfix`i'  ptnmo`i' 
		gen shemp`i' = ptemp`i' / (ptemp`i' + ptmil`i') // Allocate pension contrib to wages and self-employment income
		replace shemp`i' = 0 if shemp`i' == .
		replace ptemp`i' = ptemp`i' + ptcon`i' * shemp`i'
		replace ptmil`i' = ptmil`i' + ptcon`i' * (1-shemp`i')
		drop shemp`i' ptcon`i'
		foreach var in ptequ ptint pthou ptbus ptben ptemp ptmil {
			replace `var'`i' = `var'`i' * pepti`i' / ptinc`i'
		}
		replace ptint`i' = ptint`i' + penpi`i' + pegov`i' 
		replace ptben`i' = ptben`i' + pesup`i' + peinv`i' 
		drop pesup`i' peinv`i' pegov`i'  penpi`i'
		*egen peinc`i' = rsum(ptequ`i' ptint`i' pthou`i' ptbus`i' ptben`i' ptemp`i' ptmil`i'), missing
	}

	drop pepti* ptinc*
	order year  peinc0 ptequ0 ptint0 pthou0 ptbus0 ptben0 ptemp0 ptmil0 ///
				peinc1 ptequ1 ptint1 pthou1 ptbus1 ptben1 ptemp1 ptmil1 /// 
				peinc2 ptequ2 ptint2 pthou2 ptbus2 ptben2 ptemp2 ptmil2 ///
				peinc3 ptequ3 ptint3 pthou3 ptbus3 ptben3 ptemp3 ptmil3 /// 
				peinc4 ptequ4 ptint4 pthou4 ptbus4 ptben4 ptemp4 ptmil4 /// 
				peinc5 ptequ5 ptint5 pthou5 ptbus5 ptben5 ptemp5 ptmil5 /// 
				peinc6 ptequ6 ptint6 pthou6 ptbus6 ptben6 ptemp6 ptmil6 ///
				peinc7 ptequ7 ptint7 pthou7 ptbus7 ptben7 ptemp7 ptmil7 ///
				peinc8 ptequ8 ptint8 pthou8 ptbus8 ptben8 ptemp8 ptmil8 ///
				peinc9 ptequ9 ptint9 pthou9 ptbus9 ptben9 ptemp9 ptmil9 ///
				peinc10 ptequ10 ptint10 pthou10 ptbus10 ptben10 ptemp10 ptmil10
	export excel using  "$diroutexcel", first(var) sheetreplace sheet(compopeinc) 


* Export real average pre-tax income, different populations
	use "$dirgraph/datagraph.dta", clear
	keep year avgpeinc*99
	rename *99 *
	cap drop avgpeinc0equal 
	cap drop *oldwgt
order year  			   avgpeinc0indiv avgpeinc0working avgpeinc0male avgpeinc0female avgpeinc0taxu ///
			avgpeinc1equal avgpeinc1indiv avgpeinc1working avgpeinc1male avgpeinc1female avgpeinc1taxu /// 
			avgpeinc2equal avgpeinc2indiv avgpeinc2working avgpeinc2male avgpeinc2female avgpeinc2taxu /// 
			avgpeinc3equal avgpeinc3indiv avgpeinc3working avgpeinc3male avgpeinc3female avgpeinc3taxu /// 
			avgpeinc4equal avgpeinc4indiv avgpeinc4working avgpeinc4male avgpeinc4female avgpeinc4taxu /// 
			avgpeinc5equal avgpeinc5indiv avgpeinc5working avgpeinc5male avgpeinc5female avgpeinc5taxu /// 
			avgpeinc6equal avgpeinc6indiv avgpeinc6working avgpeinc6male avgpeinc6female avgpeinc6taxu /// 
			avgpeinc7equal avgpeinc7indiv avgpeinc7working avgpeinc7male avgpeinc7female avgpeinc7taxu /// 
			avgpeinc8equal avgpeinc8indiv avgpeinc8working avgpeinc8male avgpeinc8female avgpeinc8taxu /// 
			avgpeinc9equal avgpeinc9indiv avgpeinc9working avgpeinc9male avgpeinc9female avgpeinc9taxu /// 
			avgpeinc10equal avgpeinc10indiv avgpeinc10working avgpeinc10male avgpeinc10female avgpeinc10taxu 
	export excel using  "$diroutexcel", first(var) sheetreplace sheet(avgpeinc)	

* Export median pre-tax income, diff pop
 	use "$dirgraph/datagraph.dta", clear
	keep year threspeinc1*99
	rename *99 *
	order year threspeinc1equal threspeinc1indiv threspeinc1working threspeinc1male threspeinc1female threspeinc1taxu 
	export excel using  "$diroutexcel", first(var) sheetreplace sheet(medpeinc)


* Top indiv pre-tax capital income (ranked by Yk) and pre-tax labor income (ranked by Yl) shares
* Update March 2017: removed; instead: outputs gperc of pre-tax capital income and pre-tax labor income matching NI
 * 	use "$dirgraph/datagraph.dta", clear
	* keep year shpkinc*equal99 shplinc*equal99
	* rename *99 *
	* order year shpkinc9equal shpkinc8equal  shpkinc10equal  shpkinc2equal  shpkinc3equal  shpkinc4equal  shpkinc5equal  shpkinc6equal  shpkinc7equal ///
	* 		   shplinc9equal shplinc8equal  shplinc10equal  shplinc2equal  shplinc3equal  shplinc4equal  shplinc5equal  shplinc6equal  shplinc7equal 
	* export excel using  "$diroutexcel", first(var) sheetreplace sheet(shpkpl)


* Export compo post tax income = income net of taxes + health transfers (medicare + medicaid) + other transfers
	use "$dirgraph/datagraph.dta", clear
	keep year shpo*equal99 shdi*equal99 
	order year *0* *1* *2* *3* *4* *5* *6* *7* *8* *9* *10*
	rename sh*equal99 *
	forval i=0/10 {
		foreach var in dipre disal dipro ditax diest dicor dibus dioth diben divet dihlt dikdn dicxp {
			replace `var'`i' = `var'`i' * podii`i' / diinc`i'
		}
		gen transf`i' = diben`i' + divet`i' + dihlt`i' + dikdn`i' + dicxp`i' // all transfers including health
		gen health`i' = dihlt`i' // isolate health transfers 
		gen netinc`i' = poinc`i' - transf`i'
	}
	drop di* podii* pogov* ponpi* posup* poinv* posug*
	order year  poinc0 netinc0 transf0 health0  ///
				poinc1 netinc1 transf1 health1  /// 
				poinc2 netinc2 transf2 health2  ///
				poinc3 netinc3 transf3 health3  /// 
				poinc4 netinc4 transf4 health4  /// 
				poinc5 netinc5 transf5 health5  /// 
				poinc6 netinc6 transf6 health6  ///
				poinc7 netinc7 transf7 health7  ///
				poinc8 netinc8 transf8 health8  ///
				poinc9 netinc9 transf9 health9  ///
				poinc10 netinc10 transf10 health10 
	export excel using  "$diroutexcel", first(var) sheetreplace sheet(compopoinc) 

* Export real average post-tax income, different populations
	use "$dirgraph/datagraph.dta", clear
	keep year avgpoinc*99
	rename *99 *
	cap drop avgpoinc0equal 
	cap drop *oldwgt
order year   			   avgpoinc0indiv avgpoinc0working avgpoinc0male avgpoinc0female avgpoinc0taxu ///
			avgpoinc1equal avgpoinc1indiv avgpoinc1working avgpoinc1male avgpoinc1female avgpoinc1taxu /// 
			avgpoinc2equal avgpoinc2indiv avgpoinc2working avgpoinc2male avgpoinc2female avgpoinc2taxu /// 
			avgpoinc3equal avgpoinc3indiv avgpoinc3working avgpoinc3male avgpoinc3female avgpoinc3taxu /// 
			avgpoinc4equal avgpoinc4indiv avgpoinc4working avgpoinc4male avgpoinc4female avgpoinc4taxu /// 
			avgpoinc5equal avgpoinc5indiv avgpoinc5working avgpoinc5male avgpoinc5female avgpoinc5taxu /// 
			avgpoinc6equal avgpoinc6indiv avgpoinc6working avgpoinc6male avgpoinc6female avgpoinc6taxu /// 
			avgpoinc7equal avgpoinc7indiv avgpoinc7working avgpoinc7male avgpoinc7female avgpoinc7taxu /// 
			avgpoinc8equal avgpoinc8indiv avgpoinc8working avgpoinc8male avgpoinc8female avgpoinc8taxu /// 
			avgpoinc9equal avgpoinc9indiv avgpoinc9working avgpoinc9male avgpoinc9female avgpoinc9taxu /// 
			avgpoinc10equal avgpoinc10indiv avgpoinc10working avgpoinc10male avgpoinc10female avgpoinc10taxu 
	export excel using  "$diroutexcel", first(var) sheetreplace sheet(avgpoinc)	


* Export median post-tax income, diff pop
 	use "$dirgraph/datagraph.dta", clear
	keep year threspoinc1*99
	rename *99 *
	order year  threspoinc1equal threspoinc1indiv threspoinc1working threspoinc1male threspoinc1female threspoinc1taxu 
	export excel using  "$diroutexcel", first(var) sheetreplace sheet(medpoinc)




* Export compo of top fiscal income shares 
	use "$dirgraph/datagraph.dta", clear
	keep year shfi*taxu99 shfn*taxu99  
	order year *0* *1* *2* *3* *4* *5* *6* *7* *8* *9* *10*
	rename sh*taxu99 *
	keep year fiinc* fn*
	order year  fiinc0  fninc0  fnwag0  fnbus0  fndiv0  fnint0  fnren0  ///
				fiinc1  fninc1  fnwag1  fnbus1  fndiv1  fnint1  fnren1  /// 
				fiinc2  fninc2  fnwag2  fnbus2  fndiv2  fnint2  fnren2  ///
				fiinc3  fninc3  fnwag3  fnbus3  fndiv3  fnint3  fnren3  /// 
				fiinc4  fninc4  fnwag4  fnbus4  fndiv4  fnint4  fnren4  /// 
				fiinc5  fninc5  fnwag5  fnbus5  fndiv5  fnint5  fnren5  /// 
				fiinc6  fninc6  fnwag6  fnbus6  fndiv6  fnint6  fnren6  ///
				fiinc7  fninc7  fnwag7  fnbus7  fndiv7  fnint7  fnren7  ///
				fiinc8  fninc8  fnwag8  fnbus8  fndiv8  fnint8  fnren8  ///
				fiinc9  fninc9  fnwag9  fnbus9  fndiv9  fnint9  fnren9  ///
				fiinc10	fninc10 fnwag10 fnbus10 fndiv10 fnint10 fnren10 
	export excel using  "$diroutexcel", first(var) sheetreplace sheet(compofiinc) 


* Export real average fiscal income, different populations
	use "$dirgraph/datagraph.dta", clear
	keep year avgfiinc*99
	rename *99 *
	cap drop avgfiinc0equal 
	cap drop *oldwgt
order year   			   avgfiinc0indiv avgfiinc0working avgfiinc0male avgfiinc0female avgfiinc0taxu ///
			avgfiinc1equal avgfiinc1indiv avgfiinc1working avgfiinc1male avgfiinc1female avgfiinc1taxu /// 
			avgfiinc2equal avgfiinc2indiv avgfiinc2working avgfiinc2male avgfiinc2female avgfiinc2taxu /// 
			avgfiinc3equal avgfiinc3indiv avgfiinc3working avgfiinc3male avgfiinc3female avgfiinc3taxu /// 
			avgfiinc4equal avgfiinc4indiv avgfiinc4working avgfiinc4male avgfiinc4female avgfiinc4taxu /// 
			avgfiinc5equal avgfiinc5indiv avgfiinc5working avgfiinc5male avgfiinc5female avgfiinc5taxu /// 
			avgfiinc6equal avgfiinc6indiv avgfiinc6working avgfiinc6male avgfiinc6female avgfiinc6taxu /// 
			avgfiinc7equal avgfiinc7indiv avgfiinc7working avgfiinc7male avgfiinc7female avgfiinc7taxu /// 
			avgfiinc8equal avgfiinc8indiv avgfiinc8working avgfiinc8male avgfiinc8female avgfiinc8taxu /// 
			avgfiinc9equal avgfiinc9indiv avgfiinc9working avgfiinc9male avgfiinc9female avgfiinc9taxu /// 
			avgfiinc10equal avgfiinc10indiv avgfiinc10working avgfiinc10male avgfiinc10female avgfiinc10taxu 
	export excel using  "$diroutexcel", first(var) sheetreplace sheet(avgfiinc)


* Export median fiscal income, diff pop
 	use "$dirgraph/datagraph.dta", clear
	keep year thresfiinc1*99 
	rename *99 *
	order year thresfiinc1equal thresfiinc1indiv thresfiinc1working thresfiinc1male thresfiinc1female thresfiinc1taxu 
	export excel using  "$diroutexcel", first(var) sheetreplace sheet(medfiinc)



* Export compo of top wealth shares
	use "$dirgraph/datagraph.dta", clear
	keep year shhwealnokg*indiv99 shhweal*indiv99 shhwequ*indiv99 shbond*indiv99 shcurrency*indiv99 shnonmort*indiv99 shrental*indiv99 shownerhome*indiv99 shownermort*indiv99 shhwbus*indiv99 shhwpen*indiv99  
	order year *0* *1* *2* *3* *4* *5* *6* *7* *8* *9* *10*
	rename sh*indiv99 *
	forval i=0/10 {
		gen fix`i' = bond`i' + currency`i' + nonmort`i' 
		gen housing`i' = rental`i' + ownerhome`i' + ownermort`i'  
	}
	order year  hwealnokg0  hweal0  hwequ0  fix0  housing0  hwbus0  hwpen0  ///
				hwealnokg1  hweal1  hwequ1  fix1  housing1  hwbus1  hwpen1  /// 
				hwealnokg2  hweal2  hwequ2  fix2  housing2  hwbus2  hwpen2  ///
				hwealnokg3  hweal3  hwequ3  fix3  housing3  hwbus3  hwpen3  /// 
				hwealnokg4  hweal4  hwequ4  fix4  housing4  hwbus4  hwpen4  /// 
				hwealnokg5  hweal5  hwequ5  fix5  housing5  hwbus5  hwpen5  /// 
				hwealnokg6  hweal6  hwequ6  fix6  housing6  hwbus6  hwpen6  ///
				hwealnokg7  hweal7  hwequ7  fix7  housing7  hwbus7  hwpen7  ///
				hwealnokg8  hweal8  hwequ8  fix8  housing8  hwbus8  hwpen8  ///
				hwealnokg9  hweal9  hwequ9  fix9  housing9  hwbus9  hwpen9  ///
				hwealnokg10	hweal10 hwequ10 fix10 housing10 hwbus10 hwpen10 
	drop bond* currency* nonmort* rental* ownerhome* ownermort*	
	export excel using  "$diroutexcel", first(var) sheetreplace sheet(compohweal) 


* Export real average wealth, different populations
	use "$dirgraph/datagraph.dta", clear
	keep year avghweal*99
	rename *99 *
	cap drop avghweal0equal
	cap drop *oldwgt
order year   			 	avghweal0indiv  avghweal0working  avghweal0male  avghweal0female  avghweal0taxu ///
			avghweal1equal  avghweal1indiv  avghweal1working  avghweal1male  avghweal1female  avghweal1taxu /// 
			avghweal2equal  avghweal2indiv  avghweal2working  avghweal2male  avghweal2female  avghweal2taxu /// 
			avghweal3equal  avghweal3indiv  avghweal3working  avghweal3male  avghweal3female  avghweal3taxu /// 
			avghweal4equal  avghweal4indiv  avghweal4working  avghweal4male  avghweal4female  avghweal4taxu /// 
			avghweal5equal  avghweal5indiv  avghweal5working  avghweal5male  avghweal5female  avghweal5taxu /// 
			avghweal6equal  avghweal6indiv  avghweal6working  avghweal6male  avghweal6female  avghweal6taxu /// 
			avghweal7equal  avghweal7indiv  avghweal7working  avghweal7male  avghweal7female  avghweal7taxu /// 
			avghweal8equal  avghweal8indiv  avghweal8working  avghweal8male  avghweal8female  avghweal8taxu /// 
			avghweal9equal  avghweal9indiv  avghweal9working  avghweal9male  avghweal9female  avghweal9taxu /// 
			avghweal10equal avghweal1indiv  avghweal10working avghweal10male avghweal10female avghweal10taxu 
	export excel using  "$diroutexcel", first(var) sheetreplace sheet(avghweal)

