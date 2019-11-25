* new program created 4/2016 to move up the creation of the aggregate tab for earnings split between spouses
* at the bottom I do the gender tabulations for imputations 1962-1978 using the 1969 and 1974 information
* this program runs on the x`yr' files before the small files are created
* program creates tables wagspouse`yr'.csv for each year combining CPS for bottom 95% and tax data (interpolated) for top 5%
*
* TO DO1: for external, produce internally for 1999+ tables of the form wagsp`year' using internal data
* TO DO2: for external, produce internally for 1979+ tables of the form xcollgender`year' using internal data
* TO DO3: CPS and tax data are not fully consistent for bottom 95% when both info available creating slight
* discontinuity in 1998 to 1999
*
******************************************************************************************
******************************************************************************************
******************************************************************************************

***************************************************************************************
* tabulations based on tax data, I create micro files work2008, work1969, work1974, work1982-1986
***************************************************************************************

* create the 2008 micro-data and table based on percentiles (instead of)
* I corrected the file wages2008corr.csv because of initial error in interpretation
* wages2008corr.csv created from IRS SOI published tabulation

local yr=2008
insheet using "$dirmatrix/wagmat/wages`yr'corr.csv", clear 
mkmat v1-v7, matrix(split) 

use "$dirirs/x`yr'.dta", clear
cap drop id
gen id=_n
gen married=(mars==2)
replace dweght=round(1000*dweght)
set seed 4301
gen rand=runiform()
set seed 1231
gen rand2=runiform()

local cols=colsof(split)-1
local rows=rowsof(split)-1

gen bracket=0
foreach brack of numlist 1/`rows' {
 replace bracket=`brack' if wages>=split[`brack'+1,1]
}
gen wagemin=split[bracket+1,1]
replace wagemin=0 if bracket==0

gen sharebrac=0
gen cumshare=0
foreach brack of numlist 1/`cols' {
 replace cumshare=cumshare+split[bracket+1,`brack'+1]
 replace sharebrac=`brack' if rand>=cumshare
}

gen sharemin=split[1,sharebrac+1]
gen sharemax=1
replace sharemax=split[1,sharebrac+2] if sharebrac+2<`cols'+1
replace sharemin=0 if sharemax==0
replace sharemin=1 if sharemin>=.999
replace sharemax=1 if sharemax>=.999

tab sharemin sharemax

cap drop share_f
gen share_f=rand2*(sharemax-sharemin)+sharemin if married==1
replace share_f=0 if married==1 & wages==0

gen wage_f=round(share_f*wages)
gen wage_m=round((1-share_f)*wages)

/*
* test I: reproduce the IRS table
gen one=1
matrix testwag = split
foreach brac of numlist 1/`rows' {
	quietly sum one [w=dweght] if married==1 & bracket==`brac' & wages>0
	local denom=r(sum_w)
	quietly sum one [w=dweght] if married==1 & bracket==`brac' & wage_f==0 & wages>0
	matrix testwag[`brac'+1,2]=r(sum_w)/`denom'
	quietly sum one [w=dweght] if married==1 & bracket==`brac' & wage_m==0 & wages>0
	matrix testwag[`brac'+1,`cols'+1]=r(sum_w)/`denom'
	
	foreach col of numlist 3/`cols' {
	quietly sum one [w=dweght] if married==1 & bracket==`brac' & wage_f/wages>testwag[1,`col'-1] & wage_f/wages<=testwag[1,`col'] & wages>0
	matrix testwag[`brac'+1,`col']=r(sum_w)/`denom'
	}

}

matrix list testwag
matrix test=100*(split-testwag)
matrix list test
* end of test I, bottom line: this test seems fine
*/

keep id wages wage_f wage_m share_f dweght married
sort id
saveold "$root/output/temp/cps/work2008.dta", replace


/*
* test II: reproduce the SSA W2 indiv table
use "$root/output/temp/cps/work2008.dta", clear
gen second=1
replace second=2 if married==1
expand second
bys id: gen count=_n
replace second=count-1
tab married second
replace wages=wage_m if married==1 & second==0
replace wages=wage_f if married==1 & second==1
sum wages [w=dweght] 
display r(sum)*1e-11
order wages wage_f wage_m married second id
* end of test II bottom line: for 2008, individual distribution from this exercise does not perfectly match the SSA tab, could be due to various factors, including married filing separately in community states, the approximation, etc.
*/

* 1969, 1974 datasets

use $dirirs/x1969.dta, clear
gen id=_n
gen married=(mars==2)
rename wght dweght
replace dweght=round(100000*dweght)
*gen share_f=w2wge/(w2mwge+w2wge)
* XX 10/2016 modified
gen share_f=0
replace share_f=w2wge/wages if married==1
replace share_f=1 if share_f>1
replace share_f=0 if wages==0 | w2mwge+w2wge==0  | share_f<0
gen wage_f=share_f*wages
gen wage_m=(1-share_f)*wages
keep id wages wage_f wage_m share_f dweght married
sort id
sum wages wage_f wage_m share_f [w=dweght] if married==1
saveold "$root/output/temp/cps/work1969.dta", replace

use $dirirs/x1974.dta, clear
gen id=_n
gen married=(mars==2)
rename wght dweght
replace dweght=round(100000*dweght)
*gen share_f=w2fwge/(w2mwge+w2fwge) if married==1
* XX 10/2016 modified
gen share_f=0
replace share_f=w2fwge/wages if married==1
replace share_f=1 if share_f>1
replace share_f=0 if wages==0 | w2mwge+w2fwge==0 | share_f<0
gen wage_f=share_f*wages
gen wage_m=(1-share_f)*wages
keep id wages wage_f wage_m share_f dweght married
sort id
sum wages wage_f wage_m share_f [w=dweght] if married==1
saveold "$root/output/temp/cps/work1974.dta", replace



* 1983-1986 datasets, use split based on total earnings (note, no sey and seysec in 1983, best to use 1984 for interp)
* case with zero spousal wages, impossible to assign wages to primary vs secondary, need to fix this later on
* secondary is always defined as the person with lowest wages so it introduces a bias downward for wives
* and secondary earnings are capped at 30K
foreach yr of numlist 1983/1986 {
	local yrr=`yr'-1900
    use $dirirs/x`yr'.dta, clear
    replace dweght=round(1000*dweght)
    cap gen seysec=0
	cap gen sey=0
	* XX 11/2016 need to modify sey and seysec internally, check XX
	* externally, this does not work well, need to import the internal files 
	if $data==1 {
	replace sey=seyprimirs+seysecirs
	replace seysec=seysecirs
	}	
	gen id=_n
	gen married=(mars==2)
	gen wage_m=wages if married==1 
	gen wage_f=0 if married==1 
	replace wage_f=mrrdsy-seysec if married==1 & secern>0
	replace wage_m=mrrdpy-(sey-seysec) if married==1 & secern>0
	replace wage_f=0 if wage_f<0 & married==1
	replace wage_m=0 if wage_m<0 & married==1
	gen share_f=wage_f/(wage_f+wage_m) if married==1
	replace share_f=0 if (wage_f+wage_m==0 | wages==0) & married==1
	replace wage_f=wages*share_f
	replace wage_m=wages*(1-share_f)
	keep id wages wage_f wage_m share_f dweght married
	sort id
	sum wages wage_f wage_m share_f [w=dweght] if married==1
	sum share_f [w=dweght] if married==1 & share_f>0, det
saveold "$root/output/temp/cps/work`yr'.dta", replace
}


* producing the fractile based tabulation wagsp`yr' that will be used for interpolation from the work`yr.dta
* datasets for 1969, 1974, 1983/6, 2008


global yearsint="1969 1974 1983/1986 2008"

matrix input perc = (0 .1 .2 .3 .4 .5 .6 .7 .8 .9 .95 .99 .999 .9999 1)
matrix input shfem = (-.01 0 .05 .25 .5 .75 .9999 1)
local shnum=colsof(shfem)
local percnum=colsof(perc)

foreach yr of numlist $yearsint {
matrix wagsp`yr' = J(`percnum'+1,`shnum'+1,.)
matrix wagsp`yr'[1,1]=`yr'
local percnum2=`percnum'-1
local shnum2=`shnum'-1
foreach pc of numlist 1/`percnum2' {
	matrix wagsp`yr'[`pc'+2,1]=perc[1,`pc']
	matrix wagsp`yr'[`pc'+2,2]=perc[1,`pc'+1]
}

use  "$root/output/temp/cps/work`yr'.dta", clear
gen aux=wages
set seed 342342
replace aux=aux+runiform()/2 if wages>0
cumul aux [w=dweght] if married==1 & wages>0, gen(rankw)
foreach sh of numlist 1/`shnum2' {
	local shmin=shfem[1,`sh']
	local shmax=shfem[1,`sh'+1]
	matrix wagsp`yr'[1,2+`sh']=`shmin'
	matrix wagsp`yr'[2,2+`sh']=`shmax'
	foreach pc of numlist 1/`percnum2' {
		local pcmin=perc[1,`pc']
		local pcmax=perc[1,`pc'+1]
		quietly sum wage_f [w=dweght] if rankw!=. & rankw>`pcmin' & rankw<=`pcmax'
		local denom=r(sum_w)
		quietly sum wage_f [w=dweght] if rankw!=. & rankw>`pcmin' & rankw<=`pcmax' & wage_f/wages>`shmin' & wage_f/wages<=`shmax'
		matrix wagsp`yr'[2+`pc',2+`sh']=r(sum_w)/`denom'
		}	
	}

matrix list wagsp`yr'
xsvmat double wagsp`yr', fast names(col)
mkmat _all, mat(wagsp`yr')
outsheet using  "$dirmatrix/wagmat/wagsp`yr'.xls", replace

}


* 1983-6 fixing the one spouse has all wages cases using 1974 case (improve later on if possible)

insheet using  "$dirmatrix/wagmat/wagsp1974.xls", clear 
mkmat c1-c9, matrix(split1974)
matrix list split1974

foreach yr of numlist 1983/1986 {
	insheet using  "$dirmatrix/wagmat/wagsp`yr'.xls", clear 
	mkmat c1-c9, matrix(split`yr')
	matrix list split`yr'
	local percnum2=rowsof(split`yr')-2
	foreach pc of numlist 1/`percnum2' {
		local aux74=split1974[2+`pc',9]/(split1974[2+`pc',3]+split1974[2+`pc',9])
		local aux=split`yr'[2+`pc',3]+split`yr'[2+`pc',9]
		matrix split`yr'[2+`pc',9]=`aux74'*`aux'
		matrix split`yr'[2+`pc',3]=(1-`aux74')*`aux'
		}
	matrix list split`yr'	
	xsvmat double wagsp`yr', fast names(col)
	mkmat _all, mat(wagsp`yr')
	outsheet using  "$dirmatrix/wagmat/wagsp`yr'.xls", replace

}


* 8/2016: add routine here if $data==1 to create wagsp`yr' with 1999-2014 xYYYY.dta files 
* use variables w2wages=w2wagesprim+w2wagessec (as in build_usdina)
* XX check that 2008 wagsp2008 and wagspint2008 are similar, check the distance 1999 to 2008

* XX temp
matrix input perc = (0 .1 .2 .3 .4 .5 .6 .7 .8 .9 .95 .99 .999 .9999 1)
matrix input shfem = (-.01 0 .05 .25 .5 .75 .9999 1)
local shnum=colsof(shfem)
local percnum=colsof(perc)
* XX end of temp


if $data==1 {
foreach yr of numlist 1999/$endyear {
matrix wagsp`yr' = J(`percnum'+1,`shnum'+1,.)
matrix wagsp`yr'[1,1]=`yr'
local percnum2=`percnum'-1
local shnum2=`shnum'-1
foreach pc of numlist 1/`percnum2' {
	matrix wagsp`yr'[`pc'+2,1]=perc[1,`pc']
	matrix wagsp`yr'[`pc'+2,2]=perc[1,`pc'+1]
}
matrix wagspN`yr'=wagsp`yr'


use  "$dirirs/x`yr'.dta", clear
gen aux=wages
gen married=(mars==2)
set seed 342342
replace aux=aux+runiform()/2 if wages>0
if $data==1 & `yr'!=1985 & `yr'!=1986 & `yr'>=1979 replace dweght=dweght*100
replace dweght=round(dweght)
cumul aux [w=dweght] if married==1 & wages>0, gen(rankw)
* bc of missing W2 income, I decide to use wages and w2wagessec to split
* cumul aux [w=dweght] if married==1 & w2wages>0, gen(rankw)
* compute share female using same code as in addsharef
gen share_ftrue=0
replace share_ftrue=w2wagessec/wages if wages>0 & married==1 & w2wagessec>=0 
replace share_ftrue=min(share_ftrue,1)
replace share_ftrue=0 if share_ftrue==. | share_ftrue<0
gen wage_f=wages*share_ftrue
replace wage_f=0 if wage_f==.


foreach sh of numlist 1/`shnum2' {
	local shmin=shfem[1,`sh']
	local shmax=shfem[1,`sh'+1]
	matrix wagsp`yr'[1,2+`sh']=`shmin'
	matrix wagsp`yr'[2,2+`sh']=`shmax'
	matrix wagspN`yr'[1,2+`sh']=`shmin'
	matrix wagspN`yr'[2,2+`sh']=`shmax'
	foreach pc of numlist 1/`percnum2' {
		local pcmin=perc[1,`pc']
		local pcmax=perc[1,`pc'+1]
		quietly sum wage_f [w=dweght] if rankw!=. & rankw>`pcmin' & rankw<=`pcmax'
		local denom=r(sum_w)
		quietly sum wage_f [w=dweght] if rankw!=. & rankw>`pcmin' & rankw<=`pcmax' & wage_f/wages>`shmin' & wage_f/wages<=`shmax'
		matrix wagsp`yr'[2+`pc',2+`sh']=r(sum_w)/`denom'
		matrix wagspN`yr'[2+`pc',2+`sh']=round(r(sum_w)*1e-2)
		* added 11/2016 to zero out cells with 1 or 2 obs.
		if round(r(sum_w)*1e-2)<10 & round(r(sum_w)*1e-2)>0 {
			matrix wagsp`yr'[2+`pc',2+`sh']=0
			matrix wagspN`yr'[2+`pc',2+`sh']=0
			}	
		
		
		}	
	}

matrix list wagsp`yr'
xsvmat double wagsp`yr', fast names(col)
mkmat _all, mat(wagsp`yr')
* added 11/2016 renormalize to sum to one for each row (due to small cells removal)
local last=`shnum'+1
display " TEST = " `last'
egen tot=rsum(c3-c`last')	
foreach num of numlist 3/`last' {
    replace c`num'=c`num'/tot if c2!=.
		}
drop tot	
*end of renormalization
outsheet using  "$dirmatrix/wagmat/wagspint`yr'.xls", replace

matrix list wagspN`yr'
xsvmat double wagspN`yr', fast names(col)
mkmat _all, mat(wagspN`yr')
outsheet using  "$dirmatrix/wagmat/wagspintN`yr'.xls", replace


}


}





********************************************************************************
* adding share_fcps using the CPS data prepared by Juliana   
* CPS excel tabs $dirmatrix/wagmat/wagcps`yr'.xls" are created here (formally in program sub_marriedwages.do)
********************************************************************************

local endyearcps=$endyear+1
foreach yr of numlist 1962/2015 {

* I create table by deciles, CPS year = actual earnings year +1
set seed 4343241

matrix input perc = (0 .1 .2 .3 .4 .5 .6 .7 .8 .9 .95 .99 .999 .9999 1)
matrix input shfem = (-.01 0 .05 .25 .5 .75 .9999 1)
local shnum=colsof(shfem)
local percnum=colsof(perc)

*foreach yr of numlist $yearcps {
matrix wagsp`yr' = J(`percnum'+1,`shnum'+1,.)
matrix wagsp`yr'[1,1]=`yr'-1
local percnum2=`percnum'-1
local shnum2=`shnum'-1
foreach pc of numlist 1/`percnum2' {
    matrix wagsp`yr'[`pc'+2,1]=perc[1,`pc']
    matrix wagsp`yr'[`pc'+2,2]=perc[1,`pc'+1]
    }

use $dirnonfilers/cpsmar`yr'.dta, clear
keep if married==1
rename wage_husband wage_m
rename wage_wife wage_f
replace dweght=round(dweght)

*use $diroutput/misc/cps/marriedwages/cpsmar`yr'_marriedwages.dta, clear
*rename wageearnings_husband wage_m
*rename wageearnings_wife wage_f
*gen dweght=round(wt*1e5)
*glue

replace wage_m=0 if wage_m==.
replace wage_f=0 if wage_f==.
replace wages=wage_m+wage_f
quietly: sum wage_m [w=dweght] if wage_m>0, detail
display "YEAR =" `yr'   "Male P99 = " r(p99) "Male P95 = " r(p95)
gen share_fcps=wage_f/wages
cap drop aux
gen aux=wages
*gen married=1
set seed 3432553
replace aux=aux+runiform()/2 if wages>0
cumul aux [w=dweght] if married==1 & wages>0, gen(rankw)

foreach sh of numlist 1/`shnum2' {
    local shmin=shfem[1,`sh']
    local shmax=shfem[1,`sh'+1]
    matrix wagsp`yr'[1,2+`sh']=`shmin'
    matrix wagsp`yr'[2,2+`sh']=`shmax'
    foreach pc of numlist 1/`percnum2' {
        local pcmin=perc[1,`pc']
        local pcmax=perc[1,`pc'+1]
        quietly sum wage_f [w=dweght] if rankw!=. & rankw>`pcmin' & rankw<=`pcmax'
        local denom=r(sum_w)
        quietly sum wage_f [w=dweght] if rankw!=. & rankw>`pcmin' & rankw<=`pcmax' & wage_f/wages>`shmin' & wage_f/wages<=`shmax'
        matrix wagsp`yr'[2+`pc',2+`sh']=r(sum_w)/`denom'
        }   
    }

matrix list wagsp`yr'
xsvmat double wagsp`yr', fast names(col)
mkmat _all, mat(wagsp`yr')
local yearirs=`yr'-1
outsheet using  "$dirmatrix/wagmat/wagcps`yearirs'.xls", replace
}


**************************************************************************************
* creating tabulations for all years 1962-endyear using the interpolation 
**************************************************************************************

* for bottom 95%, use CPS data
* for top 5%, use tax data as follows
* 1962-1968: use 1969
* 1970-1973: linear interpolation 1969 to 1974
* 1975-1982: linear interpolation 1974 to 1983
* new 9/2016: 1987-1998: linear interpolation 1986 to 1999 (wagspint1999)
* new 9/2016: 1999+: use wagspint`yr' from inside files

* old 1987-2007: linear interpolation 1986 to 2008
* old 2009+: use the 2008 table

foreach yr of numlist 1969 1974 1983 1984 1985 1986 2008 {
insheet using  "$dirmatrix/wagmat/wagsp`yr'.xls", clear 
mkmat c1-c9, matrix(tax`yr')
}
foreach yr of numlist 1999/$endyear {
insheet using  "$dirmatrix/wagmat/wagspint`yr'.xls", clear 
mkmat c1-c9, matrix(tax`yr')
}

foreach yr of numlist 1962/$endyear {
insheet using  "$dirmatrix/wagmat/wagcps`yr'.xls", clear 
mkmat c1-c9, matrix(cps`yr')
}

* creating the split`yr' matrices from 1960/2008 using both the tax`yr' + interpolation for top 5% and cps`yr' for bottom 95%

foreach yr of numlist 1962 1964 1966/$endyear {
	matrix split=cps`yr'
	* replace bottom 4 rows 13-16 by the tax based interpolation
	if `yr'<=1969 {
		matrix tempmat=tax1969
		*matrix tempmat=tax1969+(tax1974-tax1969)*(`yr'-1969)/(1974-1969)
		}
	if `yr'>1969 & `yr'<=1974  {
		matrix tempmat=tax1969+(tax1974-tax1969)*(`yr'-1969)/(1974-1969)
		}
	if `yr'>1974 & `yr'<=1983  {
		matrix tempmat=tax1974+(tax1983-tax1974)*(`yr'-1974)/(1983-1974)
		}
	if `yr'>=1983 & `yr'<=1986 {
		matrix tempmat=tax`yr'
		}	
	if `yr'>1986 & `yr'<=1998  {
			matrix tempmat=tax1986+(tax1999-tax1986)*(`yr'-1986)/(1999-1986)
			}
	if `yr'>1998 {
			matrix tempmat=tax`yr'
			}
	* for top 5% (bottom 4 rows) use tax data		
	foreach ii of numlist 13/16 {
	foreach jj of numlist 1/9 {
			matrix split[`ii',`jj']= tempmat[`ii',`jj']
			}
			}	
	
	display "year = " `yr'
	matrix list split	
	* saving matrix wagspouse`yr'.csv
	xsvmat double split, fast names(col)
	mkmat _all, mat(wagsp`yr')
	outsheet using  "$dirmatrix/wagmat/wagspouse`yr'.xls", replace
}


*****************************************************************************************************************
* 4/2016: imputing gender 1962-1978 for singles using 1969, 1974 and 1979
* divide data in coarse cells (agibins*shwag*kidold), need obs in all cells for later merging
* need to do this here rather than in impute.do because I compute interpolated matrices (so need all years first)
*****************************************************************************************************************

if $data==0 global yeargender="1969 1974"
if $data==1 global yeargender="1969 1974 1979"

foreach yr of numlist $yeargender {

use $dirirs/x`yr'.dta, clear
gen married=(mars==2)
cap rename wght dweght
replace dweght=round(100000*dweght)
keep if married==0
* recreate oldexm and xkids using the build_small code
gen oldexm=0 
cap replace oldexm=1 if agex!=. & agex>0 & (`yr'==1964 | (`yr'>=1971 & `yr'<=1974)) 
cap replace oldexm=1 if agex!=. & (agex==1 | agex==3) & (`yr'>=1982 & `yr'<=1995) 
cap replace oldexm=1 if ageex!=. & ageex>0 & (`yr'==1962 | (`yr'>=1966 & `yr'<=1970 ) | `yr'==1975)
cap replace oldexm=1 if (xfpt==2 | xfpt==3) & (`yr'>=1976 & `yr'<=1981) 
if $data==1 & `yr'>=1979 replace oldexm=(age>=65 & age!=.)
gen xkids=0
cap replace xkids=dpndx if `yr'==1977 | `yr'==1976 | (`yr'>=1971 & `yr'<=1974) | (`yr'>=1968 & `yr'<=1969) | `yr'==1966 
cap replace xkids=xocah if `yr'>=1978 
cap gen female=0
cap replace female=1 if sex==5 & `yr'==1969 & married!=1
cap replace female=1 if sex==2 & `yr'==1974 & married!=1
cap replace agi=agi-agidef if `yr'==1969   

sum oldexm xkids female agi wages [w=dweght]


* note: need coarser bins than in subsquent xcollsinglecoarse so that all cells are populated
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
keep $cellvar dweght oldexm female agi
sort $cellvar
compress
desc
* save $dirsmall/collapse/temp.dta, replace
gen one=1
collapse (rawsum) one dweght (mean) female [w=dweght], by ($cellvar)

sort $cellvar
duplicates report $cellvar
replace dweght=round(dweght*1e-5)
keep $cellvar female one dweght
display "NEED 108 cells for completeness, I have ="
count
table agibin shwag [w=dweght], c(mean female)
sort $cellvar
save  $dirsmall/collapse/xcollgender`yr'.dta, replace
}

* for some reason, excess number of women in 1969 for high wages (relative to 1974, not clear why, probably data issue)
use $dirsmall/collapse/xcollgender1969.dta, clear
gen year=1969
save $dirsmall/collapse/auxgender.dta, replace
append using $dirsmall/collapse/xcollgender1974.dta
replace year=1974 if year==.
sort $cellvar year
bys $cellvar: replace female=female[_n+1] if year==1969 & agibin>=.999 & shwag>=.01
bys $cellvar: replace female=female[_n+1] if year==1969 & agibin==.99 & shwag==.5

keep if year==1969
drop year
save  $dirsmall/collapse/xcollgender1969.dta, replace
table agibin shwag [w=dweght], c(mean female)


use $dirsmall/collapse/xcollgender1969.dta, clear
mkmat *, matrix(gender1969)
	
use $dirsmall/collapse/xcollgender1974.dta, clear
mkmat *, matrix(gender1974)
* xcollgender1979 is internally produced only
use $dirsmall/collapse/xcollgender1979.dta, clear
mkmat *, matrix(gender1979)


* creating matrices for interpolation 
foreach yr of numlist 1962 1964 1966/1978 {
   if `yr'<=1969 matrix gender=gender1969
   if `yr'>1969 & `yr'<1974 matrix gender=gender1969+((`yr'-1969)/(1974-1969))*(gender1974-gender1969)
   if `yr'>=1974 matrix gender=gender1974+((`yr'-1974)/(1979-1974))*(gender1979-gender1974)
   * saving matrix wagspouse`yr'.csv
  xsvmat double gender, fast names(col)
  mkmat _all, mat(gender)
  replace dweght=round(dweght)
  display "YEAR = " `yr'
  table agibin shwag [w=dweght], c(mean female)
  keep  $cellvar female
  sort $cellvar
  save "$dirsmall/collapse/xcollgender`yr'.dta", replace 
  }

  
*****************************************************************************************************************
* 10/2016: tabulation share female self-employment among married, using internal files 1979+ (use 1979 for pre-1979)
*****************************************************************************************************************

matrix input perc = (0 .2 .4 .6 .8 .9 .95 .99 .999 .9999 1)
matrix input shfem = (-.01 0 .05 .25 .5 .75 .9999 1)
local shnum=colsof(shfem)
local percnum=colsof(perc)

if $data==1 {
foreach yr of numlist 1979/$endyear {
matrix wagsp`yr' = J(`percnum'+1,`shnum'+1,.)
matrix wagsp`yr'[1,1]=`yr'
local percnum2=`percnum'-1
local shnum2=`shnum'-1
foreach pc of numlist 1/`percnum2' {
	matrix wagsp`yr'[`pc'+2,1]=perc[1,`pc']
	matrix wagsp`yr'[`pc'+2,2]=perc[1,`pc'+1]
	}
matrix define wagspN`yr'=wagsp`yr'
	
use  "$dirirs/x`yr'.dta", clear
if $data==1 & `yr'!=1985 & `yr'!=1986 & `yr'>=1979 replace dweght=dweght*100
if $data==0 {
* for testing in 1991 only
gen seysecirs=seysec
gen seyprimirs=max(0,sey-seysec)
}

gen aux=max(0,seyprimirs+seysecirs)
gen married=(mars==2)
set seed 342342
replace aux=aux+runiform()/2 if aux>0
replace dweght=round(dweght)
cumul aux [w=dweght] if married==1 & aux>0, gen(rankw)
gen share_fse=0
replace share_fse=seysecirs/max(0,seyprimirs+seysecirs) if aux>0 & married==1 & seysecirs>=0 
replace share_fse=min(share_fse,1)
replace share_fse=0 if share_fse==. | share_fse<0

foreach sh of numlist 1/`shnum2' {
	local shmin=shfem[1,`sh']
	local shmax=shfem[1,`sh'+1]
	matrix wagsp`yr'[1,2+`sh']=`shmin'
	matrix wagsp`yr'[2,2+`sh']=`shmax'
	matrix wagspN`yr'[1,2+`sh']=`shmin'
	matrix wagspN`yr'[2,2+`sh']=`shmax'
	foreach pc of numlist 1/`percnum2' {
		local pcmin=perc[1,`pc']
		local pcmax=perc[1,`pc'+1]
		quietly sum share_fse [w=dweght] if rankw!=. & rankw>`pcmin' & rankw<=`pcmax'
		local denom=r(sum_w)
		*display `yr' "   Num records in bin" `pc' " = " r(N)
		quietly sum share_fse [w=dweght] if rankw!=. & rankw>`pcmin' & rankw<=`pcmax' & share_fse>`shmin' & share_fse<=`shmax'
		matrix wagsp`yr'[2+`pc',2+`sh']=r(sum_w)/`denom'
		matrix wagspN`yr'[2+`pc',2+`sh']=round(r(sum_w)*1e-2)
		* added 11/2016 to zero out cells with 1 or 2 obs.
		if round(r(sum_w)*1e-2)<10 & round(r(sum_w)*1e-2)>0 {
			matrix wagsp`yr'[2+`pc',2+`sh']=0
			matrix wagspN`yr'[2+`pc',2+`sh']=0
			}	
		}
		
	}

			
matrix list wagsp`yr'
xsvmat double wagsp`yr', fast names(col)
mkmat _all, mat(wagsp`yr')
* added 11/2016 renormalize to sum to one for each row (due to small cells removal)
local last=`shnum'+1
display " TEST = " `last'
egen tot=rsum(c3-c`last')	
foreach num of numlist 3/`last' {
    replace c`num'=c`num'/tot if c2!=.
		}
drop tot	
*end of renormalization
outsheet using  "$dirmatrix/wagmat/sespint`yr'.xls", replace

matrix list wagspN`yr'
xsvmat double wagspN`yr', fast names(col)
mkmat _all, mat(wagspN`yr')
outsheet using  "$dirmatrix/wagmat/sespintN`yr'.xls", replace

* end of yr loop for se matrices
}


* end of if $data==1 loop for se matrices
}


