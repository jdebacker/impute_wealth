* Generates DINA collapsed files: g-percentiles in row and averages in column, one file per year and year x population
* Part 1 collapses by y (people ranked by y)
* Part 2 collapses by y x age (people ranked by y within age)

* All income concepts matching national income

*global 	y     	"fiinc fninc fainc flinc fkinc ptinc plinc pkinc diinc hweal" 
global 	y     	"hweal" 

*----------------------------------------------------------
* Part 1: without age dimension
*----------------------------------------------------------


* New code
	* foreach u of global pop {
	* 	global unit="`u'"
	* 	foreach y of varlist $y {
	* 		foreach yr of numlist $years { 

	* 		*  Define components	
	* 			if "`var'" == "fiinc" local compo "filin fiwag filal ficap filak firen fiint fidiv fikgi"
	* 			if "`var'" == "fninc" local compo "fnlin fnwag fnbus fnren fnint fndiv"
	* 			if "`var'" == "fainc" local compo "faemp famil fahou faequ fafix fabus fapen fadeb" 
	* 			if "`var'" == "flinc" local compo "flemp flwag flsup flmil" 
	* 			if "`var'" == "fkinc" local compo "fkhou fkequ fkfix fkbus fkpen fkdeb fkmor fknmo"								 
	* 			if "`var'" == "ptinc" local compo "ptemp ptmil ptben ptcon pthoumain pthourent ptequ ptfix ptbus ptmor ptnmo"
	* 			if "`var'" == "plinc" local compo "plemp plmil plbel plcon"
	* 			if "`var'" == "pkinc" local compo "pkbek pkhou pkequ pkfix pkbus pkdeb"
	* 			if "`var'" == "diinc" local compo "dipre diprl diprk dipro ditax diest dicor dioth diben divet dikdn dicxp"   
	* 			if "`var'" == "hweal" local compo "hwequ bond currency nonmort rental ownerhome ownermort hwbus hwpen"


	* 			use  "$root/output/dinafiles/usdina`yr'.dta", clear

	* 		*  Create / rename variables to obtain desired compo and matching of national income
	* 			quietly {
	* 				if  "`var'" == "fiinc"  {
	* 					gen filal = 2 * fibus / 3 // split business income into labor and capital
	* 					gen filak = 1 * fibus / 3
	* 					gen filin = fiwag + filal
	* 					gen ficap = filak + firen + fiint + fidiv + fikgi
	* 				}	
	* 				if  "`var'" == "fninc"  {
	* 					rename fiwag fnwag
	* 					rename fibus fnbus
	* 					rename firen fnren
	* 					rename fiint fnint
	* 					rename fidiv fndiv
	* 					gen fnlal = 2 * fnbus / 3 // split business income into labor and capital
	* 					gen fnlin = fnwag + fnlal
	* 					replace fnbus = fnbus / 3
	* 					gen fncap = fnbus + fnren + fnint + fndiv
	* 				}		
	* 				if  "`var'" == "flinc"  {
	* 					gen shemp = flemp / (flemp + flmil) // Allocate labor product taxes to components
	* 					replace shemp = 0 if shemp == .
	* 					replace flemp = flemp + flprl * shemp
	* 					replace flmil = flmil + flprl * (1-shemp)
	* 					drop shemp
	* 					// for now do not allocate labor product taxes to flwag & flsup; could be done here
	* 					} 
	* 				if  "`var'" == "fkinc"  {
	* 					replace fkinc = fkinc + govin + npinc // add income to match national income						
	* 					replace fkfix = fkfix + govin + npinc 
	* 				}									
	* 				if  "`var'" == "fainc"  {
	* 					gen shemp = flemp / (flemp + flmil) // Allocate labor product taxes to components
	* 					replace shemp = 0 if shemp == .
	* 					replace flemp = flemp + flprl * shemp
	* 					replace flmil = flmil + flprl * (1-shemp)
	* 					drop shemp
	* 					rename flemp faemp // renamove compo with fa prefix
	* 					rename flmil famil
	* 					rename fkhou fahou
	* 					rename fkequ faequ
	* 					rename fkfix fafix
	* 					rename fkbus fabus
	* 					rename fkpen fapen
	* 					rename fkmor famor
	* 					rename fknmo fanmo 
	* 					replace fainc = fainc + govin + npinc // add income to match national income						
	* 					replace fafix = fafix + govin + npinc 
	* 				}
	* 				if "`var'" == "plinc" {
	* 					gen shemp = flemp / (flemp + flmil) // Allocate labor product taxes to components
	* 					replace shemp = 0 if shemp == .
	* 					replace flemp = flemp + flprl * shemp
	* 					replace flmil = flmil + flprl * (1-shemp)
	* 					drop shemp
	* 					rename flemp plemp // Rename compo with pl prefix
	* 				 	rename flmil plmil
	* 				 	replace plemp = plemp + prisupen // add income to match national income

	* 				}
	* 				if "`var'" == "pkinc" {
	* 					rename fkfix = pkfix  // Rename  compo with pk prefix
	* 					rename fkhou  pkhou 
	* 					rename fkequ pkequ
	* 			 		rename fkbus pkbus
	* 			 		rename fkdeb pkdeb
	* 			 		drop pkpen // add income to match national income; for pension this means count all pension fund capital income
	* 			 		rename fkpen pkpen 
	* 			 		replace pkfix = pkfix + govin + npinc 
	* 			 		drop pkinc
	* 			 		gen pkinc = pkfix + pkhou + pkequ + pkbus + pkdeb + pkpen + pkbek + govin + npinc 						
						
	* 				}		
	* 				if "`var'" == "ptinc" {
	* 					gen shemp = flemp / (flemp + flmil) // Allocate labor product taxes to components
	* 					replace shemp = 0 if shemp == .
	* 					replace flemp = flemp + flprl * shemp
	* 					replace flmil = flmil + flprl * (1-shemp)
	* 					drop shemp
	* 					rename flemp ptemp // Rename all compo with pt prefix
	* 			 		rename flmil ptmil
	* 			 		*rename plben ptben
	* 			 		rename plbel ptbel
	* 			 		rename plcon ptcon
	* 			 		rename pkbek ptbek
	* 			 		rename fkhou pthou
	* 					rename fkequ ptequ
	* 			 		rename fkfix ptfix
	* 			 		rename fkbus ptbus
	* 			 		rename fkdeb ptdeb
	* 			 		*rename fkmor ptmor
	* 			 		*rename fknmo ptnmo
	* 			 		replace plemp = plemp + prisupen // add income to match national income
	* 			 		drop pkpen 
	* 			 		rename fkpen pkpen 
	* 			 		replace pkfix = pkfix + govin + npinc 
	* 			 		drop ptinc
	* 			 		gen ptinc = ptemp + ptmil + ptcon + ptbel + ptbek + pthou + ptequ + ptfix + ptbus + ptpen + ptdeb
	* 				}
	* 				if "`var'" == "diinc" {
	* 					replace fkprk = fkprk - proptax //  Isolate property tax from capital product taxes for pre-62 imputations
	* 					foreach tax in flprl fkprk proptax ditax estatetax corptax othercontrib { 
	* 					replace `tax' = - `tax' // put taxes with a minus sign so that compo add up to 100%
	* 					}
	* 					rename ptinc dipre // Rename all compo with di prefix
	* 					rename flprl diprl
	* 					rename fkprk diprk
	* 					rename proptax dipro
	* 					rename estatetax diest
	* 					rename corptax dicor
	* 					rename othercontrib dioth
	* 					gen diben = divet + dicred + diwco + difoo + disup + dicao
	* 					rename inkindinc dikdn
	* 					rename colexp dicxp
	* 					replace dipre = (flemp + flmil + flprl) + (plcon + plben + prisupenprivate) + (fkhou + fkequ + fkfix + fkbus + fkpen + fkdeb + npinc) // add income to match national income
	* 					gen didef = govin + prisupgov 
	* 					gen diinc = dipre + dipro + diest + dicor + dioth + diben + dikdn + dicxp + didef 
	* 				}		
	* 			* 	if "`var'" == "princ" {
	* 			* 		rename fainc prfai
	* 			* 		rename npinc prnpi
	* 			* 		rename govin prgov
	* 			* 	}
	* 			* 	if "`var'" == "peinc" {
	* 			* 		rename ptinc pepti
	* 			* 		rename npinc penpi
	* 			* 		rename govin pegov
	* 			* 		rename prisupen pesup
	* 			* 		rename invpen peinv
	* 			* 	}	
	* 			* 	if "`var'" == "poinc" {
	* 			* 		rename diinc podii
	* 			* 		rename npinc ponpi
	* 			* 		rename govin pogov
	* 			* 		rename prisupenprivate posup
	* 			* 		rename prisupgov posug	
	* 			* 		rename invpen poinv				
	* 			* 	}
	* 			* 	if "`var'" == "hweal" {
	* 			* 		qui gen bond = taxbond + muni 
	* 			* 	}	
	* 			* }

	* 			keep `var'* `compo' dweght* id married second female old

	* 		*  Restrict to population of interest 
	* 			if "`pop'" == "taxu" collapse (sum) `var'* `compo' (mean) dweght, by(id)
	* 			if "`pop'" == "equal" {
	* 			collapse (first) married (mean) `var'* `compo' dweght, by(id)
	* 			qui gen second=1
	* 			qui replace second=2 if married==1
	* 			expand second
	* 			}
	* 			if "`pop'" == "oldwgt" {
	* 				collapse (sum) `var'* `compo' (mean) dweght dweghttaxu, by(id)
	* 				replace dweght = dweghttaxu
	* 				drop dweghttaxu
	* 			}
	* 			if "`pop'" == "working" keep if old == 0
	* 			if "`pop'" == "male" 	keep if female == 0
	* 			if "`pop'" == "female"  keep if female == 1

	* 		*  Compute component tables	
	* 			if "`var'" != "hweal" shcomp    `var' `compo' [w=dweght], matname(compo`yr'`pop')
	* 			if "`var'" == "hweal" shcomp   hwealnokg `var' `compo' [w=dweght], matname(compo`yr'`pop')

	* 		* Display matrices of results 	
	* 			mat compo`yr'`pop'  = (`yr', compo`yr'`pop')
	* 			mat `var'`pop'   = (nullmat(`var'`pop')  \ compo`yr'`pop')
	* 			mat list `var'`pop'	
	* 		}




* Old code


use "$root/output/dinafiles/usdina$yr.dta", clear


* Loop over population of interest 
if "`u'"=="t" {
ds dweght, not  
gen hhold=id 
collapse  (sum) `r(varlist)' (mean) dweght, by(hhold)
drop hhold
}
if "`u'" == "m" keep if female==0
if "`u'" == "f" keep if female==1
if "`u'" == "e" keep if old == 0

* Create g-percentiles for our y variables
foreach y of varlist $y {
cumul `y' [w=dweght], gen(rank_`y') 
gen ptile_`y'=0
replace ptile_`y'= int(100*rank_`y') if rank_`y'<0.99
replace ptile_`y'=min(int(1000*rank_`y'),999)/10 if rank_`y'>=0.99 & rank_`y'<0.999
*replace ptile_`y'=min(int(10000*rank_`y'),9999)/100 if rank_`y'>=0.999 
replace ptile_`y'=min(int(10000*rank_`y'),9999)/100 if rank_`y'>=0.999 & rank_`y'<0.9999
replace ptile_`y'=min(int(100000*rank_`y'),99999)/1000 if rank_`y'>=0.9999
drop rank_`y'
rename ptile_`y' p`y'


* Collapses by g-percentile
preserve
collapse (count) n`y'=dweght (min) t`y'=`y' (mean) a`y'=`y' ${`y'} ${m${`y'}} [fw=dweght], by(p`y')  
replace n`y'=round(n`y'/1e5)




* Rename income and wealth components (make sure each compo is uniquely named across all y and pop loops otherwise impossible to move to big matrix)   
local concept=substr("`y'",1,2)
foreach var of varlist ${`y'} ${m${`y'}} {
local compo=substr("`var'",3,3)
rename `var' a`concept'`compo'
}



* Rename with suffix 992 to indicate adults 20+
rename (n* a* t*) (n*992 a*992 t*992)


* Move collapsed file into matrix
mkmat _all, matrix(`y')
matrix results`u'${yr}=nullmat(results`u'${yr}), `y'
restore
}



* Exports one .dta file by pop x year
xsvmat double results`u'${yr}, fast names(col)
clear matrix
gen p=pfiinc
drop p?????
gen year=$yr
gen pop="$unit"
reshape wide n* t* a*, i(p) j(pop) string
save "$root/output/export/collapsed/collapsed${yr}${unit}noage", replace

}



* Exports one .dta file by year (merged on pop)
use "$root/output/export/collapsed/collapsed${yr}inoage.dta", clear
keep p year
save "$root/output/export/collapsed/collapsed${yr}noage.dta", replace
foreach u of global pop {
 merge 1:1 year p using "$root/output/export/collapsed/collapsed${yr}`u'noage"
 drop _m
 }
save "$root/output/export/collapsed/collapsed${yr}noage.dta", replace




*----------------------------------------------------------
* Part 2: with age dimension
*----------------------------------------------------------




foreach u of global pop {
global unit="`u'"

use "$root/output/dinafiles/usdina$yr.dta", clear
cap drop ageg
gen ageg=0
local ii=20
foreach num of numlist 1/15 {
replace ageg=`ii'1 if age>=`ii' & age<`ii'+5
local ii=`ii'+5
}
replace ageg=998 if age>=80
replace ageg=991 if age<20



* Loop over population of interest (tax units, males, females, or individuals)
if "`u'"=="t" {
ds dweght, not  
gen hhold=id 
gen age2=age
collapse  (sum) `r(varlist)' (mean) dweght age2, by(hhold)
cap drop hhold 
cap drop age
rename age2 age
}
if "`u'"=="m" {
keep if female==0
}
if "`u'"=="f" {
keep if female==1
}


* Create g-percentiles for our y variables
foreach y of varlist $y {
cumul `y' [w=dweght], by(ageg) gen(rank_`y') 
gen ptile_`y'=0
replace ptile_`y'= int(100*rank_`y') if rank_`y'<0.99
replace ptile_`y'=min(int(1000*rank_`y'),999)/10 if rank_`y'>=0.99 & rank_`y'<0.999
replace ptile_`y'=min(int(10000*rank_`y'),9999)/100 if rank_`y'>=0.999 
*replace ptile_`y'=min(int(10000*rank_`y'),9999)/100 if rank_`y'>=0.999 & rank_`y'<0.9999
*replace ptile_`y'=min(int(100000*rank_`y'),99999)/1000 if rank_`y'>=0.9999
drop rank_`y'
rename ptile_`y' p`y'



* Collapses by g-percentile
preserve
collapse (count) n`y'=dweght (min) t`y'=`y' (mean) a`y'=`y' ${`y'} ${m${`y'}}  [fw=dweght], by(p`y' ageg)  
replace n`y'=round(n`y'/1e5)




* Rename income and wealth components (make sure each compo is uniquely named across all y and pop loops otherwise impossible to move to big matrix)   
local concept=substr("`y'",1,2)
foreach var of varlist ${`y'} ${m${`y'}} {
local compo=substr("`var'",3,3)
rename `var' a`concept'`compo'
}
rename ageg ageg`y'


* Reshape age wide
reshape wide n`y' t`y' a?????, i(p`y') j(ageg`y')



* Move collapsed file into matrix
mkmat _all, matrix(`y')
matrix results`u'${yr}=nullmat(results`u'${yr}), `y'
restore
}



* Exports one .dta file by pop x year
xsvmat double results`u'${yr}, fast names(col)
clear matrix
gen p=pfiinc
drop p?????
gen year=$yr
gen pop="$unit"
reshape wide n* t* a*, i(p) j(pop) string
save "$root/output/export/collapsed/collapsed${yr}${unit}", replace

}



* Exports one .dta file by year (merged on pop)
use "$root/output/export/collapsed/collapsed${yr}i.dta", clear
keep p year
save "$root/output/export/collapsed/collapsed${yr}.dta", replace
foreach u of global pop {
 merge 1:1 year p using "$root/output/export/collapsed/collapsed${yr}`u'"
 drop _m
 }
save "$root/output/export/collapsed/collapsed${yr}.dta", replace


* Merge with noage
merge 1:1 year p using "$root/output/export/collapsed/collapsed${yr}noage"
drop _m
order year p *99* *10* *20* *25* *30* *35* *40* *45* *50* *55* *60* *65* *70* *75* *80* *85* *90*
save "$root/output/export/collapsed/collapsed${yr}.dta", replace



