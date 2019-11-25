* Nov. 2018: Fix Fiscal income / Pre-tax income ratio at the very top
* Assume that DINA generates correct top 400 wealth (and hence correct top 400 pre-tax income) 
* (This assumption is consistent with fact that top 400 wealth DINA ~ top 400 Forbes wealth)
* But ranking problem: DINA top 400 has by construction high fiscal income, while true top 400 has low fiscal / pre-tax income ratio
* Fix here based on internal computations suggesting true top 400 fiscal/pre-tax income ratio ~ 45% 
* Assume constant over time (the very top always mostly has C-corp equity >> sturcturally low fiscal/pre-tax ratios)
* This creates two new variables: fiinc_fixed400 and ditax_fixed400

foreach yr of numlist $years { 

	use peinc hweal fiinc ditax dweght* id married using "$dirusdina/usdina`yr'.dta" , clear

// Collapse at tax unit level
	collapse (sum) peinc hweal fiinc ditax (mean) dweght* married, by(id)
	* replace dweght = dweghttaxu
	qui sum dweght, mean 
		local total_pop = round(r(sum) / 1e5, 1)
		di "Total population in `yr' = `total_pop' tax units"
	qui sum hweal [w=dweght], mean
		local total_wealth = r(sum)

// Compute top 400 share of pre-tax income, wealth, and average fiscal/pre-tax income ratio 
	qui sum peinc [w=dweght], mean
		local total_peinc = r(sum) 
	qui cumul peinc [fw=dweght], gen(cum) freq
	qui keep if cum >= (`total_pop' - 400) * 1e5
	qui sum dweght, mean
		local nb_top400 = r(sum) / 1e5
		local nb_records = r(N)
		di "Number of top 400 in file in `yr' = `nb_top400' tax units"
		di "Number of records for top 400 in `yr' = `nb_records'"
	qui sum peinc [w=dweght], mean
		local total_peinc_top400 = r(sum)
		local share_inc_top400 = round(100 * `total_peinc_top400' / `total_peinc', 0.01)
		di "Share of pre-tax income earned by top 400 in `yr' = `share_inc_top400'%"
	qui sum hweal [w=dweght], mean
		local share_wealth_top400 = round(100 * r(sum) / `total_wealth', 0.01)
		di "Share of wealth earned by top 400 in `yr' = `share_wealth_top400'%"
	qui sum fiinc [w=dweght], mean
		local ratio_fiscal_pretax = round(r(sum) / `total_peinc_top400', 0.001)
		di "Raw fiscal income / pre-tax income ratio for top 400 in `yr' = `ratio_fiscal_pretax'"

// Replace fiscal income by constant fraction of pre-tax income and scale income taxes proportionally
	qui gen fiinc_fixed400 = min(0.45, `ratio_fiscal_pretax') * peinc
	qui sum fiinc_fixed400 [w=dweght], mean
		local ratio_fiscal_pretax_corr = round(r(sum) / `total_peinc_top400', 0.001)
		di "Corrected fiscal income / pre-tax income ratio for top 400 in `yr' = `ratio_fiscal_pretax_corr'"
	qui gen ditax_fixed400 = ditax * fiinc_fixed400 / fiinc
	qui compress
	qui save "$diroutput/temp/top400_`yr'.dta", replace

// Merge corrected top 400 to DINA files
	use "$dirusdina/usdina`yr'.dta" , clear
	cap drop ditax_fixed400 fiinc_fixed400
	merge m:1 id using $diroutput/temp/top400_`yr'.dta
	qui bys id: egen ditax_taxu = sum(ditax)
	qui bys id: egen fiinc_taxu = sum(fiinc)
	replace ditax_fixed400 = ditax_fixed400 * ditax / ditax_taxu if _merge == 3
	replace fiinc_fixed400 = fiinc_fixed400 * fiinc / fiinc_taxu if _merge == 3
	drop _merge ditax_taxu fiinc_taxu
	qui replace ditax_fixed400 = ditax if ditax_fixed == .
	qui replace fiinc_fixed400 = fiinc if fiinc_fixed == .

// 	Reallocate missing fiscal income 
	qui sum fiinc [w=dweght], mean
		local total_fiinc = r(sum)
		di round(`total_fiinc', 1e5) 
	qui sum fiinc_fixed400 [w=dweght], mean
		local total_fiinc_corr = r(sum) 
	local income_removed = round((`total_fiinc' - `total_fiinc_corr') / 10e10)
		di "Fiscal income removed from top 400 in `yr' = $`income_removed' million"
	qui replace fiinc_fixed400 = fiinc_fixed400 * `total_fiinc' / `total_fiinc_corr'
	qui sum fiinc_fixed400 [w=dweght], mean
	* assert round(r(sum), 1e10) == round(`total_fiinc', 1e10) 

// 	Reallocate missing taxes
	qui sum ditax [w=dweght], mean
		local total_tax = r(sum) 
	qui sum ditax_fixed400 [w=dweght], mean
		local total_tax_corr = r(sum) 
	local taxed_removed = round((`total_tax' - `total_tax_corr') / 10e10)
		di "Taxes removed from top 400 in `yr' = $`taxed_removed' million"
	qui replace ditax_fixed400 = ditax_fixed400 * `total_tax' / `total_tax_corr'
	qui sum ditax_fixed400 [w=dweght], mean
	* assert round(r(sum), 1e10) == round(`total_tax', 1e10) 

	qui saveold "$dirusdina/usdina`yr'.dta", replace 

// Output stats on uncorrected top 400 (tax unit level)
	mat top400`yr' = (`yr', `nb_top400', `nb_records', `share_inc_top400', `share_wealth_top400', `ratio_fiscal_pretax', `ratio_fiscal_pretax_corr') 
	mat top400   = (nullmat(top400)  \ top400`yr')
	mat colnames top400 = year nb_t400 nb_records sh_peinc sh_wealth fisc_pretax_ratio ratio_fixed
	if `yr' == $lastyear {
		mat list top400
		clear
		qui svmat top400, names(col)
		qui compress
		export excel using "$diroutsheet/top400.xlsx", first(var) replace	
	}	
}	



