*****************************************************************************************************************
* 3/2016: tabulation is a subroutine that prepares the collapsed table using internal data
* requires to have defined globals $cellvar $cellcoarse $outvar $mincell $tabname $dataname in main program impute.do
* $cellvar is the list of categorical variables to divide data in cells
* $cellcoarse is the list of categorical variables to merge too small initial cells into coarser cells
* $outvar is the list of outcome variables (need to sum to one)
* $mincell is the minimum # of records per cell (aggregation if cells too small)
* $tabname is the name of the collapsed dataset created and saved by this subroutine
* $dataname is the name of the imputed dataset used and re-saved by this subroutine
*****************************************************************************************************************

* cd c:\saez\usdina\programs

if $data==1 & $test==1 {
*************************************************************************
* preparing the collapsed dataset internal only
*************************************************************************
keep dweght one $cellvar $outvar 
cap drop test
* this collapse is super memory intensive, fails for 2014 on IRS PC
if $yr<2014 | c(k)<1500 {
	collapse (rawsum) one dweght (mean) $outvar [w=dweght], by ($cellvar)
}

* need to program work around memory limitation for yr>=2014 by splitting the collapse 
if $yr>=2014 & c(k)>=1500 {
	foreach age of numlist $agebins {
		preserve
		keep one dweght $cellvar age_m`age'*
		collapse (rawsum) one dweght (mean) age* [w=dweght], by ($cellvar)
		sort $cellvar
		save  $dircollapse/aux`age'.dta, replace
		restore
	}
	use $dircollapse/aux0.dta, clear
	foreach age of numlist $agebinsplus {
		merge 1:1 $cellvar using $dircollapse/aux`age'.dta
		cap drop _merge
	}
}

gen toofewobs=0
replace toofewobs=1 if one<$mincell
display "# CELLS TOO SMALL"
count if toofewobs==1
sum toofewobs [w=dweght]
global jjm=$jjm+1
cap matrix monitor[$yr-1979+1,$jjm]=r(N)
global jjm=$jjm+1
cap matrix monitor[$yr-1979+1,$jjm]=r(mean)

* aggregating small cells, aggregate them by $cellcoarse in step 0 and aggregate all remaining cells in step 1
cap gen uni=1

cap gen aggcell=0
label variable aggcell "=0 if one cell, =1 if coarse cell (shwag pool), =2 all remaining cells (full pool)"

foreach step of numlist 0/1 {
	if `step'==0 global cell2="$cellcoarse"
	* XX modified 10/2016 to avoid imputing age>=65 when oldexm,f=1, needs to be tested inside 
	if `step'==1 global cell2="$cellcoarse2"
	foreach var of varlist one dweght {
  	cap drop auxvar*
  	bys uni $cell2: egen auxvar=sum(`var') if toofewobs==1
  	* cap gen `var'2=`var'
  	replace `var'=auxvar if toofewobs==1
	}
foreach var of varlist $outvar {
  	cap drop auxvar*
  	bys uni $cell2: egen auxvar=sum(dweght*`var') if toofewobs==1
  	bys uni $cell2: egen auxvar2=sum(dweght) if toofewobs==1
  	* cap gen `var'2=`var'
  	replace `var'=auxvar/auxvar2 if toofewobs==1
	}
	replace aggcell=`step'+1 if toofewobs==1
	replace toofewobs=0
	replace toofewobs=1 if one>=1 & one<=$mincell-1
	
display "# CELLS TOO SMALL AFTER COARSENING STEP  " `step'
count if toofewobs==1
sum toofewobs [w=dweght]
global jjm=$jjm+1
cap matrix monitor[$yr-1979+1,$jjm]=r(mean)
}

/*
display "# CELLS TOO SMALL AFTER COARSENING"
count if toofewobs==1
sum toofewobs [w=dweght]
*/
drop if toofewobs==1

* added 10/2016, for pooled cells aggcell==2, need to respect oldexf and oldexm




sort $cellvar
duplicates report $cellvar
* added 11/2016 for disclosure
gen onew=round(dweght*1e-5)
keep $cellvar $outvar one aggcell onew
* desc
compress
save  $dircollapse/$tabname.dta, replace
}



*************************************************************************
* merging the collapsed table to the micro dataset and imputing, external and internal (for testing)
*************************************************************************

use $dircollapse/$dataname.dta, clear
cap drop one
merge m:1 $cellvar using $dircollapse/$tabname.dta


* drop cells from tabname that don't merge (happens in external data)
global jjm=$jjm+1
cap matrix monitor[$yr-1979+1,$jjm]= r(N)
drop if _merge==2
* some external records don't merge likely due to rounding and blurring 
* [number non merging jumps up from 50 to 100 in 1996 when wage blurring starts]
count if _merge==1
global jjm=$jjm+1
cap matrix monitor[$yr-1979+1,$jjm]= r(N)

sort id
duplicates report id
global jjm=$jjm+1
cap matrix monitor[$yr-1979+1,$jjm]= r(N)-r(unique_value)
drop _merge one*

* imputing the variable
set seed 431324
gen randm=uniform()
gen cumu=0

gen indexvar=0
local num=0
foreach var of varlist $outvar {
 local num=`num'+1
 replace indexvar=`num' if randm>=cumu & randm<cumu+`var'
 replace cumu=cumu+`var'
 drop `var'
 gen byte `var'=(indexvar==`num')
}

display "YR = " `yr' "   CUMU needs to be one uniformly"
sum cumu
* egen test=rsum($outvar)
* sum test 
* drop test
* tab indexvar

drop randm cumu indexvar 
cap drop aggcell
sort id
* desc
* compress
save $dircollapse/$dataname.dta, replace



