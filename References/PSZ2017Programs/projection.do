
*************************************************************************************
* created 10/2018, projection beyond $endyear	
* strategy: take the 2012 small file and assume distribution in 2017+ is like 2012
* 2017: blow up weights and incomes to be consistent with macro numbers from Piketty-Saez series
* 2018+: use the same ad-hoc methodology as in parameters
* recompute fedtax using taxsim
*************************************************************************************		
	
* global yr is the year for which we compute projected dataset (defined in runusdina)
* global yr=2020	


	
* need to grab population totals from parameters
insheet using "$parameters", clear names
keep if yr==$yr
foreach var of varlist _all {
local `var'=`var'
}

* I defined two globals that will be used below
global tottaxunits `tottaxunits'
global totadults20 `totadults20'

* projection for 2017 uses the Piketty-Saez series
if $yr==2017 {
* we start from 2012 small file
	use $dirsmall/small2012.dta, clear

* modifying year variables
replace year=$yr
replace flpdyr=$yr
		
* modifying dweght to match corresponding population totals
quietly sum agi [w=dweghttaxu]
local sumw=r(sum_w)*1e-8
display $tottaxunits/`sumw'
replace dweghttaxu=round(dweghttaxu*$tottaxunits/`sumw')
quietly sum agi [w=dweghttaxu]

gen adult=1
replace adult=2 if married==1
quietly sum adult [w=dweght]
local sumw=r(sum)*1e-8
display `sumw'
display $totadults20/`sumw'
replace dweght=round(dweght*$totadults20/`sumw')
sum adult [w=dweght]
local sumw=r(sum)*1e-8
display `sumw'
drop adult
* note that the fraction married is not going to be quite right nor is the full population (kids), nor fraction 65+

* modifying all income sources to match 2017 totals
* target values from 2017 Piketty-Saez (found in DINA(aggreg).xls, sheet DataIncome, cols. WN+
* note that AGI nominal growth from 2016 to 2017 was 7.0%, business income growth was 10.5%,
* net rents, royalties, fiduciary was 12.9%

* known totals (based on prelim 2017 stats, to be revised in Jan 2019 with complete CDW data)
local totagi=10917*1e+9
local totwaginc=7565*1e+9
local totpeninc=1003*1e+9
local totkginc= 846*1e+9
local totaginokg=(10917-846)*1e+9
local totagiadj= 162*1e+9
local totdivinc= 277*1e+9
local totintinc = 105*1e+9
local totbusinc = 1054*1e+9
local totfedtax = 1563*1e+9
local totuiinc = 24.34*1e+9

gen businc=scorinc+partinc+schcinc
gen aginokg=agi-kgagi

foreach var of varlist agi waginc peninc kginc agiadj divinc intinc fedtax uiinc businc aginokg {
	quietly sum `var' [w=dweght] if filer==1
	local sumw=r(sum)*1e-5
	* display `sumw'
	* display `tot`var''
	local gr`var'=`tot`var''/`sumw'
	* display `gr`var''
	replace `var'=`var'*`gr`var''
	quietly sum `var' [w=dweght]
	local sumw=r(sum)*1e-5
	* display `sumw'
	}
		
replace wages=waginc
replace wagincsec=wagincsec*`grwaginc'
replace penincnt=penincnt*`grpeninc'
replace penira=penira*`grpeninc'
replace intexm=intexm*`grintinc'
replace kgagi=kginc
replace kgincfull=kginc

* replace unknown components using agi without K gains
foreach var of varlist setax sey seysec income agicrr charit-studentded eictot-realestatetax ssinc ssincsec incomeps {
	replace `var'=`var'*`graginokg'
	}

* replace business components using businc
foreach var of varlist rentinc-partscorl {	
	replace `var'=`var'*`grbusinc'
	}

cap drop businc aginokg

* recompute variables
replace suminc=waginc+peninc+divinc+intinc+rentinc+estinc+rylinc+schcinc+scorinc+partinc 
replace othinc=income-suminc 

sort id
save $dirsmall/small$yr.dta, replace

* recompute fedtax using taxsim subroutine, fedtax$yr id saved in fedtax$yr.dta (set global $taxsim=0 if no need to recompute)
if $taxsim==1 do programs/taxsim.do
cap mkdir $dirsmall/taxsim
if $taxsim==0 use $dirsmall/taxsim/fedtax$yr.dta, clear

merge 1:1 id using $dirsmall/small$yr.dta

* renormalize fedtax, not clear whether taxsim is super accurate
sum fedtax* [w=dweght] if filer==1
sum fedtax* [w=dweght] if filer==1 & agi>=500000

replace fedtax2017=0 if filer==0
quietly sum fedtax2017 [w=dweght] if filer==1
local sumw=r(sum)*1e-5
quietly sum fedtax [w=dweght] if filer==1
local sumw2=r(sum)*1e-5
replace fedtax2017=fedtax2017*`sumw2'/`sumw'
sum fedtax* [w=dweght] if filer==1
replace fedtax=fedtax2017
drop _merge fedtax2017

order year dweght dweghttaxu filer id
sort id
save $dirsmall/small$yr.dta, replace


}
* end of year 2017 case


* simplified projection for years beyond 2017, extrapolate from small2017.dta previously constructed
// nominal GDP annual growth for 2018=5.3%, 2019=4.5%, 2020=4.1%, 2021=3.9%
// from DINA(aggreg).xls sheet Projections (at the back)
// population 20+ growth is .9% per year after 2017



* for 2018, need to re-use taxsim calculator

if $yr>=2018 {
	local prioryr=$yr-1
	use $dirsmall/small`prioryr'.dta, clear
	
* modifying year variables
replace year=$yr
replace flpdyr=$yr	
	
* upgrade population weights (.9% growth per year after 2017)
	replace dweght=round(dweght*1.009)
	replace dweghttaxu=round(dweghttaxu*1.009)

* upgrade all income measures
	foreach var of varlist agi-othinc wagincsec ssincsec incomeps {	
	if $yr==2018 replace `var'=`var'*(1.053/1.009)
	if $yr==2019 replace `var'=`var'*(1.045/1.009)
	if $yr==2020 replace `var'=`var'*(1.041/1.009)
	if $yr==2021 replace `var'=`var'*(1.039/1.009)
	}
	
	sort id
	save $dirsmall/small$yr.dta, replace
	
	if $yr==2018 {
	* recompute fedtax using taxsim subroutine, fedtax$yr id saved in fedtax$yr.dta (set global $taxsim=0 if no need to recompute)
	if $taxsim==1 do programs/taxsim.do
	if $taxsim==0 use $dirsmall/taxsim/fedtax$yr.dta, clear
	merge 1:1 id using $dirsmall/small$yr.dta
	* total for fedtax2018 is reasonable, $112bn less than baseline
	sum fedtax* [w=dweght]
	gen fedtax2017=fedtax
	replace fedtax2018=0 if filer==0
	replace fedtax=fedtax2018
	*replace fedtax=min(fedtax,fedtax2018) if agi>400000
	sum fedtax* [w=dweght]
	sum fedtax* [w=dweght] if agi>=400000
	drop _merge fedtax2018 fedtax2017

}



order year dweght dweghttaxu filer id
sort id
save $dirsmall/small$yr.dta, replace

}



		
	
	



