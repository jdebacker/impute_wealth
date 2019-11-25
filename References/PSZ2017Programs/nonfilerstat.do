*****************************************************************************************************************
* revised 10/2016: comparison of CPS nonfilers to IRS nonfilers for 2000-2013
*****************************************************************************************************************

* compute a bunch of variables: absolute number 65+, frac with wag>0, frac with ssinc>0, frac with ui>0, total wag, total ssinc, total uiinc
* goal is to adjust the CPS nonfilers [probably upward for wages to better reflect actual IRS nonfilers

matrix nfiler=J(15,35,.)	

foreach yr of numlist 1999/2010 {

local ii=`yr'-1998

matrix nfiler[`ii',1]=`yr'

* start easy using the small files


* CPS nonfilers in small files, put them in individual format for comparison
use $dirsmall/small`yr'.dta, clear
keep if filer==0
expand 2 if married==1
bys id: gen second=_n
replace second=second-1
replace female=0 if married==1 & second==0
replace female=1 if married==1 & second==1
replace waginc=waginc-wagincsec if married==1 & second==0
replace waginc=wagincsec if married==1 & second==1
replace ssinc=ssinc-ssincsec if married==1 & second==0
replace ssinc=ssincsec if married==1 & second==1
replace age=agesec if married==1 & second==1
gen old=oldexm
replace old=oldexf if married==1 & second==1
gen ssdum=(ssinc>0)
gen wagdum=(waginc>0)
gen uidum=(uiinc>0)
gen one=1
gen wt=round(dweght*1e-5)
keep married female ssinc uiinc waginc ssdum wagdum uidum old wt 
order wt old female wagdum ssdum  uidum waginc ssinc uiinc married
* sum * [w=wt] 
gen one=1
display "YEAR CPS NF = " `yr'
table one [w=wt], c(sum old sum waginc sum ssinc)

local jj=0
foreach var of varlist one old ssdum wagdum  uidum ssinc waginc  uiinc {
local jj=`jj'+4
quietly sum `var' [w=wt]
matrix nfiler[`ii',`jj']=r(sum)*1e-6
}


use ../internalIRS/pufimprove/population/rawdata/nonfilertabout_v2.dta, clear
rename *, lower
keep if tax_yr==`yr'
drop if age<20
gen age=20
replace age=45 if agebin>=45
replace age=65 if agebin>=65
gen old=(age==65)
gen wagdum=(wagbin>0)
gen ssdum=(ssincbin>0)
rename uidum uidum
rename ssinc_mean ssinc
rename uiinc_mean uiinc
rename wages_mean waginc
rename x_freq_ wt
keep female ssinc uiinc waginc ssdum wagdum uidum old wt 
order wt old female wagdum ssdum  uidum waginc ssinc uiinc 
* sum * [w=wt] 
gen one=1
display "YEAR IRS NF = " `yr'
table one [w=wt], c(sum old sum waginc sum ssinc)

local jj=1
foreach var of varlist one old ssdum wagdum uidum ssinc waginc uiinc {
local jj=`jj'+4
quietly sum `var' [w=wt]
matrix nfiler[`ii',`jj']=r(sum)*1e-6
matrix nfiler[`ii',`jj'+1]=nfiler[`ii',`jj'-1]/nfiler[`ii',`jj']
}


}


matrix list nfiler

* bottom line: approximately same number of old (65+), SSA beneficiaries, and total SSA benefits in CPS NF vs IRS NF
* no need to adjust anything here
* however: 2.5 times more wages earners and 5 times more total wage income in IRS NF than in CPS NF
* for UI, 2 times more UI recipients and UI amount in IRS NF than in CPS NF
* need to adjust, how? first approximation:
* double wages from CPS NF and then increase the weight of wage earners by 2.5
* double weight on UI earners


glue

local row=2

foreach case of numlist 1 {
if `case'==1 local xlsname="cps"	
if `case'==2 local xlsname="irspop"
if `case'==3 local xlsname="irscwhs"

putexcel A`row'=("year") using "$diroutput/nonfilerstats.xlsx", sh("`xlsname'") modify

putexcel B`row'=("# people") using "$diroutput/nonfilerstats.xlsx", sh("`xlsname'") modify




}



glue


putexcel B`row'=("count adults 20+") using "$diroutput/nonfilerstats.xlsx", sh("nonfilerstats") modify
putexcel C`row'=("count 65+") using "$diroutput/nonfilerstats.xlsx", sh("nonfilerstats") modify
putexcel D`row'=("count with wages>0") using "$diroutput/nonfilerstats.xlsx", sh("nonfilerstats") modify
putexcel E`row'=("count with ssinc>0") using "$diroutput/nonfilerstats.xlsx", sh("nonfilerstats") modify
putexcel F`row'=("count with uiinc>0") using "$diroutput/nonfilerstats.xlsx", sh("nonfilerstats") modify
putexcel G`row'=("total wages") using "$diroutput/nonfilerstats.xlsx", sh("nonfilerstats") modify
putexcel H`row'=("total ssinc") using "$diroutput/nonfilerstats.xlsx", sh("nonfilerstats") modify
putexcel I`row'=("total uiinc") using "$diroutput/nonfilerstats.xlsx", sh("nonfilerstats") modify


}


foreach yr in numlist 2010 {
local row=`row'+1


* CPS nonfilers in small files, put them in individual format for comparison
use $dirsmall/small`yr'.dta, clear
keep if filer==0
expand 2 if married==1
bys id: gen second=_n
replace second=second-1
replace female=0 if married==1 & second==0
replace female=1 if married==1 & second==1
replace waginc=waginc-wagincsec if married==1 & second==0
replace waginc=wagincsec if married==1 & second==1
replace ssinc=ssinc-ssincsec if married==1 & second==0
replace ssinc=ssincsec if married==1 & second==1
replace age=agesec if married==1 & second==1
gen old=oldexm
replace old=oldexf if married==1 & second==1
gen ssdum=(ssinc>0)
gen wagdum=(waginc>0)
gen uidum=(uiinc>0)
gen one=1
gen wt=round(dweght*1e-5)
keep married female ssinc uiinc waginc ssdum wagdum uidum old wt 
gen one=1


sum wagdum [w=wt] 
local 
putexcel A`row'=`yr' using "$diroutput/nonfilerstats.xlsx", sh("nonfilerstats") modify
putexcel B`row'=`yr' using "$diroutput/nonfilerstats.xlsx", sh("nonfilerstats") modify


}





/* old stuff
*****************************************************************************************************************
* 3/2016: goal of program is to compute a synthetic table of nonfilers at IRS for comparison with CPS nonfilers
*****************************************************************************************************************

local yr=2008

use $dirsmall/small`yr'.dta, clear
keep if filer==0
expand 2 if married==1
bys id: gen second=_n
replace second=second-1
replace female=0 if married==1 & second==0
replace female=1 if married==1 & second==1
replace waginc=waginc-wagincsec if married==1 & second==0
replace waginc=wagincsec if married==1 & second==1
replace ssinc=ssinc-ssincsec if married==1 & second==0
replace ssinc=ssincsec if married==1 & second==1
replace age=agesec if married==1 & second==1
gen old=oldexm
replace old=oldexf if married==1 & second==1
gen ssdum=(ssinc>0)
gen wagdum=(waginc>0)
gen uidum=(uiinc>0)
gen one=1
gen wt=round(dweght*1e-5)
keep married female ssinc uiinc waginc ssdum wagdum uidum old wt 
gen one=1
* wage bracket variable
gen wagbrack=0
gen ssbrack=0
foreach num of numlist 1 2000 4000 6000 8000 10000 12000 14000 16000 18000 20000 25000 30000 35000 40000 45000 50000 {
 replace wagbrack=`num' if waginc>`num'
 replace ssbrack=`num' if ssinc>`num'
}

count
sum one waginc ssinc wagdum ssdum uidum old female [w=wt]
* collapsing the dataset
collapse (sum) wt one (mean) waginc ssinc uiinc married female uidum, by (wagbrack ssbrack old)

gen toofewobs=0
replace toofewobs=1 if one>=1 & one<=2
sum toofewobs [w=wt] 
display "FRACTION TOO FEW :   " r(sum)/r(sum_w)
* very sparse obs with both ssinc and waginc
* tab ssbrack wagbrack [w=wt]

save $dirsmall/nfcollapse`yr'.dta, replace

* recreating the dataset from the collapsed one
use $dirsmall/nfcollapse`yr'.dta, clear

expand one 
replace wt=round(wt/one)
replace one=1
replace ssinc=0 if ssinc<1
replace waginc=0 if waginc<1
gen ssdum=(ssinc>0)
gen wagdum=(waginc>0)
sum one waginc ssinc wagdum ssdum uidum old female [w=wt]
sum one waginc ssinc wagdum ssdum uidum old female [w=wt] if toofewobs==0

* attributes dummy variables randomly
set seed 43423
gen female2=(female>runiform())
sum female female2 [w=wt]
gen married2=(married>runiform())
sum married married2 [w=wt]

* bottom line: pretty good method to generate synthetic dataset when few observations










