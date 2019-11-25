* CPS SUMMARY STATS AND COMPARISON WITH DINA USING CPS-NBER AND CPS-IPUMS DATA

*****************************************************
* NUMBER OF INDIVIDUALS AND MARRIED COUPLES
*****************************************************
* Compute weighted number of individuals and weighted number of married people in indiv files
mat drop _all
foreach year of numlist 1962/2015 { // file years
	local incomeyr = `year' - 1

	* IPUMS data (swap)
	if `year' < 1980 local nbofindividuals = 0
	if `year' < 1980 local nbofmarried = 0
	if `year' < 1980 local nbofmarried2 = 0	
	if `year'>=1980{
		use "$diroutput/cpsindiv/ipums/cpsmar`year'indiv_swap.dta", clear
		cap rename marsupwt dweght
		* Number of individuals
		qui total dweght	// (estimates the) sum of all the weights (individuals)
		matrix b = e(b)		// save the 1x1 matrix of estimates
		local nbofindividuals = b[1,1]
		qui total dweght if sploc != 0
		matrix b = e(b)		
		local nbofmarried = b[1,1]
		qui total dweght if a_spouse != 0 & a_spouse != .
		matrix b = e(b)		
		local nbofmarried2 = b[1,1]
		}
	qui mat nb_`year'  = (`incomeyr',`nbofindividuals',`nbofmarried', `nbofmarried2')
	qui mat nb_of_people = (nullmat(nb_of_people)  \ nb_`year')
	matname nb_of_people year_swap individuals_swap married_sploc_swap married_spouse_swap, columns(1..4) explicit

	* IPUMS data (no swap)
	if `year' < 1980 local nbofindividuals = 0
	if `year' < 1980 local nbofmarried = 0
	if `year' < 1980 local nbofmarried2 = 0	
	if `year'>=1980{
	use "$diroutput/cpsindiv/ipums/cpsmar`year'indiv_noswap.dta", clear
	cap rename marsupwt dweght
	* Number of individuals
	qui total dweght	
	matrix b = e(b)		
	local nbofindividuals = b[1,1]
	qui total dweght if sploc != 0
	matrix b = e(b)		
	local nbofmarried = b[1,1]
	qui total dweght if a_spouse != 0 & a_spouse != .
	matrix b = e(b)		
	local nbofmarried2 = b[1,1]
	}
	qui mat nb_`year'_noswap  = (`incomeyr',`nbofindividuals',`nbofmarried', `nbofmarried2')
	qui mat nb_of_people_noswap = (nullmat(nb_of_people_noswap)  \ nb_`year'_noswap)
	matname nb_of_people_noswap year_noswap individuals_noswap married_sploc_noswap married_spouse_noswap, columns(1..4) explicit

	* NBER
	use "$diroutput/cpsindiv/cpsmar`year'indiv.dta", clear
	cap rename marsupwt dweght
	* Number of individuals
	qui total dweght	
	matrix b = e(b)		
	local nbofindividuals_nber = b[1,1]
	qui total dweght if a_spouse != 0 & a_spouse != .
	matrix b = e(b)		
	local nbofmarried2_nber = b[1,1]
	qui mat nb_`year'_nber  = (`incomeyr',`nbofindividuals_nber', `nbofmarried2_nber')
	qui mat nb_of_people_nber = (nullmat(nb_of_people_nber)  \ nb_`year'_nber)
	matname nb_of_people_nber year_nber individuals_nber married_spouse_nber, columns(1..3) explicit
}
clear
qui mat nb_of_people_all = (nullmat(nb_of_people), nullmat(nb_of_people_noswap), nullmat(nb_of_people_nber), nullmat(nboftaxunits_nber_larrimore))
svmat nb_of_people_all, names(col)
assert year_swap == year_nber
assert year_swap == year_noswap
drop year_nber year_noswap
export excel using "$diroutput/temp/cps/nb_married_indiv.xlsx", first(var) replace


*****************************************************
* NUMBER OF TAX UNITS
*****************************************************
* Compute number of tax units
mat drop _all
foreach year of numlist 1962/2015 { // file years

	local incomeyr = `year' - 1

	* IPUMS SWAP
	if `year' < 1980 local nboftaxunits_swap = 0
	if `year'>=1980{
	use "$diroutput/cpstaxunit/ipums/juliana/cpsmar`year'_swap.dta", clear
	* Number of tax units
	qui total dweght	
	matrix b = e(b)		
	local nboftaxunits_swap = b[1,1]
	}
	qui mat nb_`year'  = (`incomeyr',`nboftaxunits_swap')
	qui mat nb_of_people_swap = (nullmat(nb_of_people_swap)  \ nb_`year')
	matname nb_of_people_swap year_swap nboftaxunits_swap, columns(1..2) explicit

	* IPUMS SWAP
	if `year' < 1980 local nboftaxunits_noswap = 0	
	if `year'>=1980{
	use "$diroutput/cpstaxunit/ipums/juliana/cpsmar`year'_noswap.dta", clear
	* Number of tax units
	qui total dweght	
	matrix b = e(b)		
	local nboftaxunits_noswap = b[1,1]
	}
	qui mat nb_`year'  = (`incomeyr',`nboftaxunits_noswap')
	qui mat nb_of_people_noswap = (nullmat(nb_of_people_noswap)  \ nb_`year')
	matname nb_of_people_noswap year_noswap nboftaxunits_noswap, columns(1..2) explicit

	* NBER
	use "$diroutput/cpstaxunit/juliana/cpsmar`year'.dta", clear
	* Number of tax units
	qui total dweght	
	matrix b = e(b)		
	local nboftaxunits = b[1,1]
	qui mat nb_`year'  = (`incomeyr',`nboftaxunits')
	qui mat nb_of_people_nber = (nullmat(nb_of_people_nber)  \ nb_`year')
	matname nb_of_people_nber year_nber nboftaxunits_nber, columns(1..2) explicit


	* USDINA	
	if `incomeyr'>2010 local nboftaxunits = 0					// because no data after 2010
	if `incomeyr' <= 2010{
		if `incomeyr' <= 1965 local nboftaxunits = 0			// because 1963 and 1965 are missing, so I just discard years before 1965
		if `incomeyr' > 1965{
			use "$diroutput/dinafiles/usdina`incomeyr'.dta", clear
			* Number of tax units
			bys id: assert dweght == dweght[1]					// check that all observations for a given tax unit (id=tax unit id) has same weight
			egen tag = tag(id)									// tag only one observation per tax unit
			qui total dweght if tag == 1
			matrix b = e(b)
			local nboftaxunits = b[1,1]/100000 					// because USDINA multiplies weights by 100000 (to get integer weights)
		}
	}
	qui mat nb_`year'  = (`incomeyr',`nboftaxunits')
	qui mat nb_of_people_dina = (nullmat(nb_of_people_dina)  \ nb_`year')
	matname nb_of_people_dina year_dina nboftaxunits_dina, columns(1..2) explicit


	* small files (IRS public files)	
	if `incomeyr'>2010 local nboftaxunits = 0					// because no data after 2010
	if `incomeyr' <= 2010{
		if `incomeyr' <= 1965 local nboftaxunits = 0			// because 1963 and 1965 are missing, so I just discard years before 1965
		if `incomeyr' > 1965{
			use "$diroutput/small/small`incomeyr'.dta", clear
			* Number of tax units
			qui total dweght
			matrix b = e(b)
			local nboftaxunits = b[1,1]/100000 					// because small files multiplie weights by 100000 (to get integer weights)
		}
	}
	qui mat nb_`year'  = (`incomeyr',`nboftaxunits')
	qui mat nb_of_people_small = (nullmat(nb_of_people_small)  \ nb_`year')
	matname nb_of_people_small year_small nboftaxunits_small, columns(1..2) explicit

	* small files (IRS public files) w/ dweghttaxu	
	if `incomeyr'>2010 local nboftaxunits = 0					// because no data after 2010
	if `incomeyr' <= 2010{
		if `incomeyr' <= 1965 local nboftaxunits = 0			// because 1963 and 1965 are missing, so I just discard years before 1965
		if `incomeyr' > 1965{
			use "$diroutput/small/small`incomeyr'.dta", clear
			* Number of tax units
			qui total dweghttaxu
			matrix b = e(b)
			local nboftaxunits = b[1,1]/100000 					// because small files multiplie weights by 100000 (to get integer weights)
		}
	}
	qui mat nb_`year'  = (`incomeyr',`nboftaxunits')
	qui mat nb_of_people_small2 = (nullmat(nb_of_people_small2)  \ nb_`year')
	matname nb_of_people_small2 year_small2 nboftaxunits_tu, columns(1..2) explicit

}
clear
qui mat nb_of_people_all = (nullmat(nb_of_people_swap), nullmat(nb_of_people_noswap), nullmat(nb_of_people_nber), nullmat(nb_of_people_dina), nullmat(nb_of_people_small), nullmat(nb_of_people_small2))
svmat nb_of_people_all, names(col)
drop year_nber year_noswap year_dina year_small year_small2
rename year_swap year
export excel using "$diroutput/temp/cps/nb_taxunits_juliana.xlsx", first(var) replace



*****************************************************
* Program creating excel files with distributions
*****************************************************
capture program drop create_distrib
program define create_distrib
	* first argument gives the file to open
	* second argument gives the extension of file to open
	* the year will go in between first and second arguments. example: nameoffileYEAR.dta or nameoffileYEARindiv.dta
	* third argument gives the file to save to
	* fourth argument gives the income variable
	* fifth argument gives the weight variable
	* sixth argument gives equal split or not
	* seventh argument gives the begining year
	* eighth argument gives the end year

	args used_file extension saved_file income_var weight_var equal_split year_beg year_end

	mat drop _all	
	
	foreach year of numlist `year_beg'/`year_end' { // CPS year
		* open file
		local filename "`used_file'`year'`extension'"
		use "`filename'", clear
		
		disp "using `filename'"
		qui: sum `income_var'
		qui: sum `weight_var'
		
		* define income variable
		rename `income_var' income

		* Equal split between spouses
		if "`equal_split'"== "split"{
				disp "equal split" 
				qui gen second=1
				qui replace second=2 if married==1
				qui expand second
				qui replace income = income / 2 if married == 1 // fixme. make sure a_spouse == . did not give married == 1
		}
		if "`equal_split'"== "nosplit"{
				disp "no split"
		}

		if ("`equal_split'" != "nosplit" & "`equal_split'" != "split"){
			disp "problem with split/nosplit argument"
			exit
		} 

		* define weight as dweght variable (first delete dweght if it already exists)
		gen weight_temp =  `weight_var'
		cap drop dweght
		gen dweght = weight_temp
		qui drop if dweght < 0
		qui replace dweght = round(dweght)				// because weighting in avgcomp program needs integers 
		
		local incomeyr = `year' - 1
		di "`year' CPS = INCOME EARNED IN `incomeyr'"

		* Compute average income by bin (0 = all, 1 = top 50%, 2 = top 10, top 5%, etc.n as defined in ado file avgcomp)
		qui avgcomp income [w=dweght], matname(avg_pretax_inc`year')
		qui mat avg_pretax_inc`year'  = (`incomeyr', avg_pretax_inc`year')
		qui mat avg_pretax_inc  = (nullmat(avg_pretax_inc)  \ avg_pretax_inc`year')

		* Add average bottom 50% as group 8
		qui cumul income [w=dweght], gen(rank_inctot)
		qui su income [w=dweght] if rank_inctot <= .5, meanonly
		qui mat bot50`year' = r(mean)
		qui mat bot50 = (nullmat(bot50) \ bot50`year')
		qui mat colnames bot50 = inctot8

		}

	di "AVERAGE FISCAL INCOME BY BIN"
	mat avg_pretax_inc = (avg_pretax_inc, bot50)
	* Export results in Excel
	clear
	svmat avg_pretax_inc, names(col)
	qui compress
	export excel using "`saved_file'", first(var) replace

	end



**********************************************************************************************************
* 									NO SPLIT
**********************************************************************************************************


*****************************************************
* FISCAL INCOME NBER (WITH TAX UNIT A LA JULIANA)
*****************************************************
* Fiscal income (NBER) NO split - Juliana units
create_distrib "$diroutput/cpstaxunit/juliana/cpsmar" ".dta" /// 
				"$diroutput/temp/cps/avg_fiscal_inc_nosplit_nber_juliana.xlsx" ///
				"incfiscal" "dweght" "nosplit" "1962" "2015"


*****************************************************
* MONEY INCOME NBER (WITH TAX UNIT A LA JULIANA)
*****************************************************
* Money income (NBER) NO split - Juliana units
create_distrib "$diroutput/cpstaxunit/juliana/cpsmar" ".dta" /// 
				"$diroutput/temp/cps/avg_money_inc_nosplit_nber_juliana.xlsx" ///
				"ptotval" "dweght" "nosplit" "1962" "2015"



**********************************************************************************************************
* 									EQUAL SPLIT
**********************************************************************************************************


*****************************************************
* FISCAL INCOME NBER (WITH TAX UNIT A LA JULIANA) EQUAL SPLIT
*****************************************************
* Fiscal income (NBER) EQUAL SPLIT - Juliana units
create_distrib "$diroutput/cpstaxunit/juliana/cpsmar" ".dta" /// 
				"$diroutput/temp/cps/avg_fiscal_inc_split_nber_juliana.xlsx" ///
				"incfiscal" "dweght" ///
				"split" ///
				"1962" "2015"


*****************************************************
* MONEY INCOME NBER (WITH TAX UNIT A LA JULIANA) EQUAL SPLIT
*****************************************************
* Money income (NBER) EQUAL SPLIT - Juliana
create_distrib "$diroutput/cpstaxunit/juliana/cpsmar" ".dta" /// 
				"$diroutput/temp/cps/avg_money_inc_split_nber_juliana.xlsx" ///
				"ptotval" "dweght" ///
				"split" ///
				"1962" "2015"




**********************************************************************************************************
* 									COMPENSATION FROM SMALL.DTA FILES (AGGREGATE OR TOP 10%)
**********************************************************************************************************



******************************************
* Checking discrepency between tax-return and CPS bottom 50% share
* by adding the missing aggregate fiscal income from small files
* to CPS data and re-computing the shares
******************************************
* Fiscal income (NBER) NO SPLIT - Juliana units / Compensated (= addition of one synthetic observation from small files)

mat drop _all
*	foreach incomeyr of numlist 1966/2015 { 		// small has missing files before 1966 (1963 and 1965 are missing)
	foreach incomeyr of numlist 1966/2010 {

	* Get fiscal income aggregate from USDINA files
		use "$diroutput/small/small`incomeyr'.dta", clear
		qui total income [w=dweghttaxu]						
		matrix b = e(b)												
		local taxreturn_total = b[1,1]/100000    // /100000 because weights are multiplied by 100000 in USDINA (to get integer weights)

	* Get fiscal income aggregate from CPS files
		local year_cps = `incomeyr'+1
		use "$diroutput/cpstaxunit/juliana/cpsmar`year_cps'.dta", clear 
		rename incfiscal inctot
		qui total inctot [iw=dweght]			// compute total weighted aggregate " fiscal" income
		matrix b = e(b)
		local cps_total = b[1,1]

	* Compute difference between aggregates
		local missingincome = `taxreturn_total' - `cps_total' // differente between both aggregates
		*assert `missingincome' >= 0				// should be positive because CPS miss a large part of 10%
													// (however CPS also has institutionalized adults, missing in tax data)

	* Save difference of aggregates in missing_income.dta file as a record
		preserve
			use "$diroutput/temp/cps/missing_income.dta", clear
			replace missing_income_agg = `missingincome' if year == `incomeyr'
			save "$diroutput/temp/cps/missing_income.dta", replace
		restore

	* Computes the shares
		di "`year_cps' CPS & `incomeyr' TAX-RETURNS = INCOME EARNED IN `incomeyr'"
		local year = `incomeyr'

	
	* Add synthetic observation with fiscal income = difference between aggregate (missing income)
	*	use $diroutput/cpstaxunit/cpsmar`year'.dta, clear
		set obs `=_N+1'											// adding an observation with all missing income
		replace inctot =  `missingincome' 			    if _n == _N
		replace dweght = 1 								if _n == _N // give weight of 1
		replace married = 0 							if _n == _N // not married
		*assert `missingincome' >= 0 // not true


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
export excel using "$diroutput/temp/cps/avg_fiscal_inc_nosplit_nber_juliana_comp.xlsx", first(var) replace

/*
******************************************
* FISCAL INCOME NO SPLIT SWAPPING TOP 10 (IRS to CPS)
******************************************
* Fiscal income (NBER) NO SPLIT - Juliana units

mat drop _all
*	foreach incomeyr of numlist 1966/2015 {
	foreach incomeyr of numlist 1966/2010 {			// small has no files after 2010; 1963 and 1965 are missing

	local year_cps = `incomeyr' + 1

	* Get total weights in CPS ro reweight small files
	use "$diroutput/cpstaxunit/juliana/cpsmar`year_cps'.dta", clear
		qui total dweght
		matrix b = e(b)
		local weight_cps = b[1,1]
		disp "total weight cps: " `weight_cps'

	* Get top 10% total fiscal income  from small files
		use "$diroutput/small/small`incomeyr'.dta", clear
		qui: replace dweghttaxu = dweghttaxu / 100000
		qui total dweghttaxu
		matrix b = e(b)
		local weight_small = b[1,1]
		disp "total weight small: " `weight_small'

		qui: replace dweghttaxu = dweghttaxu * `weight_cps' / `weight_small'

		_pctile income [iweight = dweghttaxu], p(90) 
		// could write instead: 
		* cumul income [weight=dweghttaxu], gen(cum)
		* sum income [iweight=dweghttaxu] if cum >=0.9
		local threshold_small = `r(r1)'
		_pctile income [iweight = dweghttaxu], p(50) 
		// could write instead: 
		* cumul income [weight=dweghttaxu], gen(cum)
		* sum income [iweight=dweghttaxu] if cum >=0.9
		local median_small = `r(r1)'


		qui total income [iweight = dweghttaxu] if income >= `threshold_small'
		matrix b = e(b)
		local top10inc_small = b[1,1] // no need to divide by 100000 because has been reweighted already
		disp "top10 inc in small: " `top10inc_small'
		qui total income [iweight = dweghttaxu] if income >= `median_small'
		matrix b = e(b)
		local bot50inc_small = b[1,1] // no need to divide by 100000 because has been reweighted already
		
		qui: keep if income  >= `threshold_small'
		qui: keep dweghttaxu income married
		qui: rename income inctot // for merge to come
		qui: rename dweghttaxu dweght
		save "$diroutput/cpstaxunit/juliana/smalltop10temp.dta", replace  

	* Get top 10% total fiscal income  from CPS files
		use "$diroutput/cpstaxunit/juliana/cpsmar`year_cps'.dta", clear
		rename incfiscal inctot
		_pctile inctot [iweight = dweght], p(90)
		local threshold_cps = `r(r1)'
		_pctile inctot [iweight = dweght], p(50)
		local median_cps = `r(r1)'

		qui total inctot [iweight = dweght] if inctot >= `threshold_cps'
		matrix b = e(b)
		local top10inc_cps = b[1,1]
		disp "top10 inc in cps: " `top10inc_cps'
		qui total inctot [iweight = dweght] if inctot >= `median_cps'
		matrix b = e(b)
		local bot50inc_cps = b[1,1]

	* Compute difference between top 10% aggregates
		local missingincome = `top10inc_small' - `top10inc_cps' 		// difference between both aggregates
		*assert `missingincome' >= 0									// should be positive because CPS misses a large part of 10%
		disp "missing income: " `missingincome'							// (however CPS also has institutionalized adults which are missing in tax data)
		disp "threshold cps : " `threshold_cps'
		disp "threshold small: " `threshold_small'
		local missingbot50 = `bot50inc_small' - `bot50inc_cps'

	* Save difference of aggregate top 10% in missing_income.dta file as a record
		preserve
			use "$diroutput/temp/cps/missing_income.dta", clear
			replace missing_income_top10 = `missingincome' if year == `incomeyr'
			replace missing_income_bot50 = `missingbot50' if year == `incomeyr'
			save "$diroutput/temp/cps/missing_income.dta", replace
		restore

	* Computes the shares
		di "`year_cps' CPS & `incomeyr' TAX-RETURNS = INCOME EARNED IN `incomeyr'"
		local year = `incomeyr'

	* Drop variables in top 10 and replace them with top 10% small files observations
		qui drop if inctot >= `threshold_cps'
		append using "$diroutput/cpstaxunit/juliana/smalltop10temp.dta", keep(dweght inctot married)
		erase "$diroutput/cpstaxunit/juliana/smalltop10temp.dta"


		replace dweght = round(dweght)
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
export excel using "$diroutput/temp/cps/avg_fiscal_inc_nosplit_nber_juliana_comp10.xlsx", first(var) replace
*/

******************************************
* FISCAL INCOME NO SPLIT SWAPPING TOP 10 (IRS to CPS)
******************************************
* Fiscal income (NBER) NO SPLIT - Juliana units - Top 10 swapped with small files
create_distrib "$diroutput/cpstaxunit/cps_smalltop10/cps" "_smalltop10.dta" /// 
				"$diroutput/temp/cps/avg_fiscal_inc_nosplit_nber_juliana_comp10.xlsx" ///
				"incfiscal" "dweght" ///
				"nosplit" ///
				"1967" "2011"				 // fiscal years 1966 to 2010 (small files has no files after 2010; 1963 and 1965 are missing)


******************************************
* FISCAL INCOME EQUAL SPLIT SWAPPING TOP 10 (IRS to CPS)
******************************************
* Fiscal income (NBER) EQUAL SPLIT - Juliana units

mat drop _all
*	foreach incomeyr of numlist 1966/2015 {
	foreach incomeyr of numlist 1966/2010 {			// small has no files after 2010; 1963 and 1965 are missing

	local year_cps = `incomeyr' + 1

	* Get total weights in CPS ro reweight small files
	use "$diroutput/cpstaxunit/juliana/cpsmar`year_cps'.dta", clear
		qui total dweght
		matrix b = e(b)
		local weight_cps = b[1,1]

	* Get top 10% total fiscal income  from small files
		use "$diroutput/small/small`incomeyr'.dta", clear
		qui: replace dweght = dweght / 100000
		qui total dweght
		matrix b = e(b)
		local weight_small = b[1,1]

		qui: replace dweght = dweght * `weight_cps' / `weight_small'

		_pctile income [iweight = dweght], p(90) // could write instead: cumul income [weight=dweght], gen(cum) and sum income [iweight=dweght] if cum >=0.9
		local threshold_small = `r(r1)'

		qui total income [iweight = dweght] if income >= `threshold_small'
		matrix b = e(b)
		local top10inc_small = b[1,1] // no need to divide by 100000 because has been reweighted already
		
		qui: keep if income  >= `threshold_small'
		qui: keep dweght income married
		qui: rename income inctot // for merge to come
		save "$diroutput/cpstaxunit/juliana/smalltop10temp.dta", replace  

	* Get top 10% total fiscal income  from CPS files
		use "$diroutput/cpstaxunit/juliana/cpsmar`year_cps'.dta", clear
		rename incfiscal inctot
		_pctile inctot [iweight = dweght], p(90)
		local threshold_cps = `r(r1)'
		qui total inctot [iweight = dweght] if inctot >= `threshold_cps'
		matrix b = e(b)
		local top10inc_cps = b[1,1]

	* Compute difference between aggregates
		local missingincome = `top10inc_small' - `top10inc_cps' 		// difference between both aggregates
		*assert `missingincome' >= 0									// should be positive because CPS misses a large part of 10%
		disp "missing income: " `missingincome'							// (however CPS also has institutionalized adults which are missing in tax data)
		disp "threshold cps : " `threshold_cps'
		disp "threshold small: " `threshold_small'

	* Drop variables in top 10 and replace them with top 10% small observations
		qui drop if inctot >= `threshold_cps'
		append using "$diroutput/cpstaxunit/juliana/smalltop10temp.dta", keep(dweght inctot married)
		erase "$diroutput/cpstaxunit/juliana/smalltop10temp.dta"

		di "`year_cps' CPS & `incomeyr' TAX-RETURNS = INCOME EARNED IN `incomeyr'"
		local year = `incomeyr'

	* Equal split between spouses
		qui gen second=1
		qui replace second=2 if married==1
		qui expand second
		qui replace dweght = round(dweght)
		qui replace inctot = inctot / 2 if married == 1 // fixme. make sure a_spouse == . did not give married == 1

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
		export excel using "$diroutput/temp/cps/avg_fiscal_inc_split_nber_juliana_comp10.xlsx", first(var) replace

******************************************
* FISCAL INCOME EQUAL SPLIT SWAPPING TOP 10 (IRS to CPS)
******************************************
* Fiscal income (NBER) EQUAL SPLIT - Juliana units
create_distrib "$diroutput/cpstaxunit/cps_smalltop10/cps" "_smalltop10.dta" /// 
				"$diroutput/temp/cps/avg_fiscal_inc_split_nber_juliana_comp10.xlsx" ///
				"incfiscal" "dweght" ///
				"split" ///
				"1967" "2011"				 // fiscal years 1966 to 2010 (small files has no files after 2010; 1963 and 1965 are missing)


/*
******************************************
* Checking discrepency between tax-return and CPS bottom 50% share
* by adding the missing aggregate fiscal income from USDINA
* to CPS data and re-computing the shares
******************************************
* Fiscal income (NBER) EQUAL SPLIT - Juliana units / Compensated (= addition of one synthetic observation)

mat drop _all
*	foreach incomeyr of numlist 1966/2015 { 		// USDINA has missing files before 1966 (1963 and 1965 are missing)
	foreach incomeyr of numlist 1979/2015 {

	* Get fiscal income aggregate from USDINA files
		use "$diroutput/dinafiles/usdina`incomeyr'.dta", clear
		qui total fiinc [w=dweght]						
		matrix b = e(b)												
		local taxreturn_total = b[1,1]/100000    // /100000 because weights are multiplied by 100000 in USDINA (to get integer weights)

	* Get fiscal income aggregate from CPS files
		local year_cps = `incomeyr'+1
*		use "$diroutput/cpsindiv/cpsmar`year'indiv.dta", clear // using individual data (could use tax unit data too)
		use "$diroutput/cpstaxunit/juliana/cpsmar`year_cps'.dta", clear 
		rename incfiscal inctot
		qui total inctot [iw=dweght]			// compute total weighted aggregate " fiscal" income
		matrix b = e(b)
		local cps_total = b[1,1]

	* Compute difference between aggregates
		local missingincome = `taxreturn_total' - `cps_total' // differente between both aggregates
		*assert `missingincome' >= 0				// should be positive because CPS miss a large part of 10%
													// (however CPS also has institutionalized adults, missing in tax data)
	
	* Add synthetic observation with fiscal income = difference between aggregate (missing income)
*		use $diroutput/cpstaxunit/cpsmar`year'.dta, clear
		set obs `=_N+1'											// adding an observation with all missing income
		replace inctot =  `missingincome' 			if _n == _N
		replace dweght = 1 								if _n == _N // give weight of 1
		replace married = 0 							if _n == _N // not married


		di "`year_cps' CPS & `incomeyr' TAX-RETURNS = INCOME EARNED IN `incomeyr'"
		local year = `incomeyr'

	* Equal split between spouses
		qui gen second=1
		qui replace second=2 if married==1
		qui expand second
		qui replace dweght = round(dweght)
		qui replace inctot = inctot / 2 if married == 1 // fixme. make sure a_spouse == . did not give married == 1

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
		export excel using "$diroutput/temp/cps/avg_fiscal_inc_split_nber_juliana_comp_dina.xlsx", first(var) replace
*/


/*
******************************************
* Checking discrepency between tax-return and CPS bottom 50% share
* by adding the missing aggregate fiscal income from small files
* to CPS data and re-computing the shares
******************************************
* Fiscal income (NBER) EQUAL SPLIT - Juliana units / Compensated (= addition of one synthetic observation)

mat drop _all
*	foreach incomeyr of numlist 1966/2015 { 		// small has missing files before 1966 (1963 and 1965 are missing)
	foreach incomeyr of numlist 1966/2010 {

	* Get fiscal income aggregate from USDINA files
		use "$diroutput/small/small`incomeyr'.dta", clear
		qui total income [w=dweghttaxu]						
		matrix b = e(b)												
		local taxreturn_total = b[1,1]/100000    // /100000 because weights are multiplied by 100000 in USDINA (to get integer weights)

	* Get fiscal income aggregate from CPS files
		local year_cps = `incomeyr'+1
		use "$diroutput/cpstaxunit/juliana/cpsmar`year_cps'.dta", clear 
		rename incfiscal inctot
		qui total inctot [iw=dweght]			// compute total weighted aggregate " fiscal" income
		matrix b = e(b)
		local cps_total = b[1,1]

	* Compute difference between aggregates
		local missingincome = `taxreturn_total' - `cps_total' // differente between both aggregates
		*assert `missingincome' >= 0				// should be positive because CPS miss a large part of 10%
													// (however CPS also has institutionalized adults, missing in tax data)
	
	* Add synthetic observation with fiscal income = difference between aggregate (missing income)
*		use $diroutput/cpstaxunit/cpsmar`year'.dta, clear
		set obs `=_N+1'											// adding an observation with all missing income
		replace inctot =  `missingincome' 			if _n == _N
		replace dweght = 1 								if _n == _N // give weight of 1
		replace married = 0 							if _n == _N // not married


		di "`year_cps' CPS & `incomeyr' TAX-RETURNS = INCOME EARNED IN `incomeyr'"
		local year = `incomeyr'

	* Equal split between spouses
		qui gen second=1
		qui replace second=2 if married==1
		qui expand second
		qui replace dweght = round(dweght)
		qui replace inctot = inctot / 2 if married == 1 // fixme. make sure a_spouse == . did not give married == 1

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
		export excel using "$diroutput/temp/cps/avg_fiscal_inc_split_nber_juliana_comp.xlsx", first(var) replace
*/

