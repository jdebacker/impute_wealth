* CPS SUMMARY STATS AND COMPARISON WITH DINA


* do "$dirprograms/sub_cpssumstats.do"
/*
* Median household income in CPS
mat drop _all
	foreach year of numlist 1962/2015 {
		use $diroutput/cpsindiv/cpsmar`year'indiv.dta, clear
		collapse (sum) inctotal marsupwt, by(h_seq)
		quietly su inctotal [w=marsupwt], detail
			local med_hhinc_cps`year' =  r(p50)
		mat  med_hhinc_cps = (nullmat(med_hhinc_cps) \ `med_hhinc_cps`year'')
		local incomeyr = `year' - 1
		mat  year = (nullmat(year) \ `incomeyr')
	}
	mat  		 med_hhcps = (year, med_hhinc_cps)
	mat colnames med_hhcps =  year  med_hhinc_cps
	clear
	svmat med_hhcps, names(col)

	export excel using "$diroutput/temp/cps/med_hhcps.xlsx", first(var) replace

mat drop _all
	foreach year of numlist 1962/2015 {
		use $diroutput/cpsindiv/cpsmar`year'indiv.dta, clear
		collapse (sum) inctotal marsupwt, by(h_seq)
		quietly su inctotal [w=marsupwt], detail
			local avg_hhinc_cps`year' =  r(mean)
		mat  avg_hhinc_cps = (nullmat(avg_hhinc_cps) \ `avg_hhinc_cps`year'')
		local incomeyr = `year' - 1
		mat  year = (nullmat(year) \ `incomeyr')
	}
	mat  		 avg_hhcps = (year, avg_hhinc_cps)
	mat colnames avg_hhcps =  year  avg_hhinc_cps
	clear
	svmat avg_hhcps, names(col)

	export excel using "$diroutput/temp/cps/avg_hhcps.xlsx", first(var) replace

* Comparison of individual adult wages and income CPS vs. DINA
* CPS
	foreach year of numlist 1962/2015 {
		use $diroutput/cpsindiv/cpsmar`year'indiv.dta, clear
		* replace marsupwt = round(marsupwt)*10e4
		* gperc wsal_val if wsal_val>0 & a_age>=20 [w=marsupwt], matname(wage_perc_cps`year')
		* 	putexcel A1=("Individual adult wage distribution in CPS (conditional on wage > 0)") using "$diroutput/temp/cps/wage_perc_cps`year'.xlsx", replace
		* 	putexcel A2=matrix(wage_perc_cps`year', names) using "$diroutput/temp/cps/wage_perc_cps`year'.xlsx", modify
		* gperc inctotal [w=marsupwt] if a_age>=20, matname(agi_perc_cps`year')
		* 	putexcel A1=("Individual adult market income distribution in CPS") using "$diroutput/temp/cps/agi_perc_cps`year'.xlsx", replace
		* 	putexcel A2=matrix(agi_perc_cps`year', names) using "$diroutput/temp/cps/agi_perc_cps`year'.xlsx", modify
		* Memo: inctotal = Piketty-Saez market income = excludes Social Security income (--> lots of people with 0 income)
		quietly su wsal_val [w=marsupwt] if a_age>=20 & wsal_val>0, meanonly
			local mean_wag_cps`year' = r(mean)
		quietly su wsal_val [w=marsupwt] if a_age>=20 & wsal_val > 0.15 * `mean_wag_cps`year'', detail // Get rid of very small wages (coded as 0 in CPS, contrary to IRS)
			local med_wag_cps`year' =  r(p50)
		mat med_wag_cps = (nullmat(med_wag_cps) \ `med_wag_cps`year'')
		quietly su inctotal if a_age>=20 [w=marsupwt], detail
			local med_inc_cps`year' =  r(p50)
		mat  med_inc_cps = (nullmat(med_inc_cps) \ `med_inc_cps`year'')
		local incomeyr = `year' - 1
		mat  year = (nullmat(year) \ `incomeyr')
	}
	mat  		 med_cps = (year, med_wag_cps, med_inc_cps)
	mat colnames med_cps =  year  med_wag_cps  med_inc_cps
* DINA
	foreach year of numlist 1962 1964 1966/2009 {
		local yearcps = `year' + 1
		use $diroutput/dinafiles/usdina`year'.dta, clear
		quietly su flwag [w=dweght] if flwag > 0.15 * `mean_wag_cps`yearcps'', detail
			local med_wag_dina`year' =  r(p50)
		quietly su flemp [w=dweght] if flemp > 0.15 * `mean_wag_cps`yearcps'', detail
			local med_emp_dina`year' =  r(p50)
		quietly su fninc [w=dweghttaxu], detail
			local med_inc_ps`year' =  r(p50)
		mat med_wag_dina = (nullmat(med_wag_dina) \ `med_wag_dina`year'')
		mat med_emp_dina = (nullmat(med_emp_dina) \ `med_emp_dina`year'')
		mat med_inc_ps = (nullmat(med_inc_ps) \ `med_inc_ps`year'')
		mat  yeardina = (nullmat(yeardina) \ `year')
	}
	mat  		 med_dina = (yeardina, med_wag_dina, med_emp_dina, med_inc_ps)
	mat colnames med_dina =  year  	   med_wag_dina  med_emp_dina  med_inc_ps
* Comparison
	clear
	svmat med_cps, names(col)
	tempfile med_cps
	save `med_cps'
	export excel using "$diroutput/temp/cps/med_cps.xlsx", first(var) replace
	clear
	svmat med_dina, names(col)
	tempfile med_dina
	save `med_dina'
	export excel using "$diroutput/temp/cps/med_dina.xlsx", first(var) replace
	merge 1:1 year using `med_cps'
	keep if _merge==3
	drop _merge
	export excel using "$diroutput/temp/cps/med_comparison.xlsx", first(var) replace



* Same comparison but tax-unit level
	* CPS
	foreach year of numlist 1962/2015 {
		use $diroutput/cpstaxunit/cpsmar`year'.dta, clear
		quietly su waginc [w=dweght] if (age>=20 | age_spouse>=20) & waginc>0, meanonly
			local mean_wag_cps`year' = r(mean)
		quietly su waginc [w=dweght] if (age>=20 | age_spouse>=20) & waginc>0, detail
			local med_wag_cps`year' =  r(p50)
		mat med_wag_cpstaxu = (nullmat(med_wag_cpstaxu) \ `med_wag_cps`year'')
		quietly su inctot if (age>=20 | age_spouse>=20) [w=dweght], detail
			local med_inc_cps`year' =  r(p50)
		mat  med_inc_cpstaxu = (nullmat(med_inc_cpstaxu) \ `med_inc_cps`year'')
		local incomeyr = `year' - 1
		mat  year = (nullmat(year) \ `incomeyr')
	}
	mat  		 med_cpstaxu = (year, med_wag_cpstaxu, med_inc_cpstaxu)
	mat colnames med_cpstaxu =  year  med_wag_cpstaxu  med_inc_cpstaxu
* DINA
	foreach year of numlist 1962 1964 1966/2009 {
		local yearcps = `year' + 1
		use $diroutput/dinafiles/usdina`year'.dta, clear
		collapse  (sum) flwag flemp fninc  (mean) dweght, by(id)
		quietly su flwag [w=dweght] if flwag > 0, detail
			local med_wag_dina`year' =  r(p50)
		quietly su flemp [w=dweght] if flemp > 0, detail
			local med_emp_dina`year' =  r(p50)
		quietly su fninc [w=dweght], detail
			local med_inc_ps`year' =  r(p50)
		mat med_wag_dinataxu = (nullmat(med_wag_dinataxu) \ `med_wag_dina`year'')
		mat med_emp_dinataxu = (nullmat(med_emp_dinataxu) \ `med_emp_dina`year'')
		mat med_inc_pstaxu = (nullmat(med_inc_pstaxu) \ `med_inc_ps`year'')
		mat  yeardina = (nullmat(yeardina) \ `year')
	}
	mat  		 med_dinataxu = (yeardina, med_wag_dinataxu, med_emp_dinataxu, med_inc_pstaxu)
	mat colnames med_dinataxu =  year  	   med_wag_dinataxu  med_emp_dinataxu  med_inc_pstaxu
* Comparison
	clear
	svmat med_cpstaxu, names(col)
	tempfile med_cpstaxu
	save `med_cpstaxu'
	export excel using "$diroutput/temp/cps/med_cpstaxu.xlsx", first(var) replace
	clear
	svmat med_dinataxu, names(col)
	tempfile med_dinataxu
	save `med_dinataxu'
	export excel using "$diroutput/temp/cps/med_dinataxu.xlsx", first(var) replace
	merge 1:1 year using `med_cpstaxu'
	keep if _merge==3
	drop _merge
	export excel using "$diroutput/temp/cps/med_comparisontaxu.xlsx", first(var) replace
*/


******************************************
*       Fiscal income equal split
******************************************
foreach taxunitmethod of numlist 0/1 { // loop over methods to create income values for tax unit (see indiv_sum)
																			// 1 if tax-unit level files used are the ones created by summing up variables for all members of tax unit
																		 // 0 if tax-unit level files used are the ones created by keeping the highest earner/couple variables
global indiv_sum = `taxunitmethod' 		// see above for definition of indiv_sum
mat drop _all

	foreach year of numlist 1962/2014 {
		if $indiv_sum == 0{
			use $diroutput/cpstaxunit/cpsmar`year'.dta, clear
			}
		if $indiv_sum == 1{							// if computing with sum over individual variables in tax unit
			use $diroutput/cpstaxunit/indiv_variables/cpsmar`year'.dta, clear
			rename inctotal inctot										 // to use the same code in both cases
			assert married ==0 | married == 1
			}
		local incomeyr = `year' - 1
		di "`year' CPS = INCOME EARNED IN `incomeyr'"


	* Equal split between spouses
		qui gen second=1
		qui replace second=2 if married==1
		qui expand second									// double observations when married
		qui replace dweght = round(dweght)
		qui replace inctot = inctot / 2 if married == 1 

	* Compute average income by bin (0 = all, 1 = top 50%, 2 = top 10, top 5%, etc.n as defined in ado file avgcomp)
		qui avgcomp inctot [w=dweght], matname(avg_fiscal_inc`year')
		qui mat avg_fiscal_inc`year'  = (`incomeyr', avg_fiscal_inc`year')
		qui mat avg_fiscal_inc  = (nullmat(avg_fiscal_inc)  \ avg_fiscal_inc`year')

	* Add average bottom 50% as group 8
		qui cumul inctot [w=dweght], gen(rank_inctot)
		qui su inctot [w=dweght] if rank_inctot <= .5, meanonly
		qui mat bot50`year' = r(mean)
		qui mat bot50 = (nullmat(bot50) \ bot50`year')
		qui mat colnames bot50 = inctot8

	}
		di "AVERAGE FISCAL INCOME BY BIN"
		mat avg_fiscal_inc = (avg_fiscal_inc, bot50)
	* Export results in Excel
		clear
		svmat avg_fiscal_inc, names(col)
		qui compress
		if $indiv_sum == 0 export excel using "$diroutput/temp/cps/avg_fiscal_inc.xlsx", first(var) replace
		if $indiv_sum == 1 export excel using "$diroutput/temp/cps/avg_fiscal_inc_indiv.xlsx", first(var) replace
}


******************************************
*       Fiscal income TAX UNIT level (no equal split)
******************************************
foreach taxunitmethod of numlist 0/1 { // loop over methods to create income values for tax unit (see indiv_sum)
																			// 1 if tax-unit level files used are the ones created by summing up variables for all members of tax unit
																		 // 0 if tax-unit level files used are the ones created by keeping the highest earner/couple variables
global indiv_sum = `taxunitmethod' 		// see above for definition of indiv_sum
mat drop _all

	foreach year of numlist 1962/2014 {
		if $indiv_sum == 0{
			use $diroutput/cpstaxunit/cpsmar`year'.dta, clear
			}
		if $indiv_sum == 1{
			use $diroutput/cpstaxunit/indiv_variables/cpsmar`year'.dta, clear // if computing with sum over individual variables in tax unit
			rename inctotal inctot
			assert married ==0 | married == 1
			}
		local incomeyr = `year' - 1
		di "`year' CPS = INCOME EARNED IN `incomeyr'"

	* Tax unit level, NO SPLIT
		*qui gen second=1
		*qui replace second=2 if married==1
		*qui expand second
		*qui replace inctot = inctot / 2 if married == 1 
		bys tunit: assert (_N == 1 | tunit == .)
		qui replace dweght = round(dweght) // because avgcomp (below) cannot handle non-integer weights

	* Compute average income by bin (0 = all, 1 = top 50%, 2 = top 10, top 5%, etc.n as defined in ado file avgcomp)
		qui avgcomp inctot [w=dweght], matname(avg_fiscal_inc`year')
		qui mat avg_fiscal_inc`year'  = (`incomeyr', avg_fiscal_inc`year')
		qui mat avg_fiscal_inc  = (nullmat(avg_fiscal_inc)  \ avg_fiscal_inc`year')

	* Add average bottom 50% as group 8
		qui cumul inctot [w=dweght], gen(rank_inctot)
		qui su inctot [w=dweght] if rank_inctot <= .5, meanonly
		qui mat bot50`year' = r(mean)
		qui mat bot50 = (nullmat(bot50) \ bot50`year')
		qui mat colnames bot50 = inctot8

	}
		di "AVERAGE FISCAL INCOME BY BIN"
		mat avg_fiscal_inc = (avg_fiscal_inc, bot50)
	* Export results in Excel
		clear
		svmat avg_fiscal_inc, names(col)
		qui compress
		if $indiv_sum == 0 export excel using "$diroutput/temp/cps/avg_fiscal_inc_nosplit.xlsx", first(var) replace
		if $indiv_sum == 1 export excel using "$diroutput/temp/cps/avg_fiscal_inc_indiv_nosplit.xlsx", first(var) replace
}


******************************************
* Money income equal split (Antoine, Oct-Nov-Dec 2016)
******************************************

foreach taxunitmethod of numlist 0/1 { // loop over methods to create income values for tax unit (see indiv_sum)
global indiv_sum = `taxunitmethod' 		// see above for definition of indiv_sum
mat drop _all

	foreach year of numlist 1962/2014 {
		if $indiv_sum == 0{
			use $diroutput/cpstaxunit/cpsmar`year'.dta, clear
			}
		if $indiv_sum == 1{
			use $diroutput/cpstaxunit/indiv_variables/cpsmar`year'.dta, clear
			rename ptotval moneyinctot
			assert married ==0 | married == 1
			}

		local incomeyr = `year' - 1
		di "`year' CPS = INCOME EARNED IN `incomeyr'"

	* Equal split between spouses
		qui gen second=1
		qui replace second=2 if married==1
		qui expand second
		qui replace moneyinctot = moneyinctot / 2 if married == 1
		qui replace dweght = round(dweght)

	* Compute average money income by bin (0 = all, 1 = top 50%, 2 = top 10, top 5%, etc.n as defined in ado file avgcomp)
		qui avgcomp moneyinctot [w=dweght], matname(avg_money_inc`year')
		qui mat avg_money_inc`year'  = (`incomeyr', avg_money_inc`year')
		qui mat avg_money_inc  = (nullmat(avg_money_inc)  \ avg_money_inc`year')


	* Add average bottom 50% as group 8
		qui cumul moneyinctot [w=dweght], gen(rank_moneyinctot)
		qui su moneyinctot [w=dweght] if rank_moneyinctot <= .5, meanonly
		qui mat bot50`year' = r(mean)
		qui mat bot50 = (nullmat(bot50) \ bot50`year')
		qui mat colnames bot50 = moneyinctot8

	}
		di "AVERAGE MONEY INCOME BY BIN"
		mat avg_money_inc = (avg_money_inc, bot50)
	* Export results in Excel
		clear
		svmat avg_money_inc, names(col)
		qui compress
		if $indiv_sum == 0 export excel using "$diroutput/temp/cps/avg_money_inc.xlsx", first(var) replace
		if $indiv_sum == 1 export excel using "$diroutput/temp/cps/avg_money_inc_indiv.xlsx", first(var) replace // if computing with sum over individual variables in tax unit
}

******************************************
* Money income NO equal split (Antoine, Oct-Nov-Dec 2016)
******************************************

foreach taxunitmethod of numlist 0/1 { // loop over methods to create income values for tax unit (see indiv_sum)
global indiv_sum = `taxunitmethod' 		// see above for definition of indiv_sum
mat drop _all

	foreach year of numlist 1962/2014 {
		if $indiv_sum == 0{
			use $diroutput/cpstaxunit/cpsmar`year'.dta, clear
			}
		if $indiv_sum == 1{
			use $diroutput/cpstaxunit/indiv_variables/cpsmar`year'.dta, clear
			rename ptotval moneyinctot
			assert married ==0 | married == 1
			}

		local incomeyr = `year' - 1
		di "`year' CPS = INCOME EARNED IN `incomeyr'"

	* Tax unit level, NO SPLIT
		*		qui gen second=1
		*		qui replace second=2 if married==1
		*		qui expand second
		*		qui replace moneyinctot = moneyinctot / 2 if married == 1
		bys tunit: assert (_N == 1 | tunit == .)
		qui replace dweght = round(dweght)

	* Compute average money income by bin (0 = all, 1 = top 50%, 2 = top 10, top 5%, etc.n as defined in ado file avgcomp)
		qui avgcomp moneyinctot [w=dweght], matname(avg_money_inc`year')
		qui mat avg_money_inc`year'  = (`incomeyr', avg_money_inc`year')
		qui mat avg_money_inc  = (nullmat(avg_money_inc)  \ avg_money_inc`year')


	* Add average bottom 50% as group 8
		qui cumul moneyinctot [w=dweght], gen(rank_moneyinctot)
		qui su moneyinctot [w=dweght] if rank_moneyinctot <= .5, meanonly
		qui mat bot50`year' = r(mean)
		qui mat bot50 = (nullmat(bot50) \ bot50`year')
		qui mat colnames bot50 = moneyinctot8

	}
		di "AVERAGE MONEY INCOME BY BIN"
		mat avg_money_inc = (avg_money_inc, bot50)
	* Export results in Excel
		clear
		svmat avg_money_inc, names(col)
		qui compress
		if $indiv_sum == 0 export excel using "$diroutput/temp/cps/avg_money_inc_nosplit.xlsx", first(var) replace
		if $indiv_sum == 1 export excel using "$diroutput/temp/cps/avg_money_inc_indiv_nosplit.xlsx", first(var) replace // if computing with sum over individual variables in tax unit
}


******************************************
* Compute total number of tax units and "adults" (=2 if married, 1 otherwise) per year
******************************************

mat drop _all
foreach taxunitmethod of numlist 0/1 { // loop over methods to create income values for tax unit (see indiv_sum)
global indiv_sum = `taxunitmethod' 		// see above for definition of indiv_sum

	foreach year of numlist 1962/2014 {
		if $indiv_sum == 0{ 				// no need of this. in both cases, same number of observations (tax units) and adults.
			use $diroutput/cpstaxunit/cpsmar`year'.dta, clear
		}
		if $indiv_sum == 1{
			use $diroutput/cpstaxunit/indiv_variables/cpsmar`year'.dta, clear // if computing with sum over individual variables in tax unit
			}
		local incomeyr = `year' - 1
		di "`year' CPS = INCOME EARNED IN `incomeyr'"

	* Number of tax-units
		qui total dweght	// (estimates the) sum of all the weights for tax units
		matrix b = e(b)		// save the 1x1 matrix of estimates
		local nbofunits = b[1,1]
	* Number of adults  - this uses the weight of the main earner / couple. see use_cps.do
		qui gen second=1
		qui replace second=2 if married==1
		qui expand second
		qui total dweght
		matrix b = e(b)
		local nbofadults = b[1,1]
	* Number of adults and tax units
		qui mat nb_of_tunits`year'  = (`incomeyr',`nbofunits',`nbofadults')
		if $indiv_sum == 0 {
			qui mat nb_of_tunits = (nullmat(nb_of_tunits)  \ nb_of_tunits`year')
			matname nb_of_tunits year nb_of_tunits nb_of_adults, columns(1..3) explicit
		}
		if $indiv_sum == 1 {
			qui mat nb_of_tunits_indiv = (nullmat(nb_of_tunits_indiv)  \ nb_of_tunits`year')
			matname nb_of_tunits_indiv year nb_of_tunits_indiv nb_of_adults_indiv, columns(1..3) explicit
		}

	} // loop over years
} // loop over collapse method
	* Export results in Excel
		di "NUMBER OF TAX UNITS AND ADULTS"
		qui mat nb_of_tunitsall = (nullmat(nb_of_tunits), nullmat(nb_of_tunits_indiv))
		clear
		matname nb_of_tunitsall year nb_of_tunits nb_of_adults year2 nb_of_tunits_indiv nb_of_adults_indiv, columns(1..6) explicit
		svmat nb_of_tunitsall, names(col)
		export excel using "$diroutput/temp/cps/nb_of_taxunits.xlsx", first(var) replace



******************************************
* Checking discrepency between tax-return and CPS bottom 50% share
* by adding the missing aggregate fiscal income to CPS data
* and re-computing the shares
******************************************

mat drop _all
	foreach incomeyr of numlist 1966/2010 {
		use $diroutput/dinafiles/usdina`incomeyr'.dta, clear
		qui total fiinc [w=dweght]						// compute total weighted aggregate fiscal income
		matrix b = e(b)												// ... and saves result in 1x1 matrix
		local taxreturn_total = b[1,1]/100000 // divide because weight are times 100000 in tax data

		local year_cps = `incomeyr'+1
*		use $diroutput/cpsindiv/cpsmar`year'indiv.dta, clear // using individual data (could use tax unit data too)
		use $diroutput/cpstaxunit/indiv_variables/cpsmar`year_cps'.dta, clear // using individual data (could use tax unit data too)
		qui total inctotal [iw=marsupwt]			// compute total weighted aggregate " fiscal" income
		matrix b = e(b)
		local cps_total = b[1,1]

		local missingincome = `taxreturn_total' - `cps_total' // differente between both aggregates
		*assert `missingincome' >= 0				// should be positive because CPS miss a large part of 10%
																				// (however CPS also has institutionalized adults, missing in tax data)

*		use $diroutput/cpstaxunit/cpsmar`year'.dta, clear
		set obs `=_N+1'											// adding an observation with all missing income
		replace inctot =  `missingincome' if _n == _N
		replace dweght = 1 								if _n == _N // give weight of 1
		replace married = 0 							if _n == _N // not married


		di "`year_cps' CPS & `incomeyr' TAX-RETURNS = INCOME EARNED IN `incomeyr'"
		local year = `incomeyr'

	* Equal split between spouses
		qui gen second=1
		qui replace second=2 if married==1
		qui expand second
		qui replace dweght = round(dweght)
		qui replace inctot = inctot / 2 if married == 1 

	* Compute average income by bin (0 = all, 1 = top 50%, 2 = top 10, top 5%, etc.n as defined in ado file avgcomp)
		qui avgcomp inctot [w=dweght], matname(avg_fiscal_inc`year')
		qui mat avg_fiscal_inc`year'  = (`incomeyr', avg_fiscal_inc`year')
		qui mat avg_fiscal_inc  = (nullmat(avg_fiscal_inc)  \ avg_fiscal_inc`year')

	* Add average bottom 50% as group 8
		qui cumul inctot [w=dweght], gen(rank_inctot)
		qui su inctot [w=dweght] if rank_inctot <= .5, meanonly
		qui mat bot50`year' = r(mean)
		qui mat bot50 = (nullmat(bot50) \ bot50`year')
		qui mat colnames bot50 = inctot8

	}
		di "AVERAGE FISCAL INCOME BY BIN"
		mat avg_fiscal_inc = (avg_fiscal_inc, bot50)
	* Export results in Excel
		clear
		svmat avg_fiscal_inc, names(col)
		qui compress
		export excel using "$diroutput/temp/cps/avg_fiscal_inc_indiv_compensated.xlsx", first(var) replace


		******************************************
		*           NO EQUAL SPLIT
		* Checking discrepency between tax-return and CPS bottom 50% share of fiscal income
		* by adding the missing aggregate fiscal income to CPS data
		* and re-computing the shares
		******************************************

		mat drop _all
			foreach incomeyr of numlist 1966/2010 {
				use $diroutput/dinafiles/usdina`incomeyr'.dta, clear
				qui total fiinc [w=dweght]						// compute total weighted aggregate fiscal income
				matrix b = e(b)												// ... and saves result in 1x1 matrix
				local taxreturn_total = b[1,1]/100000 // divide because weight are times 100000 in tax data

				local year_cps = `incomeyr'+1
		*		use $diroutput/cpsindiv/cpsmar`year'indiv.dta, clear // using individual data (could use tax unit data too)
				use $diroutput/cpstaxunit/indiv_variables/cpsmar`year_cps'.dta, clear // using individual data (could use tax unit data too)
				qui total inctotal [iw=marsupwt]			// compute total weighted aggregate " fiscal" income
				matrix b = e(b)
				local cps_total = b[1,1]

				local missingincome = `taxreturn_total' - `cps_total' // differente between both aggregates
				*assert `missingincome' >= 0				// should be positive because CPS miss a large part of 10%
																						// (however CPS also has institutionalized adults, missing in tax data)

		*		use $diroutput/cpstaxunit/cpsmar`year'.dta, clear
				set obs `=_N+1'											// adding an observation with all missing income
				replace inctot =  `missingincome' if _n == _N
				replace dweght = 1 								if _n == _N // give weight of 1
				replace married = 0 							if _n == _N // not married


				di "`year_cps' CPS & `incomeyr' TAX-RETURNS = INCOME EARNED IN `incomeyr'"
				local year = `incomeyr'

			* Tax-unit level: NO EQUAL SPLIT
				*qui gen second=1
				*qui replace second=2 if married==1
				*qui expand second
					*qui replace inctot = inctot / 2 if married == 1 
					bys tunit: assert(_N == 1 | tunit == .)
					qui replace dweght = round(dweght)

			* Compute average income by bin (0 = all, 1 = top 50%, 2 = top 10, top 5%, etc.n as defined in ado file avgcomp)
				qui avgcomp inctot [w=dweght], matname(avg_fiscal_inc`year')
				qui mat avg_fiscal_inc`year'  = (`incomeyr', avg_fiscal_inc`year')
				qui mat avg_fiscal_inc  = (nullmat(avg_fiscal_inc)  \ avg_fiscal_inc`year')

			* Add average bottom 50% as group 8
				qui cumul inctot [w=dweght], gen(rank_inctot)
				qui su inctot [w=dweght] if rank_inctot <= .5, meanonly
				qui mat bot50`year' = r(mean)
				qui mat bot50 = (nullmat(bot50) \ bot50`year')
				qui mat colnames bot50 = inctot8

			}
				di "AVERAGE FISCAL INCOME BY BIN"
				mat avg_fiscal_inc = (avg_fiscal_inc, bot50)
			* Export results in Excel
				clear
				svmat avg_fiscal_inc, names(col)
				qui compress
				export excel using "$diroutput/temp/cps/avg_fiscal_inc_indiv_compensated_nosplit.xlsx", first(var) replace














/*
* Money income equal split from indiv files
mat drop _all
	foreach year of numlist 1962/2015 {

		use $diroutput/cpstaxunit/cpsmar`year'.dta, clear

		local incomeyr = `year' - 1
		di "`year' CPS = INCOME EARNED IN `incomeyr'"
/*
	* Number of tax-units
		qui total dweght	// (estimates the) sum of all the weights for tax units
		matrix b = e(b)		// save the 1x1 matrix of estimates
		local nbofunits = b[1,1]
*		qui mat nb_of_tunits`year'  = (`incomeyr', `nbofunits')
*		qui mat nb_of_tunits = (nullmat(nb_of_tunits)  \ nb_of_tunits`year')
*/
	* Equal split between spouses
		*gen married = (a_spouse!=0)
		*collapse (first) married marsupwt (sum) moneyinctot, by(tunit)
		qui gen second=1
		qui replace second=2 if married==1
		qui expand second
		qui replace moneyinctot = moneyinctot/2 if married == 1

		qui replace dweght = round(dweght)


	* Compute average money income by bin (0 = all, 1 = top 50%, 2 = top 10, top 5%, etc.n as defined in ado file avgcomp)
		qui avgcomp moneyinctot [w=dweght], matname(avg_money_inc`year')
		qui mat avg_money_inc`year'  = (`incomeyr', avg_money_inc`year')
		qui mat avg_money_inc  = (nullmat(avg_money_inc)  \ avg_money_inc`year')


	* Add average bottom 50% as group 8
		qui cumul moneyinctot [w=dweght], gen(rank_moneyinctot)
		qui su moneyinctot [w=dweght] if rank_moneyinctot <= .5, meanonly
		qui mat bot50`year' = r(mean)
		qui mat bot50 = (nullmat(bot50) \ bot50`year')
		qui mat colnames bot50 = moneyinctot8


/*	* Number of adults and tax units
		qui mat nb_of_tunits`year'  = (`incomeyr',`nbofunits',`nbofadults')
		qui mat nb_of_tunits = (nullmat(nb_of_tunits)  \ nb_of_tunits`year')
*/
	}
		di "AVERAGE FISCAL INCOME BY BIN"
		mat avg_money_inc = (avg_money_inc, bot50)
	* Export results in Excel
		clear
		svmat avg_money_inc, names(col)
		qui compress
		export excel using "$diroutput/temp/cps/avg_money_inc_taxu.xlsx", first(var) replace
