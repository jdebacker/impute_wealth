***********************************************************************************************************************
* program that computes the SCF statistics presented in the Saez-Zucman paper
* program used the publicly SCF data for 1989 1992 ... 2013 available at 
* http://www.federalreserve.gov/econresdata/scf/scfindex.htm
* two datasets used: 
* 1) the full public data fullpYYYY.dta in global directory $datascfdir1 (year by year subdirectories)
* codebook for 1989 at http://www.federalreserve.gov/econresdata/scf/files/codebk89.txt
* codebook for 2010 at http://www.federalreserve.gov/econresdata/scf/files/codebk2010.txt
* 2) the Summary Extract Public Data rscfpYYYY.dta $datascfdir2
* construction at http://www.federalreserve.gov/econresdata/scf/files/bulletin.macro.txt
* SCF year t has wealth as of September year t but asks income as of year t-1 
* the summary extract file is in real $ while the full public data is in nominal $ so need to convert
* IMPORTANT NOTE: the 1989-2010 datasets were downloaded before 2013 was available so summary extract files for 1989-2010 are in 2010 dollars, while the summary extract file for 2013 is in 2013 $
* RESULTS: 2 xls sheets produced scf_stataagg.xls for aggregate results, and scf_stataoutput.xls for distributional results
***********************************************************************************************************************

clear all
set maxvar 10000
global datascfdir1 "/Users/manu/Dropbox/SaezZucman2014/SCF/juliana_SCF/data/FullPublicData/"
global datascfdir2 "/Users/manu/Dropbox/SaezZucman2014/SCF/datascf/"
global datascfdir3 "/Users/manu/Dropbox/SaezZucman2014/PaperWealth/OnlineFiles/ReplicationPrograms"
global scratchdir "/Volumes/Macintosh HD 2/scratch"
global years="1989 1992 1995 1998 2001 2004 2007 2010 2013"
* global years="2013"
local numyears=9

cd /Users/manu/Dropbox/SaezZucman2014/SCF

***********************************************************************************************************************
* creating homogeneous SCF datasets for each year with the relevant wealth/income/capitalized income variables
***********************************************************************************************************************

/*
* change Y1 to y1 name in summary extract for merge 
use $datascfdir2/rscfp2013.dta, clear
cap rename Y1 y1
sort y1
save $datascfdir2/rscfp2013.dta, replace
*/


foreach year of numlist $years {

* Importing the totals for each wealth category from the Saez-Zucman denominator to recalculate SCF networth consistent with Saez-Zucman denominator

clear
insheet using "$datascfdir3/parameters(SZ).csv", clear names
	keep if yr==`year'
	keep ttwealth	ttdivw	ttintw ttinttaxw ttintexmw	ttschcpartw	ttscorw	ttrentw	ttmortw	ttrestw	ttpeniraw	ttpenw	ttothdebt ttcurrency 
	rename ttwealth networth_totsz
	rename ttdivw equity_totsz
	rename ttinttaxw bond_totsz
	rename ttintexmw muni_totsz
	rename ttcurrency  currency_totsz
	rename ttothdebt otherdebt_totsz
	rename ttrestw housing_totsz
	rename ttmortw mortgagedebt_totsz
	rename ttrentw netrental_totsz
	gen business_totsz=ttschcpartw+ttscorw
	gen pension_totsz=ttpenw+ttpeniraw	
	gen nonhousing_totsz=networth_totsz-housing_totsz-mortgagedebt_totsz
	gen nhousingpen_totsz=networth_totsz-housing_totsz-pension_totsz-mortgagedebt_totsz
	gen nethousing_totsz=housing_totsz+mortgagedebt_totsz+netrental_totsz
	gen vehicart_totsz=0
	gen fixclaim_totsz=bond_totsz+muni_totsz+currency_totsz+otherdebt_totsz
	gen busrent_totsz= business_totsz+netrental_totsz
	keep networth equity bond muni currency otherdebt housing mortgagedebt netrental business pension nonhousing nhousingpen vehicart fixclaim busrent nethousing 
	order networth equity bond muni currency otherdebt housing mortgagedebt netrental business pension nonhousing nhousingpen vehicart fixclaim busrent nethousing 
	
	foreach var of varlist _all {
	local `var'=`var'
	* display ``var''
	}	
		
* Importing capital income total variables for `year'-1, (added 8/2015 but not used in the end)
insheet using "$datascfdir3/parameters(SZ).csv", clear 
		keep if yr==`year'-1
		keep ttintinc ttdivinc ttkg ttkinc2
		rename ttintinc intinc_totsz 
		rename ttdivinc divinc_totsz 
		rename ttkg kginc_totsz 
		gen bussefarminc_totsz=ttkinc2-(intinc_totsz+divinc_totsz)
		keep intinc divinc kginc bussefarminc
		order  intinc divinc kginc bussefarminc	
	
	foreach var of varlist _all {
	local `var'=`var'
	* display ``var''
	}



* merging the full public data with the summary extract public data (ID variable is Y1 except for 1989 when it is X1)
* 5 records for each respondent (for imputation of missing variables), population weights is variable wg

use $datascfdir1/`year'/fullp`year'.dta, clear
gen year=`year'
cap rename Y1 y1 
cap rename X1 y1 
sort y1
merge 1:1 y1 using $datascfdir2/rscfp`year'.dta
gen cpi=1
gen cpi_wealth=1
save "$scratchdir/big.dta", replace

************************************************
* defining capital income and wealth variables using the same names as in /SaezZucman2014/Data/irs_small/smallYYYY.dta files  
* We use the naming convention of income variables from smallYYYY.dta files and use suffix _wscf for the corresponding wealth measures in SCF
************************************************

use "$scratchdir/big.dta", clear
* cpi is cpi adjustment for income variables (year - 1 relative to file year)
* cpi_wealth is cpi adjustment for wealth variables (same year as file year)
* careful, the cpi adjustments in the summary extract are adjusted with each new wave 
* 1989-2010 downloaded before 2013 was available so we used the 2010 old adjustment then
replace cpi=(3208/1902)*(1886/1808) if year==1989
replace cpi=(3208/2116)*(2103/2051) if year==1992
replace cpi=(3208/2265)*(2254/2201) if year==1995
replace cpi=(3208/2405)*(2397/2364) if year==1998
replace cpi=(3208/2618)*(2600/2529) if year==2001
replace cpi=(3208/2788)*(2774/2701) if year==2004
replace cpi=(3208/3062)*(3045/2961) if year==2007
replace cpi=(3208/3208)*(3202/3150) if year==2010
replace cpi=(3438/3438)*(3421/3372) if year==2013

replace cpi_wealth=(3208/1902) if year==1989
replace cpi_wealth=(3208/2116) if year==1992
replace cpi_wealth=(3208/2265) if year==1995
replace cpi_wealth=(3208/2405) if year==1998
replace cpi_wealth=(3208/2618) if year==2001
replace cpi_wealth=(3208/2788) if year==2004
replace cpi_wealth=(3208/3062) if year==2007
replace cpi_wealth=(3208/3208) if year==2010
replace cpi_wealth=(3438/3438) if year==2013

* test of cpi with kginc and X5712
gen test=kginc-X5712*cpi
sum test, det
drop test

* integer weight
gen wgint=round(wgt*10000)

* filed or will file tax return
gen filedtax=0
replace filedtax=1 if X5744==1 | X5744==6
* tax returns in the unit, set to 2 when 2 spouses/partners file separate returns
gen numbertaxreturns=filedtax
replace numbertaxreturns=2 if X5746==2

cap drop married
gen married=0
replace married=1 if X8023==1
* lives with partner but not married
gen partner=0
replace partner=1 if X8023==2

* itemized deduction dummy for respondent or spouse (X7369==1) is when spouse/partner filing separately itemized, only since 1995
gen item=0
cap gen X7367=0
cap gen X7368=0
cap gen X7369=0
replace item=1 if X7367==1 | X7368==1 | X7369==1

* A. Corporate equities (excluding pensions)
* dividend income
gen divinc=X5710*cpi
* capital gains, kginc already exists
* equity wealth sum of direct stock holdings + mutual funds stock holdings
gen kgdivinc=max(0,kginc)+divinc
gen divinc_wscf=stocks+stmutf+.5*comutf
gen kgdivinc_wscf=stocks+stmutf+.5*comutf

* B. Fixed claim assets
* non-taxable bonds (munis)
gen intexm=X5706*cpi
gen intexm_wscf=notxbnd+tfbmutf

* taxable fixed claim assets
gen intinc=X5708*cpi
gen intinc_wscf=liq+cds+savbnd+bond-notxbnd+nmmf-stmutf-tfbmutf-.5*comutf

* C. Unincorporated businesses
* aggregates schedC+farm+schedE (schedE=rental, partnership, S-corp, royalties, trust income)
gen businc=max(0,bussefarminc)
gen businc_wscf=bus+othfin+nnresre

* D. Pension income
* ssretinc also includes social security so need to calculate social security income ssinc to subtract it
* ssinc is reported either monthly or annually so need to calculate this
gen ssinc=0
replace ssinc=ssinc+X5306*cpi if X5307==6
replace ssinc=ssinc+12*X5306*cpi if X5307==4
replace ssinc=ssinc+X5311*cpi if X5312==6
replace ssinc=ssinc+12*X5311*cpi if X5312==4
gen peninc= max(0,ssretinc-ssinc)
* peninc includes IRAs, 401(k) distributions and annuities from DBs
replace penacctwd=0 if penacctwd==.
gen penincdb=max(0,peninc-penacctwd)
gen penincdc=peninc-penincdb
* penincdb should be DB pension income
* penincdc should be DC pension income

* presence of DB plan
gen db=0
replace db=1 if dbplant==1

sum pen* [w=wgint]

* E. Housing wealth
gen nethousing=houses+oresre-mrthel-resdbt

* real estate taxes on owner occupied housing (need to adjust for periodicity)
gen realestatetax=X721*cpi
replace realestatetax=12*realestatetax if X722==4
replace realestatetax=4*realestatetax if X722==5
replace realestatetax=2*realestatetax if X722==11
replace realestatetax=max(0,realestatetax)

* mortgage payments per month variable is mortpay, create annualized variable
replace mortpay=12*mortpay

* generating total income variable totinc consistent with Piketty-Saez income definition (i.e. excluding SS and govt transfers and non-taxable interest)
gen othinc=X5724*cpi
gen totinc=wageinc+bussefarminc+intinc+divinc+kginc+peninc+othinc
gen capinc=max(0,bussefarminc)+intinc+divinc+max(0,kginc)
gen capincnokg=max(0,bussefarminc)+intinc+divinc
* no way to get passive capital income from SCF as schedule E income is not broken down (partnership+S-corp profits with rents, royalties, trust+estate)
gen intdivkinc=intinc+divinc
gen capinc_wscf=kgdivinc_wscf+businc_wscf+intinc_wscf+0*intexm_wscf 

gen kgdivbusinc=kgdivinc+businc 
gen inttotinc=intinc+intexm 
gen kgdivbusinc_wscf=kgdivinc_wscf+businc_wscf
gen inttotinc_wscf=intinc_wscf+intexm_wscf 

* gen test=wageinc+bussefarminc+intdivinc+kginc+ssretinc+transfothinc-income

/*
* variables definition in summary file
WAGEINC=X5702;
BUSSEFARMINC=X5704+X5714;
INTDIVINC=X5706+X5708+X5710; X5706 is non-taxable interest, X5708 is taxable interest, X5710 is dividends 
KGINC=X5712;
SSRETINC=X5722+PENACCTWD; X5722 includes both SSA benefits and other pension benefits but not IRA distributions or 401K after 2004
PENACCTWD includes IRA+401(k) distributions
TRANSFOTHINC=X5716+X5718+X5720+X5724; X5716 is UI/workers comp, X5718 is child support/alimony, X5720 is TANF/SSI/Foodstamps, X5724 is other income on income tax return
*/

* note: income (reported total income) is not the same as income2 (sum of reported income components) because of imputations, income leads to a top income share in 1992 that seems too low
gen income2=cpi*(X5702+X5704+X5714+X5706+X5708+X5710+X5722+X5716+X5718+X5720+X5724)


* WEALTH COMPONENTS
* total networth Kennickell definition is variable networth, used to replicate Kennickell (2009b) wealth shares
gen equitywealth=stocks+stmutf+.5*comutf+.5*othma
gen bondwealth=liq-checking+cds+savbnd+bond-notxbnd+nmmf-stmutf-tfbmutf-.5*comutf+.5*othma
gen muniwealth=notxbnd+tfbmutf
gen currencywealth=checking
gen otherdebtwealth=-(install+othloc+ccbal+odebt)
gen housingwealth=houses+oresre
gen mortgagedebtwealth=-(mrthel+resdbt)
gen fixclaimwealth= bondwealth+muniwealth+currencywealth+otherdebtwealth
gen netrentalwealth=nnresre
gen businesswealth=bus+othfin
gen busrentwealth=businesswealth+netrentalwealth
* SCF pensionwealth does not include DB plans
gen pensionwealth=retqliq+cashli
gen vehicartwealth=vehic+othnfin
* wealth excluding housing and durables
gen nonhousingwealth=networth-housingwealth-vehicartwealth-mortgagedebtwealth
* wealth excluding housing, durables, and pensions (used to test capitalization method in SCF)
gen nhousingpenwealth=networth-housingwealth-pensionwealth-vehicartwealth-mortgagedebtwealth
* net housing wealth in SCF
gen nethousingwealth=housingwealth+mortgagedebtwealth+netrentalwealth


gen networth2=equitywealth+bondwealth+muniwealth+currencywealth+otherdebtwealth+housingwealth+mortgagedebtwealth+netrentalwealth+businesswealth+pensionwealth+vehicartwealth

keep wgt wgint *_wscf *wealth wageinc divinc kginc kgdivinc intexm intinc businc totinc othinc capinc capincnokg intdivkinc  income* filedtax item ssretinc peninc* ssinc cpi cpi_wealth kgdivbusinc inttotinc networth* retqliq irakh nethousing year realestatetax mortpay bussefarminc
* sum [w=wgt]

*********************************
* moving back to nominal values
*********************************

* wealth variables
foreach var of varlist *_wscf networth* equitywealth bondwealth muniwealth currencywealth otherdebtwealth housingwealth mortgagedebtwealth netrentalwealth businesswealth pensionwealth vehicartwealth nonhousingwealth nhousingpenwealth busrentwealth fixclaimwealth nethousingwealth retqliq irakh nethousing  {
	replace `var'=`var'/cpi_wealth
	}
* income variables	
foreach var of varlist wageinc divinc kginc kgdivinc intexm intinc businc totinc othinc capinc capincnokg intdivkinc income* ssretinc peninc* ssinc kgdivbusinc inttotinc realestatetax mortpay {
		replace `var'=`var'/cpi
		}	
	
* computing the SCF wealth rescaling based on Saez-Zucman (_sz) aggregates obtained above from parameters(SZ).csv file
foreach var in equity bond muni currency otherdebt housing mortgagedebt netrental business pension vehicart nonhousing nhousingpen nethousing fixclaim busrent {
quietly: sum `var'wealth [w=wgt]
local `var'_tot=r(sum)*1e-6
gen `var'_sz=`var'wealth*``var'_totsz'/``var'_tot'
display "YEAR = " `year' " `var' "   ``var'_totsz'/``var'_tot'
}
gen networth_sz=equity_sz+bond_sz+muni_sz+currency_sz+otherdebt_sz+housing_sz+mortgagedebt_sz+netrental_sz+business_sz+pension_sz+vehicart_sz

* computing the SCF capital income rescaling based on Saez-Zucman (_sz) aggregates obtained above from parameters(SZ).csv file, added 8/2015
foreach var in kginc divinc intinc bussefarminc  {
quietly: sum `var' [w=wgt]
local `var'_tot=r(sum)*1e-6
gen `var'_sz=`var'*``var'_totsz'/``var'_tot'
display "YEAR = " `year' " `var' "   ``var'_totsz'/``var'_tot'
}

gen capinc_sz=max(0,bussefarminc_sz)+intinc_sz+divinc_sz+max(0,kginc_sz)
gen capincnokg_sz=max(0,bussefarminc_sz)+intinc_sz+divinc_sz



/*
gen networthscf_sz=networth_sz+vehicartwealth
gen networth_sz2=equity_sz+fixclaim_sz+nethousing_sz+business_sz+pension_sz+vehicart_sz
gen networthscf_sz2=networth_sz2+vehicartwealth
*/

cap drop test
gen test=networth-networth2
sum test [w=wgt], det
sum networth* [w=wgt]

* calculating capitalization factors by asset class
foreach var of varlist divinc kgdivinc intexm intinc businc  {
quietly: sum `var' [w=wgt]
local `var'_tot=r(sum)*1e-9 
quietly: sum `var'_wscf [w=wgt]
local `var'_wscf_tot=r(sum)*1e-9 
local `var'_cap=``var'_wscf_tot'/``var'_tot'
display "`var' " ``var'_cap'
gen `var'_w=`var'*``var'_cap'
}

* wealth definition for capitalization test: does not include pensions nor net housing wealth (for lack of as good info on asset or income side for housing and pensions)
* actual wealth directly measured in scf
gen wealth_scf=kgdivinc_wscf+intexm_wscf+intinc_wscf+businc_wscf
* capitalized wealth using only dividends and ignoring capital gains when capitalizing equities
gen wealth_cap=divinc_w+intexm_w+intinc_w+businc_w
* capitalized wealth including both dividends and capital gains when capitalizing equities
gen wealthkg_cap=kgdivinc_w+intexm_w+intinc_w+businc_w

foreach var of varlist wealth_scf wealthkg_cap wealth_cap income totinc capinc capincnokg intdivkinc networth retqliq irakh nethousing networth_sz capinc_sz capincnokg_sz {
	cumul `var' [w=wgint], gen(rank`var')
	}

cumul wageinc [w=wgint] if wageinc>0, gen(rankwageinc) 
replace rankwageinc=0 if rankwageinc==.

gen one=1
quietly: sum one [w=wgt]
local num_tot=r(sum)

* Piketty-Saez total tax units (in millions) from year t-1 (1988 for SCF 1989 etc.), this comes from Table A0 in Piketty-Saez income series
gen totfam=0
replace totfam=114.656  if year==1989
replace totfam=120.453  if year==1992
replace totfam=124.716  if year==1995
replace totfam=129.301  if year==1998
replace totfam=134.473  if year==2001
replace totfam=141.843  if year==2004
replace totfam=148.361  if year==2007
replace totfam=153.543  if year==2010
replace totfam=160.681  if year==2013
replace totfam=totfam*1e+6
* ranking assuming the Piketty-Saez total number of tax units (assumes that at the top, each household is a single tax unit, a reasonable assumption)
foreach var of varlist wealth_scf wealthkg_cap wealth_cap income totinc capinc capincnokg intdivkinc networth retqliq irakh nethousing networth_sz capinc_sz capincnokg_sz {
	gen rank`var'_ps=1-(1-rank`var')*`num_tot'/totfam
	}

* Forbes 400 total nominal wealth (in $bn) from year t, see numbers in appendix table C3, column 2
gen forbes400=0
replace forbes400=268 if year==1989
replace forbes400=301 if year==1992
replace forbes400=394 if year==1995
replace forbes400=738 if year==1998
replace forbes400=951 if year==2001
replace forbes400=1005 if year==2004
replace forbes400=1540 if year==2007
replace forbes400=1370 if year==2010
replace forbes400=2000 if year==2013

save $datascfdir2/capitalization`year'.dta, replace

}



***********************************************************************************************************************************************
* SCF aggregate results on fraction real estate taxes and mortgage payments of itemizers, no data 1989, 1992, and aggregates SCF vs Saez-Zucman
* edited 2/2015 to provide stronger justification on our numbers
***********************************************************************************************************************************************

matrix results = J(`numyears',29,.)

local yy=0
foreach year of numlist $years {
local yy=`yy'+1

use $datascfdir2/capitalization`year', clear

matrix results[`yy',1]=`year'



local jj=2
foreach var of varlist one realestatetax mortpay  {
	local jj=`jj'+1
	quietly: sum `var' [w=wgt]
	local aux1=r(sum)*1e-9
	quietly: sum `var' [w=wgt] if item==1
	local aux2=r(sum)*1e-9
	matrix results[`yy',`jj']=`aux2'/`aux1'
	}
* frac itemizers among all tax units (instead of households)
quietly: sum one [w=wgt]
local num_tot=r(sum)
quietly: sum totfam [w=wgt]
local num_taxunit=r(mean)

matrix results[`yy',2]=results[`yy',3]*`num_tot'/`num_taxunit'

local jj=0
foreach var of varlist networth  {
	quietly sum networth [w=wgt]
	matrix results[`yy',6+`jj']=r(mean)
	local jj=`jj'+1
	}

quietly sum totfam [w=wgt]
matrix results[`yy',6+`jj']=r(sum_w)*1e-6
matrix results[`yy',6+`jj'+1]=r(mean)*1e-6



local jj=`jj'+2
quietly sum networth [w=wgt]
local aux=r(sum)
matrix results[`yy',6+`jj']=`aux'*1e-9
quietly sum networth_sz [w=wgt]
matrix results[`yy',6+`jj'+1]=`aux'/r(sum)

local jj=`jj'+2
foreach var in equity bond muni currency otherdebt housing mortgagedebt netrental business pension nonhousing nhousingpen {  
	quietly sum `var'wealth [w=wgt]
	local aux=r(sum)
	quietly sum `var'_sz [w=wgt]
	matrix results[`yy',6+`jj']=`aux'/r(sum)
	local jj=`jj'+1
	}

* added 2/2015

	foreach var of varlist housingwealth mortgagedebtwealth {
		quietly: sum `var' [w=wgt]
		local aux1=r(sum)*1e-9
		quietly: sum `var' [w=wgt] if item==1
		local aux2=r(sum)*1e-9
		matrix results[`yy',6+`jj']=`aux2'/`aux1'
		local jj=`jj'+1
		}
	display `jj'
	quietly sum retqliq [w=wgt] 
	local tot_penwealth=r(sum)
	quietly sum retqliq [w=wgt] if peninc>0
	matrix results[`yy',6+`jj']=r(sum)/`tot_penwealth'
	quietly sum retqliq [w=wgt] if rankwageinc>0.5
	matrix results[`yy',6+`jj'+1]=r(sum)/`tot_penwealth'
	quietly sum retqliq [w=wgt] if rankwageinc<=0.5 & peninc==0
	matrix results[`yy',6+`jj'+2]=r(sum)/`tot_penwealth'

local jj=`jj'+3
foreach var in capinc capincnokg {  
		quietly sum `var' [w=wgt]
		matrix results[`yy',6+`jj']=r(sum)*1e-9
		local jj=`jj'+1
		}
}

matrix list results

svmat results
keep results*
rename results1 year
rename results2 fracitemtaxunits
rename results3 fracitemhouseholds
rename results4 fracitemproptax
rename results5 fracitemmort
rename results6 meannetworth
rename results7 scfhouseholds
rename results8 pikettytaxunits
rename results9 networthscf
rename results10 networthscf_to_sz
rename results11 equityscf_to_sz
rename results12 bondscf_to_sz
rename results13 muniscf_to_sz
rename results14 currencyscf_to_sz
rename results15 otherdebtscf_to_sz
rename results16 housingscf_to_sz
rename results17 mortgagedebtscf_to_sz
rename results18 netrentalscf_to_sz
rename results19 businessscf_to_sz
rename results20 pensionscf_to_sz
rename results21 nonhousingscf_to_sz
rename results22 nhousingpenscf_to_sz
* added 2/2015
rename results23 fracitemgrosshousing
rename results24 fracitemmortdebt
rename results25 fracpenwealth_pension
rename results26 fracpenwealth_wagetop50
rename results27 fracpenwealth_nopenwagebottom50
* added 8/2015
rename results28 capinckgtot
rename results29 capincnokgtot


outsheet using scf_stataagg.xls, replace
* more explanations on each output variable in the notes of this sheet in the file AppendixTables(OtherEstimates).xlsx


***********************************************************************************************************************
* top wealth shares/top income shares output in scf_stataoutput.xls
* edited on 8/21/2015 adding capital income no KG and interest+dividends (closest to passive K income) 
***********************************************************************************************************************

matrix results = J(6*`numyears',31,.)
local yy=0
foreach year of numlist $years {


use $datascfdir2/capitalization`year', clear

foreach var of varlist wealth_scf income totinc capinc capincnokg intdivkinc networth retqliq irakh nethousing {
quietly: sum `var' [w=wgt]
local `var'_tot=r(sum)*1e-9
}

local ii=1
foreach fract of numlist .9 .95 .99 .995 .999 .9999 {
	matrix results[`numyears'*(`ii'-1)+`yy'+1,1]=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,2]=`year'
	quietly: sum wealth_scf [w=wgt] if rankwealth_scf>=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,3]=1e-9*r(sum)/`wealth_scf_tot'
	quietly: sum wealth_cap [w=wgt] if rankwealth_cap>=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,4]=1e-9*r(sum)/`wealth_scf_tot'
	quietly: sum wealthkg_cap [w=wgt] if rankwealth_cap>=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,5]=1e-9*r(sum)/`wealth_scf_tot'
	quietly: sum wealthkg_cap [w=wgt] if rankwealthkg_cap>=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,6]=1e-9*r(sum)/`wealth_scf_tot'
	local jj=0
	foreach var of varlist income totinc capinc networth retqliq nethousing {
		quietly: sum `var' [w=wgt] if rank`var'>=`fract'
		matrix results[`numyears'*(`ii'-1)+`yy'+1,7+`jj']=1e-9*r(sum)/``var'_tot'
		local jj=`jj'+1
		}
	foreach var of varlist retqliq irakh nethousing {	
		quietly: sum `var' [w=wgt] if ranknetworth>=`fract'
		matrix results[`numyears'*(`ii'-1)+`yy'+1,7+`jj']=1e-9*r(sum)/``var'_tot'
		local jj=`jj'+1
		}
	* mean networth above fractile and below fractile
	quietly: sum networth [w=wgt]
	matrix results[`numyears'*(`ii'-1)+`yy'+1,7+`jj']=results[`numyears'*(`ii'-1)+`yy'+1,7+3]*r(mean)/(1-`fract')	
	local jj=`jj'+1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,7+`jj']=(1-results[`numyears'*(`ii'-1)+`yy'+1,7+3])*r(mean)/(`fract')	
	
	quietly: sum capinc [w=wgt] if rankcapinc_ps>=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,18]=1e-9*r(sum)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,19]=`capinc_tot'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,20]=1e-9*r(sum)/`capinc_tot'
	quietly: sum totinc [w=wgt] if ranktotinc_ps>=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,21]=1e-9*r(sum)/`totinc_tot'
	
	quietly: sum networth [w=wgt] 
	local aux=r(sum)
	quietly: sum forbes400 [w=wgt] 
	local aux400=r(mean)*1e+9
	quietly: sum networth [w=wgt] if ranknetworth>=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,22]=r(sum)/`aux'
	quietly: sum networth [w=wgt] if ranknetworth_ps>=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,23]=r(sum)/`aux'
	quietly: sum networth_sz [w=wgt] 
	local aux=r(sum)
	* typo here in ranking in 1st NBER WP version, used to rank by networth_sz_ps instead of networth_sz, corrected on 8/2015
	quietly: sum networth_sz [w=wgt] if ranknetworth_sz_ps>=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,24]=r(sum)/`aux'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,25]=(r(sum)+`aux400')/(`aux'+`aux400')		
		
	* added 8/21/2015, capital income with KG and without KG, households and tax units for fast reference
	local jj=1
	foreach var of varlist capinc capincnokg {
		quietly: sum `var' [w=wgt] if rank`var'>=`fract'
		matrix results[`numyears'*(`ii'-1)+`yy'+1,25+`jj']=1e-9*r(sum)/``var'_tot'
		local jj=`jj'+1
		}
	foreach var of varlist capinc capincnokg {
			quietly: sum `var' [w=wgt] if rank`var'_ps>=`fract'
			matrix results[`numyears'*(`ii'-1)+`yy'+1,25+`jj']=1e-9*r(sum)/``var'_tot'
			local jj=`jj'+1
			}
	
	foreach var of varlist capinc capincnokg {
			quietly: sum `var'_sz [w=wgt] 
			local aux=r(sum)
			quietly: sum `var'_sz [w=wgt] if rank`var'_sz_ps>=`fract'
			matrix results[`numyears'*(`ii'-1)+`yy'+1,25+`jj']=r(sum)/`aux'
			local jj=`jj'+1
			}
	
		
	local ii=`ii'+1
	}
		
local yy=`yy'+1
}

matrix list results

svmat results

keep results*
rename results1 fractile 
rename results2 year
rename results3 wealthshare
rename results4 wealthsh_capdiv
rename results5 wealthsh_capmix
rename results6 wealthsh_capkg
rename results7 incomeSCFshare
rename results8 incomePSshare
rename results9 capincshare
rename results10 networthshare
rename results11 pensionshare
rename results12 housingshare
rename results13 pensionsharebynetworth
rename results14 irasharebynetworth
rename results15 housingsharebynetworth
rename results16 networthperhouseholdtop
rename results17 networthperhouseholdbottom
rename results18 capincamtPSunits
rename results19 capinctotal
rename results20 capincsharePSunits
rename results21 incomePSsharePSunits
rename results22 SCFnetworthshare
rename results23 SCFshare_PSunits
rename results24 SCFshare_PSunits_reweight
rename results25 SCFshare_PSunits_reweight_f400
rename results26 capinckgshare
rename results27 capincnokgshare
rename results28 capinckgsharePSunits
rename results29 capincnokgsharePSunits
rename results30 capinckgsharePSunits_sz
rename results31 capincnokgsharePSunits_sz
drop capinckgsharePSunits_sz capincnokgsharePSunits_sz

format networth* %12.0g
outsheet using scf_stataoutput.xls, replace
* more explanations on each output variable in the notes of this sheet in the file AppendixTables(OtherEstimates).xlsx


