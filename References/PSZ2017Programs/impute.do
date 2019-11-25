*****************************************************************************************************************
* 3/2016: adding synthetic variables for PUF files using INSOLEs
* revised 10/2016 to simplify imputation for online files
*****************************************************************************************************************

* XX 10/2016 to do, do here coarse interpolation gender*agecoarse for single, agecoarse for married
*******************************************************************************************************
* internal 1979+: create matrix for singles for gender*agecoarse by agibin*shwag*kidold
* internal 1979+: create matrix for married for agecoarse by agibin*shwag*kidold
* simplest strategy: create these coarse tabs separately 
*******************************************************************************************************
* XX end to to do 10/2016

*****************************************************************************************************************
*****************************************************************************************************************
*  1979+ gender + age + earnings split (1999+) imputations using INSOLE DATA
*****************************************************************************************************************
*****************************************************************************************************************


if $yr>=1979 {


* $cellvar includes all the categorical variables used to partition data in cells
* XX careful to generate variables in specified format to avoid matching problems
* $cellcoarse provides a coarser partition to aggregate initial cells that are too small (below $mincell)
* $outvar is the set of categorical variables that include variable outcome
* $tabname is the name of the collapsed data
* $dataname is the name of the data with the imputed variable (use id for merging)


* set test=1 if you want to redo internal collapse and tests on data 
* collapses on internal data take a very long time and test works only internally
global test=1

* set simpler=1 for coarser agebins (20-44, 45-64, 65+) and not doing earnings split imputation post 1999 (to simplify)
global simpler=1

* mincell is minimum cell number allowed (eg 3)
global mincell=3
if $simpler==1 global mincell=10


global agibins="0 .1 .2 .3 .4 .5 .6 .7 .8 .9 .95 .99 .999 .9999"
global shwagbins=".1 .25 .5 .75 .95"
global splitbins="0 1 10 25 50 75 99"
*global splitbins="0 99"
global agebins="0 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90"
global agebinsplus="20 25 30 35 40 45 50 55 60 65 70 75 80 85 90"
*global agebins="0 20 35 45 55 65 75"
*global agebins="0 65"

if $simpler==1 {
* coarser agebins
global agibins="0 .2 .4 .6 .8 .9 .95 .99 .999 .9999"
global agebins="0 45 65"
global agebinsplus="45 65"
}


* foreach yr of numlist 1979/2009 {

local yr=$yr
global jjm=0
* global yr=`yr'
global jjm=$jjm+1
cap matrix monitor[`yr'-1979+1,$jjm]=`yr'

*************************************************************************
* 1) single filers only age*gender outcome
*************************************************************************

use $dirsmall/small`yr'.dta, clear
cap keep if filer==1
keep if married==0
sum married
global jjm=$jjm+1
cap matrix monitor[`yr'-1979+1,$jjm]=r(N)

global cellvar "oldexm agibin shwag ssdum pendum kiddum"
global cellcoarse "oldexm agibin"
global cellcoarse2 "oldexm"
global tabname "xcollsingle`yr'"
global dataname "xsingle`yr'"

if $simpler==1 {
* coarser cellvar
global cellvar "kidold agibin shwag"
global cellcoarse "kidold agibin"
global cellcoarse2 "kidold"
global tabname "xcollsinglecoarse`yr'"
global dataname "xsinglecoarse`yr'"
}


* creating the $cellvar variables
replace dweght=round(dweght)
cumul agi [w=dweght] if agi>=0, gen(agirank)
gen float agibin=-1
foreach num of numlist $agibins {
 replace agibin=`num' if agirank>=`num' & agi>=0
}
gen float shwag=0
foreach num of numlist $shwagbins {
 replace shwag=`num' if wages>=`num'*agi & agi>0
}
gen byte ssdum=(ssinc>0)
gen byte pendum=(peninc>0)
gen byte kiddum=(xkids>0)

gen byte kidold=0
replace kidold=1 if xkids>0
replace kidold=2 if oldexm==1

* added 10/2016
if $data==1 drop if age==.


keep $cellvar dweght age agesec female femalesec agi id
sort $cellvar
compress
desc
save $dircollapse/$dataname.dta, replace

if $data==1 {
* creating the $outvar variables
gen agerange=0
foreach num of numlist $agebins {
 replace agerange=`num' if age>=`num' & age!=.
	}

global outvar ""
foreach num of numlist $agebins {
 gen byte age`num'm=(agerange==`num' & female==0)
 gen byte age`num'f=(agerange==`num' & female==1)
 *global outvar "$outvar age`num'm age`num'f"
	}

* testing (sum of $outvar needs to be one always)
*egen test=rsum($outvar)
*sum test 
*drop test

cap gen one=1
}


global outvar ""
foreach num of numlist $agebins {
 global outvar "$outvar age`num'm age`num'f"
	}

* preparing the collapsed dataset (internally) and merging back to main data with subroutine
do programs/sub_impute.do

* generating the imputed data (this code is specific to the $outvar)

egen femaleimp=rsum(age*f)
gen ageimp=.
foreach ager of numlist $agebins {
  replace ageimp=`ager' if age`ager'm==1 | age`ager'f==1
  }

  
keep id femaleimp ageimp agibin
sort id 
duplicates report
desc
save $dircollapse/$dataname.dta, replace  

if $test==1 {    
* testing merging back inside
use   $dirsmall/small`yr'.dta, clear
cap drop ageimp femaleimp 
cap drop agibin
sort id
merge 1:1 id using $dircollapse/$dataname.dta
order age ageimp female femaleimp married 
  
* testing the data
gen wt=round(dweght*1e-5) 
tab femaleimp female [w=wt]
corr femaleimp female [w=wt]
sum femaleimp female [w=wt]  if femaleimp!=.
bys agibin: sum femaleimp female [w=wt]

gen agetrue=0
foreach ager of numlist $agebins {
  replace agetrue=`ager' if age>=`ager' & age!=.
  }

tab ageimp agetrue [w=wt]
corr ageimp agetrue [w=wt]
sum ageimp agetrue  [w=wt] if ageimp!=.
bys agibin: sum ageimp agetrue [w=wt]
}

*************************************************************************
* 2) married filers age*agesec imputation (no earnings split)
*************************************************************************

use $dirsmall/small`yr'.dta, clear
cap keep if filer==1
keep if married==1 
* if `yr'>=1999 keep if waginc==0
sum married
global jjm=$jjm+1
cap matrix monitor[`yr'-1979+1,$jjm]=r(N)

/*
* making sure agesec always refer to female spouse, obsolete after 9/2016
 cap gen old=age
 replace age=agesec if female==1 & married==1
 replace agesec=old if female==1 & married==1
 cap drop old
 */

global cellvar "oldexm oldexf agibin shwag ssdum pendum kiddum"
global cellcoarse "oldexm oldexf agibin"
global cellcoarse2 "oldexm oldexf"
global tabname "xcollmarried`yr'"
global dataname "xmarried`yr'"

if $simpler==1 {
* coarser cellvar
global cellvar "oldexm oldexf agibin shwag"
global cellcoarse "oldexm oldexf agibin"
global cellcoarse2 "oldexm oldexf"
global tabname "xcollmarriedcoarse`yr'"
global dataname "xmarriedcoarse`yr'"
}


* creating the $cellvar variables
replace dweght=round(dweght)
cumul agi [w=dweght] if agi>=0, gen(agirank)
gen float agibin=-1
foreach num of numlist $agibins {
 replace agibin=`num' if agirank>=`num' & agi>=0
}
gen float shwag=0
foreach num of numlist $shwagbins {
 replace shwag=`num' if wages>=`num'*agi & agi>0
}
gen byte ssdum=(ssinc>0)
gen byte pendum=(peninc>0)
gen byte kiddum=(xkids>0)
gen byte wagdum=(waginc>0)
* added 10/2016
if $data==1 drop if age==. | agesec==.


keep $cellvar wagdum dweght age agesec female femalesec agi id
sort $cellvar
compress
* desc
saveold  $dircollapse/$dataname.dta, replace

if $data==1 {
* creating the $outvar variables
gen agerange=0
foreach num of numlist $agebins {
 replace agerange=`num' if age>=`num' & age!=.
}
gen agesecrange=0
foreach num of numlist $agebins {
 replace agesecrange=`num' if agesec>=`num' & agesec!=.
}

global outvar ""
foreach m of numlist $agebins {
	foreach f of numlist $agebins {
		gen byte age_m`m'f`f'=(agerange==`m' & agesecrange==`f')
		*global outvar "$outvar age_m`m'f`f'"
		}
	}

	
* testing (sum of $outvar needs to be one always)
*egen test=rsum($outvar)
*sum test 
*drop test

cap gen one=1
}

global outvar ""
foreach m of numlist $agebins {
	foreach f of numlist $agebins {
		global outvar "$outvar age_m`m'f`f'"
		}
	}
* preparing the collapsed dataset and merging back to main data with subroutine
do programs/sub_impute.do

* generating the imputed data (this code is specific to the $outvar)
gen ageimp=.
gen agesecimp=.
foreach m of numlist $agebins {
	foreach f of numlist $agebins {
		replace ageimp=`m' if age_m`m'f`f'==1
		replace agesecimp=`f' if age_m`m'f`f'==1
		}
  }
  
  
  
keep id ageimp agesecimp agibin wagdum
sort id 
display "YEAR = " $yr
duplicates report
desc
saveold $dircollapse/$dataname.dta, replace  



if $test==1 {    
* testing merging back internally
use   $dirsmall/small`yr'.dta, clear
cap drop ageimp agesecimp 
cap drop agibin
sort id
merge 1:1 id using $dircollapse/$dataname.dta
order age agesec ageimp agesecimp married waginc
  
 
* testing the data
gen wt=round(dweght*1e-5) 

gen agetrue=0
foreach ager of numlist $agebins {
  replace agetrue=`ager' if age>=`ager' & age!=.
  }
gen agesectrue=0
foreach ager of numlist $agebins {
  replace agesectrue=`ager' if agesec>=`ager' & agesec!=.
  }  

tab ageimp agetrue [w=wt]
corr ageimp agetrue [w=wt]
sum ageimp agetrue  [w=wt] if ageimp!=.
bys agibin: sum ageimp agetrue [w=wt]

tab agesecimp agesectrue [w=wt]
corr agesecimp agesectrue [w=wt]
sum agesecimp agesectrue  [w=wt] if ageimp!=.
bys agibin: sum agesecimp agesectrue [w=wt]
}


*************************************************************************
* 3) married filers age*agesec*earnsplit imputation (only if simpler!=1)
*************************************************************************

if `yr'>=1999 & $simpler!=1 {
use $dirsmall/small`yr'.dta, clear
cap keep if filer==1
keep if married==1 & waginc>0
sum married
global jjm=$jjm+1
cap matrix monitor[`yr'-1979+1,$jjm]=r(N)

cap gen w2wagesprim=waginc
cap gen w2wagessec=0

/*
* [obsolete after 9/2016] making sure agesec always refer to female spouse
 cap gen old=age
 replace age=agesec if female==1 & married==1
 replace agesec=old if female==1 & married==1
 cap drop old
* making sure w2wagesec always refer to female spouse 
 cap gen w2wagesprim=waginc
 cap gen w2wagessec=0
 cap gen old=w2wagesprim
 replace w2wagesprim=w2wagessec if female==1 & married==1
 replace w2wagessec=old if female==1 & married==1
 cap drop old
 */
 
global cellvar "oldexm oldexf agibin shwag ssdum pendum kiddum"
global cellcoarse "oldexm oldexf agibin"
global cellcoarse2 "oldexm oldexf"
global tabname "xcollmarriedsplit`yr'"
global dataname "xmarriedsplit`yr'"


* creating the $cellvar variables
replace dweght=round(dweght)
cumul agi [w=dweght] if agi>=0, gen(agirank)
gen float agibin=-1
foreach num of numlist $agibins {
 replace agibin=`num' if agirank>=`num' & agi>=0
}
gen float shwag=0
foreach num of numlist $shwagbins {
 replace shwag=`num' if wages>=`num'*agi & agi>0
}
gen byte ssdum=(ssinc>0)
gen byte pendum=(peninc>0)
gen byte kiddum=(xkids>0)
* added 10/2016
if $data==1 drop if age==. | agesec==.

keep $cellvar dweght age agesec female femalesec agi w2wagessec w2wagesprim id
sort $cellvar
compress
desc
saveold $dircollapse/$dataname.dta, replace

if $data==1 {
* creating the $outvar variables
gen agerange=0
foreach num of numlist $agebins {
 replace agerange=`num' if age>=`num' & age!=.
}
gen agesecrange=0
foreach num of numlist $agebins {
 replace agesecrange=`num' if agesec>=`num' & agesec!=.
}

gen earnsplit=0
foreach num of numlist $splitbins {
 replace earnsplit=`num' if w2wagessec>=(`num'/100)*(w2wagesprim+w2wagessec)
}

global outvar ""
foreach m of numlist $agebins {
	foreach f of numlist $agebins {
		foreach sp of numlist $splitbins {
			gen byte age_m`m'f`f'sp`sp'=(agerange==`m' & agesecrange==`f' & earnsplit==`sp')
			*global outvar "$outvar age_m`m'f`f'sp`sp'"
			}
		}
	}

	
* testing (sum of $outvar needs to be one always)
* egen test=rsum($outvar)
* sum test 
* drop test

* desc


cap gen one=1
}


global outvar ""
foreach m of numlist $agebins {
	foreach f of numlist $agebins {
		foreach sp of numlist $splitbins {
			global outvar "$outvar age_m`m'f`f'sp`sp'"
			}
		}
	}
* preparing the collapsed dataset and merging back to main data with subroutine
do programs/sub_impute.do

* generating the imputed data (this code is specific to the $outvar)

gen ageimp=.
gen agesecimp=.
gen earnsplitimp=.
foreach m of numlist $agebins {
	foreach f of numlist $agebins {
		foreach sp of numlist $splitbins {
			replace ageimp=`m' if age_m`m'f`f'sp`sp'==1
			replace agesecimp=`f' if age_m`m'f`f'sp`sp'==1
			replace earnsplitimp=`sp'/100 if age_m`m'f`f'sp`sp'==1
			}
		}
  }
  
  
  
keep id ageimp agesecimp earnsplitimp agibin
sort id 
display "YEAR = " $yr
duplicates report
desc
saveold $dircollapse/$dataname.dta, replace  



if $test==1 {   
* testing merging back
use   $dirsmall/small`yr'.dta, clear
cap drop ageimp agesecimp earnsplitimp
cap drop agibin
sort id
merge 1:1 id using $dircollapse/$dataname.dta
order age agesec ageimp agesecimp married earnsplit*
  
   
* testing the data internally
gen wt=round(dweght*1e-5) 



cap gen w2wagesprim=waginc
cap gen w2wagessec=0
/*
* obsolete after 9/2016
 cap gen old=age
 replace age=agesec if female==1 & married==1
 replace agesec=old if female==1 & married==1
 cap drop old
* making sure w2wagesec always refer to female spouse
 cap gen w2wagesprim=waginc
 cap gen w2wagessec=0
 cap gen old=w2wagesprim
 replace w2wagesprim=w2wagessec if female==1 & married==1
 replace w2wagessec=old if female==1 & married==1
 cap drop old
*/


gen agetrue=0
foreach ager of numlist $agebins {
  replace agetrue=`ager' if age>=`ager' & age!=.
  }
gen agesectrue=0
foreach ager of numlist $agebins {
  replace agesectrue=`ager' if agesec>=`ager' & agesec!=.
  }  
gen earnsplittrue=0  
foreach num of numlist $splitbins {
 replace earnsplittrue=`num' if w2wagessec>=(`num'/100)*(wages)
}  

tab ageimp agetrue [w=wt]
corr ageimp agetrue [w=wt]
sum ageimp agetrue  [w=wt] if ageimp!=.
* bys agibin: sum ageimp agetrue [w=wt]

tab agesecimp agesectrue [w=wt]
corr agesecimp agesectrue [w=wt]
sum agesecimp agesectrue  [w=wt] if ageimp!=.
* bys agibin: sum agesecimp agesectrue [w=wt]

tab earnsplitimp earnsplittrue [w=wt]
corr earnsplitimp earnsplittrue [w=wt]
sum earnsplitimp earnsplittrue  [w=wt] if ageimp!=.
* bys agibin: sum earnsplitimp earnsplittrue [w=wt]
}



* end of married with wages loop for 1999+
}



**********************************************
* merging back to small file and saving
**********************************************
* combine all three files into a single one for later merging
if $simpler!=1 {
use $dircollapse/xmarried`yr'.dta, clear
if `yr'>=1999 {
	keep if wagdum==0
	append using $dircollapse/xmarriedsplit`yr'.dta
	}
append using $dircollapse/xsingle`yr'.dta	
sort id
duplicates report id
save $dirsmall/temp.dta, replace
}

if $simpler==1 {
use $dircollapse/xmarriedcoarse`yr'.dta, clear
append using $dircollapse/xsinglecoarse`yr'.dta	
sort id
duplicates report id
replace ageimp=20 if ageimp==0
replace agesecimp=20 if agesecimp==0
save $dirsmall/temp.dta, replace
}


use $dirsmall/small`yr'.dta, clear
cap drop ageimp agesecimp femaleimp
cap drop randu
if $data==0 cap drop age agesec
if `yr'>=1999 cap drop share_f2 
* XX corrected line below 8/2016
if `yr'>=1999 cap drop wagincsec
merge 1:1 id using $dirsmall/temp.dta
tab _merge 
drop wagdum agibin _merge
if $data==0 replace female=femaleimp if femaleimp!=. 
if $simpler!=1 replace ageimp=17 if ageimp==0
if $simpler!=1 replace agesecimp=17 if agesecimp==0
* imputing female, age, and wagincsec [=wife's wage]
set seed 5454326
gen randu=uniform()

cap gen age=.
cap gen agesec=.
* do not condition on data==0 to fill in missing ages in INSOLE files
* impute agesec using age when agesec missing (more common than age missing)
if $data==1 replace agesec=max(age-3,18) if agesec==. & married==1 & age!=.
if $simpler!=1 {
replace age=ageimp+trunc(5*randu) if age==. & ageimp!=. & ageimp>=20
replace agesec=agesecimp+trunc(5*randu) if agesec==. & agesecimp!=. & agesecimp>=20
replace age=ageimp+trunc(3*randu) if age==. & ageimp!=. & ageimp<20
replace agesec=agesecimp+trunc(3*randu) if agesec==. & agesecimp!=. & agesecimp<20
}

if $simpler==1 & $data==0 {
replace age=ageimp
replace agesec=agesecimp
}
* imputing missing age in internal files for coarse age imputation (added 10/2016)
if $simpler==1 & $data==1 {
replace age=ageimp+trunc(20*randu) if age==. & ageimp!=.
replace agesec=agesecimp+trunc(20*randu) if agesec==. & agesecimp!=.
}

if $simpler==1 {
cap gen share_f2=.
cap gen earnsplitimp=.
cap gen wagincsec=.
}
drop randu



if `yr'>=1999 & $simpler!=1 {
set seed 13537
gen randu=uniform()
* global splitbins="0 1 10 25 50 75 99"
cap gen share_f2=.
replace share_f2=0 if abs(earnsplitimp-0)<.0001 | abs(earnsplitimp-.01)<.0001
replace share_f2=.01*(10-0)*randu if abs(earnsplitimp-.01)<.0001
replace share_f2=.01*(10+(25-10)*randu) if abs(earnsplitimp-.1)<.0001
replace share_f2=.01*(25+(50-25)*randu) if abs(earnsplitimp-.25)<.0001
replace share_f2=.01*(50+(75-50)*randu) if abs(earnsplitimp-.50)<.0001
replace share_f2=.01*(75+(100-75)*randu) if abs(earnsplitimp-.75)<.0001
replace share_f2=1 if abs(earnsplitimp-.99)<.0001
cap gen wagincsec=.
replace wagincsec=waginc*share_f2 if wagincsec==.
drop randu
}

if `yr'>=1999 label variable earnsplitimp "Imputed frac. wages earned by wife in married with waginc>0 (lower bracket value)"
if `yr'>=1999 label variable share_f2 "Imputed fraction wages earned by wife in married filers with waginc>0 (sophisticated imputation 1999+)"
label variable ageimp "Imputed age of primary filer (husband if married), (lower bracket value)"
label variable agesecimp "Imputed age of wife in married, (lower bracket value)"
if $data==0 label variable age "Imputed age of primary filer (husband if married)"
if $data==0 label variable agesec "Imputed age of wife in married filers"
label variable femaleimp "Dummy for being female (imputed for non married filers)"
if `yr'>=1999 label variable wagincsec "Imputed wage earnings of wife based on share_f2, 1999+"

saveold $dirsmall/small`yr'.dta, replace


/*
display "TEST OF DATA, YEAR = " `yr'
gen one=1
gen wagdum=0 if waginc>0
sum one age agesec female if married==0
if `yr'<1999 sum one age agesec if married==1
if `yr'>=1999 sum one age agesec share_f2 wagdum if married==1
*/

* end of the overall insole file yr>=1979
} 

* matrix list monitor 



*****************************************************************************************************************
*****************************************************************************************************************
*  1962-1978 gender imputation using the files created at end of sharefbuild.do program
*****************************************************************************************************************
*****************************************************************************************************************

if $yr<1979 {

local yr=$yr	
use $dirsmall/small`yr'.dta, clear
keep if married==0 
cap keep if filer==1
global agibins="0 .5 .75 .9 .99 .999 .9999"
global shwagbins=".01 .25 .5 .75"
replace dweght=round(dweght)
cumul agi [w=dweght] if agi>=0, gen(agirank)
gen double agibin=-1
foreach num of numlist $agibins {
 replace agibin=`num' if agirank>=`num' & agi>=0
}
gen double shwag=0
foreach num of numlist $shwagbins {
 replace shwag=`num' if wages>=`num'*agi & agi>0
}

gen byte kidold=0
replace kidold=1 if xkids>0
replace kidold=2 if oldexm==1
gen byte kiddum=(xkids>0)
global cellvar "kidold agibin shwag"
keep $cellvar id
sort $cellvar
compress
desc
save $dircollapse/temp.dta, replace
merge m:1 $cellvar using $dircollapse/xcollgender`yr'.dta
drop if _merge==2
sort id
duplicates report id
set seed 431224
gen randm=uniform()
gen femaleimp=0
replace femaleimp=1 if randm<=female
sort id
keep id femaleimp
save $dircollapse/temp.dta, replace
count

use $dirsmall/small`yr'.dta, clear
cap drop femaleimp
sort id
merge 1:1 id using $dircollapse/temp.dta
tab _merge 
drop _merge
replace female=femaleimp if femaleimp!=.
sum femaleimp [w=dweght] 
sum femaleimp [w=dweght] if xkids>0
label variable femaleimp "Dummy for being female (imputed for non married filers)"

* added 3/2018, fixing age variable
replace age=65 if oldexm==1
replace agesec=65 if oldexf==1


save $dirsmall/small`yr'.dta, replace
}	










