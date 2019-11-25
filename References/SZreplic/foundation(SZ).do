**************************************************************************************
**************************************************************************************
**************************************************************************************
* PART A
* Creation of foundation data files, one file per year with the relevant variables for wealth capitalization project
* Raw source = IRS ASCII file "MainDataFile.txt"
* Description of variables in this file is in "DataElementRefList.xls" 
**************************************************************************************
**************************************************************************************
**************************************************************************************


cd $directory
local years="1985/2010"

* IMPORT ASCII DATA

#delimit;
infix 1 lines 1:
yr 1-4 
double id 5-13 
str name 18-77 
str type 86-86 /* See explanation in CodeBook.xls */

/* Income and expenditure */
float contrib 102-113 /* Contributions, gifts, grants etc. received */
float revenue 186-197 /* Total income + contributions */
float intsav 114-125 /* Interest on savings and temporary cash investment */
float divint 126-137 /* Dividends and interest from securities, including tax exempt secs. (contrary to col. b of form 990PF part 1 which excludes tax exempt interest) */
float rent 138-149 /* gross rents */
float kg 150-161 /* Includes kg of mutual funds and kg on derivatives */
float sale 162-173 /* Gross profit (= gross sales - costs of goods sold) from sales of inventory (= itmes the organization either makes to sell to others or buys for resale). */
float othinc 174-185 /* Includes things like royalties, tickets sold, events, & partnership income */
float expense 366-377 /* Total expenses and disbursments */

/* Fair market value of assets at end of year, unless otherwise noted */
float totasset 90-101 /* Faire market value of total assets (end of year) */
float cash 1086-1097 /* Not interest bearing (end of year) */
float savings 1098-1109 /* Savings & temporary cash investemnt (end of year). Memo: savings at book value (col. b) virtually identical */
float accrec 1110-1121 /* accounts receivable (end of year) */
float pledgerec 1122-1133 /* pledge receivable (end of year) */
float grantrec 1134-1145 /* grant receivable (end of year) */
float personrec 1146-1157 /* Receivable due from officers... and other persons (end of year) */
float othrec 1158-1169 /* Other notes & loans receivable (end of year) */
float inventory 1170-1181 /* Inventories for sale or use (end of year) */
float deferred 1182-1193 /* Prepaid expenses and deferred charges (end of year) */
float govbond 1194-1205 /* US and state gov obligations. Only since 1990 (end of year) */
float equity 1206-1217 /* Corporate stocks. Only since 1990 (end of year) */
float corpbond 1218-1229 /* Corporate bonds. Only since 1990 (end of year) */
float rental 1230-1241 /* Real estate investments (land, building), net of depreciation (end of year) */
float mortgage 1242-1253 /* Mortgage loans (end of year) */
float othinv 1254-1265 /* Will typically include private equity and hedge funds (end of year) */
float ownrestat 1266-1277 /* Land, building and equipment net of depreciation (end of year) */
float othasset 1278-1289 /* e.g., future beneficial interest in trusts (Penn), sometimes include hedge/pe funds (Heinz), fine art (Getty)...  (end of year) */
float liab 1062-1073 /* Total liabilities (end of year) */
float totassetb 1050-1061 /* Total assets at book value (end of year) */
float netbook 1074-1085 /* Net assets at book value (end of year): netbook = netbookinit+revenue-expense+unrelkg-unrelkl */
float totassetbinit 810-821 /* Total assets at book value beginning of year */
float liabinit 822-833 /* Total liabilities at beginning of year */
float netbookinit 834-845 /* Net assets at book value beginning of year: netbook = netbookinit+revenue-expense+unrelkg-unrelkl */
float unrelkg 1302-1313 /* Unrealized capital gains: netbook = netbookinit+revenue-expense+unrelkg-unrelkl */
float unrelkl 1314-1325 /* Unrealized capital losses: netbook = netbookinit+revenue-expense+unrelkg-unrelkl */
float weight 2841-2846
using "Foundations/RawData/IRSfoundations/MainDataFile.txt", clear;
#delimit cr

/* Drop Gates foundation which is counted twice in 2006 and 2007 */
drop if id==562618866&(yr==2007|yr==2006)


* DATA CREATION


* Simplified wealth categories 
local receivable "accrec pledgerec grantrec personrec othrec deferred"
egen receivable=rsum(`receivable')
drop `receivable'
gen liquid=0
replace liquid=cash+savings+receivable
gen bond=0
replace bond=govbond+corpbond+mortgage
gen fix=0
replace fix=liquid+bond
gen real=0
replace real=ownrestat+rental+inventory
gen other=0
replace other=othinv+othasset
* no distinction between equity & bonds prior to '90
gen sec=0
replace sec=govbond+corpbond+mortgage+equity
replace sec=totasset-(liquid+other+real) if yr<=1990
*gen check=totasset-(real+equity+bond+liquid+other)
*replace check=totasset-(real+sec+liquid+other) if yr<=1990



* Net assets at year-end market value and positive KG
gen netasset=totasset-liab
gen kgpos=0
replace kgpos=max(kg,0)


* Unrealized capital gains on book-value assets
gen netunrelkg=unrelkg-unrelkl

* Create assets at fair market value at beginning of year by merging with end of year-info of preceding return
format id %12.0g
gsort id yr
local wealth "totasset cash savings receivable inventory govbond corpbond bond equity sec othinv ownrestat rental mortgage othasset netasset liquid fix real other weight"
foreach var of varlist `wealth' {
gen `var'init=`var'[_n-1] if (id[_n]==id[_n-1]) & (yr[_n]==yr[_n-1]+1)
}


* Create assets at mid-year as average of beginning of year and end-of-year market values
foreach var of varlist `wealth' {
gen `var'mid=(`var'+`var'init)/2
}


* Create measure of total KG (realized + unrelized) on market value wealth = deltaW-S
gen totkg=totasset-liab-(totassetinit-liabinit)-(revenue-kg-expense)




save "Foundations/Data/foundationfull.dta", replace



**************************************************************************************
**************************************************************************************
*************************************************************************************** 
* PART B
* Check of capitalization method with foundation data
* Updated July 2014: add code to compute composition of foundation wealth by fractile 
**************************************************************************************
**************************************************************************************
**************************************************************************************
**************************************************************************************

clear
cd $directory


* MACRO DEFINITIONS


foreach part of numlist 1/4 {

* Definitions of different variants for computation of wealth and its distribution:
* wealth = wealth used to compute shares
* wealthrank = wealth used to rank units

* Part 1 = distribution of foundation wealth (end of year)
if `part'==1 {
loca name          "found_wealth"
local wealth       "liquid sec real other"
local wealthrank   "liquid sec real other"
local wealthcompo  "liquid sec bond equity real other"
}

* Part 2: distribution of capitalized income (end of year, mixed method)
if `part'==2 {
loca name          "found_capitmix"
local wealth       "capinc"
local wealthrank   "capincnokg"
local wealthcompo  ""
}

* Part 3: distribution of capitalized income (end of year, no capital gains)
if `part'==3 {
loca name          "found_capitnokg"
local wealth       "capincnokg"
local wealthrank   "capincnokg"
local wealthcompo  ""
}

* Part 4: distribution of capitalized income (end of year, KG in shares & rankings)
if `part'==4 {
loca name          "found_capitkg"
local wealth       "capinc"
local wealthrank   "capinc"
local wealthcompo  ""
}



* Wealth categories (equity, fix, etc.) with suffix 0 to 6 
* 0 suffix denotes aggregates 
* 1: top 10%; 2: top 5%; 3: top 1%; 4: top 0.5%; 5: top 0.1%; 6: top 0.01% 
foreach i of numlist 0/6 {
local wealth`i'
foreach w of local wealthcompo {
             local wealth`i' `wealth`i'' `w'`i'
}
}

* Create matrix of results to be ultimately exported in Excel
local nbcateg: list sizeof wealthcompo
matrix results = J($nbyears,(`nbcateg'+5)*7,.)
#delimit;
matrix colnames results = 
year0 w0 wm0 wsu0 sh0 `wealth0'
year1 w1 wm1 wsu1 sh1 `wealth1'
year2 w2 wm2 wsu2 sh2 `wealth2'
year3 w3 wm3 wsu3 sh3 `wealth3'
year4 w4 wm4 wsu4 sh4 `wealth4'
year5 w5 wm5 wsu5 sh5 `wealth5'
year6 w6 wm6 wsu6 sh6 `wealth6';
#delimit cr
* w=threshold (not meaningful for mixed method)
* wm = average wealth
* wsu = total wealth
* sh = wealth share 



* COMPUTATION OF CAPITALIZED INCOME
 local ii=0
 foreach yr of numlist $years {
local ii=`ii'+1
use "Foundations/Data/foundationfull.dta" , clear
keep if yr==`yr'

* Compute capitalization factors 
local incwealth "totasset intsav divint rent kgpos"
collapse (count) id (sum) `incwealth' [pw=weight]
gen f=totasset/(intsav+divint+rent+kgpos)
gen fnokg=totasset/(intsav+divint+rent)
foreach var of varlist _all {
local `var'=`var'
}

* Compute capitalized income
use "Foundations/Data/foundationfull.dta" , clear
keep if yr==`yr'
gen income=0
replace income=intsav+divint+rent+kgpos
gen capinc=0
replace capinc=income*`f'
gen incomenokg=0
replace incomenokg=intsav+divint+rent
gen capincnokg=0
replace capincnokg=incomenokg*`fnokg'
drop income incomenokg
* Would be straighforward to compute mid-year and beginning of year capitalized income
* With one asset class, makes no difference
* Adding a second asset class (real estate vs. financial wealth) makes very little difference 



* COMPUTATION OF TOP WEALTH SHARES
* Wealth distribution and invidual wealth
egen wealthrank=rsum(`wealthrank') 
cumul wealthrank [aw=weight], gen(rank)
egen wealth=rsum(`wealth')


* Wealth shares and composition by fractile
local jj=1
foreach fract of numlist 0 .9 .95 .99 .995 .999 .9999 {

	matrix results[`ii',`jj']=`yr' 
	quietly: su wealth [aw=weight] if rank>=`fract'
	matrix results[`ii',`jj'+1]=r(min)
	matrix results[`ii',`jj'+2]=r(mean)
	matrix results[`ii',`jj'+3]=r(sum)/1e6
	matrix results[`ii',`jj'+4]=results[`ii',`jj'+3]/results[`ii',4]
	
	local ll=`jj'+5
	foreach var of local wealthcompo {
		quietly: su `var' [aw=weight] if rank>=`fract'
		matrix results[`ii',`ll']=(r(sum)/1e6)/results[`ii',4]
			local ll=`ll'+1 
	}
	
	local jj=`jj'+5+`nbcateg'
	
	}

}


* EXPORT RESULTS
* Converts matrix into variables (need xsvmat for double option)
xsvmat double results, fast names(col)

* Rounding, saving
foreach Y of numlist 0/6 {
*replace year`Y'=1900+year`Y' if year`Y'<2000
replace w`Y'=round(w`Y',1)
replace wm`Y'=round(wm`Y',1)
replace wsu`Y'=round(wsu`Y',1)
replace sh`Y'=round(sh`Y',0.00001)
foreach var of local wealthcompo {
	replace `var'`Y'=round(`var'`Y',0.00001)
}
}

* Add results to Foundations.xlsx (need Stata13 for putexcel command)
mkmat _all, mat(results)
putexcel A1=matrix(results, colnames) using "PaperWealth/ExcelFiles/AppendixTables(OtherEstimates).xlsx", sh(`name') modify keepcellf


}



**************************************************************************************
**************************************************************************************
**************************************************************************************
* Partc C: computation of returns on foundation wealth, by wealth class
* We consider several definitions of return (no KG, realized KG, etc.)
* We consider several measures of assets (beginning of period, mid year, etc.)
* We subtract CPI-U inflation to get real returns
* We compute weighted vs. unweighted returns (makes almost no difference)
**************************************************************************************
**************************************************************************************
**************************************************************************************

clear
cd $directory


* DEFINITION OF LOCAL MACRO VARIABLES


local defreturn "nokg relkgpos relkg allkgbook allkgmarket"
local defasset "begin mid end"
matrix define threshold=(0, 1e5, 1e6, 1e7, 1e8, 5e8, 5e9, .) /* Wealth classes, in constant 2010$ */
local nbgroups=colsof(threshold)-1 
local stats="N wsum kincsum rweight runweight"
local nbstats: word count `stats'
* Stats with group suffix:
foreach i of numlist 0/`nbgroups' { /* Suffix 0 for totals, 1 for first group etc. */
local stats`i'
foreach w of local stats {
             local stats`i' `stats`i'' `w'`i'
}
}


local part=0
foreach def of local defreturn {
local part=`part'+1

local subpart=0
foreach measure of local defasset {
local subpart=`subpart'+1

* Part 1: return = income excluding KG / assets
if `part'==1 {
local kincome       "intsav divint rent" 
}

* Part 2: return = income including positive realized KG / assets
if `part'==2 {
local kincome       "intsav divint rent kgpos"
}

* Part 3: return = income including all realized KG / assets
if `part'==3 {
local kincome       "intsav divint rent kg"
}

* Part 4: return = income including realized KG + unrealized KG on book value assets, as reported by foundations / assets
if `part'==4 {
local kincome       "intsav divint rent kg netunrelkg"
}

* Part 5: return = income including all KG (incl. unrealized on market value wealth), computed as deltaW-S / assets
if `part'==5 {
local kincome       "intsav divint rent totkg"
}

* Measure of asset 1: asset = beginning of year market value
if `subpart'==1 {
local asset       "cashinit savingsinit secinit rentalinit mortgageinit othinvinit"
}

* Measure of asset 2: asset = mid-year market value
if `subpart'==2 {
local asset       "cashmid savingsmid secmid rentalmid mortgagemid othinvmid"
}

* Measure of asset 3: asset = end-of-year market value
if `subpart'==3 {
local asset       "cash savings sec rental mortgage othinv"
}

* Create matrix of results
matrix return_`def'_`measure' = J($nbyears,1+`nbstats'*(`nbgroups'+1),0)
matrix colnames return_`def'_`measure' = year `stats0' `stats1' `stats2' `stats3' `stats4' `stats5' `stats6' `stats7'

* Deflators for constant dollar wealth threshold and real returns computations, (CPI-U year average)
* 1984=209.871
* 2010=100

#delimit;
matrix define deflator=(
209.871, 202.654, 198.956, 191.951, 184.325, 175.852, 
166.837, 160.100, 155.421, 150.904, 147.136, 143.081, 138.978, 135.860, 133.777, 130.886, 
126.630, 123.126, 121.210, 118.509, 115.435, 111.652, 108.163, 105.167, 101.279, 101.640,
100.000);
#delimit cr
foreach kk of numlist $years {
local deflator`kk'=deflator[1,`kk'-1984+1]
local infrate`kk'=deflator[1,`kk'-1984]/deflator[1,`kk'-1984+1]-1
}



* COMPUTATIONS OF STATS: TOTAL (0) AND BY GROUP (1 to `nbgroups') 

* Start looping over years
local ii=0
foreach yr of numlist $years {
local ii=`ii'+1
use "Foundations/Data/foundationfull.dta" , clear
keep if yr==`yr'

* Create foundation-level data
egen kincome=rsum(`kincome')
egen asset=rsum(`asset')
gen return_`def'_`measure'=kincome/asset-`infrate`yr''
gen assetc=asset*`deflator`yr''/100

* Define non-outliers
local nonoutliers "(return_`def'_`measure'>-1) & (return_`def'_`measure'<1)"

* Stats by wealth group + total
gen group=.
replace group=0 if `nonoutliers' /* 0 = total, excluding outliers */
matrix return_`def'_`measure'[`ii',1]=`yr' 
local kk=2
local jj=0
foreach jj of numlist 0/`nbgroups' {
quietly: su weight if group==`jj' & `nonoutliers' /* Number of foundations */
matrix return_`def'_`measure'[`ii',`kk']=r(sum)
quietly: su asset [aw=weight] if group==`jj' & `nonoutliers' /* Total assets (in mn) */
matrix return_`def'_`measure'[`ii',`kk'+1]=r(sum)/1e6
quietly: su kincome [aw=weight] if group==`jj' & `nonoutliers' /* Total capital income (in mn) */
matrix return_`def'_`measure'[`ii',`kk'+2]=r(sum)/1e6
matrix return_`def'_`measure'[`ii',`kk'+3]=return_`def'_`measure'[`ii',`kk'+2]/return_`def'_`measure'[`ii',`kk'+1]-`infrate`yr'' /* weighetd mean return */
quietly: su return_`def'_`mesure' [aw=weight] if group==`jj' & `nonoutliers'
matrix return_`def'_`measure'[`ii',`kk'+4]=r(mean) /* unweighed mean return */
local kk=`kk'+`nbstats'
local jj=`jj'+1
replace group=`jj' if (threshold[1,`jj']<assetc) & (assetc<=threshold[1,`jj'+1]) & `nonoutliers'
}

}

}


* EXPORT RESULTS


* One matrix per part, subparts (= assets at begginning, mid, or end of year) from left to right
matrix return_`def'= return_`def'_begin,  return_`def'_mid, return_`def'_end
* Export results to Excel (need Stata13 for putexcel command)
putexcel A1=matrix(return_`def', colnames) using "PaperWealth/ExcelFiles/AppendixTables(OtherEstimates).xlsx", sh(found_return_`def') modify keepcellf

}

