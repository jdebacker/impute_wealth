
if $source == 0 {
	global diroutsheet "$root/output/ToExcel"
}	
if $source == 1 {
	global diroutsheet "$root/output/ToExcelInternal"
}


********************************************************************************
* Import Piketty-Saez series
********************************************************************************

local lastyear = 2020
cap mkdir "$diroutput/pre62"	

cd $direxcel
*copy "https://eml.berkeley.edu/~saez/TabFig2015prel.xls" "TabFig2015prel.xls", replace
cd $root

* Top shares excluding KG
	import excel "$direxcel/TabFig2015prel.xls", clear sheet(Table A1)
	keep if _n>5
	qui rename A year
	destring year, force replace
	rename B fninc2
	rename C fninc3
	rename D fninc4
	rename E fninc5
	rename F fninc6
	rename G fninc7 
	keep year fn*
	foreach var of varlist fn* {
		destring `var', force replace
		replace `var' = `var' / 100
	}
	keep if year<=`lastyear'
	saveold "$diroutput/pre62/pre62comp.dta", replace	

* Top shares including KG
	import excel "$direxcel/TabFig2015prel.xls", clear sheet(Table A3)
	keep if _n>5
	qui rename A year
	destring year, force replace
	rename B fiinc2
	rename C fiinc3
	rename D fiinc4
	rename E fiinc5
	rename F fiinc6
	rename G fiinc7 
	keep year fi*
	foreach var of varlist fi* {
		destring `var', force replace
		replace `var' = `var' / 100
	}
	keep if year<=`lastyear'
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta"
	drop _merge
	saveold "$diroutput/pre62/pre62comp.dta", replace

* Compo excluding KG
	import excel "$direxcel/TabFig2015prel.xls", clear sheet(Table A7) 
	keep if _n>6
	qui rename A year
	destring year, force replace
	rename B fnwag2
	rename C fnbus2
	rename D fndiv2
	rename E fnint2
	rename F fnren2
	
	rename I fnwag3
	rename J fnbus3
	rename K fndiv3
	rename L fnint3
	rename M fnren3

	rename P fnwag4
	rename Q fnbus4
	rename R fndiv4
	rename S fnint4
	rename T fnren4

	rename W fnwag5
	rename X fnbus5
	rename Y fndiv5
	rename Z fnint5
	rename AA fnren5
	keep year fn*
	foreach var of varlist fn* {
		destring `var', force replace
		replace `var' = `var' / 100
	}
	keep if year<=`lastyear'
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta"
	drop _merge
	sort year
	saveold "$diroutput/pre62/pre62comp.dta", replace

	import excel "$direxcel/TabFig2015prel.xls", clear sheet(Table A7 (cont.)) 
	keep if _n>6
	qui rename A year
	destring year, force replace
	rename B fnwag6
	rename C fnbus6
	rename D fndiv6
	rename E fnint6
	rename F fnren6
	
	rename I fnwag7
	rename J fnbus7
	rename K fndiv7
	rename L fnint7
	rename M fnren7	
	keep year fn*
	foreach var of varlist fn* {
		destring `var', force replace
		replace `var' = `var' /100
	}
	keep if year<=`lastyear'
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta"
	drop _merge
	sort year
	saveold "$diroutput/pre62/pre62comp.dta", replace

* Capital gains
	import excel "$direxcel/TabFig2015prel.xls", clear sheet(Table A8) 
	keep if _n>6
	qui rename A year
	destring year, force replace
	rename B fnkgi2
	rename C fnkgi3
	rename D fnkgi4
	rename E fnkgi5
	rename F fnkgi6
	rename G fnkgi7
	rename Q fikgi2
	rename R fikgi3
	rename S fikgi4
	rename T fikgi5
	rename U fikgi6		
	rename V fikgi7
	keep year fn* fi*
	foreach var of varlist fn* fi* {
		destring `var', force replace
		replace `var' = `var' /100
	}
	keep if year<=`lastyear'
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta"
	drop _merge
	sort year
	saveold "$diroutput/pre62/pre62comp.dta", replace

* 1913-1915 components for top 1% and above = assume same as in 1916
	forval i = 4/7 {
		foreach compo in wag bus div int ren kgi {
			forval ii = 1/3 {
				local year = 1916
				replace fn`compo'`i' = fn`compo'`i'[_n+1] if year == `year' - `ii'
			}	
		}
	}

* 1913-1917 top 10% and top 5% shares: assume P90-P95 and P95-P99 have constant shares
gen fn9095=fninc2-fninc3
gen fn9599=fninc3-fninc4
gen fi9095=fiinc2-fiinc3
gen fi9599=fiinc3-fiinc4
		forval ii = 1/4 {
			local year = 1917
			foreach var in fn9095 fn9599 fi9095 fi9599 {
				replace `var' = `var'[_n+1] if year == `year' - `ii'
			}	
		}	
replace fninc3 = fninc4 + fn9599 if year<1917
replace fiinc3 = fiinc4 + fi9599 if year<1917
replace fninc2 = fninc3 + fn9095 if year<1917
replace fiinc2 = fiinc3 + fi9095 if year<1917
drop fn9095 fn9599 fi9095 fi9599

* 1913-1916 components for top 5%: assume same compo as 1917	
	foreach compo in wag bus div int ren kgi {
		forval ii = 1/4 {
			local year = 1917
			replace fn`compo'3 = fn`compo'3[_n+1] if year == `year' - `ii'
		}	
	}

* 1913-1917 components for top 10%: assume same compo as 1918	
	foreach compo in wag bus div int ren kgi {
		forval ii = 1/5 {
			local year = 1918
			replace fn`compo'2 = fn`compo'2[_n+1] if year == `year' - `ii'
		}	
	}


	
	saveold "$diroutput/pre62/pre62comp.dta", replace


* Compute component by component shares (= frac) and mean frac in 1962-1963
	insheet using "$parameters", clear names
	keep yr piksaez* 
	rename yr year
	keep if year>=1913 & year < `lastyear'
	foreach var of varlist _all {
		destring `var', force replace
	}
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta"
	qui drop _merge
	saveold "$diroutput/pre62/pre62comp.dta", replace
	forval i = 2/7 {
		foreach compo in wag bus div int ren {
			qui gen fracfn`compo'`i' = fn`compo'`i' * fninc`i' * piksaezden / piksaez`compo'
		}
		qui gen fracfnpen`i' 	= fnwag`i' * fninc`i' * piksaezden / (0.5 * piksaezwag) // assume bottom 50% wags don't get any pension
		qui gen fracdivmix`i' = (fndiv`i' * (1 - fnkgi`i') + fnkgi`i') * fiinc`i' * piksaezdenkg / (piksaezdiv + piksaezdenkg - piksaezden) // div + KG mixed method
		foreach compo in wag bus div int ren wag pen {
			su fracfn`compo'`i' if year == 1962 | year == 1963
			global meanfrac`compo'_`i' = r(mean)
		}
		su fracdivmix`i' if year == 1962 | year == 1963
			global meanfracdivmix_`i' = r(mean)
		*	di "${meanfracdivmix_`i'}"
		*	di "`r(mean)'"
	}		
	saveold "$diroutput/pre62/pre62comp.dta", replace

* Pre-1917 adjustments (same as in SZ 2016 QJE)
	foreach compo in fndiv divmix {
		forval ii = 1/3 {
			local year = 1916
			replace frac`compo'6 = frac`compo'6[_n+1] if year == `year' - `ii'
		}
		replace frac`compo'7 = (frac`compo'7[_n+1] + frac`compo'7[_n-1]) / 2 if year == 1915	
	}
	saveold "$diroutput/pre62/pre62comp.dta", replace

********************************************************************************
* Compute top wealth shares pre-62
********************************************************************************	

* Same method as in Saez-Zucman: component by component with adjustment in 1962, mixed method for equities

foreach pop in taxu indiv {

* Load totals
	insheet using "$parameters", clear names
	keep yr hwequ0 bond0 currency0 nonmort0 rental0 ownerhome0 ownermort0 hwbus0 hwpen0
	rename yr year
	foreach var of varlist *0 {
		qui rename `var' `var'`pop'
	}
	keep if year>=1913 & year < `lastyear'
	foreach var of varlist _all {
		destring `var', force replace
	}
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta"
	qui drop _merge
	saveold "$diroutput/pre62/pre62comp.dta", replace

* Import post-62 data
	import excel using "$diroutsheet/compohweal`pop'99.xlsx", first clear
	rename c1 year
	foreach var of varlist hweal* hwequ* bond* currency* nonmort* rental* ownerhome* ownermort* hwbus* hwpen* {
		qui rename `var' `var'`pop'
	}
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta"
	drop _merge
	sort year
	foreach var of varlist _all {
		replace `var' = 0.5 * (`var'[_n-1] + `var'[_n+1]) if (year == 1963 | year == 1965) & `var' == .
	}
	saveold "$diroutput/pre62/pre62comp.dta", replace

* Compute component by component shares (= frac)
	forval i = 2/7 {
		foreach compo in hwequ bond currency nonmort rental ownerhome ownermort hwbus hwpen {
			qui gen frac`compo'`i'`pop' = `compo'`i'`pop' / `compo'0`pop'		
		}

* Pre-62 imputations for currency, debt, etc.: fixed shares
		foreach compo in currency nonmort ownerhome ownermort {
			su frac`compo'`i'`pop' if year == 1962 | year == 1963
			local frac`compo'`i'`pop'pre62 = r(mean)
			qui replace frac`compo'`i'`pop' = `frac`compo'`i'`pop'pre62' if year < 1962
		}		
* Pre-62 imputations for equities, bonds, etc.: using fiscal income shares and correcting for reranking in 62
		foreach compo in hwequ bond rental hwbus hwpen {
			su frac`compo'`i'`pop' if year == 1962 | year == 1963
			global meanfrac`compo'_`i'`pop' = r(mean)
		}
		qui replace frachwequ`i'`pop' 	= min(0.95, 1 - (1 - fracdivmix`i') * (1 - ${meanfrachwequ_`i'`pop'}) / (1 - ${meanfracdivmix_`i'})) if year < 1962
		qui replace fracbond`i'`pop' 	= min(0.95, 1 - (1 - fracfnint`i') * (1 - ${meanfracbond_`i'`pop'}) / (1 - ${meanfracint_`i'})) if year < 1962
		qui replace fracrental`i'`pop'	= min(0.95, 1 - (1 - fracfnren`i') * (1 - ${meanfracrental_`i'`pop'}) / (1 - ${meanfracren_`i'})) if year < 1962
		qui replace frachwbus`i'`pop' 	= min(0.95, 1 - (1 - fracfnbus`i') * (1 - ${meanfrachwbus_`i'`pop'}) / (1 - ${meanfracbus_`i'})) if year < 1962
		qui replace frachwpen`i'`pop' 	= min(0.95, 1 - (1 - fracfnpen`i') * (1 - ${meanfrachwpen_`i'`pop'}) / (1 - ${meanfracpen_`i'})) if year < 1962

* Pre-62 wealth and components as % of total household wealth
		qui replace hweal`i'`pop' = 0 if year < 1962
		foreach compo in hwequ bond currency nonmort rental ownerhome ownermort hwbus hwpen {
			qui replace `compo'`i'`pop' = frac`compo'`i'`pop' * `compo'0`pop' if year < 1962
			qui replace hweal`i'`pop' = hweal`i'`pop' + `compo'`i'`pop' if year < 1962
		}
	}
	qui replace hweal0`pop' = hwequ0`pop'+ bond0`pop'+ currency0`pop'+ nonmort0`pop'+ rental0`pop'+ ownerhome0`pop'+ ownermort0`pop'+ hwbus0`pop'+ hwpen0`pop' if year < 1962

	saveold "$diroutput/pre62/pre62comp.dta", replace		
}

********************************************************************************
* Compute top factor income shares pre-62
********************************************************************************	

* Same method as for wealth: component by component with adjustment in 1962

** XX starting with fainc here, I define a local components macro at the beginning to automate a bit; to be done for wealth above ultimately 
** XX Also ideally these components macro should be defined only once in runusdina (and not once in outsheet, once in pre62 ...)

local components "faemp famil fahoumain fahourent faequ fafix fabus fapen famor fanmo"

foreach pop in taxu indiv equal {

* Load totals
	insheet using "$parameters", clear names
	keep yr flemp0 flmil0 fkhoumain0 fkhourent0 fkequ0 fkfix0 fkbus0 fkpen0 fkmor0 fknmo0
	rename yr year
	rename fl* fa*
	rename fk* fa*
	foreach var of varlist *0 {
		qui rename `var' `var'`pop'
	}
	keep if year>=1913 & year < `lastyear'
	foreach var of varlist _all {
		destring `var', force replace
	}
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta"
	qui drop _merge
	saveold "$diroutput/pre62/pre62comp.dta", replace


* Import post-62 data: income components
	import excel using "$diroutsheet/compofainc`pop'99.xlsx", first clear
	rename c1 year
	foreach var in fainc `components' {
		forval i = 0/7 {
			qui rename `var'`i' `var'`i'`pop'
		}
	}
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta"
	drop _merge
	sort year
	foreach var of varlist _all {
		replace `var' = 0.5 * (`var'[_n-1] + `var'[_n+1]) if (year == 1963 | year == 1965) & `var' == .
	}	
	saveold "$diroutput/pre62/pre62comp.dta", replace

* Compute component by component shares (= frac)
	forval i = 2/7 {
		foreach compo of local components  {
			qui gen frac`compo'`i'`pop' = `compo'`i'`pop' / `compo'0`pop'
			su frac`compo'`i'`pop' if year == 1962 | year == 1963
			global meanfrac`compo'_`i'`pop' = r(mean)		
		}

* Pre-62 imputations for main housing, debt, etc.: fixed shares
		foreach compo in fahoumain famor fanmo {
			su frac`compo'`i'`pop' if year == 1962 | year == 1963
			local frac`compo'`i'`pop'pre62 = r(mean)
			qui replace frac`compo'`i'`pop' = `frac`compo'`i'`pop'pre62' if year < 1962
		}

* Pre-62 imputations for other components: using fiscal income shares and correcting for reranking in 62
		qui replace fracfaemp`i'`pop' 	= min(0.95, 1 - (1 - fracfnwag`i') * (1 - ${meanfracfaemp_`i'`pop'}) / (1 - ${meanfracwag_`i'})) if year < 1962
		qui replace fracfamil`i'`pop' 	= min(0.95, 1 - (1 - fracfnbus`i') * (1 - ${meanfracfamil_`i'`pop'}) / (1 - ${meanfracbus_`i'})) if year < 1962
	  	qui replace fracfahourent`i'`pop' = min(0.95, 1 - (1 - fracfnren`i') * (1 - ${meanfracfahourent_`i'`pop'}) / (1 - ${meanfracren_`i'})) if year < 1962
		qui replace fracfaequ`i'`pop' 	= min(0.95, 1 - (1 - fracdivmix`i') * (1 - ${meanfracfaequ_`i'`pop'}) / (1 - ${meanfracdivmix_`i'})) if year < 1962
		qui replace fracfafix`i'`pop' 	= min(0.95, 1 - (1 - fracfnint`i') * (1 - ${meanfracfafix_`i'`pop'}) / (1 - ${meanfracint_`i'})) if year < 1962
		qui replace fracfabus`i'`pop' 	= min(0.95, 1 - (1 - fracfnbus`i') * (1 - ${meanfracfabus_`i'`pop'}) / (1 - ${meanfracbus_`i'})) if year < 1962
		qui replace fracfapen`i'`pop' 	= min(0.95, 1 - (1 - fracfnpen`i') * (1 - ${meanfracfapen_`i'`pop'}) / (1 - ${meanfracpen_`i'})) if year < 1962
	
* Pre-62 income and components as % of total income
		qui replace fainc`i'`pop' = 0 if year < 1962
		foreach compo in `components' {
			qui replace `compo'`i'`pop' = frac`compo'`i'`pop' * `compo'0`pop' if year < 1962
			if `i' >= 4 { // deal with re-ranking at very top due to negative corporate profits
				if "`compo'" == "faequ" qui replace faequ`i'`pop'	= 0.05 * hwequ`i'indiv * 4.76  if year == 1931
				if "`compo'" == "faequ" qui replace faequ`i'`pop'	= 0.03 * hwequ`i'indiv * 5.03  if year == 1932
				if "`compo'" == "faequ" qui replace faequ`i'`pop'	= 0.03 * hwequ`i'indiv * 5.48  if year == 1933   
			}
			if `i' == 2 { // deal with re-ranking at very top due to negative corporate profits
				if "`compo'" == "faequ" qui replace faequ`i'`pop'	= 0.01 * hwequ`i'indiv * 5.03  if year == 1932
				if "`compo'" == "faequ" qui replace faequ`i'`pop'	= 0.01 * hwequ`i'indiv * 5.48  if year == 1933   
			}
			qui replace fainc`i'`pop' = fainc`i'`pop' + `compo'`i'`pop' if year < 1962
		}
	}

	qui replace fainc0`pop' = 0 if year < 1962
	foreach compo in `components' {
		qui replace fainc0`pop' = fainc0`pop' + `compo'0`pop' if year < 1962 
	}

	sort year
	saveold "$diroutput/pre62/pre62comp.dta", replace		
}


********************************************************************************
* Pre-tax income 
********************************************************************************

local components "ptemp ptmil pthoumain pthourent ptequ ptfix ptbus ptmor ptnmo ptben ptcon"

foreach pop in taxu indiv equal {

* Load totals
	insheet using "$parameters", clear names
	keep yr flemp0 flmil0 fkhoumain0 fkhourent0 fkequ0 fkfix0 fkbus0 fkmor0 fknmo0 ttplcon ttpenben ttuidiben ttinvincpen fkpen0  ttptinc  ttfainc
	replace fkfix0 = fkfix0 + (fkpen0 - ttinvincpen / ttptinc)
	rename fl* pt*
	rename fk* pt*
	gen ptcon0 = - ttplcon / ttptinc
	gen ptben0 =  (ttpenben + ttuidiben) / ttptinc
	rename yr year
	foreach var of varlist *0 {
		replace `var' = `var' * ttfainc / ttptinc
		qui rename `var' `var'`pop'
	}
	keep if year>=1913 & year < `lastyear'
	foreach var of varlist _all {
		destring `var', force replace
	}
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta"
	qui drop _merge
	saveold "$diroutput/pre62/pre62comp.dta", replace

* Import post-62 data: income components
	import excel using "$diroutsheet/compoptinc`pop'99.xlsx", first clear
	rename c1 year
	foreach var in ptinc `components' {
		forval i = 0/7 {
			qui rename `var'`i' `var'`i'`pop'
		}
	}
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta"
	drop _merge
	sort year
	foreach var of varlist _all {
		replace `var' = 0.5 * (`var'[_n-1] + `var'[_n+1]) if (year == 1963 | year == 1965) & `var' == . 
	}	
	saveold "$diroutput/pre62/pre62comp.dta", replace

* Compute component by component shares (= frac)
	forval i = 2/7 {
		foreach compo of local components {
			qui gen frac`compo'`i'`pop' = `compo'`i'`pop' / `compo'0`pop'
			su frac`compo'`i'`pop' if year == 1962 | year == 1963
			global meanfrac`compo'_`i'`pop' = r(mean)		
		}

* Pre-62 imputations for main housing, debt, and social insurance contributions & benefits: fixed shares
		foreach compo in pthoumain ptmor ptnmo ptben ptcon {
			su frac`compo'`i'`pop' if year == 1962 | year == 1963
			local frac`compo'`i'`pop'pre62 = r(mean)
			qui replace frac`compo'`i'`pop' = `frac`compo'`i'`pop'pre62' if year < 1962
		}

* Pre-62 imputations for other components: using fiscal income shares and correcting for reranking in 62		
		qui replace fracptemp`i'`pop' 	= min(0.95, 1 - (1 - fracfnwag`i') * (1 - ${meanfracptemp_`i'`pop'}) / (1 - ${meanfracwag_`i'})) if year < 1962
		qui replace fracptmil`i'`pop' 	= min(0.95, 1 - (1 - fracfnbus`i') * (1 - ${meanfracptmil_`i'`pop'}) / (1 - ${meanfracbus_`i'})) if year < 1962
	  	qui replace fracpthourent`i'`pop' = min(0.95, 1 - (1 - fracfnren`i') * (1 - ${meanfracpthourent_`i'`pop'}) / (1 - ${meanfracren_`i'})) if year < 1962
		qui replace fracptequ`i'`pop' 	= min(0.95, 1 - (1 - fracdivmix`i') * (1 - ${meanfracptequ_`i'`pop'}) / (1 - ${meanfracdivmix_`i'})) if year < 1962
		qui replace fracptfix`i'`pop' 	= min(0.95, 1 - (1 - fracfnint`i') * (1 - ${meanfracptfix_`i'`pop'}) / (1 - ${meanfracint_`i'})) if year < 1962
		qui replace fracptbus`i'`pop' 	= min(0.95, 1 - (1 - fracfnbus`i') * (1 - ${meanfracptbus_`i'`pop'}) / (1 - ${meanfracbus_`i'})) if year < 1962
	
* Pre-62 income and components as % of total income
		qui replace ptinc`i'`pop' = 0 if year < 1962
		foreach compo in `components' {
			qui replace `compo'`i'`pop' = frac`compo'`i'`pop' * `compo'0`pop' if year < 1962
			if `i' >= 4 { // deal with re-ranking at very top due to negative corporate profits
				if "`compo'" == "ptequ" qui replace ptequ`i'`pop'	= 0.05 * hwequ`i'indiv * 4.76  if year == 1931
				if "`compo'" == "ptequ" qui replace ptequ`i'`pop'	= 0.03 * hwequ`i'indiv * 5.03  if year == 1932
				if "`compo'" == "ptequ" qui replace ptequ`i'`pop'	= 0.03 * hwequ`i'indiv * 5.48  if year == 1933   
			}
			if `i' == 2 { // deal with re-ranking at very top due to negative corporate profits
				if "`compo'" == "ptequ" qui replace ptequ`i'`pop'	= 0.01 * hwequ`i'indiv * 5.03  if year == 1932
				if "`compo'" == "ptequ" qui replace ptequ`i'`pop'	= 0.01 * hwequ`i'indiv * 5.48  if year == 1933   
			}	
			qui replace ptinc`i'`pop' = ptinc`i'`pop' + `compo'`i'`pop' if year < 1962
		}
	}

	qui replace ptinc0`pop' = 0 if year < 1962
	foreach compo in `components' {
		qui replace ptinc0`pop' = ptinc0`pop' + `compo'0`pop' if year < 1962 
	}
	sort year
	saveold "$diroutput/pre62/pre62comp.dta", replace		
}

********************************************************************************
* Disposable income
********************************************************************************

local components "dipre disal dipro ditax diest dicor dibus dioth diben divet dihlt dikdn dicxp" 

foreach pop in taxu indiv equal {

* Load totals
	insheet using "$parameters", clear names
	keep yr ttdiinc ttdivw ttscorw ttschcpartw ttdikin ttptinc ttflprl ttfkprk ttproptax_res ttproptax_bus ttfedtax ttstatetax ttestatetax ttfkcot ttothcon ttnonvetben ttvetben ttmedicare ttmedicaid ttothinkind ttcolexp  ttoacont ttsecont_oa ttdicont ttsecont_di ttuicont ttwealth ttrestw ttrentw ttrentmortw
	gen dipre0 = ttptinc / ttdiinc
	gen disal0 = - (ttflprl + ttfkprk) / ttdiinc
	gen dipro0 = - ttproptax_res / ttdiinc
	gen ditax0 = - (ttfedtax + ttstatetax) / ttdiinc
	gen diest0 = - ttestatetax / ttdiinc
	gen dicor0 = - (ttfkcot) / ttdiinc
	gen dibus0 = - (ttproptax_bus) / ttdiinc
	gen dioth0 = - ttothcon / ttdiinc
	gen diben0 = ttnonvetben / ttdiinc
	gen divet0 = ttvetben / ttdiinc
	gen dihlt0 = (ttmedicare + ttmedicaid) / ttdiinc	
	gen dikdn0 = ttothinkind / ttdiinc
	gen dicxp0 = ttcolexp / ttdiinc
	gen h0     = (ttrestw + ttrentw - ttrentmortw) / ttwealth
	gen nh0	   = (ttwealth - (ttrestw + ttrentw - ttrentmortw)) / ttwealth
	gen bus0   = (ttdivw + ttscorw + ttschcpartw) / ttwealth
	rename yr year
	foreach var of varlist *0 {
		qui rename `var' `var'`pop'
	}
	keep if year>=1913 & year < `lastyear'
	foreach var of varlist _all {
		destring `var', force replace
	}
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta"
	qui drop _merge
	saveold "$diroutput/pre62/pre62comp.dta", replace

* Import post-62 data: income components
	import excel using "$diroutsheet/compodiinc`pop'99.xlsx", first clear
	rename c1 year
	foreach var in diinc `components'  {
		forval i = 0/7 {
			qui rename `var'`i' `var'`i'`pop'
		}
	}
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta"
	drop _merge
	sort year
	foreach var of varlist _all {
		replace `var' = 0.5 * (`var'[_n-1] + `var'[_n+1]) if (year == 1963 | year == 1965) & `var' == .
	}	
	saveold "$diroutput/pre62/pre62comp.dta", replace

* Compute component by component shares (= frac)
	forval i = 2/7 {
		foreach compo of local components {
			qui gen frac`compo'`i'`pop' = `compo'`i'`pop' / `compo'0`pop'
			su frac`compo'`i'`pop' if year == 1962 | year == 1963
			global meanfrac`compo'_`i'`pop' = r(mean)		
		}
	}
	saveold "$diroutput/pre62/pre62comp.dta", replace

* Load frac estate tax paid
	import excel "$root/rawdata/rawexcel/taxratespre62.xls", clear sheet(results-estatetax)
	keep if _n>2 & _n < 110
	qui rename A year
	destring year, force replace
	rename I fracdiest0
	rename J fracdiest2
	rename K fracdiest3
	rename L fracdiest4
	rename M fracdiest5
	rename N fracdiest6 
	rename O fracdiest7 
	keep year frac*
	foreach var of varlist frac* {
		destring `var', force replace
		replace `var' = 0 if `var' == .
	}
	drop if year==.
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta"
	drop _merge
	saveold "$diroutput/pre62/pre62comp.dta", replace

* Load frac income tax paid
	import excel "$root/rawdata/rawexcel/taxratespre62.xls", clear sheet(results-incometax)
	keep if _n>2 & _n < 56
	qui rename A year
	destring year, force replace
	rename S fracfedtax0
	rename T fracfedtax2
	rename U fracfedtax3
	rename V fracfedtax4
	rename W fracfedtax5
	rename X fracfedtax6 
	rename Y fracfedtax7 
	keep year frac*
	foreach var of varlist frac* {
		destring `var', force replace
		replace `var' = 0 if `var' == . & year==1913
	}
	drop if year==.
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta"
	drop _merge
	saveold "$diroutput/pre62/pre62comp.dta", replace

* Pre-62 imputations for other Social contrib, sales tax (fixed fractions) and health benefits (medicare = medicaid = 0 before 1966)
	forval i = 2/7 {	
		foreach compo in dioth disal {
			su frac`compo'`i'`pop' if year == 1962 | year == 1963
			local frac`compo'`i'`pop'pre62 = r(mean)
			replace frac`compo'`i'`pop' = `frac`compo'`i'`pop'pre62' if year < 1962
		}
		replace fracdihlt`i'`pop' = 0 if year < 1966

* Pre-62 imputations for all other components of diposable income: 
		su ptinc`i'`pop' if year == 1962 | year == 1963 
			global meanptinc_`i'`pop' = r(mean)	
		replace fracdipre`i'`pop'   = 1 - (1 - ptinc`i'`pop') * (1 - ${meanfracdipre_`i'`pop'}) / (1 - ${meanptinc_`i'`pop'}) if year < 1962 // dipre follows ptinc
		
		* qui gen falab`i'`pop' = (faemp`i'`pop' + famil`i'`pop') / (faemp0`pop' + famil0`pop') 
		* 	qui su falab`i'`pop' if year == 1962 | year == 1963
		* 	global meanfalab_`i'`pop' = r(mean)	
		* qui gen facap`i'`pop' = (fahoumain`i'`pop' + fahourent`i'`pop' + faequ`i'`pop' + fafix`i'`pop' + fabus`i'`pop' + fapen`i'`pop' + famor`i'`pop' + fanmo`i'`pop') / (fahoumain0`pop' + fahourent0`pop' + faequ0`pop' + fafix0`pop' + fabus0`pop' + fapen0`pop' + famor0`pop' + fanmo0`pop')
		* 	qui su facap`i'`pop' if year == 1962 | year == 1963
		* 	global meanfacap_`i'`pop' = r(mean)	
		
		if "`pop'" != "equal" {
			qui gen h`i'`pop' 	= rental`i'`pop' + ownerhome`i'`pop'
			qui gen nh`i'`pop' 	= hweal`i'`pop' - h`i'`pop'
			qui gen bus`i'`pop' = hwequ`i'`pop' + hwbus`i'`pop' 
		}
		if "`pop'" == "equal" {
			qui gen h`i'`pop' 	= rental`i'indiv + ownerhome`i'indiv
			qui gen nh`i'`pop' 	= hweal`i'indiv - h`i'indiv
			qui gen bus`i'`pop' = hwequ`i'indiv + hwbus`i'indiv
		}

		qui gen frach`i'`pop' = h`i'`pop' / h0`pop'	
			qui su frach`i'`pop' if year == 1962 | year == 1963
			global meanh_`i'`pop' = r(mean)	
		qui gen fracnh`i'`pop' = nh`i'`pop' / nh0`pop'
			qui su fracnh`i'`pop' if year == 1962 | year == 1963
			global meannh_`i'`pop' = r(mean)
		qui gen fracbus`i'`pop' = bus`i'`pop' / bus0`pop'
			qui su fracbus`i'`pop' if year == 1962 | year == 1963
			global meanbus_`i'`pop' = r(mean)			
		if "`pop'" != "taxu" qui gen fraceq`i'`pop' = hwequ`i'indiv / hwequ0indiv
		if "`pop'" == "taxu" qui gen fraceq`i'`pop' = hwequ`i'taxu / hwequ0taxu
			qui su fraceq`i'`pop' if year == 1962 | year == 1963
			global meaneq_`i'`pop' = r(mean)			
		if "`pop'" != "equal" {
			qui replace fracdipro`i'`pop' = 1 - (1 - frach`i'`pop') * (1 - ${meanfracdipro_`i'`pop'}) / (1 - ${meanh_`i'`pop'}) if year < 1962 // follows housing wealth 
			qui replace fracdibus`i'`pop' = 1 - (1 - fracbus`i'`pop') * (1 - ${meanfracdibus_`i'`pop'}) / (1 - ${meanbus_`i'`pop'}) if year < 1962 // follows equity and business assets 
			qui replace fracdicor`i'`pop' = 1 - (1 - fraceq`i'`pop') * (1 - ${meanfracdicor_`i'`pop'}) / (1 - ${meaneq_`i'`pop'}) if year < 1962 // follows equity wealth
		}	
		if "`pop'" == "equal" {
			qui replace fracdipro`i'`pop' = 1 - (1 - frach`i'indiv) * (1 - ${meanfracdipro_`i'`pop'}) / (1 - ${meanh_`i'indiv}) if year < 1962  
			qui replace fracdibus`i'`pop' = 1 - (1 - fracbus`i'indiv) * (1 - ${meanfracdibus_`i'`pop'}) / (1 - ${meanbus_`i'indiv}) if year < 1962
			qui replace fracdicor`i'`pop' = 1 - (1 - fraceq`i'indiv) * (1 - ${meanfracdicor_`i'`pop'}) / (1 - ${meaneq_`i'indiv}) if year < 1962
		}	
		qui su fracfedtax`i' if year == 1962 | year == 1963
			global meanfracfedtax_`i' = r(mean)	
		qui replace fracditax`i'`pop' = 1 - (1 - fracfedtax`i') * (1 - ${meanfracditax_`i'`pop'}) / (1 - ${meanfracfedtax_`i'}) if year < 1962 
		qui su fracdiest`i' if year == 1962 | year == 1963
			global meanfracdiest_`i' = r(mean)	
		qui replace fracdiest`i'`pop' = min(0.95, 1 - (1 - fracdiest`i') * (1 - ${meanfracdiest_`i'`pop'}) / (1 - ${meanfracdiest_`i'})) if year < 1962 
		qui replace fracdiben`i'`pop' = 0  if year < 1962 // Worker comp, AFDC, other in cash: all for bottom 90%
		if `i' == 2 qui replace fracdivet`i'`pop' = .1 if year < 1962 // Veteran benefits = capitation = top 10% has 10%, etc.
		if `i' == 3 qui replace fracdivet`i'`pop' = .05 if year < 1962
		if `i' == 4 qui replace fracdivet`i'`pop' = .01 if year < 1962
		if `i' == 5 qui replace fracdivet`i'`pop' = .005 if year < 1962
		if `i' == 6 qui replace fracdivet`i'`pop' = .001 if year < 1962
		if `i' == 7 qui replace fracdivet`i'`pop' = .0001 if year < 1962
		qui replace fracdikdn`i'`pop' = 0 if year < 1962 //  Other in kind benefits: all for bottom 90%
		if `i' == 7 { // Cap taxes of top 0.01% to 130% of taxes paid by top 0.1% in the 1930s
			foreach t in dipro dicor dibus ditax diest disal dioth {
				qui replace frac`t'7`pop' = (`t'6`pop' / (fracdipre6`pop' * dipre0`pop') * 1.3) * (fracdipre7`pop' * dipre0`pop') / `t'0`pop' if year > 1930 & year <= 1940 
			}
		}
		gen dikin`i'`pop' = 0 if year < 1962 //  Generate disposable cash + kind income (excl. coll exp)
		foreach compo in dipre disal dipro ditax diest dicor dibus dioth diben divet dihlt dikdn { 
			qui replace dikin`i'`pop' = dikin`i'`pop' + frac`compo'`i'`pop' * `compo'0`pop' * ttdiinc / ttdikin if year < 1962			
		}
		qui replace fracdicxp`i'`pop' = dikin`i'`pop' if year < 1962 // prop to disposable cash + kind transfer income

	
* Pre-62 income and components as % of total income
		qui replace diinc`i'`pop' = 0 if year < 1962
		foreach compo in `components' {
			qui replace `compo'`i'`pop' = frac`compo'`i'`pop' * `compo'0`pop' if year < 1962
			qui replace diinc`i'`pop' = diinc`i'`pop' + `compo'`i'`pop' if year < 1962
		}
	}
	qui replace diinc0`pop' = 0 if year < 1962
	foreach compo in `components' {
		qui replace diinc0`pop' = diinc0`pop' + `compo'0`pop' if year < 1962 
	}
	saveold "$diroutput/pre62/pre62comp.dta", replace	
}

* Total tax and benefits (people ranked by disposable income); need to adjust dioth (created above) so that it includes pension + DI + UI ss contrib
	insheet using "$parameters", clear names
	keep yr ttdiinc ttoacont  ttsecont_oa  ttdicont  ttsecont_di  ttuicont  ttothcon
	gen disst0 = - (ttoacont + ttsecont_oa + ttdicont + ttsecont_di + ttuicont + ttothcon) / ttdiinc
	rename yr year
	keep if year>=1913 & year < `lastyear'
	tempfile govcontrib
	save `govcontrib'
	use "$diroutput/pre62/pre62comp.dta", clear 	
	merge 1:1 year using `govcontrib'
	drop _merge
	rename disst0 disst0taxu
	gen disst0indiv = disst0taxu
	gen disst0equal = disst0taxu
	foreach pop in taxu indiv equal {	
	gen ben0`pop' = diben0`pop' + divet0`pop' + dihlt0`pop' + dikdn0`pop' + dicxp0`pop'	
	gen tax0`pop' = - (disal0`pop' + dipro0`pop' + dicor0`pop' + dibus0`pop' + ditax0`pop' + diest0`pop' + disst0`pop')
	forval i = 2/7 {
		replace dioth`i'`pop' = dioth`i'`pop' * disst0`pop' / dioth0`pop'
		rename  dioth`i'`pop' disst`i'`pop'
		replace disst`i'`pop' = 0 if disst`i'`pop' == .
		gen tax`i'`pop' = - (disal`i'`pop' + dipro`i'`pop' + dicor`i'`pop' + dibus`i'`pop' + ditax`i'`pop' + diest`i'`pop' + disst`i'`pop')
		gen ben`i'`pop' = (diben`i'`pop' + divet`i'`pop' + dikin`i'`pop' + dicxp`i'`pop')
	}	
	sort year
	saveold "$diroutput/pre62/pre62comp.dta", replace		
}



********************************************************************************
* Factor income matching National Income
********************************************************************************

local components "prfai prgov prnpi" 

foreach pop in taxu indiv equal {

* Load totals
	insheet using "$parameters", clear names
	keep yr ttfainc ttgovint ttnpishinc ttninc
	rename yr year
	gen prfai0 = ttfainc / ttninc
	gen prgov0 = - ttgovint / ttninc
	gen prnpi0 = ttnpishinc / ttninc
	foreach var of varlist *0 {
		qui rename `var' `var'`pop'
	}

	keep if year>=1913 & year < `lastyear'
	foreach var of varlist _all {
		destring `var', force replace
	}
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta"
	qui drop _merge
	saveold "$diroutput/pre62/pre62comp.dta", replace


* Import post-62 data: income components
	import excel using "$diroutsheet/compoprinc`pop'99.xlsx", first clear
	rename c1 year
	foreach var in princ `components' {
		forval i = 0/7 {
			qui rename `var'`i' `var'`i'`pop'
		}
	}
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta"
	drop _merge
	sort year
	foreach var of varlist _all {
		replace `var' = 0.5 * (`var'[_n-1] + `var'[_n+1]) if (year == 1963 | year == 1965) & `var' == .
	}	
	saveold "$diroutput/pre62/pre62comp.dta", replace

* Compute component by component shares (= frac)
	forval i = 2/7 {
		foreach compo of local components  {
			qui gen frac`compo'`i'`pop' = `compo'`i'`pop' / `compo'0`pop'
			su frac`compo'`i'`pop' if year == 1962 | year == 1963
			global meanfrac`compo'_`i'`pop' = r(mean)		
		}

* Pre-62 imputations 
		qui su fainc`i'`pop' if year == 1962 | year == 1963 
		global meanfainc_`i'`pop' = r(mean)	
		qui replace fracprfai`i'`pop'   = 1 - (1 - fainc`i'`pop') * (1 - ${meanfracprfai_`i'`pop'}) / (1 - ${meanfainc_`i'`pop'}) if year < 1962

		gen fractax`i'`pop' = 0
		replace fractax`i'`pop' = tax`i'`pop' / tax0`pop'
		gen fracben`i'`pop' = 0
		replace fracben`i'`pop' = tax`i'`pop' / tax0`pop'
		gen fractaxben`i'`pop' = 0
		replace fractaxben`i'`pop' = 0.5 * fractax`i'`pop' + 0.5 * fracben`i'`pop'
		qui su fractaxben`i'`pop' if year == 1962 | year == 1963
			global meanfractaxben_`i'`pop' = r(mean)
		qui replace fracprgov`i'`pop'  = 1 - (1 - fractaxben`i'`pop') * (1 - ${meanfracprgov_`i'`pop'}) / (1 - ${meanfractaxben_`i'`pop'}) if year < 1962

		qui su diinc`i'`pop' if year == 1962 | year == 1963 
			global meandiinc_`i'`pop' = r(mean)	
		qui replace fracprnpi`i'`pop'   = 1 - (1 - diinc`i'`pop') * (1 - ${meanfracprnpi_`i'`pop'}) / (1 - ${meandiinc_`i'`pop'}) if year < 1962

* Pre-62 income and components as % of total income
		qui replace princ`i'`pop' = 0 if year < 1962
		foreach compo in `components' {
			qui replace `compo'`i'`pop' = frac`compo'`i'`pop' * `compo'0`pop' if year < 1962
			qui replace princ`i'`pop' = princ`i'`pop' + `compo'`i'`pop' if year < 1962
		}
	}
	qui replace princ0`pop' = 0 if year < 1962
	foreach compo in `components' {
		qui replace princ0`pop' = princ0`pop' + `compo'0`pop' if year < 1962 
	}

	sort year
	saveold "$diroutput/pre62/pre62comp.dta", replace		
}



********************************************************************************
* Pre-tax income matching National Income
********************************************************************************

local components "pepti pegov penpi pesup peinv"

foreach pop in taxu indiv equal {

* Load totals
	insheet using "$parameters", clear names
	keep yr ttptinc ttgovint ttnpishinc ttprisupss ttprisupenprivate ttninc ttinvincpen
	rename yr year
	gen pepti0 = ttptinc / ttninc
	gen pegov0 = - ttgovint / ttninc
	gen penpi0 = ttnpishinc / ttninc
	gen pesup0 = (ttprisupss + ttprisupenprivate) / ttninc
	gen peinv0 =  ttinvincpen / ttninc
	foreach var of varlist *0 {
		qui rename `var' `var'`pop'
	}

	keep if year>=1913 & year < `lastyear'
	foreach var of varlist _all {
		destring `var', force replace
	}
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta"
	qui drop _merge
	saveold "$diroutput/pre62/pre62comp.dta", replace


* Import post-62 data: income components
	import excel using "$diroutsheet/compopeinc`pop'99.xlsx", first clear
	rename c1 year
	foreach var in peinc `components' {
		forval i = 0/7 {
			qui rename `var'`i' `var'`i'`pop'
		}
	}
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta", update replace
	drop _merge
	sort year
	foreach var of varlist _all {
		replace `var' = 0.5 * (`var'[_n-1] + `var'[_n+1]) if (year == 1963 | year == 1965) & `var' == .
	}	
	saveold "$diroutput/pre62/pre62comp.dta", replace

* Compute component by component shares (= frac)
	forval i = 2/7 {
		foreach compo of local components  {
			cap drop frac`compo'`i'`pop'
			qui gen frac`compo'`i'`pop' = `compo'`i'`pop' / `compo'0`pop'
			su frac`compo'`i'`pop' if year == 1962 | year == 1963
			global meanfrac`compo'_`i'`pop' = r(mean)		
		}

* Pre-62 imputations for pension surplus: fixed share
	foreach compo in pesup {
		su frac`compo'`i'`pop' if year == 1962 | year == 1963
		local frac`compo'`i'`pop'pre62 = r(mean)
		replace frac`compo'`i'`pop' = `frac`compo'`i'`pop'pre62' if year < 1962
	}

* Pre-62 imputations for other components
		qui su ptinc`i'`pop' if year == 1962 | year == 1963 
		global meanptinc_`i'`pop' = r(mean)	
		qui replace fracpepti`i'`pop'   = 1 - (1 - ptinc`i'`pop') * (1 - ${meanfracpepti_`i'`pop'}) / (1 - ${meanptinc_`i'`pop'}) if year < 1962

		qui replace fracpegov`i'`pop'  = 1 - (1 - fractaxben`i'`pop') * (1 - ${meanfracpegov_`i'`pop'}) / (1 - ${meanfractaxben_`i'`pop'}) if year < 1962

		qui su diinc`i'`pop' if year == 1962 | year == 1963 
			global meandiinc_`i'`pop' = r(mean)	
		qui replace fracpenpi`i'`pop'   = 1 - (1 - diinc`i'`pop') * (1 - ${meanfracpenpi_`i'`pop'}) / (1 - ${meandiinc_`i'`pop'}) if year < 1962

		qui replace fracpeinv`i'`pop' = 1 - (1 - fracfapen`i'`pop') * (1 - ${meanfracpeinv_`i'`pop'}) / (1 - ${meanfracfapen_`i'`pop'}) if year < 1962

* Pre-62 income and components as % of total income
		qui replace peinc`i'`pop' = 0 if year < 1962
		foreach compo in `components' {
			qui replace `compo'`i'`pop' = frac`compo'`i'`pop' * `compo'0`pop' if year < 1962
			qui replace peinc`i'`pop' = peinc`i'`pop' + `compo'`i'`pop' if year < 1962
		}
	}
	qui replace peinc0`pop' = 0 if year < 1962
	foreach compo in `components' {
		qui replace peinc0`pop' = peinc0`pop' + `compo'0`pop' if year < 1962 
	}

	sort year
	saveold "$diroutput/pre62/pre62comp.dta", replace		
}




********************************************************************************
* Post-tax income matching National Income
********************************************************************************




local components "podii pogov ponpi posup poinv posug"

foreach pop in taxu indiv equal {

* Load totals
	insheet using "$parameters", clear names
	keep yr ttdiinc ttgovint ttnpishinc ttprimsupgov ttprisupenprivate ttninc ttinvincpen
	rename yr year
	gen podii0 = ttdiinc / ttninc
	gen pogov0 = - ttgovint / ttninc
	gen ponpi0 = ttnpishinc / ttninc
	gen posup0 = ttprisupenprivate / ttninc
	gen poinv0 =  ttinvincpen / ttninc
	gen posug0 = ttprimsupgov / ttninc
	foreach var of varlist *0 {
		qui rename `var' `var'`pop'
	}

	keep if year>=1913 & year < `lastyear'
	foreach var of varlist _all {
		destring `var', force replace
	}
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta"
	qui drop _merge
	saveold "$diroutput/pre62/pre62comp.dta", replace


* Import post-62 data: income components
	import excel using "$diroutsheet/compopoinc`pop'99.xlsx", first clear
	rename c1 year
	foreach var in poinc `components' {
		forval i = 0/7 {
			qui rename `var'`i' `var'`i'`pop'
		}
	}
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta", update replace
	drop _merge
	sort year
	foreach var of varlist _all {
		replace `var' = 0.5 * (`var'[_n-1] + `var'[_n+1]) if (year == 1963 | year == 1965) & `var' == .
	}	
	saveold "$diroutput/pre62/pre62comp.dta", replace

* Compute component by component shares (= frac)
	forval i = 2/7 {
		foreach compo of local components  {
			cap drop frac`compo'`i'`pop'
			qui gen frac`compo'`i'`pop' = `compo'`i'`pop' / `compo'0`pop'
			su frac`compo'`i'`pop' if year == 1962 | year == 1963
			global meanfrac`compo'_`i'`pop' = r(mean)		
		}

* Pre-62 imputations for pension surplus: fixed share
	foreach compo in posup {
		su frac`compo'`i'`pop' if year == 1962 | year == 1963
		local frac`compo'`i'`pop'pre62 = r(mean)
		replace frac`compo'`i'`pop' = `frac`compo'`i'`pop'pre62' if year < 1962
	}

* Pre-62 imputations for other components
		qui su diinc`i'`pop' if year == 1962 | year == 1963 
		global meanptinc_`i'`pop' = r(mean)	
		qui replace fracpodii`i'`pop'   = 1 - (1 - diinc`i'`pop') * (1 - ${meanfracpodii_`i'`pop'}) / (1 - ${meandiinc_`i'`pop'}) if year < 1962

		qui replace fracpogov`i'`pop'  = 1 - (1 - fractaxben`i'`pop') * (1 - ${meanfracpogov_`i'`pop'}) / (1 - ${meanfractaxben_`i'`pop'}) if year < 1962
		qui replace fracposug`i'`pop'  = 1 - (1 - fractaxben`i'`pop') * (1 - ${meanfracposug_`i'`pop'}) / (1 - ${meanfractaxben_`i'`pop'}) if year < 1962
		qui replace fracposug`i'`pop'  = diinc`i'`pop' if year >= 1942 & year <= 1945 // WWII deficits neutral 

		qui su diinc`i'`pop' if year == 1962 | year == 1963 
			global meandiinc_`i'`pop' = r(mean)	
		qui replace fracponpi`i'`pop'   = 1 - (1 - diinc`i'`pop') * (1 - ${meanfracponpi_`i'`pop'}) / (1 - ${meandiinc_`i'`pop'}) if year < 1962

		qui replace fracpoinv`i'`pop' = 1 - (1 - fracfapen`i'`pop') * (1 - ${meanfracpoinv_`i'`pop'}) / (1 - ${meanfracfapen_`i'`pop'}) if year < 1962


* Pre-62 income and components as % of total income
		qui replace poinc`i'`pop' = 0 if year < 1962
		foreach compo in `components' {
			qui replace `compo'`i'`pop' = frac`compo'`i'`pop' * `compo'0`pop' if year < 1962
			qui replace poinc`i'`pop' = poinc`i'`pop' + `compo'`i'`pop' if year < 1962
		}
	}
	qui replace poinc0`pop' = 0 if year < 1962
	foreach compo in `components' {
		qui replace poinc0`pop' = poinc0`pop' + `compo'0`pop' if year < 1962 
	}

	sort year
	saveold "$diroutput/pre62/pre62comp.dta", replace		
}



********************************************************************************
* Prepare pre62comp.data to merge with dagraph.dta
********************************************************************************

use "$diroutput/pre62/pre62comp.dta", clear

* Change Piketty-Saez components to express them as % of total fiscal income
* Note: in PS, no composition tables when units ranked by income incl. KG (i.e., no fiwag`i', etc.)
	foreach i of numlist 2/7 {
		foreach compo in wag bus div int ren kgi  {
			replace fn`compo'`i' = fn`compo'`i' * fninc`i'
		}
		replace fikgi`i' = fikgi`i' * fiinc`i'
	}
	gen fnwag0 = piksaezwag / piksaezden 
	gen fnbus0 = piksaezbus / piksaezden
	gen fndiv0 = piksaezdiv / piksaezden
	gen fnint0 = piksaezint / piksaezden
	gen fnren0 = piksaezren / piksaezden
	gen fnkgi0 = (piksaezdenkg - piksaezden) / piksaezden
	gen fiwag0 = piksaezwag / piksaezdenkg 
	gen fibus0 = piksaezbus / piksaezdenkg
	gen fidiv0 = piksaezdiv / piksaezdenkg
	gen fiint0 = piksaezint / piksaezdenkg
	gen firen0 = piksaezren / piksaezdenkg
	gen fikgi0 = (piksaezdenkg - piksaezden) / piksaezdenkg
	gen fiinc0 = 1
	gen fninc0 = 1
	foreach var of varlist fn* fi* {
		rename `var' `var'taxu
	}
	
* Create component by components for bottom 90% (= *9)
foreach var of varlist *0equal { 
	local j =substr("`var'",1,length("`var'")-6)
	cap gen `j'9equal = `j'0equal - `j'2equal
}	
foreach var of varlist *0indiv { 
	local j =substr("`var'",1,length("`var'")-6)
	cap gen `j'9indiv = `j'0indiv - `j'2indiv
}	
foreach var of varlist *0taxu { 
	local j =substr("`var'",1,length("`var'")-5)
	cap gen `j'9taxu = `j'0taxu - `j'2taxu
}

* Rename shares in sh`var'`pop'`age' format 
	drop piksaez* frac* tt* 
	ds year, not
	foreach var of varlist `r(varlist)' {
		rename `var' sh`var'99
	}
	saveold "$diroutput/pre62/pre62comp.dta", replace


********************************************************************************
* Create averages
********************************************************************************

*use  "$diroutput/pre62/pre62comp.dta", clear

* Bring population totals
insheet using "$parameters", clear names
	keep yr totadults20 tottaxunits piksaezden piksaezdenkg ttfainc ttptinc ttdiinc ttninc ttwealth
	rename yr year
	rename piksaezden ttfninc
	rename piksaezdenkg ttfiinc
	rename ttwealth tthweal
	gen ttprinc = ttninc
	gen ttpeinc = ttninc
	gen ttpoinc = ttninc
	keep if year>=1913 & year < `lastyear'
	merge 1:1 year using "$diroutput/pre62/pre62comp.dta"
	qui drop _merge
	saveold "$diroutput/pre62/pre62comp.dta", replace

* Create averages in avg`var'`i'`pop'`age' format 

	rename totadults20 totindiv
	gen totequal = totindiv
	rename tottaxunits tottaxu 
	foreach pop in taxu indiv equal {
		foreach var in fiinc fninc fainc ptinc diinc princ peinc poinc hweal {
				foreach age in 99 {
					foreach i of numlist 0/7 9 {
						quietly {
						if `i' == 0 cap gen avg`var'`i'`pop'99 = 1000 * sh`var'`i'`pop'99 * tt`var' / (1 * tot`pop')
						if `i' == 1 cap gen avg`var'`i'`pop'99 = 1000 * sh`var'`i'`pop'99 * tt`var' / (0.5 * tot`pop')
						if `i' == 2 cap gen avg`var'`i'`pop'99 = 1000 * sh`var'`i'`pop'99 * tt`var' / (0.1 * tot`pop')
						if `i' == 3 cap gen avg`var'`i'`pop'99 = 1000 * sh`var'`i'`pop'99 * tt`var' / (0.05 * tot`pop')
						if `i' == 4 cap gen avg`var'`i'`pop'99 = 1000 * sh`var'`i'`pop'99 * tt`var' / (0.01 * tot`pop')
						if `i' == 5 cap gen avg`var'`i'`pop'99 = 1000 * sh`var'`i'`pop'99 * tt`var' / (0.005 * tot`pop')
						if `i' == 6 cap gen avg`var'`i'`pop'99 = 1000 * sh`var'`i'`pop'99 * tt`var' / (0.001 * tot`pop')
						if `i' == 7 cap gen avg`var'`i'`pop'99 = 1000 * sh`var'`i'`pop'99 * tt`var' / (0.0001 * tot`pop')
						if `i' == 9 cap gen avg`var'`i'`pop'99 = 1000 * sh`var'`i'`pop'99 * tt`var' / (0.9 * tot`pop')
						}
					}
				}
			}
		}	
saveold "$diroutput/pre62/pre62comp.dta", replace





