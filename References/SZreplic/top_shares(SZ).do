* Program used for wealth paper: computes top shares of wealth and income at tax unit level


clear


* MACRO DEFINITIONS

* x denotes variable whose distribution we're interested in (e.g., wealth, reported capital income, total DINA income...)
* sum of components of `xrank' = variable used to rank individuals
* sum of components of `x' = variable used to compute shares
* sum of components of `control' = denominator for share computations



* foreach part of numlist 1/26 {
foreach part of numlist 26/26 {

* WEALTH


* Baseline wealth distribution (mixed method: KG in shares but not in rankings)
if `part'==1 {
local name     "wealth_baseline"
local x        "equitykg fix housing business pensionlab"
local xrank    "equity   fix housing business pensionlab"
local control  "ttwealth"
}

* Baseline with wealth details
if `part'==2 {
local name	   "wealth_detail"	
local x        "equitykg taxbond muni currency nonmort ownergross ownermort rental business pensionlab"
local xrank    "equity   fix housing business pensionlab"
local control  "ttwealth"
}

* Same as wealth_detail but with taxbond and muni lumped together
if `part'==3 {
local name		"wealth_detail2"	
local x	        "currency nonmort equitykg bond rental ownergross ownermort business pensionlab"
local xrank		"equity   fix housing business pensionlab"
local control	"ttwealth"
}

* Baseline + KG fully capitalized
if `part'==4 {
local name		"wealth_kg"	
local x	        "equitykg fix housing business pensionlab"
local xrank     "equitykg fix housing business pensionlab"
local control   "ttwealth"
}

* Baseline + KG ignored
if `part'==5 {
local name		 "wealth_nokg"	
local x          "equity fix housing business pensionlab"
local xrank   	 "equity fix housing business pensionlab"
local control    "ttwealth"
}

* Baseline + pensions proportional to distributions only
if `part'==6 {
local name		 "wealth_simplepen"	
local x          "equitykg fix housing business pension"
local xrank   	 "equity fix housing business"
local control    "ttwealth"
}

* Baseline + different yield on taxable interest income for top 1% and bottom 99%
if `part'==7 {
local name		 "wealth_heterfix"	
local x          "equitykg fixheter housing business pensionlab"
local xrank   	 "equity fixheter housing business pensionlab"
local control    "ttwealth"
}


* Baseline + non-mortgage debt prop to non-mortgage int deductions prior to 86 and to avg 62-86 distrib of non-mortgage debt after 86
if `part'==8 {
local name		 "wealth_nonmort"	
local x          "equitykg fixpretra housing business pensionlab"
local xrank      "equity   fixpretra housing business pensionlab"
local control    "ttwealth"
}


*  REPORTED CAPITAL INCOME
* partpinc and scorpinc = positive and negative income possible on same rturn
* partpinc2 scorpinc2 = income aggregated return by return = consistent with internal IRS data


* Baseline capital income distribution (mixed method: KG in shares but not in rankings)
if `part'==9 {
local name		 "kinc_baseline"
*local x         "divinc intinc rentincp estinc schcincp partpinc scorpinc kginc"
local x          "divinc intinc rentincp estinc schcincp partpinc2 scorpinc2 kginc"
*local xrank   	 "divinc intinc rentincp estinc schcincp partpinc scorpinc"
local xrank   	 "divinc intinc rentincp estinc schcincp partpinc2 scorpinc2"
* local control  "ttkinc ttkg"
local control    "ttkinc2 ttkg"
}

* KG in shares and in rankings
if `part'==10 {
local name		 "kinc_kg"
*local x         "divinc intinc rentincp estinc schcincp partpinc scorpinc kginc"
local x          "divinc intinc rentincp estinc schcincp partpinc2 scorpinc2 kginc"
*local xrank     "divinc intinc rentincp estinc schcincp partpinc scorpinc kginc"
local xrank      "divinc intinc rentincp estinc schcincp partpinc2 scorpinc2 kginc"
* local control   "ttkinc ttkg"
local control    "ttkinc2 ttkg"
}

* Ignoring KG
if `part'==11 {
local name		 "kinc_nokg"
*local x         "divinc intinc rentincp estinc schcincp partpinc scorpinc"
local x          "divinc intinc rentincp estinc schcincp partpinc2 scorpinc2"
*local xrank     "divinc intinc rentincp estinc schcincp partpinc scorpinc"
local xrank      "divinc intinc rentincp estinc schcincp partpinc2 scorpinc2"
* local control   "ttkinc"
local control    "ttkinc2"
}



* NATIONAL INCOME (DINA)


* Total DINA income by wealth
if `part'==12 {
local name       "incna_bywealth"
local x          "divkg_na int_na rent_na kbus_na pen_na wag_na lbus_na"
local xrank      "equity   fix housing business pensionlab"
local control    "ttnakinc ttnalinc"
}

* Total DINA labor income by wealth
if `part'==13 {
local name       "lincna_bywealth"
local x          "wag_na lbus_na"
local xrank      "equity   fix housing business pensionlab"
local control    "ttnalinc"
}




* INCOME AND WEALTH COMPONENTS

if `part'==14 {
local name		 "dividend"	
local x          "divinc"
local xrank      "divinc"
local control    "ttdivinc"
}

* Capital gains, including negative
if `part'==15 {
local name		 "kgain"	
local x          "kginc"
local xrank      "kginc"
local control    "ttkg"
}

if `part'==16 {
local name		 "bond"	
local x          "taxbond muni"
local xrank      "taxbond muni"
local control    "ttintw"
}


if `part'==17 {
local name		 "housing"	
local x          "housing"
local xrank      "housing"
local control    "ttrentw ttmortw ttrestw"
}

* Business excluding S corp
if `part'==18 {
local name		 "business"	
local x          "business"
local xrank      "business"
local control    "ttschcpartw"
}


if `part'==19 {
local name		 "pension"	
local x          "pensionlab"
local xrank      "pensionlab"
local control    "ttpeniraw	ttpenw"
}

* Equity including S corp, mixed method
if `part'==20 {
local name		 "equity"	
local x          "equitykg"
local xrank      "equity"
local control    "ttdivw ttscorw"
}

* Fixed claims net of non-mortgage debt
if `part'==21 {
local name		 "fixnet"	
local x          "fix"
local xrank      "fix"
local control    "ttintw ttothdebt	ttcurrency"
}


* Trust income by size of net wealth (for offshore wealth computations)
if `part'==22 {
local name		 "offshore"	
local x          "estincpos"
local xrank      "equitykg fix housing business pensionlab"
local control    "ttestpos"
}


* DETAILED COMPOTENTS FOR PURE METHODS (FULL KG OR NO KG)


* Baseline + KG fully capitalized with details
if `part'==23 {
local name		"wealth_detail2_kg"	
local x	        "currency nonmort equitykg bond rental ownergross ownermort business pensionlab"
local xrank     "equitykg fix housing business pensionlab"
local control   "ttwealth"
}

* Baseline + KG ignored with details
if `part'==24 {
local name		 "wealth_detail2_nokg"	
local x          "currency nonmort equity bond rental ownergross ownermort business pensionlab"
local xrank   	 "equity fix housing business pensionlab"
local control    "ttwealth"
}

* OTHER


* K inc passive
if `part'==25 {
local name		 "Kincpassive"	
local x          "divinc intinc rentincp estinc"
local xrank      "divinc intinc rentincp estinc"
local control    "ttdivinc ttintinc ttrentincp ttestinc"
}


* Taxable interest 
if `part'==26 {
local name		 "interest"	
local x          "intinc"
local xrank      "intinc"
local control    "ttintinc"
}


* PREPARE MATRIX OF RESULTS


* Components (equity, fix, etc.) with suffix 0 to 6 to denote groups 
foreach i of numlist 0/6 {
local x`i'
foreach w of local x {
             local x`i' `x`i'' `w'`i'
}
}
* 0 suffix denotes aggregates 
* 1: top 10%; 2: top 5%; 3: top 1%; 4: top 0.5%; 5: top 0.1%; 6: top 0.01% 
local nbcompo: list sizeof x
matrix results = J($nbyears,(`nbcompo'+6)*7,.)
#delimit;
matrix colnames results = 
year0 total  
		 wsu0 wm0 sh0 `x0'
year1 w1 wm1 wsu1 sh1 `x1'
year2 w2 wm2 wsu2 sh2 `x2'
year3 w3 wm3 wsu3 sh3 `x3'
year4 w4 wm4 wsu4 sh4 `x4'
year5 w5 wm5 wsu5 sh5 `x5'
year6 w6 wm6 wsu6 sh6 `x6'
wold0 wold1 wold2 wold3 wold4 wold5 wold6;
#delimit cr
* w = group threshold
* wm = average income or wealth of group
* wsu = total income or wealth of group
* sh = income or wealth share of group


* COMPUTATION OF SHARES FOR EACH YEAR

 
local ii=0
 foreach yr of numlist $years {
local ii=`ii'+1

* Input parameters from Aggregates.xls and convert into macros
* insheet using "$parameters", delimiter(";") clear names
insheet using "$parameters", clear names
keep if yr==`yr'
egen total=rsum(`control') 
foreach var of varlist _all {
local `var'=`var'
}

matrix results[`ii',1]=`yr'
matrix results[`ii',2]=`total'

use "dinafiles/usdina`yr'(SZ).dta" , clear
gen estincpos=max(estinc,0)



* income/wealth and rank in the distribution
egen x=rsum(`x')
egen xrank=rsum(`xrank') 
cumul xrank [w=dweght], gen(rank)
quietly: su xrank [w=dweght]
local totnum=r(sum_w)*1e-8
replace rank=1-(1-rank)*`totnum'/taxunits

* Totals
quietly: su x [w=dweght]
*matrix results[`ii',2]=r(sum)/10e10 /* for shares as a % of microfile totals rather than `control' */
matrix results[`ii',3]=r(sum)/10e10 
matrix results[`ii',4]=r(mean) 
matrix results[`ii',5]=results[`ii',3]/results[`ii',2] 

* Totals by components 
	local kk=6
	foreach var of local x {
		quietly: su `var' [w=dweght]
		matrix results[`ii',`kk']=r(sum)/10e10
				local kk=`kk'+1
	} 

* Shares and composition by fractile
local jj=6+`nbcompo'
foreach fract of numlist .9 .95 .99 .995 .999 .9999 {

	matrix results[`ii',`jj']=`yr' 
	quietly: su xrank [w=dweght] if rank>=`fract'
	matrix results[`ii',`jj'+1]=r(min)
	quietly: su x [w=dweght] if rank>=`fract'
	matrix results[`ii',`jj'+2]=r(mean)
	matrix results[`ii',`jj'+3]=r(sum)/10e10
	matrix results[`ii',`jj'+4]=results[`ii',`jj'+3]/results[`ii',2]
	
	local ll=`jj'+5
	foreach var of local x {
		quietly: su `var' [w=dweght] if rank>=`fract'
		matrix results[`ii',`ll']=(r(sum)/10e10)/results[`ii',2]
			local ll=`ll'+1 
	}
	
	local jj=`jj'+5+`nbcompo'
	
	}


* Total income/wealth for taxpayers older than 65 for each group
gen oldx=x*oldexm
local jj=(`nbcompo'+5)*7+1
foreach fract of numlist 0 .9 .95 .99 .995 .999 .9999 {

	quietly: su oldx [w=dweght] if rank>=`fract'
	matrix results[`ii',`jj']=r(sum)/10e10
	local jj=`jj'+1
}

}


* EXPORT RESULTS


* Converts matrix into variables (need xsvmat for double option)
xsvmat double results, fast names(col)


* Rounding, saving
foreach Y of numlist 0/6 {
replace wm`Y'=round(wm`Y',1)
replace wsu`Y'=round(wsu`Y',1)
replace sh`Y'=round(sh`Y',0.00001)
foreach var of local x {
	replace `var'`Y'=round(`var'`Y',0.00001)
}
}
foreach Y of numlist  1/6 {
replace w`Y'=round(w`Y',1)
}



* Add results to Distribution.xlsx (need Stata13 for putexcel command)
mkmat _all, mat(results)
putexcel A1=matrix(results, colnames) using "$dirreplic/ExcelFiles/AppendixTables(Distributions).xlsx", sh(`name') modify keepcellf

}



