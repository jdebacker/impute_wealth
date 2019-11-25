*****************************************************************************************
* CREATES WAGE INCOME (AT INDIVIDUAL LEVEL) MATCHING NIPA TOTALS 
* currently, estimated employer payroll taxes, health and pension loaded on wages capped at P99 (and no benefits below P40)

* TO DO: use 2012 internal IRS W2 data to get better distributional assumptions for health (and pension) contributions
******************************************************************************************




*insheet using "$parameters", delimiter(";") clear names
insheet using "$parameters", clear names
keep if yr==$yr
foreach var of varlist _all {
local `var'=`var'
}


use "$dirusdina/usdina$yr.dta", clear


* computing payroll taxes, cap applies to both OASDI+HI up to 1993, only to OASDI after 1993
	gen oacont=0
		label variable oacont "Old-age & survivor contributions, employer+employee"
		replace oacont = `oarate' * min(`paycap',wagind)
		quietly: su oacont [w=dweght]
		replace oacont = oacont * `ttoacont' / (r(sum)*1e-11)	
	gen dicont=0
		label variable dicont "Disability insurance contributions, employer+employee"
		replace dicont = `dirate' * min(`paycap',wagind)
		quietly: su dicont [w=dweght]
		replace dicont = dicont * `ttdicont' / (r(sum)*1e-11)		
	gen sscont=0
		label variable sscont "Old-age & survivor + DI (= OASDI = Social Security) contributions, employer+employee"
		replace sscont = oacont + dicont
		display "YEAR = $yr SOCIAL SECURITY TAX RATE = `ssrate' SOCIAL SECURITY CAP = `paycap'"
	gen hicont=0
		label variable hicont "Hospital insurance contributions (= Medicare tax), employer+employee"
		display "YEAR = $yr HOSPITAL INSURANCE TAX RATE = `hirate'"
		replace hicont = `hirate' * min(`paycap',wagind) if $yr<=1993
		replace hicont = `hirate' * wagind if $yr>1993
		quietly: su hicont [w=dweght]
		replace hicont = hicont * `tthicont' / (r(sum)*1e-11)	
		// Since 2013: additional medicare employee tax of 0.9% on wages above 200K (for singles; threshold depends on filing status); no employer match. Not coded for now since PUF stop in 2009.
		replace hicont = 0 if hicont == .
	gen payroll=0
		label variable payroll "Payroll taxes (OASDI + HI), employer+employee"
		replace payroll = sscont + hicont
	gen payroller=payroll/2
		label variable payroller "Payroll taxes, employer only"	
		*quietly sum payroller [w=dweght]
		*replace payroller=payroller*`payrolltaxer'/(r(sum)*1e-11)
		*quietly sum payroller [w=dweght]
		*display "Payroll ER = " r(sum)*1e-11 "  " `payrolltaxer' 
	*replace payroll=payroller*2

* 401k and pension contributions: dummy for receiving benefits imputed from CPS, then assume amount proportional to wages winsorized at p99
	gen wagpen=0
		label variable wagpen "Pension contributions (employer + employee)"	
	* 	cumul wagind [w=dweght] if wagind>0, gen(rankw) // old code with benefits loaded on wages capped at P99 (and no benefits below P40)
	* 	quietly sum wagind [w=dweght] if rankw>=.99 & wagind>0 
	* 	replace wagpen=min(wagind,r(min))
	* 	quietly sum wagind [w=dweght] if rankw>=.4 & wagind>0 
	* 	replace wagpen=max(0,wagpen-r(min))
	* 	quietly sum wagpen [w=dweght] if wagind>0
	* 	local basepen=r(sum)*1e-11
	* gen pen=wagpen*(`pensioncont')/`basepen'
	* 	quietly sum pen [w=dweght]
	* 	display "Pen = " r(sum)*1e-11 "  " `pensioncont'
	* drop wagpen
	* rename pen wagpen
	cap drop oldmar	
	qui egen oldmar = group(married old)
	qui xtile rank_inc = wagind [w=dweght] if wagind > 0, nq(10)
	qui tab rank_inc
		local I=r(r)
	qui tab oldmar
		local J=r(r)
	set seed 5938
	qui gen haspen = 0
	forval i = 1/`I' { 
		forval j = 1/`J' { 
			qui replace haspen = (runiform() <= frqpplan$yr[`i',`j']) if rank_inc==`i' & oldmar==`j'
		}
	}
	drop rank_inc
	gen winsorized_wage = 0
	cumul wagind [w=dweght] if wagind>0, gen(rankw)
	qui sum wagind [w=dweght] if rankw>=.99 & wagind>0 
	replace winsorized_wage = min(wagind,r(min))
	qui sum winsorized_wage [w=dweght] if haspen == 1
		local tot = r(sum)/10e10
	replace wagpen = winsorized_wage * `pensioncont' / `tot' if haspen == 1
	drop haspen
		

* Health benefits: dummy for receiving benefits imputed from CPS, then assume flat amount par bin (from CPS too).
	gen waghealth=0	
		label variable waghealth "Health insurance contributions"
	* 	quietly sum wagind [w=dweght] if rankw>=.99 & wagind>0  // old code with benefits loaded on wages capped at P99 (and no benefits below P40)
	* 	replace waghealth=min(wagind,r(min))
	* 	quietly sum wagind [w=dweght] if rankw>=.4 & wagind>0 
	* 	replace waghealth=max(0,waghealth-r(min))
	* 	quietly sum waghealth [w=dweght] if wagind>0
	* 	local basehealth=r(sum)*1e-11
	* gen health=waghealth*(`healthcont')/`basehealth'
	* 	quietly sum health [w=dweght]
	* 	display "Health = " r(sum)*1e-11 "  " `healthcont'
	* drop waghealth
	* rename health waghealth
	cap drop oldmar	
	qui egen oldmar = group(married old)
	qui xtile rank_inc = wagind [w=dweght] if wagind > 0, nq(10)
	qui tab rank_inc
		local I=r(r)
	qui tab oldmar
		local J=r(r)
	set seed 599
	forval i = 1/`I' { 
		forval j = 1/`J' { 
			qui replace waghealth = (runiform() <= frqhealth$yr[`i',`j']) * avghealth$yr[`i',`j'] if rank_inc==`i' & oldmar==`j'
		}
	}
	drop rank_inc
	qui su waghealth [w=dweght], meanonly
		local ttwaghealth = r(sum)/10e10
		local blowupwaghealth = `healthcont' / `ttwaghealth'
			di "BLOW UP FACTOR FOR HEALTH FRINGE BENEFITS IN YEAR $yr : `blowupwaghealth'"
	qui replace waghealth = waghealth * `blowupwaghealth'

* UI contributions:  loaded on wages capped at P90 
	gen wagui = 0
		quietly su wagind [w=dweght] if rankw>=.9 & wagind>0 
		replace wagui = min(wagind, r(min))
		quietly sum wagind [w=dweght] if rankw>=0 & wagind>0 
		replace wagui = max(0,wagui-r(min))
		quietly su wagui [w=dweght] if wagind>0
		local baseui = r(sum)*1e-11
	gen uicont = wagui * `ttuicont'/`baseui'
		quietly su uicont [w=dweght]
		display "TOTAL UI CONTRIBUTIONS =" r(sum)*1e-11 " " `ttuicont'
	drop wagui
	label variable uicont "Unemployment insurance contributions"


* other gap between NIPA total employee comp and wages is made proportional to wages
	gen flemp=wagind+payroller+waghealth+wagpen+uicont
		label variable flemp "Compensation of employees"
		quietly sum flemp [w=dweght]
		local blowuprest=`ttflemp'/(r(sum)*1e-11) 
		replace flemp=flemp*`blowuprest'
		quietly sum flemp [w=dweght]
		display "Total NIPA comp emp" r(sum)*1e-11 "  " `ttflemp' " Blow up factor " `blowuprest'
	gen wagoth=flemp-wagind-waghealth-wagpen-payroller-uicont
		label variable wagoth "Other supplements to wages"	
	egen flsup=rsum(payroller waghealth wagpen wagoth uicont)	
		label variable flsup "Supplements to taxable wages"
	rename wagind flwag
		label variable flwag "Taxable wages of filers + non-filers"
	drop rankw	

	
/* Old code for generating share_fna, share_fpen, share_fhealth, share_fpayroll 
	gen share_fna=0 if married==1
	sort id second
	bys id: replace share_fna=wagind_na/(wagind_na+wagind_na[_n-1]) if second==1 & married==1 & wagind_na+wagind_na[_n-1]>0
	bys id: replace share_fna=share_fna[_n+1] if second==0 & married==1 
    foreach var of varlist health pen payroller {
		gen share_f`var'=0 if married==1
		sort id second
		bys id: replace share_f`var'=`var'/(`var'+`var'[_n-1]) if second==1 & married==1 & `var'+`var'[_n-1]>0
		bys id: replace share_f`var'=share_f`var'[_n+1] if second==0 & married==1
	}
*/

	save "$dirusdina/usdina$yr.dta", replace

