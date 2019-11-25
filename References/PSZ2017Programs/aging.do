******************************************************************************************************************************
* created 2/2017 to generate aged files based on the most recent PUF and tabulations from internal data for more recent years
******************************************************************************************************************************


* computation of the table by strata and AGI percentiles in the PUF and internal files has been incorporated at the end of build_small

insheet using "$parameters", clear names
keep if yr==$yr
foreach var of varlist _all {
local `var'=`var'
}

* I defined two globals that will be used below
global tottaxunits `tottaxunits'
global totadults20 `totadults20'

******************************************************************************************************************************	
* creating the multiplier for dweght and all other variables to be used for aging	
******************************************************************************************************************************
	
* yr0 is the year of the initial dataset to be aged ($pufendyear)
global yr0=$pufendyear
* yr1 is the final year of aged dataset ($yr goes from $pufendyear+1 to $endyear)
global yr1=$yr

use $root/output/small/agetable$yr1.dta, clear
cap drop ttltxp
cap drop one
* add suffix _m to all variables to denote multiplier
global agelist ""
foreach var of varlist married-ctcrefn {
	global agelist "$agelist `var'"
	}

* global agelist "married xded xkids oldexm oldexf agi waginc peninc penira penincnt divinc intinc intexm rentinc rylinc estinc schcinc scorinc partinc kgagi kginc othinc income mortrental uiinc ssinc sey seysec agicrr agiadj studentded item itemded charit mortded intded statetax realestatetax"
foreach var of varlist dweght year $agelist {
	rename `var' `var'_m
	}
    merge m:1 strata agibin using $root/output/small/agetable$yr0.dta
* generate multipliers and store them in the _m variables
foreach var of varlist dweght year $agelist {
	replace `var'_m=`var'_m/`var' 
	replace `var'_m=1 if `var'==0 | `var'==. | `var'_m==.  
	}
keep strata agibin *_m
local yr0=$yr0
local yr1=$yr1
save $root/output/small/multiplier`yr0'to`yr1'.dta, replace	


******************************************************************************************************************************	
* creating aged dataset based on agetable$yr and most recent PUF	
******************************************************************************************************************************

* file smallforaging$pufendyear.dta was built in build_small.do
use $root/output/small/smallforaging$yr0.dta, clear
drop one
local yr0=$yr0
local yr1=$yr1
merge m:1 strata agibin using $root/output/small/multiplier`yr0'to`yr1'.dta
drop if _merge!=3
drop _merge
replace dweght=dweght*dweght_m
foreach var of varlist year $agelist {
	cap drop aux
	gen aux=`var'*`var'_m 	
	quietly sum aux [w=dweght]
	local tot=r(sum)
	* capping multipliers at +3 and 0 to avoid extreme values
	replace `var'_m=min(`var'_m,3)
	replace `var'_m=max(`var'_m,0)  
	replace `var'=`var'*`var'_m 
	quietly sum `var' [w=dweght]
	local corr=`tot'/r(sum)
	replace `var'=`var'*`corr'
	display "`var' " `corr' 
	}
drop aux	
* cap kginc at -3000
sum kginc [w=dweght]
local tot=r(sum)
replace kginc=max(-3000,kginc)
sum kginc [w=dweght]
local corr=`tot'/r(sum)
replace kginc=kginc*`corr'
replace kginc=max(-3000,kginc)

replace year=round(year)
drop strata agibin *_m
order year id dweght married xded xkids oldexm oldexf agi waginc peninc penira penincnt divinc intinc intexm rentinc rylinc estinc schcinc scorinc partinc kgagi kginc othinc income mortrental uiinc ssinc sey seysec agicrr agiadj studentded item itemded charit mortded intded statetax realestatetax setax fedtax eictot eicrefn ctctot ctcrefn
replace dweght=round(dweght)

/*
* testing, works pretty well for AGI shares
local var "kginc"
cap drop rank
cumul `var' [w=dweght] if `var'>=0, gen(rank)
sum `var' [w=dweght] if rank!=.
local tot=r(sum)
sum `var' [w=dweght] if rank>=.99
display "Top 1% share = " r(sum)/`tot'
*/

* XX rebuild all the small variables as in pufonline, maybe use a subroutine here to avoid repeating program XX
gen flpdyr=year
foreach var of newlist state marriedsep single head dependent age agesec  {
  gen `var'=.
  }
  
cap gen female=0
cap gen femalesec=1 if married==1 
gen ttltxp=realestatetax+statetax
gen suminc=waginc+peninc+divinc+intinc+rentinc+estinc+rylinc+schcinc+scorinc+partinc 

gen taxunits=$tottaxunits
gen adults20=$totadults20
  
*replace dweght=round(dweght*1e+5)
gen scorinc2=scorinc
gen partinc2=partinc
gen wages=waginc
gen intdedoth=intded-mortded
gen kgagid=kgagi
gen kgincfull=kgagi 
replace kgincfull=2.5*kgagi if $yr>=1979 & $yr<=1986 
replace kgincfull=2*kgagi if $yr>=1960 & $yr<=1978
foreach var of varlist rentinc schcinc partinc scorinc partinc2 scorinc2 { 
	gen `var'p=max(0,`var')
	gen `var'l=-min(0,`var')
	}
rename scorincp scorpinc
rename scorincl scorlinc
rename scorinc2p scorpinc2
rename scorinc2l scorlinc2
rename partincp partpinc
rename partincl partlinc
rename partinc2p partpinc2
rename partinc2l partlinc2
gen partscor=partinc+scorinc
gen partscorp=max(0,partscor)
gen partscorl=-min(0,partscor)
drop scorinc2 partinc2
foreach var of newlist partpnp partpp partlnp partlp scorpnp scorpp scorlnp scorlp othinc_imp {
	gen `var'=0
	}

* rounding categorical variables with probabilistic imputation


gen xdedr=xded-floor(xded)
gen xkidsr=xkids-floor(xkids)

foreach var of varlist xdedr xkidsr oldexf {
	local count=`count'+1  
	local numi=34235+`count'+$yr 
	set seed `numi' 
	cap drop randu
	gen randu=uniform()
	cap drop aux
	gen aux=0
	replace aux=1 if `var'>randu
	replace aux=. if `var'==.
	replace `var'=aux	
		}
		
drop aux randu	
replace xded=round(floor(xded)+xdedr)
replace xkids=round(floor(xkids)+xkidsr)
drop xdedr xkidsr

replace marriedsep=0
replace dependent=0
replace single=(married==0 & xkids==0)
replace head=(married==0 & xkids>0) 
 
* sum xded xkids oldexf [w=dweght]

replace xkids=min(xkids,3)
replace xded=min(xded,3) 
* sum xded xkids oldexf [w=dweght]

	
qui egen oldmar=group(married oldexm), label
 		label variable oldmar "Married x 65+ dummy"	
cap drop dweghtdrop
* ordering the variables as in original small$yr files (program will fail if $vartot not defined by going through build_small earlier)
* global vartot "year id state dweght flpdyr taxunits adults20 married marriedsep single head xded dependent xkids item oldexm oldexf female femalesec age agesec agi setax sey seysec wages waginc peninc penincnt penira divinc intinc intexm rentinc rentincp rentincl rylinc estinc othinc_imp schcinc schcincp schcincl partpinc partlinc scorpinc scorlinc partpnp partpp partlnp partlp scorpnp scorpp scorlnp scorlp scorinc partinc partscor scorpinc2 scorlinc2 partpinc2 partlinc2 partscorp partscorl kgagi kgincfull kgagid kginc agiadj income agicrr charit itemded intded mortded intdedoth mortrental studentded fedtax eictot eicrefn ctctot ctcrefn statetax ttltxp realestatetax uiinc ssinc suminc othinc oldmar"
   
order $vartot
save "$dirsmall/small$yr.dta", replace
		
	
	



