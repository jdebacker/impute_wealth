* Programs that outsheets DINA results, aggregates & distributions (uses export excel --> requires Stata 12+ but not 13)
* Choose statistics, population, and variable of interest by editing local macro population, variable, statistics


cap mkdir $diroutsheet

* using the correct weight added 3/2018 (make sure these lines are always run)
* set global calibweight=1 when using the calibrated weights (produced from weight_usdina.do)

foreach yr of numlist $years { 

if $online == 1 & $calibweight == 1 {
	use "$dirusdina/usdina`yr'.dta", clear
		replace dweght=dweght_cal
	save "$dirusdina/usdina`yr'.dta", replace
	}
if $online == 1 & $calibweight != 1 {
	use "$dirusdina/usdina`yr'.dta", clear
	    * next 2 lines needed to 2016 which don't have calibrated weights yet
	    cap gen dweght_old=dweght
		cap gen dweght_cal=dweght
		cap replace dweght=dweght_old
		order id dweght*
	save "$dirusdina/usdina`yr'.dta", replace
	}
}	
* end of adjusting weights

* define local variable n1979 for loops 1979/$endyear
* set local specific year for testing on 1 year otherwise use 1979
local n1979=1979




********************************************************************************
* TESTING: TOTALS, FRACTION 0 AND NEGATIVE FOR ALL VARIABLES
********************************************************************************

/*

timer on 1


* Totals
	cap mat drop totals
	foreach yr of  numlist $years { 
		use "$dirusdina/usdina`yr'.dta", clear
		bys id: gen nbtaxu = _n
		replace nbtaxu = 0 if nbtaxu > 1
		drop id age* old* dweghttaxu
		gen adults = 1
		replace xkidspop = 0 if second == 1
		qui ds dweght, not
		di `yr'
		collapse (sum) `r(varlist)' [fw=dweght]
		foreach var of varlist _all {
			qui replace `var' = `var' / 10e13
		}
		foreach var of varlist  adults married second xkidspop filer nbtaxu {
		qui replace `var' = `var' * 1000		
		}
		foreach var of varlist _all {
			qui replace `var' = round(`var',.001)
		}
		qui gen year = `yr'
		order year adults nbtaxu
		qui rename xkidspop kids
		mkmat _all, mat(totals`yr') 
		mat totals = (nullmat(totals) \ totals`yr')	
	}	
		clear
		svmat totals, names(col)
		qui compress
		export excel using "$diroutsheet/totals.xlsx", first(var) replace	
				


* Frac zero labor income (excluding sales taxes)
	mat drop _all
	local population "indiv male female" 
	*local variable "fiinc fainc  ptinc  diinc"
	local variable "flinc"

	foreach pop of local population {
		foreach y of local variable {
			foreach yr of numlist $years { 

				use `y'* flprl dweght* id married second female old* using "$dirusdina/usdina`yr'.dta", clear
				replace flinc = flinc - flprl // remove sales taxes allocated to labor

				* Restrict to population of interest 
					if "`pop'" == "equal" {
						collapse (first) married (mean) `y'* dweght, by(id)
						qui gen second=1
						qui replace second=2 if married==1
						expand second
					}
					if "`pop'" == "taxu" { 
						collapse (sum) `y'* (mean) dweght dweghttaxu, by(id)
						replace dweght = dweghttaxu
					}
					if "`pop'" == "working" {	
						collapse (first) married oldexm oldexf (mean) `y'* dweght, by(id)
						qui gen second=1
						qui replace second=2 if married==1
						expand second
						gen old = oldexm 
						bys id: replace old = oldexf if _n == 2
						keep if old == 0
					}
					if "`pop'" == "male" 	keep if female == 0
					if "`pop'" == "female"  keep if female == 1

				* Compute fraction zero 
					* cumul `y' [w=dweght], gen(rank_`y')
					* gen group0 = 1
					* gen group1 = (rank_`y'>=.5)
					* gen group2 = (rank_`y'>=.9)
					* gen group3 = (rank_`y'>=.95)
					* gen group4 = (rank_`y'>=.99)
					* gen group5 = (rank_`y'>=.995)
					* gen group6 = (rank_`y'>=.999)
					* gen group7 = (rank_`y'>=.9999)
					* gen group8 = (rank_`y'<=.5)
					* gen group9 = (rank_`y'<=.9)
				    * gen group10 = (rank_`y'>=.5 & rank_`y'<=.9)

			    replace `y' = (`y' == 0)

				* forval i = 0/10 {
				* 	quietly su `y' if group`i' == 1 [fw=dweght], meanonly
				* 	mat fraczero`i'`yr'`y' = r(mean)
				* 	matrix colnames fraczero`i'`yr'`y' = fraczero`i'
				* 	mat fraczero`yr'`y' = (nullmat(fraczero`yr'`y'), fraczero`i'`yr'`y')		
				* 	}
				* mat fraczero`yr'`y' = (`yr', fraczero`yr'`y')
				* mat fraczero`y' = (nullmat(fraczero`y') \ fraczero`yr'`y')	
				* mat list fraczero`y'

				qui su `y' [fw=dweght], meanonly
				mat fraczero`yr'`y' =  r(mean)
				matrix colnames fraczero`yr'`y' = zero`y'
				mat fraczero`y' = (nullmat(fraczero`y') \ fraczero`yr'`y')	
				mat list fraczero`y'
			}
			
			mat fraczero`pop' = (nullmat(fraczero`pop'), fraczero`y')
			mat list fraczero`pop'
			mat drop fraczero`y'
		}
		clear
		svmat fraczero`pop', names(col)
		cap drop year
		gen year = 0
		local ii = 1
		foreach yr of numlist $years {
			replace year=`yr' if _n==`ii'
			local ii = `ii' +1
		}
		order year
		qui compress
		export excel using "$diroutsheet/fraczero`y'`pop'.xlsx", first(var) replace
		mat drop fraczero`pop'
	}

		
* Frac neg
	mat drop _all
	local population "female" 
	*local population "indiv male female" 
	local variable "fiinc fainc  ptinc  diinc"

	foreach pop of local population {
		foreach y of local variable {
			foreach yr of numlist $years { 

				use `y'* dweght* id married second female old using "$dirusdina/usdina`yr'.dta", clear

				* Restrict to population of interest 
					if "`pop'" == "equal" {
						collapse (first) married (mean) `y'* dweght, by(id)
						qui gen second=1
						qui replace second=2 if married==1
						expand second
					}
					if "`pop'" == "taxu" { 
						collapse (sum) `y'* (mean) dweght dweghttaxu, by(id)
						replace dweght = dweghttaxu
					}
					if "`pop'" == "male" 	keep if female == 0
					if "`pop'" == "female"  keep if female == 1

				replace `y' = (`y' < 0)

				qui su `y' [fw=dweght], meanonly
				mat fracneg`yr'`y' =  r(mean)
				matrix colnames fracneg`yr'`y' = neg`y'
				mat fracneg`y' = (nullmat(fracneg`y') \ fracneg`yr'`y')	
				mat list fracneg`y'
			}
		mat fracneg`pop' = (nullmat(fracneg`pop'), fracneg`y')
		mat list fracneg`pop'
		mat drop fracneg`y'
		}
		clear
		svmat fracneg`pop', names(col)
		cap drop year
		gen year = 0
		local ii = 1
		foreach yr of numlist $years {
			replace year=`yr' if _n==`ii'
			local ii = `ii' +1
		}
		order year
		qui compress
		export excel using "$diroutsheet/fracneg`y'`pop'.xlsx", first(var) replace
		mat drop fracneg`pop'
	}

timer off 1		




********************************************************************************
* Distributions by pop, no age 
********************************************************************************

timer on 2
mat drop _all


local population "male female indiv equal working taxu workingmale workingfem" 
local variable "fiinc fninc fnps fainc flinc ptinc plinc dicsh diinc princ peinc poinc hweal"
local statistic "sh thres" 

foreach pop of local population {
	foreach y of local variable {
		foreach stat of local statistic  {
			foreach yr of numlist $years { 

				use `y'* dweght* id married second female old* using "$dirusdina/usdina`yr'.dta", clear
				* Restrict to population of interest 
					if "`pop'" == "equal" {
						collapse (first) married (mean) `y'* dweght, by(id)
						qui gen second=1
						qui replace second=2 if married==1
						expand second
					}
					if "`pop'" == "taxu" { 
						collapse (sum) `y'* (mean) dweght dweghttaxu, by(id)
						replace dweght = dweghttaxu
					}
					if "`pop'" == "working" {	
						collapse (first) married oldexm oldexf (mean) `y'* dweght, by(id)
						qui gen second=1
						qui replace second=2 if married==1
						expand second
						gen old = oldexm 
						bys id: replace old = oldexf if _n == 2
						keep if old == 0
					}
					if "`pop'" == "male" 			keep if female == 0
					if "`pop'" == "female"  		keep if female == 1
					if "`pop'" == "workingmale" 	keep if female == 0 & old == 0
					if "`pop'" == "workingfem" 		keep if female == 1 & old == 0

				* Total number of units  and total income (or wealth), use to compute shares
					qui su dweght, meanonly
					local n = r(sum) / 10e10
					qui su `y' [w=dweght], meanonly
					local total = r(sum) / 10e10

				* Compute statistics (need commands shcomp, avgcomp and threshcomp to be loaded)	
					if "`y'" != "hweal" {
						`stat'comp    `y' [w=dweght], matname(`stat'`yr'`pop')
					}


				* For wealth statistics: mixed method (ranking by wealth without KG capitalized)
					if "`y'" == "hweal"  {
						`stat'comp    hwealnokg hweal [w=dweght], matname(`stat'`yr'`pop')
					}	

				* Display matrices of results 

					mat `stat'`yr'`pop'  = (`yr', `n', `total', `stat'`yr'`pop')
					mat `stat'`y'`pop'   = (nullmat(`stat'`y'`pop')  \ `stat'`yr'`pop')
					mat list `stat'`y'`pop'	
			}

			* Export results in Excel
				clear
				svmat `stat'`y'`pop', names(col)

				rename c2 n
				rename c3 total
				qui compress
				export excel using "$diroutsheet/`stat'`y'`pop'99.xlsx", first(var) replace	

			 * Create matrix of average from matrix of shares	
				if "`stat'" ==  "sh" { 
					foreach var of varlist `y'* {
						replace `var' = `var' * total / (1 * n) 		if substr("`var'",-1,1) == "0" 
						replace `var' = `var' * total / (0.5 * n) 		if substr("`var'",-1,1) == "1"
						replace `var' = `var' * total / (0.1 * n) 		if substr("`var'",-1,1) == "2"
						replace `var' = `var' * total / (0.05 * n)		if substr("`var'",-1,1) == "3"
						replace `var' = `var' * total / (0.01 * n) 		if substr("`var'",-1,1) == "4"
						replace `var' = `var' * total / (0.005 * n) 	if substr("`var'",-1,1) == "5"
						replace `var' = `var' * total / (0.001 * n) 	if substr("`var'",-1,1) == "6"
						replace `var' = `var' * total / (0.0001 * n) 	if substr("`var'",-1,1) == "7"
					}
					qui compress
					export excel using "$diroutsheet/avg`y'`pop'99.xlsx", first(var) replace	
				}
		}
	}	
}

timer off 2



********************************************************************************
* Distributions by age
********************************************************************************

timer on 3

mat drop _all
local population "male female equal" 
*local population "equal" 
local variable "fiinc fninc fnps fainc flinc ptinc plinc dicsh diinc princ peinc poinc hweal"
*local variable "dicsh"
local statistic "sh"
matrix define agebin=(20\ 45\ 65\ .)
local I = rowsof(agebin)-1

foreach pop of local population {
	foreach y of local variable {
		foreach stat of local statistic  {
			forval i = 1/`I' { 	
				foreach yr of  numlist `n1979'/$endyear { 

					use `y'* dweght* id married second female old age* using "$dirusdina/usdina`yr'.dta", clear

					* Treat as 20 years old all individuals less than 20
						foreach var of varlist age* {
							replace `var' = 20 if `var' < 20
						}

					* Restrict to population of interest 
						if "`pop'" == "male" 			keep if female == 0
						if "`pop'" == "female" 			keep if female == 1
						if "`pop'" == "equal" {
							collapse (first) married ageprim agesec (mean) `y'* dweght, by(id)
							qui gen second=1
							qui replace second=2 if married==1
							expand second
								cap drop count
								bys id: gen count=_n
								qui replace second=count-1
							qui gen age = .
								qui replace age = ageprim if second == 0
								qui replace age = agesec  if second == 1
						}
						keep if age >= agebin[`i',1] & age < agebin[`i'+1,1] 
						local age = agebin[`i',1]
						di "`age'"						

					* Total number of units  and total income (or wealth)
						qui su dweght, meanonly
						local n = r(sum) / 10e10
						qui su `y' [w=dweght], meanonly
						local total = r(sum) / 10e10

					* Compute statistics (need commands shcomp, avgcomp and threshcomp to be loaded)
						if "`y'" != "hweal" {
							`stat'comp    `y' [w=dweght], matname(`stat'`yr'`pop'`age')
						}

					* For wealth statistics: mixed method (ranking by wealth without KG capitalized)
						if "`y'" == "hweal"  {
							`stat'comp    hwealnokg hweal [w=dweght], matname(`stat'`yr'`pop'`age')
						}			

					* Display matrices of results 	
						mat `stat'`yr'`pop'`age'  = (`yr', `n', `total', `stat'`yr'`pop'`age')
						mat `stat'`y'`pop'`age'   = (nullmat(`stat'`y'`pop'`age')  \ `stat'`yr'`pop'`age')
						mat list `stat'`y'`pop'`age'	
				}

			* Export results in Excel
				clear
				svmat `stat'`y'`pop'`age', names(col)
				rename c2 n
				rename c3 total
				qui compress
				export excel using "$diroutsheet/`stat'`y'`pop'`age'.xlsx", first(var) replace

			* Create matrix of average from matrix of shares
				if "`stat'" ==  "sh" {
					foreach var of varlist `y'* {
						replace `var' = `var' * total / (1 * n) 		if substr("`var'",-1,1) == "0" 
						replace `var' = `var' * total / (0.5 * n) 		if substr("`var'",-1,1) == "1"
						replace `var' = `var' * total / (0.1 * n) 		if substr("`var'",-1,1) == "2"
						replace `var' = `var' * total / (0.05 * n)		if substr("`var'",-1,1) == "3"
						replace `var' = `var' * total / (0.01 * n) 		if substr("`var'",-1,1) == "4"
						replace `var' = `var' * total / (0.005 * n) 	if substr("`var'",-1,1) == "5"
						replace `var' = `var' * total / (0.001 * n) 	if substr("`var'",-1,1) == "6"
						replace `var' = `var' * total / (0.0001 * n) 	if substr("`var'",-1,1) == "7"
					}
					qui compress
					export excel using "$diroutsheet/avg`y'`pop'`age'.xlsx", first(var) replace	
				}

			}		
		}
	}	
}

timer off 3




********************************************************************************
* Fraction female in top groups 
********************************************************************************

timer on 4 

mat drop _all
local variable "flinc"
foreach var of local variable {
	foreach yr of numlist $years { 
		di "YEAR = `yr'"
		use `var' flprl dweght* female using "$dirusdina/usdina`yr'.dta", clear
		keep `var' flprl female dweght
		replace flinc = flinc - flprl // remove sales taxes allocated to labor
		cumul `var' [w=dweght] if `var'>0, gen(rank_`var')
		replace rank_`var' = 0 if rank_`var' == .
		gen group0 = (rank_`var'>0)
		gen group1 = (rank_`var'>=.5)
		gen group2 = (rank_`var'>=.9)
		gen group3 = (rank_`var'>=.95)
		gen group4 = (rank_`var'>=.99)
		gen group5 = (rank_`var'>=.995)
		gen group6 = (rank_`var'>=.999)
		gen group7 = (rank_`var'>=.9999)
		gen group8 = (rank_`var'<=.5)
		gen group9 = (rank_`var'<=.9)
		gen group10 = (rank_`var'>=.5 & rank_`var'<=.9)
		forval i = 0/10 {
			quietly su female if group`i' == 1 [fw=dweght], meanonly
			mat frac`i'`yr'`var' = r(mean)
			matrix colnames frac`i'`yr'`var' = frac`i'
			mat frac`yr'`var' = (nullmat(frac`yr'`var'), frac`i'`yr'`var')		
		}
		mat frac`yr'`var' = (`yr', frac`yr'`var')
		mat frac`var' = (nullmat(frac`var') \ frac`yr'`var')	
		mat list frac`var'
	}
	clear
	svmat frac`var', names(col)
	qui compress
	export excel using "$diroutsheet/fracfemale_`var'.xlsx", first(var) replace
}

timer off 4 



********************************************************************************
* Detailed composition (no age) for pre-62 imputations and graphs
********************************************************************************

timer on 5 
	
	mat drop _all
	local population 	"equal indiv taxu" 
	foreach pop of local population {
		 foreach var in fiinc fninc fainc  ptinc  dicsh diinc princ peinc poinc hweal { 
		* foreach var in diinc dicsh { 

			foreach yr of numlist $years { 

			*  Define components
				if "`var'" == "fiinc" local compo "fiwag fibus firen fiint fidiv fikgi"
				if "`var'" == "fninc" local compo "fnwag fnbus fnren fnint fndiv"
				if "`var'" == "fainc" local compo "faemp famil fahoumain fahourent faequ fafix fabus fapen famor fanmo" 
				if "`var'" == "flinc" local compo "flemp flmil"
				if "`var'" == "fkinc" local compo "fkhoumain fkhourent fkequ fkfix fkbus fkpen fkmor fknmo"								 
				if "`var'" == "ptinc" local compo "ptemp ptmil ptben ptcon pthoumain pthourent ptequ ptfix ptbus ptmor ptnmo"
				if "`var'" == "plinc" local compo "plemp plmil plbel plcon"
				if "`var'" == "pkinc" local compo "pkbek pkhoumain pkhourent pkequ pkfix pkbus pkmor pknmo"
				if "`var'" == "diinc" local compo "dipre disal dipro ditax diest dicor dibus dioth diben divet dihlt dikdn dicxp"   
				if "`var'" == "dicsh" local compo "dipre disal dipro ditax diest dicor dibus dioth diben divet"   
				if "`var'" == "princ" local compo "prfai prgov prnpi"
				if "`var'" == "peinc" local compo "pepti pegov penpi pesup peinv"
				if "`var'" == "poinc" local compo "podii pogov ponpi posup poinv posug"
				if "`var'" == "hweal" local compo "hwequ bond currency nonmort rental ownerhome ownermort hwbus hwpen"

				use  "$dirusdina/usdina`yr'.dta", clear

			*  Create / rename variables to obtain desired compo
				quietly {
					if  "`var'" == "fninc"  {
						rename fiwag fnwag
						rename fibus fnbus
						rename firen fnren
						rename fiint fnint
						rename fidiv fndiv
					}		
					if  "`var'" == "flinc"  {
						gen shemp = flemp / (flemp + flmil) // Allocate labor product taxes to components
						replace shemp = 0 if shemp == .
						replace flemp = flemp + flprl * shemp
						replace flmil = flmil + flprl * (1-shemp)
						drop shemp
						} 
					if  "`var'" == "fainc"  {
						gen shemp = flemp / (flemp + flmil) // Allocate labor product taxes to components
						replace shemp = 0 if shemp == .
						replace flemp = flemp + flprl * shemp
						replace flmil = flmil + flprl * (1-shemp)
						drop shemp
						rename flemp faemp // rename compo with fa prefix
						rename flmil famil
						rename fkhoumain fahoumain
						rename fkhourent fahourent
						rename fkequ faequ
						rename fkfix fafix
						rename fkbus fabus
						rename fkpen fapen
						rename fkmor famor
						rename fknmo fanmo
					}
					if "`var'" == "plinc" {
						gen shemp = flemp / (flemp + flmil) // Allocate labor product taxes to components
						replace shemp = 0 if shemp == .
						replace flemp = flemp + flprl * shemp
						replace flmil = flmil + flprl * (1-shemp)
						drop shemp
						rename flemp plemp // Rename compo with pl prefix
					 	rename flmil plmil
					}
					if "`var'" == "pkinc" {
						replace fkfix = fkfix + fkpen + pkpen // remove (fkpen + pkpen) (not exactly zero because fkpen includes corp and prop tax that fall on pensions)
						rename fkhoumain  pkhoumain // Rename  compo with pk prefix
						rename fkhourent  pkhourent
						rename fkequ pkequ
				 		rename fkfix pkfix
				 		rename fkbus pkbus
				 		rename fkmor pkmor
				 		rename fknmo pknmo
					}		
					if "`var'" == "ptinc" {
						gen shemp = flemp / (flemp + flmil) // Allocate labor product taxes to components
						replace shemp = 0 if shemp == .
						replace flemp = flemp + flprl * shemp
						replace flmil = flmil + flprl * (1-shemp)
						drop shemp
						replace fkfix = fkfix + fkpen + pkpen // remove (fkpen + pkpen) (not exactly zero because fkpen includes corp and prop tax that fall on pensions)
						rename flemp ptemp // Rename all compo with pt prefix
				 		rename flmil ptmil
				 		rename plben ptben
				 		rename plcon ptcon
				 		rename fkhoumain  pthoumain 
						rename fkhourent  pthourent
						rename fkequ ptequ
				 		rename fkfix ptfix
				 		rename fkbus ptbus
				 		rename fkmor ptmor
				 		rename fknmo ptnmo
					}
					if "`var'" == "diinc" | "`var'" == "dicsh" {
						gen cashben = 0 //  Isolate vet benefits from dicab (cashben = dicab - divet) for pre-62 imputations
						replace cashben = dicred + diwco + difoo + disup + dicao
						gen disal = salestax
						foreach tax in disal proprestax propbustax ditax estatetax corptax othercontrib { 
						replace `tax' = - `tax' // put taxes with a minus sign so that compo add up to 100%
						}
						rename ptinc dipre // Rename all compo with di prefix
						rename proprestax dipro
						rename estatetax diest
						rename corptax dicor
						rename propbustax dibus
						* replace dicor = dicor + propbustax // lump together corporate tax and business property tax
						rename othercontrib dioth
						rename cashben diben
						gen dihlt = medicare + medicaid // split in-kind benefits into health benefits (dihlt) and other in-kind (dikdn)
						gen dikdn = inkindinc - dihlt						
						rename colexp dicxp
					}		
					if "`var'" == "princ" {
						rename fainc prfai
						rename npinc prnpi
						rename govin prgov
					}
					if "`var'" == "peinc" {
						rename ptinc pepti
						rename npinc penpi
						rename govin pegov
						rename prisupen pesup
						rename invpen peinv
					}	
					if "`var'" == "poinc" {
						rename diinc podii
						rename npinc ponpi
						rename govin pogov
						rename prisupenprivate posup
						rename prisupgov posug	
						rename invpen poinv				
					}
					if "`var'" == "hweal" {
						qui gen bond = taxbond + muni 
					}	
				}

				keep `var'* `compo' dweght* id married second female old

			*  Restrict to population of interest 
				if "`pop'" == "equal" {
					collapse (first) married (mean) `var'* `compo' dweght, by(id)
					qui gen second=1
					qui replace second=2 if married==1
					expand second
				}
				if "`pop'" == "taxu" { 
					collapse (sum) `var'* `compo' (mean) dweght dweghttaxu, by(id)
					replace dweght = dweghttaxu
				}
				if "`pop'" == "male" 	keep if female == 0
				if "`pop'" == "female"  keep if female == 1

			*  Compute component tables	
				if "`var'" != "hweal" shcomp    `var' `compo' [w=dweght], matname(compo`yr'`pop')
				if "`var'" == "hweal" shcomp   hwealnokg `var' `compo' [w=dweght], matname(compo`yr'`pop')

			* Display matrices of results 	
				mat compo`yr'`pop'  = (`yr', compo`yr'`pop')
				mat `var'`pop'   = (nullmat(`var'`pop')  \ compo`yr'`pop')
				mat list `var'`pop'	
			}

		* Export results in Excel
			clear
			svmat `var'`pop', names(col)
			qui compress
			export excel using "$diroutsheet/compo`var'`pop'99.xlsx", first(var) replace	
		}
	}	
timer off 5 

********************************************************************************
* Age-wealth and age-income profiles
********************************************************************************

 
* Not used for now

* if $data == 1 {

* timer on 6 

* 	local variable "fiinc fninc fainc  ptinc  dicsh diinc princ peinc poinc hweal"
* 	foreach yr of  numlist `n1979'/$endyear { 
* 		use `variable' age dweght using "$dirusdina/usdina`yr'.dta", clear
* 		gen agerange=0
* 		foreach num of numlist 20 35 45 55 65 75 {
*  			replace agerange=`num' if age>=`num' & age!=.
* 		}
* 		foreach var of local variable {
* 			quietly su `var' [w=dweght], meanonly
* 			local mean`var'=r(mean)
* 		}
* 	* Age bins
* 		preserve	
* 			collapse (mean) `variable' [w=dweght], by(agerange) 
* 			drop if agerange==0
* 			foreach var of local variable {
* 				replace `var' = `var' / `mean`var''
* 			}
* 			export excel using "$diroutsheet/agerangeprofile_`yr'.xlsx", first(var) replace
* 	* Exact age
* 		restore  
* 		drop if age < 20
* 		replace age = 80 if age >= 80 & age < 85
* 		replace age = 85 if age >= 85 & age < 90
* 		replace age = 90 if age >= 90 & age < 94
* 		replace age = 94 if age >= 94	
* 		collapse (mean) `variable' [w=dweght], by(age) 
* 			foreach var of local variable {
* 				replace `var' = `var' / `mean`var''
* 			}	
* 			export excel using "$diroutsheet/ageprofile_`yr'.xlsx", first(var) replace
* 	}	
* timer off 6
* }



********************************************************************************
* Average age in top groups
********************************************************************************

* Only internal for now

if $data == 1 {

timer on 7

local population "indiv male female" 
local variable "princ peinc poinc hweal"
*local variable "fainc  princ poinc hweal"

	foreach pop of local population {
		foreach y of local variable {
			foreach yr of numlist `n1979'/$endyear { 

				use `y'* dweght* female age using "$dirusdina/usdina`yr'.dta", clear

				* Restrict to population of interest 
					if "`pop'" == "male" 	keep if female == 0
					if "`pop'" == "female"  keep if female == 1
				
				* Fractiles
					matrix input cumul = (0, .5, .9, .95, .99, .995, .999, .9999)
					local nbgroup = colsof(cumul)
				
				* Compute average age by fractile and put in matrix
					matrix age`y'`yr'`pop' = J(1, `nbgroup', 0)
					if "`y'" == "hweal" replace hweal = hwealnokg
					cumul `y' [w=dweght], gen(rank`y')  
					forval j = 1/`nbgroup' {
						su age [w=dweght] if rank`y'>=cumul[1,`j'], meanonly
						mat age`y'`yr'`pop'[1,`j']=r(mean)
					}
				
				* Display matrices of results 	
					mat age`y'`yr'`pop'  = (`yr', age`y'`yr'`pop')
					mat age`y'`pop'   = (nullmat(age`y'`pop')  \ age`y'`yr'`pop')
					mat colnames age`y'`pop' = year age0 age1 age2 age3 age4 age5 age6 age7
					mat list age`y'`pop'
			}

			* Export results in Excel
				clear
				svmat age`y'`pop', names(col)
				qui compress
				export excel using "$diroutsheet/ageavg`y'`pop'.xlsx", first(var) replace	

		}
	}	

timer off 7

}

********************************************************************************
* Benefits received by pre-tax and post-tax income group
********************************************************************************


timer on 8

	mat drop _all
	local population 	"equal working" 
	local variable "poinc peinc"


foreach benef in ben_excl_ss ben_incl_ss {

	if "`benef'" == "ben_excl_ss" local compo 		   "dicred divet diwco difoo disup dicao inkindinc colexp"
	if "`benef'" == "ben_incl_ss" local compo "ssinc_oa dicred divet diwco difoo disup dicao inkindinc colexp"
	foreach pop of local population {
		 foreach y of local variable { 
			foreach yr of numlist $years { 

				use `y' ben `compo' ss* uiinc  prop* dweght* id married second female old* using "$dirusdina/usdina`yr'.dta", clear
				replace ssinc_oa = ssinc_oa + ssinc_di + uiinc  
				if "`benef'" == "ben_incl_ss" replace ben = ben + ssinc_oa

				* Restrict to population of interest 
					if "`pop'" == "equal" {
						collapse (first) married (mean) `y' ben `compo' dweght, by(id)
						qui gen second=1
						qui replace second=2 if married==1
						expand second
					}					
					if "`pop'" == "taxu" { 
						collapse (sum) `y' ben `compo' (mean) dweght dweghttaxu, by(id)
						replace dweght = dweghttaxu
					}
					if "`pop'" == "working" {	
						collapse (first) married oldexm oldexf  (mean) `y' ben `compo' dweght, by(id)
						qui gen second=1
						qui replace second=2 if married==1
						expand second
						gen old = oldexm 
						bys id: replace old = oldexf if _n == 2
						keep if old == 0
					}	
					if "`pop'" == "male" 	keep if female == 0
					if "`pop'" == "female"  keep if female == 1

				* Compute statistics 
						shcomp `y' ben `compo' [w=dweght], matname(`benef'`yr'`pop')

				* Display matrices of results 	
					mat `benef'`yr'`pop'  = (`yr', `benef'`yr'`pop')
					mat `benef'`y'`pop'   = (nullmat(`benef'`y'`pop')  \ `benef'`yr'`pop')
					mat list `benef'`y'`pop'	
			}

			* Export results in Excel
				clear
				svmat `benef'`y'`pop', names(col)
				qui compress
				if "`benef'" == "ben_incl_ss" rename ssinc_oa* ss*
				export excel using "$diroutsheet/`benef'`y'`pop'99.xlsx", first(var) replace
		}
	}	
}

timer off 8


********************************************************************************
* Taxes by g-percentile of pre-tax income (with compo) [adults with > 1/2 min wage only for *equal files]
********************************************************************************


timer on 9

	mat drop _all
	local compo	"salestax proprestax govcontrib ditax* corptax estatetax"
	local ordering "salestax proprestax govcontrib ditax corptax estatetax denom fninc fikgi hweal wealth_above*"
	local population "equal" 
	
foreach pop of local population {
		* foreach yr of numlist $years { 
	foreach yr of numlist $years { 

		// Load minimum wage in current $
			insheet using "$parameters", clear names
			qui keep if yr == `yr'
			local minwage = 2087 * minwage
			* local fraceqpen = fraceqpen

			use peinc fkequ fkpen fikgi fiinc* fninc princ flemp flmil hweal tax `compo' propbustax dweght* id married second female old* using "$dirusdina/usdina`yr'.dta", clear
				qui replace corptax = corptax + propbustax
				* qui gen corpprofits = fkequ + `fraceqpen' * fkpen

			// Deal with top 400 and capital gains	
				qui gen top400 = (abs(ditax_fixed400)  <  abs(ditax))
					qui replace fikgi = fikgi * fiinc_fixed400 / fiinc  if top400 == 1
					qui replace fninc = fninc * fiinc_fixed400 / fiinc  if top400 == 1
					qui replace fiinc = fiinc_fixed400 
					qui replace ditax = ditax_fixed400
					qui drop tax ditax_fixed400
				qui egen tax = rsum(`compo')

				qui gen kg_agi = fikgi
					if `yr' < 1978 replace kg_agi = 0.5 * fikgi
					if `yr' >= 1978 & `yr' < 1987 replace kg_agi = 0.4 * fikgi
				qui sum kg_agi [w=dweght], mean
					local tot_kg_agi = r(sum)
				qui sum peinc [w=dweght], mean
					local tot_ninc = r(sum)
					local frac = `tot_kg_agi' / `tot_ninc'
					local frac_di = round(100 * `frac', 0.1) 
					di "REALIZED CAPITAL GAINS IN AGI IN `yr' = `frac_di'% OF NATIONAL INCOME "		
				qui gen pure_kg  =  max(0, `frac' - 0.03) / `frac' * kg_agi
				if `yr' == 1986 replace pure_kg = kg_agi * 0.5 
				qui gen peinc_kg = peinc
					qui replace peinc_kg = peinc + pure_kg
				drop top400

			// Create wealth above various threshold
				qui cumul hweal [w=dweght], gen(rank_wealth)
				* qui su hweal [w=dweght] if rank_wealth>=.99
				* local p99 = r(min)
				* qui gen wealth_above_99 = max(0, hweal - `p99') 
				qui gen wealth_above_50m = max(0, hweal - 5e7) 	
				*qui su hweal [w=dweght] if rank_wealth>=.999
				*local p99_9 = r(min)
				*qui gen wealth_above_99_9 = max(0, hweal - `p99_9')
				qui gen wealth_above_1b = max(0, hweal - 1e9) 
				*qui su hweal [w=dweght] if rank_wealth>=.9999
				*local p99_99 = r(min)
				*qui gen wealth_above_99_99 = max(0, hweal - `p99_99') 
				

			* Restrict to population of interest 
				if "`pop'" == "equal" { // Keep people with more than 1/2 min wage in pre-tax inc
					collapse (first) married (mean) peinc* princ hweal wealth* fninc fikgi tax `compo' dweght, by(id)
					qui gen second=1
					qui replace second=2 if married==1
					expand second
					keep if peinc > `minwage' / 2
				}
				if "`pop'" == "taxu" { 
					collapse (sum) peinc* princ hweal  wealth* fninc fikgi tax `compo' (mean) dweght dweghttaxu, by(id)
					replace dweght = dweghttaxu
				}
				if "`pop'" == "working" { // working here removes working-age with 0 or very small labor income
					qui gen laborinc = flemp + flmil
					keep if laborinc > 0
					qui sum laborinc [w=dweght], det
					keep if laborinc > r(p10)
					collapse (first) married oldexm oldexf (mean) peinc* princ hweal wealth* fninc fikgi tax `compo' dweght, by(id)
					qui gen second=1
					qui replace second=2 if married==1
					expand second
					gen old = oldexm 
					bys id: replace old = oldexf if _n == 2
					keep if old == 0

				}	
				if "`pop'" == "male" 	keep if female == 0
				if "`pop'" == "female"  keep if female == 1
	
			* Compute gperc (need commands shcomp, avgcomp and threshcomp to be loaded)	
					* if "`y'" == "peinc" 	gperc peinc tax `compo' *eal* peinc_kg fninc fikgi [w=dweght], matname(tax`yr'`y'`pop')	
					* if "`y'" == "princ" 	gperc princ tax `compo' *eal* fninc fikgi [w=dweght], matname(tax`yr'`y'`pop')	
					* if "`y'" == "hweal" 	gperc hweal tax `compo' *eal* peinc_kg fninc fikgi [w=dweght], matname(tax`yr'`y'`pop')	
					gen denom = peinc_kg
					gperc peinc tax `ordering' [w=dweght], matname(tax`yr'peinc_kg`pop')	
					* order gperc nb thres sh avg tax `compo' peinc_kg fninc fikgi *eal*
					mat list tax`yr'peinc_kg`pop'	

			* Add top 400 as separate row
				qui sum peinc [fw=dweght], mean
					local total = r(sum)
				qui sum dweght, mean 
					local total_pop = round(r(sum) / 1e5, 1)
				qui cumul peinc [fw=dweght], gen(cum) freq
				qui keep if cum >= (`total_pop' - 400) * 1e5
				* if "`y'" == "peinc" 	collapse (count) nb = dweght (min) thres = `y' (mean) avg = `y' tax `compo' *eal* fninc fikgi (sum) sh = `y' [fw=dweght]
				* if "`y'" == "princ" 	collapse (count) nb = dweght (min) thres = `y' (mean) avg = `y' tax `compo' *eal* fninc fikgi (sum) sh = `y' [fw=dweght]
				* if "`y'" == "hweal" 	collapse (count) nb = dweght (min) thres = `y' (mean) avg = `y' tax `compo' peinc_kg fninc fikgi (sum) sh = `y' [fw=dweght]
				* if "`y'" == "peinc_kg" 	collapse (count) nb = dweght (min) thres = `y' (mean) avg = `y' tax `compo' *eal* peinc_kg fninc fikgi (sum) sh = `y' [fw=dweght]
				collapse (count) nb = dweght (min) thres = peinc (mean) avg = peinc tax `compo' peinc_kg fninc fikgi *eal* (sum) sh = peinc [fw=dweght]
				replace nb = nb/1e5
				gen gperc = 400
				replace sh = sh / `total'
				rename peinc_kg denom
				order gperc nb thres sh avg tax `ordering'
				mkmat _all, matrix(top400`yr'peinc_kg`pop')
				mat tax`yr'peinc_kg`pop' = tax`yr'peinc_kg`pop' \ top400`yr'peinc_kg`pop'

			* Export results in Excel
				clear
				svmat tax`yr'peinc_kg`pop', names(col)
				* if "`y'" == "peinc" 	gen denom = avg	
				* if "`y'" == "princ" 	gen denom = avg	
				* if "`y'" == "hweal" 	gen denom = peinc_kg
				* if "`y'" == "peinc_kg" 	gen denom = peinc_kg
				gen effrate = tax / denom
				foreach var of varlist salestax proprestax govcontrib ditax corptax estatetax  {
					replace `var' = `var' / denom
				}
				cap drop peinc
				cap drop peinc_kg
				order gperc nb thres sh avg tax effrate `ordering'
				qui compress
				export excel using "$diroutsheet/taxgperc`yr'peinc_kg`pop'99_warren.xlsx", first(var) replace

		}	
	
}	


timer off 9



********************************************************************************
* Tax rates by income and wealth groups (incl. bot 50%, middle 40%, and very top), with compo [full pop]
********************************************************************************

timer on 10
mat drop _all
local compo	"salestax proprestax govcontrib ditax corptax propbustax estatetax"

foreach y in peinc peinc_kg hweal {
* foreach y in peinc_kg {	
	foreach yr of numlist $years { 

		use peinc hweal tax fikgi fiinc* `compo' ditax_fixed400  propbustax dweght* id married second female old* using "$dirusdina/usdina`yr'.dta", clear
		* replace corptax = corptax + propbustax

			// Deal with top 400 and capital gains	
				qui gen top400 = (abs(ditax_fixed400)  <  abs(ditax))
					qui replace fikgi = fikgi * fiinc_fixed400 / fiinc  if top400 == 1
					qui replace ditax = ditax_fixed400
					qui drop tax ditax_fixed400
				qui egen tax = rsum(`compo')

				qui gen kg_agi = fikgi
					if `yr' < 1978 replace kg_agi = 0.5 * fikgi
					if `yr' >= 1978 & `yr' < 1987 replace kg_agi = 0.4 * fikgi
				qui sum kg_agi [w=dweght], mean
					local tot_kg_agi = r(sum)
				qui sum peinc [w=dweght], mean
					local tot_ninc = r(sum)
					local frac = `tot_kg_agi' / `tot_ninc'
					local frac_di = round(100 * `frac', 0.1) 
					di "REALIZED CAPITAL GAINS IN AGI IN `yr' = `frac_di'% OF NATIONAL INCOME "		
				qui gen pure_kg  =  max(0, `frac' - 0.03) / `frac' * kg_agi
				if `yr' == 1986 replace pure_kg = kg_agi * 0.5 
				qui gen peinc_kg = peinc
					qui replace peinc_kg = peinc + pure_kg
				drop top400

			// Denominator
				if "`y'" == "peinc" 	gen denom = peinc	
				if "`y'" == "hweal" 	gen denom = peinc_kg
				if "`y'" == "peinc_kg" 	gen denom = peinc_kg


		* Restrict to population of interest: equal split
			collapse (first) married (mean) denom `y' tax `compo' dweght, by(id)
			qui gen second=1
			qui replace second=2 if married==1
			expand second
		
		* Identify groups
			cumul `y' [fw=dweght], gen(rank_`y')
			gen all 			= 1
			gen bot90 			= (rank_`y' <=.9)
			gen bot50 			= (rank_`y' <=.5)
			gen middle40		= (rank_`y' > .5  & rank_`y' <= .9)
			gen top10			= (rank_`y' > .9)
			gen top5			= (rank_`y' > .95)
			gen top1			= (rank_`y' > .99)
			gen top0p5			= (rank_`y' > .995)
			gen top0p1			= (rank_`y' > .999)
			gen top0p01			= (rank_`y' > .9999)	
			gen top0p001		= (rank_`y' > .99999)
			gen P90_P95			= (rank_`y' > .9 & 		rank_`y' <= .95)
			gen P95_P99 		= (rank_`y' > .95 & 	rank_`y' <= .99)
			gen P99_P99p5		= (rank_`y' > .99 & 	rank_`y' <= .995)
			gen P99p5_P99p9 	= (rank_`y' > .995 & 	rank_`y' <= .999)
			gen P99p9_P99p99 	= (rank_`y' > .999 & 	rank_`y' <= .9999)
			gen P99p99_P99p999 	= (rank_`y' > .9999 & 	rank_`y' <= .99999)
			sum dweght, mean
			local totpop = r(sum) / 1e5
			gen top400			= (rank_`y' >= 1 - 400/`totpop')
			
			foreach group in all bot90 bot50 middle40 top10 top5 top1 top0p5 top0p1 top0p01 top0p001 P90_P95 P95_P99 P99_P99p5 P99p5_P99p9 P99p9_P99p99 P99p99_P99p999 top400 {
				foreach tax in tax `compo' {
					gen `tax'`group' = `tax' * `group'
				}
				gen denom`group' = denom * `group'	
			} 
	 		
		* Tax rates
			rename *govcontrib* *paytax*
			collapse (sum) denom* *tax* [fw=dweght]
			foreach group in all bot90 bot50 middle40 top10 top5 top1 top0p5 top0p1 top0p01 top0p001 P90_P95 P95_P99 P99_P99p5 P99p5_P99p9 P99p9_P99p99 P99p99_P99p999 top400 {
				foreach tax in tax salestax proprestax paytax ditax corptax propbustax estatetax {
					replace `tax'`group' = `tax'`group' / denom`group'
				}
			}	
			drop denom* tax salestax proprestax paytax ditax corptax estatetax propbustax
			gen year= `yr'
			order year

	* Display matrices of results 	
		mkmat _all, matrix(tax`yr') 
		mat tax`y'   = (nullmat(tax`y')  \ tax`yr')
		mat list tax`y'
	}
		
* Export results in Excel
	clear
	svmat tax`y', names(col)
	qui compress
	export excel using "$diroutsheet/taxrate`y'_00.xlsx", first(var) replace
}

timer off 10

/*

********************************************************************************
* Income and wealth by g-percentile 
********************************************************************************



timer on 11
	mat drop _all
	local population 	"equal"
	* local population 	"equal working " 
	local variable "dicsh princ peinc peinck peincl poinc fiinc hweal"
	* local variable "dicsh"

	foreach pop of local population {
		 foreach y of local variable { 
			foreach yr of numlist $years { 

				use `y' dweght* id married second female old* using "$dirusdina/usdina`yr'.dta", clear

				* Restrict to population of interest 
					if "`pop'" == "equal" {
						collapse (first) married (mean) `y' dweght, by(id)
						qui gen second=1
						qui replace second=2 if married==1
						expand second
					}
					if "`pop'" == "taxu" { 
						collapse (sum) `y' (mean) dweght dweghttaxu, by(id)
						replace dweght = dweghttaxu
					}
					if "`pop'" == "working" {	
						collapse (first) married oldexm oldexf (mean) `y' dweght, by(id)
						qui gen second=1
						qui replace second=2 if married==1
						expand second
						gen old = oldexm 
						bys id: replace old = oldexf if _n == 2
						keep if old == 0
					}
					if "`pop'" == "male" 	keep if female == 0
					if "`pop'" == "female"  keep if female == 1

				* Compute statistics (need commands shcomp, avgcomp and threshcomp to be loaded)	
						gperc `y'   [w=dweght], matname(gperc`yr'`y'`pop')	
						mat list gperc`yr'`y'`pop'

			* Export results in Excel
				clear
				svmat gperc`yr'`y'`pop', names(col)
				qui compress
				export excel using "$diroutsheet/gperc`y'`yr'`pop'.xlsx", first(var) replace

			}	
		}
	}		
timer off 11

********************************************************************************
* Joint distributions (no compo)
********************************************************************************

timer on 12
	local population 	"indiv" 
	local variable 		"hweal"
	local byvar 		"peinc"

	foreach pop of local population {
		foreach var of local variable {
			foreach by of local byvar {
				foreach yr of numlist $years { 

					use "$dirusdina/usdina`yr'.dta", clear


					if "`pop'" == "male" 	keep if female == 0
					if "`pop'" == "female"  keep if female == 1

					shcomp    `by'  `var' [w=dweght], matname(joint`yr'`pop'`by') 
					
					* Correction of denominator (shcomp uses total of `by' as denominator)
						quietly su `by' [w=dweght], meanonly 
						local tot`by'=r(sum)/10e10
						quietly su `var' [w=dweght], meanonly
						local tot`var' = r(sum)/10e10
						local corr`yr' = `tot`by'' / `tot`var''
						mat joint`yr'`pop'`by' =  joint`yr'`pop'`by' * `corr`yr''	
			
					* Display matrices of results 	
						mat joint`yr'`pop'`by'  = (`yr', joint`yr'`pop'`by')
						mat `var'`pop'`by'   = (nullmat(`var'`pop'`by')  \ joint`yr'`pop'`by')
						mat list `var'`pop'`by'	
				}

				* Export results in Excel
					clear
					svmat `var'`pop'`by', names(col)
					drop `by'*
					* forval i = 0/7 {
					* 	gen hweal`i' = 0
					* 	foreach var of local joint {
					* 		replace hweal`i' = hweal`i' + `var'`i'
					* 	}
					* }
					qui compress
					export excel using "$diroutsheet/`var'by`by'`pop'99.xlsx", first(var) replace	
			}	
		}
	}
timer off 12


********************************************************************************
* Decomposition of pre-tax income into capital income, taxable labor income, tax-exempt labor income
********************************************************************************

timer on 13
mat drop _all

* Capital share of pension income

local population "equal" 
local statistic "sh" 

foreach pop of local population {
		foreach stat of local statistic  {
			foreach yr of numlist $years { 

				use "$dirusdina/usdina`yr'.dta", clear

				*  Restrict to population of interest 
					if "`pop'" == "equal" {
					collapse (first) married (mean) peinc pkpen plcon invpen dweght, by(id)
					qui gen second=1
					qui replace second=2 if married==1
					expand second
					}
					if "`pop'" == "taxu" { 
						collapse (sum) peinc pkpen plcon invpen (mean) dweght dweghttaxu, by(id)
						replace dweght = dweghttaxu
					}
					if "`pop'" == "working" {	
						collapse (first) married oldexm oldexf (mean) peinc pkpen plcon invpen dweght, by(id)
						qui gen second=1
						qui replace second=2 if married==1
						expand second
						gen old = oldexm 
						bys id: replace old = oldexf if _n == 2
						keep if old == 0
					}
					if "`pop'" == "male" 	keep if female == 0
					if "`pop'" == "female"  keep if female == 1

				* Compute capital share of pension income in each group

					qui cumul peinc [w=dweght], gen(rank_peinc)
					cap drop group*
					qui gen group0 = 1
					qui gen group1 =  (rank_peinc >= .5)
					qui gen group2 =  (rank_peinc >= .9)
					qui gen group3 =  (rank_peinc >= .95)
					qui gen group4 =  (rank_peinc >= .99)
					qui gen group5 =  (rank_peinc >= .995)
					qui gen group6 =  (rank_peinc >= .999)
					qui gen group7 =  (rank_peinc >= .9999)
					qui gen group8 =  (rank_peinc <= .5)
					qui gen group9 =  (rank_peinc <= .9)
				    qui gen group10 = (rank_peinc >=. 5 & rank_peinc<=.9)

				forval i = 0/10 {
					qui su pkpen  if group`i' == 1 [fw=dweght], meanonly
						local tot_invpen = - r(sum)
					qui su plcon if group`i' == 1 [fw=dweght], meanonly	
						local tot_plcon = - r(sum)
					local alpha_pension_`i' = `tot_invpen' / (`tot_invpen' + `tot_plcon')	
					mat alpha_pension_`yr'_`i' = `alpha_pension_`i''
						mat colnames alpha_pension_`yr'_`i' = ksharepen`i'
					mat alpha_pension_`yr' = (nullmat(alpha_pension_`yr'), alpha_pension_`yr'_`i')		

					}
				mat alpha_pension_`yr' = (`yr', alpha_pension_`yr')
				mat alpha_pension = (nullmat(alpha_pension) \ alpha_pension_`yr')	
				mat list alpha_pension
			}

				* Export results in Excel
					clear
					svmat alpha_pension, names(col)
					qui compress
					export excel using "$diroutsheet/alpha_pension.xlsx", first(var) replace	

			}
		}


* Tax exempt labor by group

local population "equal" 
local statistic "sh" 

foreach pop of local population {
		foreach stat of local statistic  {
			foreach yr of numlist $years { 

				use "$dirusdina/usdina`yr'.dta", clear

				*  Restrict to population of interest 
					if "`pop'" == "equal" {
					collapse (first) married (mean) peinc flsup flwag dweght, by(id)
					qui gen second=1
					qui replace second=2 if married==1
					expand second
					}
					if "`pop'" == "taxu" { 
						collapse (sum) peinc flsup flwag (mean) dweght dweghttaxu, by(id)
						replace dweght = dweghttaxu
					}
					if "`pop'" == "working" {	
						collapse (first) married oldexm oldexf (mean) peinc flsup flwag dweght, by(id)
						qui gen second=1
						qui replace second=2 if married==1
						expand second
						gen old = oldexm 
						bys id: replace old = oldexf if _n == 2
						keep if old == 0
					}
					if "`pop'" == "male" 	keep if female == 0
					if "`pop'" == "female"  keep if female == 1

			*  Compute component tables	
				shcomp    peinc flsup flwag [w=dweght], matname(compo`yr'`pop')

			* Display matrices of results 	
				mat compo`yr'`pop'  = (`yr', compo`yr'`pop')
				mat `var'`pop'   = (nullmat(`var'`pop')  \ compo`yr'`pop')
				mat list `var'`pop'	
			}

		* Export results in Excel
			clear
			svmat `var'`pop', names(col)
			qui compress
			export excel using "$diroutsheet/exemptpeinc`pop'99.xlsx", first(var) replace	
		}
	}	

* Test: recreate compo of pre-tax income from DINA files (Table II-B2)
	* mat drop _all
	* foreach yr of numlist 1962 2008/$endyear { 

	* 	use "$dirusdina/usdina`yr'.dta", clear
			
	* 		qui gen inc_equity = fkequ
	* 		qui gen inc_int = fkfix + fknmo + govin + npinc + (fkpen + pkpen) // fkpen + pkpen = portion of corp and sales taxes shifted to pension inc. ==> more logical to treat this as K inc (interest to simplify) than mixed pension income
	* 		qui gen inc_rent = fkhou + fkmor
	* 		qui gen inc_kmix = fkbus
	* 		qui gen inc_pen =  plbel +  pkbek + invpen + prisupen
	* 		qui gen shemp = flemp / (flemp + flmil) // Allocate labor product taxes & PENSION CONTRIB to comp and lmix
	* 			replace shemp = 0 if shemp == .
	* 		qui gen inc_comp = flemp + (flprl + plcon) * shemp
	* 		qui gen inc_lmix =  flmil + (flprl + plcon) * (1-shemp)
			
	* 		local compo "inc_equity inc_int inc_rent inc_kmix inc_pen inc_comp inc_lmix"
	* 		local detail "fkfix fknmo govin npinc"
	* 		collapse (first) married (mean) peinc `compo' `detail' dweght, by(id)
	* 		qui gen second=1
	* 		qui replace second=2 if married==1
	* 		expand second

	* 		shcomp    peinc `compo' [w=dweght], matname(compo`yr')
	* 		mat compo`yr'  = (`yr', compo`yr')
	* 		mat compo_peinc   = (nullmat(compo_peinc)  \ compo`yr')
	* 		mat list compo_peinc

	* 		shcomp    peinc `detail' [w=dweght], matname(detail`yr')
	* 		mat detail`yr'  = (`yr', detail`yr')
	* 		mat detail_peinc   = (nullmat(detail_peinc)  \ detail`yr')
	* 		mat list detail_peinc
	* 	}	

	* 	clear
	* 	svmat compo_peinc, names(col)
	* 	qui compress
	* 	export excel using "$diroutsheet/test_compo_peinc.xlsx", first(var) replace
	* 	clear
	* 	svmat detail_peinc, names(col)
	* 	qui compress
	* 	export excel using "$diroutsheet/test_detail_peinc.xlsx", first(var) replace


timer off 13


********************************************************************************
* Distributions by age, with compo (only pre-tax and post-tax income for now)
********************************************************************************

timer on 14

mat drop _all
*local population "male female" 
local population "equal" 
*local variable "fiinc fninc fnps fainc  ptinc  diinc princ peinc poinc hweal"
local variable "peinc poinc"
matrix define agebin=(20\ 45\ 65\ .)
local I = rowsof(agebin)-1

foreach pop of local population {
	foreach y of local variable {
			forval i = 1/`I' { 	
				foreach yr of  numlist `n1979'/$endyear { 
					
					use "$dirusdina/usdina`yr'.dta", clear

					* Define components
						if "`y'" == "peinc" {
							gen shemp = flemp / (flemp + flmil) // Allocate labor product taxes to components
							replace shemp = 0 if shemp == .
							replace flemp = flemp + flprl * shemp
							replace flmil = flmil + flprl * (1-shemp)
							drop shemp
							qui gen ptemp = flemp 
							qui gen ptmil = flmil
							qui gen ptequ = fkequ
							qui gen ptint = fkfix + fknmo + npinc + govin
							qui gen pthou = fkhoumain + fkhourent + fkmor
							qui gen ptbus = fkbus 
							qui gen ptben = fkpen + plcon + plbel + pkpen + pkbek + prisupen + invpen

							local compo "ptequ ptint pthou ptbus ptben ptemp ptmil"	
						}
						if "`y'" == "poinc" {
							
							qui gen transf = ben 
							qui gen health = medicare + medicaid 
							qui gen netinc = poinc - transf	

							local compo "netinc transf health"
						}		
							
					* Treat as 20 years old all individuals less than 20
						foreach var of varlist age* {
							replace `var' = 20 if `var' < 20
						}

					* Restrict to population of interest 
						if "`pop'" == "male" 			keep if female == 0
						if "`pop'" == "female" 			keep if female == 1
						if "`pop'" == "equal" {
							collapse (first) ageprim agesec married (mean) `y'* `compo' dweght, by(id)
							qui gen second=1
							qui replace second=2 if married==1
							expand second						
								cap drop count
								bys id: gen count=_n
								qui replace second=count-1
							qui gen age = .
								qui replace age = ageprim if second == 0
								qui replace age = agesec  if second == 1
						}
					
						keep if age >= agebin[`i',1] & age < agebin[`i'+1,1] 
						local age = agebin[`i',1]
						di "Age group: `age'"	

					* Total number of units  and total income (or wealth)
						qui su dweght, meanonly
						local n = r(sum) / 10e10
						qui su `y' [w=dweght], meanonly
						local total = r(sum) / 10e10

					* Compute statistics (need commands shcomp, avgcomp and threshcomp to be loaded)
						if "`y'" != "hweal" {
							shcomp    `y' `compo' [w=dweght], matname(sh`yr'`pop'`age')
						}

					* For wealth statistics: mixed method (ranking by wealth without KG capitalized)
						if "`y'" == "hweal"  {
							shcomp    hwealnokg hweal `compo' [w=dweght], matname(sh`yr'`pop'`age')
						}			

					* Display matrices of results 	
						mat sh`yr'`pop'`age'  = (`yr', `n', `total', sh`yr'`pop'`age')
						mat sh`y'`pop'`age'   = (nullmat(sh`y'`pop'`age')  \ sh`yr'`pop'`age')
						mat list sh`y'`pop'`age'	
				}

			* Export results in Excel
				clear
				svmat sh`y'`pop'`age', names(col)
				rename c2 n
				rename c3 total
				qui compress
				export excel using "$diroutsheet/compo`y'`pop'`age'.xlsx", first(var) replace

			* Create matrix of average from matrix of shares
					* rename c1 year
					* foreach var of varlist *0 *1 *2 *3 *4 *5 *6 *7 {
					* 	replace `var' = `var' * total / (1 * n) 		if substr("`var'",-1,1) == "0" 
					* 	replace `var' = `var' * total / (0.5 * n) 		if substr("`var'",-1,1) == "1"
					* 	replace `var' = `var' * total / (0.1 * n) 		if substr("`var'",-1,1) == "2"
					* 	replace `var' = `var' * total / (0.05 * n)		if substr("`var'",-1,1) == "3"
					* 	replace `var' = `var' * total / (0.01 * n) 		if substr("`var'",-1,1) == "4"
					* 	replace `var' = `var' * total / (0.005 * n) 	if substr("`var'",-1,1) == "5"
					* 	replace `var' = `var' * total / (0.001 * n) 	if substr("`var'",-1,1) == "6"
					* 	replace `var' = `var' * total / (0.0001 * n) 	if substr("`var'",-1,1) == "7"
					* }
					* qui compress
					* export excel using "$diroutsheet/compoavg`y'`pop'`age'compo.xlsx", first(var) replace	
				

		}		
	}
}	


timer off 14


********************************************************************************
* Fraction retained earnings and corporate tax in top groups
********************************************************************************

timer on 15

	foreach var in 	corptax hwequ hwpen  {
	*foreach var in hwequ  {		
		foreach yr of numlist $years { 
			use peinc `var' dweght id married  using "$dirusdina/usdina`yr'.dta", clear
				collapse (first) married (mean) peinc `var' dweght, by(id)
				qui gen second=1
				qui replace second=2 if married==1
				expand second

				shcomp peinc `var' [w=dweght], matname(sh`var'`yr')
					mat sh`var'`yr'  = (`yr', sh`var'`yr')
					mat sh`var'  = (nullmat(sh`var')  \ sh`var'`yr')
					mat list sh`var'
				
		}		
				clear
				svmat sh`var', names(col)
				qui compress
				export excel using "$diroutsheet/sh`var'.xlsx", first(var) replace		
			
	}

timer off 15

********************************************************************************
* Average post-tax income, educ proportional vs. lump sum
********************************************************************************

timer on 16 

	foreach yr of numlist $years { 

		use poinc poinc2  dweght id married  using "$dirusdina/usdina`yr'.dta", clear

			collapse (first) married (mean) poinc poinc2 dweght, by(id)
			qui gen second=1
			qui replace second=2 if married==1
			expand second

			avgcomp poinc [w=dweght], matname(avgpoinc`yr')
				mat avg`yr' = (`yr', avgpoinc`yr')
				mat avg = (nullmat(avg) \ avg`yr')

			avgcomp poinc2 [w=dweght], matname(avgpoinceduc`yr')
				mat avgeduc = (nullmat(avgeduc) \ avgpoinceduc`yr')

	}

mat avg = (avg, avgeduc)
clear 
svmat avg, names(col)
export excel using "$diroutsheet/avgpoinceduc.xlsx", first(var) replace		


* Check: average number of kids by pre-tax income group

foreach pop in indiv equal {
	foreach yr of numlist $years { 

		use poinc dweght id married xkidspop  using "$dirusdina/usdina`yr'.dta", clear

			if "`pop'" == "equal" {
				collapse (first) married (mean) poinc xkidspop dweght, by(id)
				qui gen second=1
				qui replace second=2 if married==1
				expand second
				replace xkidspop = xkidspop / 2 if married == 1
			}

			if "`pop'" == "indiv" replace xkidspop = xkidspop / 2 if married == 1

			avgcomp poinc xkidspop [w=dweght], matname(avgkids`yr')
				mat avg`yr' = (`yr', avgkids`yr')
				mat avg`pop' = (nullmat(avg`pop') \ avg`yr')
	}

clear 
svmat avg`pop', names(col)
export excel using "$diroutsheet/avgkids`pop'.xlsx", first(var) replace		
}

timer off 16


********************************************************************************
* Post-tax income without government deficit
********************************************************************************

mat drop _all
timer on 17 

	foreach yr of numlist $years { 
		
		use poinc govin prisupgov dweght id married  using "$dirusdina/usdina`yr'.dta", clear

			collapse (first) married (mean) poinc govin prisupgov dweght, by(id)
			qui gen second=1
			qui replace second=2 if married==1
			expand second

			gen poinc_nodef = poinc - govin - prisupgov
			avgcomp poinc_nodef [w=dweght], matname(avgpoinc`yr')
				mat avg`yr' = (`yr', avgpoinc`yr')
				mat avg = (nullmat(avg) \ avg`yr')

	}

clear 
svmat avg, names(col)
export excel using "$diroutsheet/avgpoinc_nodef.xlsx", first(var) replace		


* resetting dweght to the standard (non-calibrated) weight
foreach yr of numlist $years { 
	if $online==1 & $calibweight==1 {
		use "$dirusdina/usdina`yr'.dta", clear
		replace dweght=dweght_old
		save "$dirusdina/usdina`yr'.dta", replace
	}
}

timer off 17

********************************************************************************
* Compute fiscal income / pre-tax income ratio across the distribution
********************************************************************************

mat drop _all
timer on 18 

foreach y in peinc hweal { 
* foreach y in  hweal { 	
	foreach yr of numlist $years { 

		use peinc hweal fiinc fninc id married dweght using "$dirusdina/usdina`yr'.dta", clear

		collapse (first) married (mean) peinc hweal fiinc fninc dweght, by(id)
		qui gen second=1
		qui replace second=2 if married==1
		expand second

		if "`y'" == "peinc"	gperc peinc peinc fiinc fninc [w=dweght], matname(fiscal_vs_pretax`yr'`y')
		if "`y'" == "hweal"	gperc hweal peinc fiinc fninc [w=dweght], matname(fiscal_vs_pretax`yr'`y')
		mat list fiscal_vs_pretax`yr'`y'

	* Add top 400 as separate row
		qui sum `y' [fw=dweght], mean
			local total = r(sum)
		qui sum dweght, mean 
			local total_pop = round(r(sum) / 1e5, 1)
		qui cumul `y' [fw=dweght], gen(cum) freq
		qui keep if cum >= (`total_pop' - 400) * 1e5
		
		collapse (count) nb = dweght (min) thres = `y' (mean) avg = `y' fiinc fninc peinc (sum) sh = `y' [fw=dweght]
		*if "`y'" == "peinc"  collapse (count) nb = dweght (min) thres = `y' (mean) avg = `y' fiinc fninc (sum) sh = `y' [fw=dweght]
		*if "`y'" == "hweal"  collapse (count) nb = dweght (min) thres = `y' (mean) avg = `y' fiinc fninc peinc  (sum) sh = `y' [fw=dweght]	
		replace nb = nb/1e5
		gen gperc = 400
		replace sh = sh / `total'
		cap order gperc nb thres sh avg fiinc fninc peinc
		mkmat _all, matrix(top400`yr'`y')
		mat fiscal_vs_pretax`yr'`y' = fiscal_vs_pretax`yr'`y' \ top400`yr'`y'

		* Export results in Excel
			clear
			svmat fiscal_vs_pretax`yr'`y', names(col)
			gen ratio_kg = fiinc / peinc
			gen ratio_nokg = fninc / peinc
			qui compress
			export excel using "$diroutsheet/fiscal_vs_pretax`yr'`y'", first(var) replace

		}	
}

timer off 18
timer list

********************************************************************************
* Growth of pre-tax income, decomposing labor vs. capital income
********************************************************************************
*/
*/
mat drop _all

foreach yr of numlist 1980 2018 {
	
	use peinc* id married dweght using "$dirusdina/usdina`yr'.dta", clear

	assert round(peinc) == round(peinck + peincl)
		
	collapse (first) married (mean) peinc* dweght, by(id)
		qui gen second=1
		qui replace second=2 if married==1
		expand second

	gperc peinc peincl peinck [w=dweght], matname(inc`yr')
	clear 
	svmat inc`yr', names(col)
		rename gperc gperc`yr'
		rename avg peinc`yr'
		rename peincl peincl`yr'
		rename peinck peinck`yr'
		keep  gperc`yr' peinc`yr' peincl`yr' peinck`yr'
		order gperc`yr' peinc`yr' peincl`yr' peinck`yr'
	mkmat _all, mat(inc`yr')
	mat growth = (nullmat(growth), inc`yr')
}
	
	* Export results in Excel
		clear
		svmat growth, names(col)
		qui compress
		export excel using "$diroutsheet/growth", first(var) replace



