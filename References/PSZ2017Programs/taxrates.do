
********************************************************************************
* Outseet tax rates (% of pre-tax income, equal split, people ranked by pre-tax income)
********************************************************************************
  
* Brings totals from parameters
	insheet using "$parameters", clear names
	rename yr year
	keep year ttninc ttflprl ttfkprk ttproptax_res ttproptax_bus ttfedtax ttstatetax ttestatetax ttfkcot ttoacont ttsecont_oa ttdicont ttsecont_di ttuicont ttothcon
	gen salestaxall 	= (ttflprl + ttfkprk) / ttninc
	gen proprestaxall	= ttproptax_res / ttninc
	gen paytaxall		= (ttoacont + ttsecont_oa + ttdicont + ttsecont_di + ttuicont + ttothcon) / ttninc
	gen ditaxall 		= (ttfedtax + ttstatetax) / ttninc
	gen corptaxall 		= (ttfkcot) / ttninc
	gen propbustaxall 	= (ttproptax_bus) / ttninc
	gen estatetaxall 	= ttestatetax / ttninc
	gen taxall			= salestaxall + proprestaxall + paytaxall + ditaxall + corptaxall + propbustaxall + estatetaxall
	keep if year >= 1913 & year < 2015
	saveold "$diroutput/pre62/pre62tax.dta", replace

* Merge with post-1962 tax rates and pre-1962 shares
	import excel using "$diroutsheet/taxratepeinc_kg.xlsx", first clear
	merge 1:1 year using "$diroutput/pre62/pre62tax.dta"
	sort year
		foreach var of varlist _all {
		replace `var' = 0.5 * (`var'[_n-1] + `var'[_n+1]) if (year == 1963 | year == 1965) & `var' == .
	}
	drop _merge
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta", keepusing(shpeinc*equal* shhweal*indiv* shhwequ*indiv* shrental*indiv* shownerhome*indiv*)
	foreach i of numlist 0/7 9 {
		rename shpeinc`i'equal99 shY`i'
		rename shhweal`i'indiv99 shW`i'
		rename shhwequ`i'indiv99 shE`i'
		gen shH`i' = shrental`i'indiv99 + shownerhome`i'indiv99
	}
	drop shrental*indiv* shownerhome*indiv*
	drop _merge
	foreach z in Y W H E {
		rename sh`z'0 sh`z'all
		replace sh`z'1 = sh`z'all - sh`z'1
		rename sh`z'1 sh`z'bot50
		rename sh`z'9 sh`z'bot90
		gen sh`z'middle40 = sh`z'bot90 - sh`z'bot50
		rename sh`z'2 sh`z'top10
		rename sh`z'3 sh`z'top5
		rename sh`z'4 sh`z'top1
		rename sh`z'5 sh`z'top0p5
		rename sh`z'6 sh`z'top0p1
		rename sh`z'7 sh`z'top0p01
		gen sh`z'P90_P95 = sh`z'top10 - sh`z'top5
		gen sh`z'P95_P99 = sh`z'top5 - sh`z'top1
		gen sh`z'P99_P99p5 = sh`z'top1 - sh`z'top0p5
		gen sh`z'P99p5_P99p9 = sh`z'top0p5 - sh`z'top0p1
		gen sh`z'P99p9_P99p99 = sh`z'top0p1 - sh`z'top0p01
	}

* Compute tax component by component shares (= frac)
	foreach group in all bot90 bot50 middle40 top10 top5 top1 top0p5 top0p1 top0p01 P90_P95 P95_P99 P99_P99p5 P99p5_P99p9 P99p9_P99p99 {
		foreach compo in salestax proprestax paytax ditax corptax propbustax estatetax {
			qui gen frac`compo'`group' = (`compo'`group' * shY`group') / `compo'all 
			qui su frac`compo'`group' if year == 1962 | year == 1963
			global m`compo'_`group' = r(mean)		
		}
		qui gen shNH`group' = shW`group' - shH`group'
		qui gen fracNH`group' = shNH`group' / shNHall
		qui gen fracH`group' = shH`group' / shHall 
		qui gen fracE`group' = shE`group' / shEall
	}
	saveold "$diroutput/pre62/pre62tax.dta", replace

* Load frac estate tax paid
	import excel "$root/rawdata/rawexcel/taxratespre62.xls", clear sheet(results-estatetax)
	keep if _n>2 & _n < 110
	qui rename A year
	destring year, force replace
	rename I fracestatetaxall
	rename J fracestatetaxtop10
	rename K fracestatetaxtop5
	rename L fracestatetaxtop1
	rename M fracestatetaxtop0p5
	rename N fracestatetaxtop0p1
	rename O fracestatetaxtop0p01
	rename P fracestatetaxbot90
	rename Q fracestatetaxP90_P95
	rename R fracestatetaxP95_P99
	rename S fracestatetaxP99_P99p5
	rename T fracestatetaxshP99p5_P99p9
	rename U fracestatetaxP99p9_P99p99
	keep year frac*
	foreach var of varlist frac* {
		destring `var', force replace
		replace `var' = 0 if `var' == .
	}
	drop if year==.
	merge 1:1 year using "$diroutput/pre62/pre62tax.dta"
	drop _merge
	saveold "$diroutput/pre62/pre62tax.dta", replace

* Load frac income tax paid
	import excel "$root/rawdata/rawexcel/taxratespre62.xls", clear sheet(results-incometax)
	keep if _n>2 & _n < 56
	qui rename A year
	destring year, force replace
	rename S  fracfedtaxall
	rename T  fracfedtaxtop10
	rename U  fracfedtaxtop5
	rename V  fracfedtaxtop1
	rename W  fracfedtaxtop0p5
	rename X  fracfedtaxtop0p1 
	rename Y  fracfedtaxtop0p01 
	rename Z  fracfedtaxbot90
	rename AA fracfedtaxP90_P95
	rename AB fracfedtaxP95_P99
	rename AC fracfedtaxP99_P99p5
	rename AD fracfedtaxP99p5_P99p9
	rename AE fracfedtaxP99p9_P99p99
	keep year frac*
	foreach var of varlist frac* {
		destring `var', force replace
		replace `var' = 0 if `var' == . & year==1913
	}
	drop if year==.
	merge 1:1 year using "$diroutput/pre62/pre62tax.dta"
	drop _merge
	saveold "$diroutput/pre62/pre62tax.dta", replace

* Adjust fraction of income tax paid in 1962
	foreach group in all bot90 top10 top5 top1 top0p5 top0p1 top0p01 P90_P95 P95_P99 P99_P99p5 P99p5_P99p9 P99p9_P99p99 {
		su fracfedtax`group' if year == 1962 | year == 1963 
		global meanfracfedtax_`group' = r(mean)
		replace fracditax`group'   = 1 - (1 - fracfedtax`group') * (1 - ${mditax_`group'}) / (1 - ${meanfracfedtax_`group'}) if year < 1962 
}
	replace fracditaxall = 1

* Pre-1962 imputation of sales and payroll taxes: same fraction as in 1962
	foreach group in all bot90 bot50 middle40 top10 top5 top1 top0p5 top0p1 top0p01 P90_P95 P95_P99 P99_P99p5 P99p5_P99p9 P99p9_P99p99 {
		foreach compo in salestax paytax {
			su frac`compo'`group' if year == 1962 | year == 1963
			local frac`compo'`group'pre62 = r(mean)
			replace frac`compo'`group' = `frac`compo'`group'pre62' if year < 1962
		}
	}

* Pre-62 imputations for all other taxes:
* Residential property tax: follows frac of housing wealth
* Business pproperty tax: follows frac of total wealth excluding housing
* Corporate tax: follows frac of corp equity wealth
	foreach group in bot90 bot50 middle40 top10 top5 top1 top0p5 top0p1 top0p01 P90_P95 P95_P99 P99_P99p5 P99p5_P99p9 P99p9_P99p99 {
		qui su fracH`group' if year == 1962 | year == 1963 
			global meanfracH_`group' = r(mean)
			replace fracproprestax`group'   = 1 - (1 - fracH`group') * (1 - ${mproprestax_`group'}) / (1 - ${meanfracH_`group'}) if year < 1962 
		qui su fracNH`group' if year == 1962 | year == 1963 
			global meanfracNH_`group' = r(mean)
			replace fracpropbustax`group' = 1 - (1 - fracNH`group') * (1 - ${mpropbustax_`group'}) / (1 - ${meanfracNH_`group'}) if year < 1962
		qui su fracE`group' if year == 1962 | year == 1963 
			global meanfracE_`group' = r(mean)
			replace fraccorptax`group' = 1 - (1 - fracE`group') * (1 - ${mcorptax_`group'}) / (1 - ${meanfracE_`group'}) if year < 1962

	}

* Outsheet tax rates; Lump corporate tax and business proeprty tax
	foreach group in all bot90 bot50 middle40 top10 top5 top1 top0p5 top0p1 top0p01 P90_P95 P95_P99 P99_P99p5 P99p5_P99p9 P99p9_P99p99 {
		foreach compo in salestax proprestax paytax ditax corptax propbustax estatetax {
			replace `compo'`group' = frac`compo'`group' * `compo'all / shY`group' if year < 1962
		}
		replace tax`group' = salestax`group' + proprestax`group' + paytax`group' + ditax`group' + corptax`group' + propbustax`group' + estatetax`group' if year < 1962
	}


* Cap taxes of top 0.01% to 130% of taxes paid by top 0.1% in the 1930s
	foreach t in salestax proprestax paytax ditax corptax propbustax estatetax tax {
		qui replace `t'top0p01 = `t'top0p1 * 1.3 if year > 1930 & year <= 1940 
	}
	saveold "$diroutput/pre62/pre62tax.dta", replace

	
	foreach group in all bot90 bot50 middle40 top10 top5 top1 top0p5 top0p1 top0p01 P90_P95 P95_P99 P99_P99p5 P99p5_P99p9 P99p9_P99p99 {
		replace corptax`group' = corptax`group' + propbustax`group' if year
	}
	keep year tax* salestax* proprestax* paytax* ditax* corptax* estatetax*
	order year *all *bot90 *bot50 *middle40 *top10 *top5 *top1 *top0p5 *top0p1 *top0p01 *top0p001 *P90_P95 *P95_P99 *P99_P99p5 *P99p5_P99p9 *P99p9_P99p99 *P99p99_P99p999 	
	export excel  using "$diroutexcel", first(var) sheetreplace sheet(taxrates)
  

