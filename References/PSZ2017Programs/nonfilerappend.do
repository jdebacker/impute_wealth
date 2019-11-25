* created 1/17/2016 to append reweighed CPS nonfilers to small files
* CPS nonfilers created by Juliana by program use_cps (need to update after 2008)
* IRS nonfilers created by Saez internally with aggregate stats output


*global dropbox "/Users/manu/Dropbox/SaezZucman2014"
*global dirnonfilers="$root/output/nonfilers"
*global dirsmall="$root/output/small"
*global dirscratch="/Users/manu/Dropbox/scratch"


/*
EXPLANATIONS


Added 10/2010: compare characteristics of nonfilers from CDW are comparable to nonfilers from CPS (data programs nonfilerstat.do)
conclusion: 1) need to re-weight wage earners by factor 2.5 and double their wages


We simply reweight nonfilers 65+ and nonfilers 20-65+ so that small+nonfilers match
population stats for 20+ adults and 65+ adults
For weight w2 on tax units with at least one person 65+ in nonfilers: count the 65+ individuals in PUF and non-filers so that PUF+w2*non-filers=total 65+ in population
Reweight all nonfilers tax units with at least one 65+ person with weight w2
For weight w1 on tax units with no person 65+ in nonfilers: count the 20-64 individual filers in PUF, non-filers with no 65+, non-filers with some 65+, and
calculate weight w1 so that PUF+w1*non-filers no 65+w2*non-filers 20-64 in 65+ tax unit=total 20-64 in population


2 important notes:
a) there are too few married (even adding MFS and nonfilers) in the small file relative to CPS table 
of non-institutional pop used to compute Piketty-Saez tax units.
This is likely due to the fact that some married but separated people file as head of household (and possibly noncompliance)
a) the population base from Census includes people living in group quarters 
(=correction facilities, college dorms, nursing homes, psychiatric hospitals, military barracks)
while the population base from CPS (Families and Living Arrangements tables) (used in Piketty-Saez) excludes group quarter 
=> Piketty-Saez adults 20+ in # tax units smaller by about 2% than adults 20+ totals
Hence, the resulting number of tax units in the small file counting married couples at 50% weight is larger than Piketty-Saez 
and has too few married households (relative to CPS)

For some years, 1966-1970, 1973, 1974, 1979, I end up with excess adults 20-64 even putting zero weight on nonfilers 20-64
This is due to the fact that there are too many filers in the PUF data relative to the US pop 20+ 
reasons: 
1) some people aged less than 20 file tax returns (based on Gerry Auten stats, there were about 6m such cases in 1983 and 6m again in 2012)
2) some non-residents (like US citizens abroad file tax returns)
We need to remove some filers from the PUF to meet the total (as we can't use negative weights)
We remove excess adults by removing low AGI PUF single filers, no kids, below 65, with low AGI (and low wages) 
We cut the density for such filers in a linear way so that the cut in density is zero at percentile 33 of the AGI distribution 
(for singles, no kids, below 65, low wage). We use percentile 33 because that's what's needed for the year with the most excess adults (1969)
Overall, this removes 0-3% of adults but a very small fraction of AGI and wages (typically less than .2%)

Next, we correct the number kids by creating a new variable xkidspop so that total kids+adults 20+ matches the official US population numbers
Some years have deficit of kids, some years have excess number of kids (particulary 1982-6 when filers were faking kids for tax evasion before SSN
was required).
When there are excess kids, we randomly reduce xkids by 1 kid when xkids>0
When there are too few kids, we add kids randomly by setting xkidspop=xded when xkids<xded (cases where filer claims more dependents than kids at 
home) in priority. If this is not enough, we then randomly add 1 kid to filers with xkidspop>0

We correct tax units to match Piketty-Saez tax units, we create a weight dweghtttaxu that removes low income tax units so that the total number
of tax units matches the Piketty-Saez official total 
We add a flat income to non-filers so that the denominator income (no KG) matches the Piketty-Saez income total with no KG [variable incomeps]
This allows to recover the Piketty-Saez series almost exactly


*/


local year=$yr
local ii=`year'-1961


* creation of non-filers 
* define year as the CPS year
local cpsyear=`year'+1


insheet using $parameters, clear names
keep if yr==`year'
foreach var of varlist _all {
local `var'=`var'
}


cap matrix weights[`ii',1]=`year'
cap matrix weights[`ii',26]=`year'
cap matrix weights[`ii',2]=`totadults20'-`adults65p' 
cap matrix weights[`ii',3]=`adults65p' 


* need to compute adults, adults65p, and married tax units in small files
use $dirsmall/small`year'.dta, clear
cap drop if filer==0
gen one=1
quietly sum one [w=dweght]
local taxunitsirs=r(sum)*1e-8
quietly sum one [w=dweght] if married==1
local mfjirs=2*r(sum)*1e-8
local adults20irs=`taxunitsirs'+`mfjirs'/2
quietly sum one [w=dweght] if marriedsep==1
local marriedirs=`mfjirs'+r(sum)*1e-8
* careful this married is not correct because uses pop census vs CPS no need to go back to CPS to get married
local married=2*(`totadults20'-`tottaxunits')
gen old65=oldexm+oldexf
quietly sum old65 [w=dweght]
local adults65pirs=r(sum)*1e-8
local adults2064=`totadults20'-`adults65p'
local adults2064irs=`adults20irs'-`adults65pirs'

display "TAX UNITS: " `tottaxunits' "  TAX UNITS IRS: " `taxunitsirs' 
display "ADULTS 20+: " `totadults20' "  ADULTS 20+ IRS: " `adults20irs' 
* display "MARRIEDS: " `married' "  MARRIED IRS: " `marriedirs' 
display "ADULTS 65+: " `adults65p' "  ADULTS 65+ IRS: " `adults65pirs' 

cap matrix weights[`ii',4]=`adults2064irs' 
cap matrix weights[`ii',5]=`adults65pirs' 


use $dirnonfilers/cpsmar`cpsyear', clear
keep if files==0
* added 10/2016, reweight wage earners by factor 3 (2.5 in 2009+) and multiplier wages by factor 2.5 (2 in 2009+)
if $yr>=2009 replace dweght=2.5*dweght if waginc>0 & waginc!=.
if $yr<2009 replace dweght=3*dweght if waginc>0 & waginc!=.
foreach var of varlist wages waginc wage_husband wage_wife {
if $yr>=2009 replace `var'=2*`var' if `var'>0 & `var'!=.
if $yr<2009 replace `var'=2.5*`var' if `var'>0 & `var'!=.
}
* end of added 10/2016

* fixing missing weights (3/2018)
drop if dweght==.
drop if dweght==0

gen one=1
keep if age>=20 
replace age_spouse=age if married==1 & age_spouse<18
quietly sum one [w=dweght]
local taxunitsnf=r(sum)*1e-3
gen adult=1 
replace adult=2 if married==1
quietly sum adult [w=dweght]
local adults20nf=r(sum)*1e-3
gen old=0
replace old=old+1 if oldexm==1
replace old=old+1 if oldexf==1
quietly sum old [w=dweght]
local adults65pnf=r(sum)*1e-3
* adults 65+ in tax units where BOTH spouses are 65+
quietly sum old [w=dweght] if old==2
local adults65onlynf=r(sum)*1e-3

* adults 20-64 in household with a spouse 65+ 
quietly sum one [w=dweght] if old==1 & adult==2
local adult2064oldspousenf=r(sum)*1e-3
display "ADULTS 20-64 in tax units with a 65+ spouse  "  `adult2064oldspousenf'
* adults 20-64 in household with no 65+ person
quietly sum adult [w=dweght] if old==0
local adults2064nooldspousenf=r(sum)*1e-3
display "ADULTS 20-64 in tax units with no 65+ person  "  `adults2064nooldspousenf'
* adults 20-64 all
local adult2064nf=`adult2064oldspousenf'+`adults2064nooldspousenf'

quietly sum married [w=dweght]
local marriednf=2*r(sum)*1e-3

display "TAX UNITS: " `tottaxunits' "  TAX UNITS IRS: " `taxunitsirs' "  TAX UNITS NF CPS: "   `taxunitsnf'
display "ADULTS 20+: " `totadults20' "  ADULTS 20+ IRS: " `adults20irs'  "  ADULTS 20+ NF CPS: " `adults20nf' 
display "ADULTS 65+: " `adults65p' "  ADULTS 65+ IRS: " `adults65pirs'  "  ADULTS 65+ NF CPS: " `adults65pnf' 
display "MARRIEDS: " `married' "  MARRIED IRS: " `marriedirs' " MARRIED NF CPS: " `marriednf' 


display "STATS FOR CPS NON-FILERS YEAR =  " `year'
gen age65=(age>=65)
gen age65both=(age>=65 & age_spouse>=65)
gen ssdum=(ssinc>0 & ssinc!=.)
quietly sum ssinc ssdum waginc uiinc age age65 [w=dweght]
quietly sum age65 age65both [w=dweght] if married==1

cap matrix weights[`ii',6]=`adults20nf'-`adults65pnf' 
cap matrix weights[`ii',7]=`adults65pnf' 

* weights on non-filers to get the correct 20-64 and 65+ population totals, separate weights for tax units with 65+ people vs tax units with no 65+ people
local weight65p=(`adults65p'-`adults65pirs')/`adults65pnf' 
local weight2065=(`adults2064'-`adults2064irs'-`weight65p'*`adult2064oldspousenf')/(`adults2064nooldspousenf')


cap matrix weights[`ii',8]=`weight2065'
cap matrix weights[`ii',9]=`weight65p'

* for some years, weight2065 on adults 20-64 non filers is negative: excess 20-65 when adding reweighted CPS and IRS PUF
local excess2065=0
if `weight2065'<0 {
local excess2065=-`weight2065'*`adults2064nooldspousenf'
*local weight2064all=(`adults2064'-`adults2064irs')/(`adult2064nf')
*local weight65pure=(`adults65p'-`adults65pirs'-`weight2064all'*`adult2064oldspousenf')/`adults65onlynf' 
}
cap matrix weights[`ii',10]=`excess2065'

replace dweght=`weight2065'*dweght if old==0
replace dweght=`weight65p'*dweght if old==1 | old==2

drop if dweght<0
quietly sum old [w=dweght]
display "REWEIGHTED ADULTS 65+ NF: " r(sum)*1e-3 " TARGET IS " `adults65p'-`adults65pirs'
quietly sum adult [w=dweght]
display "REWEIGHTED ADULTS 20+ NF: " r(sum)*1e-3  " TARGET IS "  `totadults20'-`adults20irs'

* preparing the nonfiler file for merging with small, in married couples, sec is always female (regardless of main householder)

replace year=year-1
gen femalesec=1 if married==1
replace female=0 if married==1
gen sey = seinc+farminc
gen schcinc = seinc+farminc
gen seysec = seinc_wife
rename wage_wife wagincsec
rename age_spouse agesec
rename ssinc_wife ssincsec
rename files filer
replace dweght=round(dweght*1e+5)

keep tunit year married age agesec agi ages waginc wagincsec peninc ssinc ssincsec uiinc schcinc rentinc estinc sey seysec xkids dweght oldexm oldexf owner head single filer female femalesec
* gen kginc=0
gen income=agi
gen suminc=agi
gen wages=waginc
gen schcincp=max(0,schcinc)
gen schcincl=-min(0,schcinc)
sort tunit
foreach var of varlist oldexf wagincsec ssincsec seysec {
replace `var'=0 if `var'==.
}
foreach var of newlist kginc marriedsep dependent  {
gen `var'=0 
}



save $dirsmall/nonfilers`year'.dta, replace

use $dirsmall/small`year'.dta, clear
cap drop if filer==0
append using $dirsmall/nonfilers`year'.dta
replace filer=1 if filer==.
local lambda=0

* need to correct weights in 1966-1970, 1973, 1974, 1979 to get rid of excess numbers of adults 20-64 --> get rid in priority of lowest income non-married returns with no elderly person
if `weight2065'<0 {
gen flag=0
cumul wages [w=dweght] if agi>=0 & oldexm==0 & married==0 & xkids==0 & filer==1, gen(wagerank)

cumul agi [w=dweght] if agi>=0 & oldexm==0 & married==0 & xkids==0 & filer==1 & wages<=agi, gen(agirank)
gen correct=1 if agirank!=.
replace correct=correct*min(agirank/.3333,1)

quietly sum agi wages [w=dweght] if correct<1
quietly sum agi [w=dweght] if correct<1
local base=r(sum_w)*1e-8
gen dweght2=dweght*max(0,correct)
quietly sum agi [w=dweght2] if correct<1
local narrow=r(sum_w)*1e-8
local lambda=`excess2065'/(`base'-`narrow')
replace correct=min(agirank/.3333,1)*`lambda'+1-`lambda' 
replace dweght2=dweght*max(0,correct)
quietly sum agi [w=dweght2] if correct<1
local narrow=r(sum_w)*1e-8
display " YEAR WITH EXCESS =  " `year'
display "base" `base' "base- narrow: " `base'-`narrow' " excess: " `excess2065' " lambda factor: " `lambda'
display "base" `base' "base- narrow: " `base'-`narrow' " excess: " `excess2065'
gen dweghtdrop=dweght-dweght2
quietly sum agi [w=dweghtdrop] if filer==1
local agilost=r(sum)*1e-8
local filerslost=r(sum_w)*1e-5
quietly sum agi [w=dweght] if filer==1
local agitot=r(sum)*1e-8
local filers=r(sum_w)*1e-5
display "% AGI Lost = " 100*`agilost'/`agitot' "  % FILERS LOST = " 100*`filerslost'/`filers'

replace dweght=round(dweght2)
drop correct agirank wagerank flag dweght2

}

* KIDS TO MATCH POPULATION TOTAL
* correcting full populatation target by creating a new xkidspop variable so that sum of primary+secondary filers+kids leads to 
* correct total population

* total population is pretty well targeted, within 1% in most years, slight excess of 2% in 1983-6 disappearing in 1987 likely due to noncompliance 
* tax filers making up kids when SSN was not required
* could correct population to match US official stats by adding/removing xkids randomly [interacts with EITC, CTC] in new variable xkidstot

cap drop xkidspop
gen xkidspop=xkids
gen people=1
replace people=people+1 if married==1
replace people=people+xkids
quietly sum people [w=dweght]
local populationt=r(sum)*1e-8
cap matrix weights[`ii',12]=(`populationt'-`population')/`population'
gen peoplef=1
replace peoplef=peoplef+1 if married==1
replace xded=xkids if xded==.
replace peoplef=peoplef+max(xded,xkids)
quietly sum peoplef [w=dweght]
local populationtf=r(sum)*1e-8
cap matrix weights[`ii',13]=(`populationtf'-`population')/`population'

/*
gen kidexcess=0
replace kidexcess=xded-xkids if xded>xkids
quietly sum kidexcess [w=dweght]
local kidexcess=r(sum)*1e-8
display `populationtf'-`populationt'   `kidexcess'
*/

* counting total number of kids
quietly sum xkids [w=dweght] if xkids>0
local xkidstot=r(sum)*1e-8
local avkids=r(mean)
local frackidexcess=(`populationt'-`population')/`xkidstot'
/*
replace xded=xkids if xded==.
quietly sum xded [w=dweght] 
local totxded=r(sum)*1e-8
cap matrix weights[`ii',14]=(`populationt'-`population')/(`totxded'-`xkidstot')
*/

* excess number of kids, need to remove them randomly
if `populationt'>=`population' {
	set seed 63432
	gen randu=uniform() if xkids>0
	* fraction of kids to remove:

	display "FRACTION EXCESS KIDS: " `frackidexcess'*`avkids'
	replace xkidspop=xkids-1 if xkids>0 & randu<`frackidexcess'*`avkids'

	quietly sum xkidspop [w=dweght] if xkids>0
	local xkidstot2=r(sum)*1e-8
	local frackidexcess=(`populationt'-`population')/(`xkidstot'-`xkidstot2')
	display "FRACTION EXCESS KIDS CORRECTED: " `frackidexcess'

	gen people2=1
	replace people2=people2+1 if married==1
	replace people2=people2+xkidspop
	quietly sum people2 [w=dweght]
	local populationtnew=r(sum)*1e-8
	display "YEAR = " `year' " POPULATION =" `populationtnew' "  TARGET DENOM WAS: " `population' "  EXCESS POPULATION % =" 100*(`populationt'/`population'-1)

}




* too few kids, need to add them starting with other dependents
* case I: xded has more kids than needed so can use cases with xded>xkids to add children
 if `populationt'<`population' & `populationtf'>=`population' {
	set seed 63432
	gen randu=uniform() 
	local xkidstotold=`xkidstot'
	local thresh=(`population'-`populationt')/(`populationtf'-`populationt')
	replace xkidspop=xded if xded>xkids & xded!=. & randu<=1*`thresh'
	quietly sum xkidspop [w=dweght] 
	local xkidstot=r(sum)*1e-8
	*local  populationt=`populationt'+`xkidstot'-`xkidstotold'
	display `thresh' " POP TARGET= " `population' "  OLD POP = " `populationt' " POP XDED= " `populationtf' "  POP CORRECTED =  " `populationt'+`xkidstot'-`xkidstotold' 
	display " KIDS TOT= " `xkidstotold' " XDED TOT = " `xkidstot' " EXCESS XDED TO XKID " `xkidstot'-`xkidstotold'
	}


* case II: not enough kids even when using xded instead of xkids, I add kids randomly among people reporting kids
if `populationt'<`population' & `populationtf'<`population' {
	set seed 63432
	gen randu=uniform() 
	local xkidstotold=`xkidstot'
    replace xkidspop=xded if xded>xkids & xded!=.
    quietly sum xkidspop [w=dweght] if xkidspop>0
    local avkids=r(mean)
	local xkidstot=r(sum)*1e-8
    local kidsdeficit=(`population'-`populationtf')/`xkidstot'
    replace xkidspop=xkidspop+1 if xkidspop>0 & randu<`kidsdeficit'*`avkids'
	quietly sum xkidspop [w=dweght] if xkidspop>0
	local xkidstot=r(sum)*1e-8
    display " POP TARGET= " `population' "  OLD POP = " `populationt' " POP XDED= " `populationtf' "  POP CORRECTED =  " `populationt'+`xkidstot'-`xkidstotold' 
	display " KIDS TOT= " `xkidstotold' " XDED TOT = " `xkidstot' " KIDS ADDED = " `xkidstot'-`xkidstotold'
    }
 

cap drop people*
gen people=1
	replace people=people+1 if married==1
	replace people=people+xkidspop
	quietly sum people [w=dweght]
	local populationtnew=r(sum)*1e-8

cap matrix weights[`ii',14]=`population'
cap matrix weights[`ii',15]=`populationtnew'

* TAX UNITS
* need to define alternative weights for tax units, defined as dweghttaxu, so that they match Piketty-Saez totadults20
* I remove in priority the lowest income single no kids

cap drop dweghttaxu
gen dweghttaxu=dweght
gen adult=1 
quietly sum adult [w=dweght]
local taxunits=r(sum)*1e-8
local excesstu=`taxunits'-`tottaxunits'
cap matrix weights[`ii',11]=(`taxunits'-`tottaxunits')/`tottaxunits'

cumul wages [w=dweght] if agi>=0 & oldexm==0 & married==0 & xkids==0, gen(wagerank)
cumul agi [w=dweght] if agi>=0 & oldexm==0 & married==0 & xkids==0 & wages<=agi, gen(agirank)
gen correct=1 if agirank!=.
* remove the bottom part of the density linearly (100% at AGI=0 and 0% at percentile p where p is chosen to remove the correct amount)
* proceed by dichotomy
local pmin=0
local pmax=1

while `pmax'-`pmin'>.0001 {
	local p=(`pmin'+`pmax')/2
	* display " DICHOTOMY =  " `p'
	cap drop correct
	gen correct=1
	replace correct=min(agirank/`p',1) if agirank!=.
	* sum agi wages [w=dweght] if correct<1
	quietly sum agi [w=dweght] if correct<1
	local base=r(sum_w)*1e-8
	replace dweghttaxu=dweght*correct
	quietly sum agi [w=dweghttaxu] if correct<1
	local narrow=r(sum_w)*1e-8
	if `base'-`narrow'<`excesstu' {
	local pmin=`p'	
	}
	if `base'-`narrow'>=`excesstu' {
	local pmax=`p'	
	}
}	
	
replace dweghttaxu=round(dweght*correct)
quietly sum agi [w=dweghttaxu] if correct<1
local narrow=r(sum_w)*1e-8

display " YEAR WITH EXCESS =  " `year'
display "base  " `base' "  base- narrow: " `base'-`narrow' " excess: " `excesstu' " percentile factor: " `p'
gen dweghtdroptu=dweght-dweghttaxu
quietly sum agi [w=dweghtdroptu] if filer==1
local agilost=r(sum)*1e-8
local filerslost=r(sum_w)*1e-5
quietly sum agi [w=dweght] if filer==1
local agitot=r(sum)*1e-8
local filers=r(sum_w)*1e-5
display "% AGI Lost = " 100*`agilost'/`agitot' "  % FILERS LOST = " 100*`filerslost'/`filers'

drop correct agirank wagerank dweghtdroptu
cap drop people*
cap drop randu 
cap drop adult

* computing incomeps for matching Piketty-Saez total by allocating more income to non-filers
cap drop incomeps
gen incomeps=income
quietly sum income [w=dweghttaxu] 
local totincirs=r(sum)*1e-5
quietly sum income [w=dweghttaxu] if filer==0
local totnonfiler=r(sum_w)*1e-5
quietly sum income [w=dweghttaxu] if filer==1
local meanincfiler=r(mean)
local incomenonfiler=(`piksaezden'*1e+6-`totincirs')/`totnonfiler'
local ratio=`incomenonfiler'/`meanincfiler'
display " MEAN INCOME FILER = " `meanincfiler' "  MEAN INCOME NON-FILER IMPUTED = " `incomenonfiler' "  RATIO NON-FILER/FILER INCOME = " `ratio'
replace incomeps=income+`incomenonfiler' if filer==0

* cleaning up to get consistent variables in nonfiler and filer subsamples
replace flpdyr=`year' if flpdyr==.
sort id tunit
replace id=_n if id==.
drop tunit
cap drop taxunits adults20

* fixing up oldmar and ageimp variables
drop oldmar
qui egen oldmar=group(married oldexm), label
label variable oldmar "Married x 65+ dummy"

if $yr>=1979 {
foreach ag of numlist $agebins {
 display "AGE = " `ag'
 replace ageimp=`ag' if age>=`ag' & filer==0
 replace agesecimp=`ag' if agesec>=`ag' & married==1 &  filer==0
 }
replace ageimp=20 if ageimp==0
replace agesecimp=20 if agesecimp==0
} 
 
 
 
foreach var of varlist item-othinc {
replace `var'=0 if `var'==.	& filer==0
}

foreach var of varlist share_ftrue share_f share_fse {
replace `var'=0 if `var'==.	& filer==0 & married==1
}

replace share_ftrue=wagincsec/waginc if filer==0 & waginc>0 & married==1
replace share_f=wagincsec/waginc if filer==0 & waginc>0 & married==1
replace share_fse=seysec/sey if filer==0 & sey>0 & married==1

label variable dweghttaxu "Population weight to recover Piketty-Saez total tax units"
label variable xkidspop "total number of children (imputed to match population total <20)"
label variable incomeps "= income for filers, and imputed flat for nonfilers to match Piketty-Saez total denominator"
order year dweght* filer

save $dirsmall/small`year'.dta, replace



/*
* test, can be commented out when re-running
gen adult=1 
quietly sum adult [w=dweght]
local taxunits=r(sum)*1e-8
replace adult=2 if married==1
quietly sum adult [w=dweght]
local adults20=r(sum)*1e-8
gen old=0
replace old=old+1 if oldexm==1
replace old=old+1 if oldexf==1
quietly sum old [w=dweght]
local adults65=r(sum)*1e-8
gen people=1
replace people=people+1 if married==1
replace people=people+xkidspop
quietly sum people [w=dweght]
local populationt=r(sum)*1e-8
gen one=1
quietly sum one [w=dweghttaxu]
local taxunits=r(sum)*1e-8
quietly sum incomeps [w=dweghttaxu]
local totincirsps=r(sum)*1e-11

*test of top 1% Piketty-Saez with no KG
*gen incomekg=incomeps+kginc
cumul incomeps [w=dweghttaxu], gen(rankkg)
quietly sum incomeps [w=dweghttaxu]
local totinc=r(sum)*1e-11
quietly sum incomeps [w=dweghttaxu] if rankkg>=.99
local topinc=r(sum)*1e-11
local top1perc=`topinc'/`totinc'


display "FINAL STATS FOR YEAR = " `year'
display "ADULTS 65+ =" `adults65' "  TARGET DENOM WAS: " `adults65p' " EXCESS ADULTS 65+ % = " 100*(`adults65'/`adults65p'-1)
display "ADULTS 20+ =" `adults20' "  TARGET DENOM WAS: " `totadults20' " EXCESS ADULTS 20+ % = " 100*(`adults20'/`totadults20'-1)
display "POPULATION =" `populationt' "  TARGET DENOM WAS: " `population' "  EXCESS POPULATION % =" 100*(`populationt'/`population'-1)
display "TAX UNITS =" `taxunits' "  TARGET DENOM WAS: " `tottaxunits' "  EXCESS TAX UNITS % =" 100*(`taxunits'/`tottaxunits'-1)
display "TOTAL INCOME TAX UNITS incomeps =" `totincirsps' "  TARGET DENOM WAS: " `piksaezden' "  EXCESS INCOME =" 100*(`totincirsps'/`piksaezden'-1)

matrix weights[`ii',16]=100*(`adults65'/`adults65p'-1)
matrix weights[`ii',17]=100*(`adults20'/`totadults20'-1)
matrix weights[`ii',18]=100*(`populationt'/`population'-1)
matrix weights[`ii',19]=100*(`taxunits'/`tottaxunits'-1)
matrix weights[`ii',20]=`p'
matrix weights[`ii',21]=100*(`totincirsps'/`piksaezden'-1)
matrix weights[`ii',22]=`ratio'
matrix weights[`ii',23]=`top1perc'
matrix weights[`ii',24]=`top1ps'
matrix weights[`ii',25]=`lambda'
*/

/*
* non-filers statistics made at the individual level for comparison with IRS internal, added 2/2016
local year=2008

use $dirsmall/small`year'.dta, clear
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
gen one=1
gen wt=dweght*1e-5
sum one wagdum waginc ssdum ssinc [w=wt] 
bys old: sum one wagdum waginc ssdum ssinc [w=wt] 
*/





