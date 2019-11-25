* Merge and exports DINA collapsed files in .csv

/*
clear
clear matrix
global 	y     	"fiinc fninc 	   fainc flinc fkinc ptinc plinc pkinc diinc  hweal" 

* Export averages, thresholds, and numbers of units variables
foreach t of numlist $years {
append using "$root/output/export/collapsed/collapsed`t'.dta"
}

outsheet using "$root/output/export/averages.csv",  delimiter(;) replace



* Export macro totals (in billions) and popluation totals (in thousands)
clear matrix
* Total number of units by age x y group
insheet using "$root/output/export/averages.csv",  delimiter(;) clear
local ageg "99 10 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90"
foreach y of global y {
local concept=substr("`y'", 1, 2)
foreach u of global pop {
foreach age of local ageg {
preserve
keep year p n`y'`age'`u'
collapse (sum) n`y'`age'`u',  by(year)  
mkmat n`y'`age'`u', matrix(n`y'`age'`u')
matrix nresults=nullmat(nresults), n`y'`age'`u'
restore
}
}
}
* Totals for each `y'`var'`age'`pop' variable
insheet using "$root/output/export/averages.csv",  delimiter(;) clear
local ageg "99 10 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90"
foreach y of global y {
local concept=substr("`y'", 1, 2)
foreach u of global pop {
foreach age of local ageg {
preserve
keep year p n`y'`age'`u' a`concept'???`age'`u'
collapse (sum) a* [fw=n`y'`age'`u'],  by(year)  
drop year
mkmat _all, matrix(a`y'`age'`u')
matrix aresults=nullmat(aresults), a`y'`age'`u'
restore
}
}
}

matrix results=nresults, aresults
xsvmat double results, fast names(col)
foreach var of varlist a* {
replace `var'=round(`var'/1e9,.001)
}
foreach var of varlist n* {
replace `var'=round(`var'/1e3)
}
gen year=0
local ii=1
foreach yr of numlist $years {
replace year=`yr' if _n==`ii'
local ii=`ii'+1
}
rename (n* a*) (p* m*)
order year *99* *10* *20* *25* *30* *35* *40* *45* *50* *55* *60* *65* *70* *75* *80* *85* *90*

save "$root/output/export/collapsed/totals.dta", replace
outsheet using "$root/output/export/totals.csv",  delimiter(;) replace





* Export top shares
clear matrix
insheet using "$root/output/export/averages.csv",  delimiter(;) clear
merge m:1 year using "$root/output/export/collapsed/totals.dta"
local ageg "99 10 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90"
foreach y of global y {
local concept=substr("`y'", 1, 2)
foreach u of global pop {
foreach age of local ageg {
sort year p
by year: gen s`y'`age'`u'=1-sum(a`y'`age'`u'[_n-1]*n`y'`age'`u'[_n-1])/(m`y'`age'`u'*1e9)
*sort year p
*by year: replace s`y'`age'`u'=1-sum(s`y'`age'`u')
*gen q`y'`age'`u'=s`y'`age'`u'[_n-1]
}
}
}
keep year p s* 
outsheet using "$root/output/export/shares.csv",  delimiter(;) replace

*/

* Extract from datagraph, October 15 2016
* For now final extract = hweal only; but I've prepared the components
* Pb with components = we don't have them by gperc at the moment, need to re-run internally after changing 
* components definition do be consistent with WID (e.g., gross housing; gross debts)

global dirgraph	   "$diroutput/graphsInternal"

* Export top wealth shares and compo
	use "$dirgraph/datagraph.dta", clear
	* keep year totequal tthweal shhweal*equal99 shhwequ*equal99 shbond*equal99 shcurrency*equal99 shnonmort*equal99 shrental*equal99 shownerhome*equal99 shownermort*equal99 shhwbus*equal99 shhwpen*equal99  
	keep year totequal tthweal ttfiinc ttprinc ttpeinc ttpoinc shfiinc?equal99 shhweal?indiv99 shprinc?equal99 shpeinc?equal99 shpoinc?equal99
	local series "hweal fiinc princ peinc poinc"
	foreach y of local series {
		local mseries "`mseries' m`y'"
		}
	*order year totequal tthweal ttprinc ttpeinc *0* *1* *2* *3* *4* *5* *6* *7* *8* *9* 
	rename sh*equal99 *
	rename sh*indiv99 *
	rename totequal nhweal0
foreach y in `series' { 		
	rename tt`y' m`y'0
	* forval i=0/10 { // component definitions WID
	* 	gen hwnfa`i' = rental`i' + ownerhome`i' + hwbus`i' // need to isolate mortgages on tenant-occupied housing
	* 	gen hwhou`i' = rental`i' + ownerhome`i'
	* 	gen hwfin`i' = hwequ`i' + bond`i' + currency`i' + hwpen`i'
	* 	gen hwfie`i' = hwfin`i' - currency`i'
	* 	gen hwfix`i' = bond`i' + currency`i' 
	* 	gen hwdeb`i' = nonmort`i' + ownermort`i'
	* 	rename currency`i' hwcud`i'
	* 	rename bond`i'     hwbol`i'
	* }
	* drop nonmort* rental* ownerhome* ownermort*	hwealnokg*

*foreach y of varlist hw*1 {
	local var = substr("`y'", 1, 5)
	gen `var'11 = `var'2 - `var'3
	gen `var'12 = `var'3 - `var'4
	gen `var'13 = `var'0 - `var'4
*}
}

*reshape long  hweal hwnfa hwhou hwfin hwfie hwfix hwdeb hwcud hwbol hwequ hwbus hwpen nhweal mhweal, i(year) j(p2)
reshape long  `series' `mseries', i(year) j(p2)
drop if (p2 >= 5 & p2<8) | p2 == 1 | p2 == 3 | p2 == 10
rename p2 p2_num
tostring p2_num, gen(p2)
replace p2 = "pall"     if p2 == "0"
replace p2 = "p90p100" if p2 == "2"
replace p2 = "p99p100" if p2 == "4"
replace p2 = "p90p95" if  p2 == "11"
replace p2 = "p95p99" if  p2 == "12"
replace p2 = "p0p90"  if  p2 == "9"
replace p2 = "p0p50"  if  p2 == "8"
replace p2 = "p0p99"  if  p2 == "13"

foreach var of varlist hw* fi* pr* pe* po* {
	rename `var' s`var'992j
}

foreach y in `series' {
	rename m`y' m`y'992j
}
rename nhweal npopul992i
tempfile groups
save `groups'

* Merge with gperc
* Import and merge all csv files
foreach y in `series' { 	
	local csvfiles : dir "$root/output/ToExcelInternal" files "gperc`y'????equal.xlsx"
	local ii = 1
	foreach file of local csvfiles {
		qui import excel using  "$root/output/ToExcelInternal/`file'", first clear
		di "Importing file `file'"
		if `ii' == 1 {
			qui gen year = substr("`file'",11,4)
			qui gen  s`y'992j = 1 - sum(sh) 
			qui save   "$root/output/export/gperc`y'.dta", replace
		}	
		if `ii' > 1 {
			qui gen year = substr("`file'",11,4)
			qui gen  s`y'992j = 1 - sum(sh[_n-1]) 
			qui append using "$root/output/export/gperc`y'.dta", 
			qui save "$root/output/export/gperc`y'.dta", replace
		}
		local ii = `ii' + 1	
	}
	qui sort year 
	compress
	cap drop thres
	replace gperc=round(gperc, .001)
	*format format(%7.3f) gperc
	tostring gperc, replace force
	gen p = "p"
	cap drop p2
	gen p2 = p + gperc
	drop p
	destring gperc, replace
	destring year, replace
	*rename nb  npopul992i
	* rename sh  
	rename avg a`y'992j
	save "$root/output/export/gperc`y'.dta", replace
}

 use "$root/output/export/gperchweal.dta", clear
	 foreach y in `series' { 	
	 merge 1:1 gperc year using "$root/output/export/gperc`y'.dta", nogen
	}
	append using `groups'


gen alpha2 = "US"
keep if year < 2015
keep alpha2 year p2 p2_num gperc npopul992i *hweal* *fiinc* *princ* *peinc* *poinc* 
*keep alpha2 year p2 p2_num gperc npopul992i *`series'*
replace npopul992i = npopul992i * 1e3
foreach y in `series' {
	replace m`y'992j = m`y'992j * 1e6
	replace a`y'992j = m`y'992j / npopul992i if p2=="pall"	
}


* Fill in gap, recompute averages and clean
	sort year p2_num gperc
	order alpha2 year p2 p2_num
	bysort year: carryforward npopul992i, replace
	foreach y in `series' {	
		bysort year: carryforward m`y'992j, replace
		replace a`y'992j = s`y'992j * m`y'992j / (0.1 * npopul992i)   if p2 == "p90p100" 
		replace a`y'992j = s`y'992j * m`y'992j / (0.01 * npopul992i)  if p2 == "p99p100" 
		replace a`y'992j = s`y'992j * m`y'992j / (0.05 * npopul992i)  if p2 == "p90p95" 
		replace a`y'992j = s`y'992j * m`y'992j / (0.04 * npopul992i)  if p2 == "p95p99" 
		replace a`y'992j = s`y'992j * m`y'992j / (0.9 * npopul992i)   if p2 == "p0p90" 
		replace a`y'992j = s`y'992j * m`y'992j / (0.5 * npopul992i)   if p2 == "p0p50" 
		replace a`y'992j = s`y'992j * m`y'992j / (0.99 * npopul992i)  if p2 == "p0p99" 
	}
	drop p2_num gperc

rename *princ* *fainc*
rename *peinc* *ptinc*
*rename *dicsh* *cainc* 	
rename *poinc* *diinc*	

outsheet using "$root/output/export/main.csv",  delimiter(;) replace





