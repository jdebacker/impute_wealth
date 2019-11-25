************************************************************************************************
* program added on 5/2017 to build a disclosure proof version of the small files
* revised 1/2018 for final online posting
* edits to try and group negative AGI records in priority
************************************************************************************************



* global group5=0 if grouping of 5 has to be redone (time consuming), group5=1 if we re-use older grouping auxfull$yr
*global group5=0

if $online==0 | $data==1 stop
* note that directory $dirsmall is $dirsmall/online when online=1 (so that old small files are not affected)

******************************************************************************************************************
* new 2/2018, bring in pre-tax and post-tax national income and imputed wealth from external dinafiles to use them in distance
******************************************************************************************************************

use id filer peinc poinc hweal using "$root/output/dinafiles/usdina$yr.dta", clear
keep if filer==1
collapse (sum) peinc poinc hweal, by(id)
duplicates report id
sort id
merge 1:1 id using "$dirsmall/small$yr.dta"
count if _merge!=3
display $yr "   " r(N)
if r(N)>1 stop
drop if _merge==1
replace peinc=agi if peinc==.
replace poinc=agi if poinc==.
replace hweal=0 if hweal==.
drop _merge
order year id state dweght flpdyr peinc poinc hweal 
save "$dirsmall/small$yr.dta", replace

* save "$dirsmall/temp.dta", replace

/* testing stuff, to be discarded later
use id filer peinc poinc hweal using "$root/output/dinafiles/usdina$yr.dta", clear
keep if filer==1
collapse (sum) peinc poinc hweal, by(id)
duplicates report id
sort id
merge 1:1 id using "$root/output/small/small$yr.dta"
keep if filer==1
count if _merge!=3
display r(N)
if r(N)!=0 stop
drop _merge
order year id state dweght flpdyr peinc poinc hweal
save "$dirsmall/temp_old.dta", replace

* testing
use "$root/output/dinafiles/online/usdina$yr.dta", clear
keep if filer==1
collapse (sum) peinc poinc hweal (mean) dweght, by(id)
save "$dirsmall/temp_old.dta", replace
use "$dirsmall/temp_old.dta", clear
local var "hweal"
cumul `var' [w=dweght], gen(rank)
sum `var' [w=dweght]
local full=r(sum)
sum `var' [w=dweght] if rank>=.99
local oldonline = r(sum)/`full'
use "$dirsmall/temp.dta", clear
cumul `var' [w=dweght], gen(rank)
sum `var' [w=dweght]
local full=r(sum)
sum `var' [w=dweght] if rank>=.99
local fulldata = r(sum)/`full'
use "$dirsmall/small$yr.dta", clear
cumul `var' [w=dweght], gen(rank)
sum `var' [w=dweght]
local full=r(sum)
sum `var' [w=dweght] if rank>=.99
local newonline = r(sum)/`full'
display " FULL DATA = "  `fulldata' " OLD RESULT = "  `oldonline'  " NEW RESULT = "  `newonline'  
display " RATIO OF OLD/FULL = " `oldonline'/`fulldata' " RATIO OF NEW/FULL = " `newonline'/`fulldata' 
*/



  
use "$dirsmall/small$yr.dta", clear
* random variable needed to split equal amounts
set seed 1234
gen randu=uniform()/20
cap drop if filer==0

******************************************************************************************************************
* create aggregate records for 1962-1995 using SOI strategy, of selecting 30 extreme records for each $ variable [weighted]
* along all the uncapped $ variables 
* (uncapped defined as max variable > $500K or min variable < -$50K (in 2011 and indexed by mean AGI for other years)
* we do this only up to 2008 as PUF does aggregate records in 2009+
******************************************************************************************************************

quietly sum id
local minid=r(min)
* variable minid used to not repeat procedure if already done

if $yr<=2008 & `minid'>=0 {

* pick all $ variables that will be left in dataset pufonline
global varaggr "wages-othinc"
global varaggr "agi waginc peninc penira penincnt divinc intinc intexm rentinc rylinc estinc schcinc scorinc partinc kgagi kginc othinc income mortrental uiinc ssinc sey seysec agicrr agiadj studentded item itemded charit mortded intded statetax realestatetax setax fedtax eictot eicrefn ctctot ctcrefn"

* nominal price index for selecting uncapped $ variable, cut-off relative to 2012 where mean AGI is $62800
sum agi [w=dweght]
global index=r(mean)/62800

* flag variable is dummy flagging extreme records needed to be aggregated
gen flag=0
foreach var of varlist $varaggr {
		* flagging positive variables
		quietly sum `var'
		if r(max)>500000*$index {
			cap drop aux0
			gen aux0=-`var'-randu
			cap drop aux1
			cumul aux0 [w=dweght] if id>0, gen(aux1) freq
		    replace flag=1 if aux1<=30*1e+5 & aux1!=. & id>0
			}
		* flagging negative variables
		quietly sum `var'
		if r(min)<-50000*$index {
			cap drop aux0
			gen aux0=`var'+randu
			cap drop aux1
			cumul aux0 [w=dweght] if id>0, gen(aux1) freq
		    replace flag=1 if aux1<=30*1e+5 & aux1!=. & id>0			
			}
			
      	}


* put flagged records in 4 buckets based on AGI as in 2011+ PUF, code: id=0 is for $100m+, id=-1 for <$0, id=-2 for $10m-$100m, id=-3 for $0-$10m
* for 1996-2008 when id=0 already exists based on SOI-PUF difference, I use a new id=-4 for $100m+ new record
* instead of using constant $ cut-off, I cut by 1/3, 1/3, 1/3 for AGI>=0 (to control for changes in distribution) 
* In 2011, roughly 1/3,1/3,1/3 for nominal cut-offs 0-10m,10m-100m,100m+, so method is consistent with actual PUF 2011+
replace id=-1 if flag==1 & agi<0
cumul agi [w=dweght] if flag==1 & agi>=0, gen(aux) 
replace id=-3 if flag==1 & agi>=0 & aux<1/3 
replace id=-2 if flag==1 & agi>=0 & aux>=1/3 & aux<2/3 
replace id=0 if flag==1 & agi>=0 & aux>=2/3 & $yr<1996
replace id=-4 if flag==1 & agi>=0 & aux>=2/3 & $yr>=1996	
drop aux0 aux1 aux

tab id if id<=0

* collapsing the aggregate records by id=0,-1,-2,-3,-4
bys id: gen num=_n if flag==1
bys id: egen dweghtm=sum(dweght) if flag==1

order id flag dweght 
foreach var of varlist year-oldmar {
	bys id: egen aux=sum(dweght*`var') if flag==1
	replace aux=aux/dweghtm if flag==1
	replace `var'=aux if flag==1
	drop aux
	}
	
replace dweght=dweghtm if flag==1
drop dweghtm
drop if num>1 & flag==1

display "XX count = "
count

* rounding categorical variables 
replace state=0 if flag==1
replace married=1 if flag==1
replace marriedsep=0 if flag==1
replace single=0 if flag==1
replace head=0 if flag==1
replace female=0 if flag==1
replace femalesec=1 if flag==1
replace item=1 if flag==1
replace dependent=0 if flag==1
replace flpdyr=$yr if flag==1
foreach var of varlist xded xkids oldexm oldexf {
   replace `var'=round(`var') if flag==1
   }

order year id state dweght
* list if flag==1   
   
drop num flag randu

save "$dirsmall/small$yr.dta", replace

}
	

	
use "$dirsmall/small$yr.dta", clear

******************************************************************************************************************
* subsampling to 1/3 max in 1962-2004 (in 2005+, 10% max subsampling in PUF)
******************************************************************************************************************

* even with seeding, the runs seem capricious, need to investigate or re-merge using auxfull$yr when group5=1

if $yr<=2004 & $data==0 & $online==1 {
duplicates report id
sort id 
* seeding so that always the same records are chosen (critical to keep auxfull$yr constant across runs)
local numi=45452342
local numi=`numi'+$yr 
set seed `numi'
gen randu=uniform()
gen topsample=(dweght<300000)
tab topsample
sum agi [w=dweght] if topsample==1 & id>0
drop if randu>dweght/300000 & topsample==1 & id>0
replace dweght=300000 if topsample==1 & id>0
sum agi [w=dweght] if topsample==1 & id>0
drop randu topsample

	}
	
sort id
sum id, det	

save "$dirsmall/small$yr.dta", replace

******************************************************************************************************************
* grouping records by groups of 5 based on proximity (time consuming)
******************************************************************************************************************

* start of block of code for grouping of 5
if $group5==0 {
use "$dirsmall/small$yr.dta", clear

* need to flag the aggregate records (as they are excluded from the grouping procedure), those with id<=0
gen aggflag=0
replace aggflag=1 if id<=0

* kids dummy
gen kidsdummy=(xkids!=0)
* positive wages dummy
gen wagdummy=(wages>0)

* creating 12 cells (married vs not)*(itemizer vs not)*(old vs young with kids vs young no kids) + cell=0 for aggregate records
* grouping will be done within each of these 12 cells
local n=1
gen cell=0
foreach mar of numlist 0 1 {
foreach itm of numlist 0 1 {
replace cell=`n' if oldexm==1 & married==`mar' & item==`itm'
local n=`n'+1
	foreach kid of numlist 0 1 {
	replace cell=`n' if oldexm==0 & married==`mar' & kidsdummy==`kid' & item==`itm'
	local n=`n'+1
		}
	}
	}
replace cell=0 if aggflag==1

global nn=5
tab cell

* breaking up big cells with over 30K obs into 2 equal sized cells ranking by AGI (for processing speed)   
global maxcellsize=20000
foreach j in numlist 1/2 {
global ncell=`n'-1
display $ncell

	foreach nc of numlist 1/$ncell {  
    quietly count if cell==`nc'
    local cellsize=r(N)
    if `cellsize'>=$maxcellsize {
       gsort cell -agi 
       bys cell: gen counter=_n
       replace cell=`n' if counter>`cellsize'/2 & cell==`nc'
       drop counter
	   local n=`n'+1
	    }
	}
}
tab cell
global ncell=`n'-1
display $ncell

* creating distance variable based on several income variables listed in $vardist
* experimenting shows that using too many variables is not good nor choosing too few, so medium number works best
gen businc=schcinc+partinc+scorinc
gen capinc=intinc+rylinc+estinc+intexm+rentinc+divinc
gen labinc=wages+peninc
*global vardistl "agi labinc businc capinc kginc divinc intinc intexm wages scorinc partinc schcinc rentinc estinc rylinc fedtax charit realestatetax statetax mortded"
global vardist "agi peinc peinc poinc poinc poinc hweal hweal hweal labinc businc capinc kginc wages divinc intinc partinc scorinc realestatetax mortded"
global vardistl $vardist


keep id cell aggflag dweght $vardistl
*rename coarse coarsem
gsort -agi 
save "$dirsmall/aux.dta", replace

quietly sum cell
global maxcell=r(max)
global nn=5

* algorithm for grouping records: separately for each cell, sort from highest AGI to lowest AGI
* start from top record, find nearest 4 neighbors, create 1 record out of these 5, remove 5 records and repeat from top record
foreach cc of numlist 1/$maxcell {
	use "$dirsmall/aux.dta", clear
	keep if cell==`cc'
	local nleft=_N
	gen coarse=0
	gen coarsesd=0
	local step=0
	* calculating standard deviation of each variable
	foreach var of varlist $vardistl {
		quietly sum `var' [w=dweght]
		local sd`var'=r(sd)
		*local sd`var'=1
		display "`var'" `sd`var''
		}


	* start from highest AGI record, find 4 nearest guys then repeat procedure until no data left
	* every 5th step start from lowest negative AGI record instead of highest (to increase match quality for large negative AGI records)
	* variable coarsed will number records for grouping 1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,...
	* local variable step is the count of the group 
	while `nleft'>=$nn {
	  local step=`step'+1
      * compute distance to top record [1] by normalizing by standard deviation putting double weight on peinc, pre-tax national income 
      gsort coarsesd -agi
	  if floor(`step'/5)==`step'/5 sort coarsesd agi
	  if agi[1]>=0 gsort coarsesd -agi
	  *display "STEP = " `step' " AGI = " agi[1] "  " agi[2]
      cap drop distancesd
	  gen distancesd=((peinc-peinc[1])/`sdpeinc')^2 if coarsesd==0
      foreach var of varlist $vardist {
      	replace distancesd=distancesd+((`var'-`var'[1])/`sd`var'')^2 if coarsesd==0
      	}
      sort distancesd
      replace coarsesd=`step' if _n<=$nn 
      * number of records left to sort
      local nleft=`nleft'-$nn
		}
    * <$nn remaining records are added to last cell to make sure all cells have 5+ records
    replace coarsesd=`step' if coarsesd==0
    save "$dirsmall/aux`cc'.dta", replace
}



* rebuilding the dataset by appending all the auxXX.dta datasets (and merging to small for exploration)
use "$dirsmall/aux.dta", clear
keep if cell==0
foreach cc of numlist 1/$maxcell {
	append using "$dirsmall/aux`cc'.dta"
	}
keep id coarse* cell
sort id
save "$dirsmall/auxfull$yr.dta", replace
* end of code block for grouping by 5
}

if $group5!=0 use "$dirsmall/auxfull$yr.dta", clear

save "$dirsmall/auxfull.dta", replace
merge 1:1 id using "$dirsmall/small$yr.dta"
tab _merge
count if _merge!=3
if r(N)>0 stop
keep if _merge==3
cap drop _merge
save "$dirsmall/auxfull.dta", replace

* averaging with each group of 5 records and selecting only 1 record 

local sd=1

use "$dirsmall/auxfull.dta", clear
gen aggflag=(cell==0)
if `sd'==1 replace coarse=coarsesd
if `sd'==1 drop coarsesd
bys cell: replace coarse=_n if cell==0
bys cell coarse: gen num=_n
bys cell coarse: egen dweghtm=sum(dweght) 
*bys cell coarsesd: gen num3=_n
*bys cell coarsesd: egen dweghtm3=sum(dweght) 
gen agiold=agi
gen xkidsold=xkids
order id cell coarse dweght

foreach var of varlist year-aggflag {
	bys cell coarse: egen aux=sum(dweght*`var')
	replace aux=aux/dweghtm
	replace `var'=aux
	drop aux
	}

	
* cleaning up various variables
keep if num==1


drop cell coarse* num agiold xkidsold dweght aggflag
rename dweghtm dweght
replace dweght=round(dweght)
order year id state dweght 


compress
replace id=_n if id>=1

* re-creating oldmar variable
drop oldmar
qui egen oldmar=group(married oldexm), label
 		label variable oldmar "Married x 65+ dummy"
 	compress


save "$dirsmall/small$yr.dta", replace



******************************************************************************************************************
* extra processing: cleaning and rounding
******************************************************************************************************************


use "$dirsmall/small$yr.dta", clear

* cleaning up various variables
* state variable set of zero
replace state=0
* set filing year always to processing year
replace flpdyr=year

* For dummy variables, I set variable based on probabilities
local count=0

sum head single marriedsep [w=dweght]

foreach var of varlist single marriedsep oldexf dependent {
	local count=`count'+1  
	local numi=34234+`count'+$yr 
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

* kids and dependents imputations not very good, better strategy is to carry xkids>=1, xkids>=2, xkids>=3 dummies and apply probabilities
foreach var of varlist xded xkids {
   replace `var'=round(`var') 
   }
* make sure xkids never above 3
replace xkids=3 if xkids>3
replace xded=3 if xded>3
  
* consistency of status when single
replace single=0 if marriedsep==1 & single==1
replace head=1-single-marriedsep if married==0
*gen test=single+head+marriedsep+married
*sum head single marriedsep test [w=dweght]

* remove female and femalesec information
replace female=0
replace femalesec=1 if married==1
replace femalesec=. if married==0

replace age=. 
replace agesec=. 


* round to 4 significant digits each $ income variable

foreach var of varlist agi-othinc {
cap drop numdigits
gen numdigits=floor(log10(abs(`var')))
cap drop aux
gen aux=`var'
replace aux=round(`var',10^(max(0,numdigits+1-4))) if abs(`var')>=100000
replace aux=round(`var',100) if abs(`var')>=10000 & abs(`var')<100000
replace aux=round(`var',10) if abs(`var')>5 & abs(`var')<10000
replace aux=2 if abs(`var')<5 & `var'>0
replace aux=-2 if abs(`var')<5 & `var'<0
replace `var'=aux
	}

		
drop numdigits aux	
* recomputed values for post-rounding consistency
replace suminc=waginc+peninc+divinc+intinc+rentinc+estinc+rylinc+schcinc+scorinc+partinc 
replace othinc=income-suminc 	
replace income=agi-kgagi+agiadj+agicrr
replace intdedoth=intded-mortded
	
sort id
duplicates report id

save "$dirsmall/small$yr.dta", replace




* cleaning up by removing extra variables not used in DINA
use "$dirsmall/small$yr.dta", clear
cap drop peinc poinc hweal
global vartot ""
global vartot0 "year-oldmar"
foreach var of varlist $vartot0 {
  global vartot "$vartot `var'"
  }

drop taxunits adults20 state flpdyr marriedsep single head dependent female femalesec age agesec 
drop wages rentincp rentincl othinc_imp schcincp schcincl partpinc partlinc scorpinc scorlinc partpnp partpp partlnp partlp scorpnp scorpp scorlnp scorlp partscor scorpinc2 scorlinc2 partpinc2 partlinc2 partscorp partscorl
drop kgincfull kgagid intdedoth suminc oldmar ttltxp
replace dweght=round(dweght*1e-5)

global onlinelist "year id dweght married xded xkids oldexm oldexf agi waginc peninc penira penincnt divinc intinc intexm rentinc rylinc estinc schcinc scorinc partinc kgagi kginc othinc income mortrental uiinc ssinc sey seysec agicrr agiadj studentded item itemded charit mortded intded statetax realestatetax setax fedtax eictot eicrefn ctctot ctcrefn"

* getting rid of any variable not in the list above $onlinelist
gen last=0
order $onlinelist last
gen last2=0
drop last-last2
order $onlinelist

* adding and amending labels
label variable id "unique ID (ID<=0 for aggregate extreme value records: ID=-1 for AGI<0, ID=0,-2,-3,-4 for AGI>=0"
label variable xded "total number of dependents (spouse does not count, capped at 3)"
label variable xkids "total number of children at home among dependents (capped at 3)"
label variable dweght "Population weight"
label variable rentinc "net rental income (schedule E)"
label variable estinc "estate and trust net income"
label variable rylinc "royalties net income"
label variable mortded  "Mortgage interest deduction (schedule A)"

compress
save "$dirsmall/pufonline/pufonline$yr.dta", replace
*cap save "$dirsmall/online/pufonline/pufonline$yr.dta", replace

* csv output version
use "$dirsmall/pufonline/pufonline$yr.dta", clear
rename oldexm oldexm2
gen oldexm=(oldexm2==1)
compress oldexm
drop oldexm2

rename married married2
gen married=(married2==1)
compress married
drop married2

order $onlinelist
outsheet using "$dirsmall/pufonline/pufonline$yr.xls", replace 



**************************************************************************************************************************
* from pufonline to small file: recompute blank variables for small$yr to work with other programs from pufonline$yr
**************************************************************************************************************************
use "$dirsmall/pufonline/pufonline$yr.dta", clear
*cap use "$dirsmall/online/pufonline/pufonline$yr.dta", clear
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
  
replace dweght=round(dweght*1e+5)
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

qui egen oldmar=group(married oldexm), label
 		label variable oldmar "Married x 65+ dummy"	
	
* ordering the variables as in original small$yr files 
order $vartot
compress
save "$dirsmall/small$yr.dta", replace


**************************************************************************************************************************
* various tests to make sure pufonline.dta, commented out as they run on all years 
**************************************************************************************************************************



* test of aggregate record numbers (commented out), aggregate records always represent at least 47 records (and almost always represent 100+ records)
* checked that all variables are present for all records
* checked that dweght>=15 for all records (except top record built by difference PUF and INSOLE from previous work)
* cd "/Users/manu/Dropbox/SaezZucman2014/usdina"
/*
log using "output/log/pufonlinelog.log", replace


foreach yr of numlist 1962 1964 1966/2014 {

   /*
   use "output/small/online/pufonline/pufonline`yr'.dta", clear
   *use "output/dinafile/online/usdina`yr'.dta", clear
   local step=0
   foreach var of varlist year-ctcrefn {
     quietly count if `var'==.
	 if r(N)>=1 local step=`step'+1
	 }
	 display "YEAR = " `yr' "  NUMBER OF VARS with MISSING = " `step'   
   *count
   *sum year dweght 
   * duplicates report id
   * list year id dweght agi if id<=0
   * sum dweght if id>0, det
   *tab married [w=dweght]
   *tab item [w=dweght]
   *tab xded xkids [w=dweght]
   *tab oldexm [w=dweght]
   *tab oldexf [w=dweght]
   */  
   }
   
   foreach yr of numlist $years {
   use "output/dinafiles/usdina`yr'.dta", clear
   gen missing=0
   local step=0
   drop if dweght==0 | dweght==.
   foreach var of varlist id-vethealth {
     quietly count if `var'==.  
	 quietly replace missing=1 if `var'==.
	 if r(N)>=1 local step=`step'+1
	 if r(N)>=1 display "VARIABLE MISSING = " "`var'"
	 }
	 display "YEAR = " `yr' "  NUMBER OF VARS with MISSING = " `step' " OBS with 0 weight = " r(N)
	 tab missing
   }  
 
* missing issues: dweght=0 records lack some variables, nonmort missing for some records, 1962-64 have dweght=.
 
 
cap log close
*/


* smallo2010first.dta uses sd method but did not incorporate realestatetax mortded
* and hence had too much middle class wealth and also too few fraczero wages
* smallo2010current.dta adds realestatetax mortded to distance and doubles weight on wages

