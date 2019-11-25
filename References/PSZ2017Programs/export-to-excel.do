*! Put all Excel outsheet (internal and external) in single Excel file with description


********************************************************************************************************
* Part I: output for Piketty-Saez-Zucman paper (external and internal sheets)
********************************************************************************************************


	local external : dir "$diroutput/ToExcel" files "*.xlsx"
	local internal : dir "$diroutput/ToExcelInternal" files "*.xlsx"
	/*
	putexcel set "$diroutput/Outsheets.xlsx", replace
	foreach mat in `external' {
		qui import excel "$diroutput/ToExcel/`mat'", firstrow clear
		local name = substr("`mat'",1,length("`mat'")-5)
		*putexcel set "$diroutput/Outsheets.xlsx", sh(0`name') modify
		local name5letter = substr("`mat'",1,5) // remove *0 in thres files
		if "`name5letter'" ==  "thres" {
			qui drop *0
		}
		foreach var of varlist _all {
			qui replace `var'=round(10000*`var')/10000
		}
		qui compress
		mkmat _all, mat(`name')
		di "Importing `name'"
		*local list = "`list' `name'"
		*di "`list'"
		qui putexcel A1=matrix(`name', colnames), sh(0`name') 
		di "Saving sheet `name'"
		*putexcel A1=matrix(`name', colnames)
	}
*/
	putexcel set "$diroutput/OutsheetsInternal.xlsx", replace
		foreach mat in `internal' {
		qui import excel "$diroutput/ToExcelInternal/`mat'", firstrow clear
		local name = substr("`mat'",1,length("`mat'")-5)
		*putexcel set "$diroutput/Outsheets.xlsx", sh(0`name') modify
		local name5letter = substr("`mat'",1,5) // remove *0 in thres files
		if "`name5letter'" ==  "thres" {
			qui drop *0
		}
		foreach var of varlist _all {
			qui replace `var'=round(10000*`var')/10000
		}
		qui compress		
		mkmat _all, mat(`name')
		di "Importing `name'"
		*local list = "`list' `name'"
		*di "`list'"
		qui putexcel A1=matrix(`name', colnames), sh(1`name') 
		di "Saving sheet `name'"
		*putexcel A1=matrix(`name', colnames)
	}

		* Add Read Me manually


********************************************************************************************************
* Part II: output for SOI white paper, internal tabs 
********************************************************************************************************
/*
* set review=1 if you want to produce counts
* set review=0 for not producing counts
global review=0


* 1. $10m+ AGI bracket for 1996-2014

foreach yr of numlist 1996/2013 {
use "$diroutput/topstat/top`yr'.dta",clear
if `yr'==2006 cap drop e0* e1* e2* e3* e5* e6* e8* e9* t2* s2* p2* p6* p0* s0*
cap drop agiadj
cap drop sey*irs
cap drop statetaxirs
cap replace state=0
cap replace retid=0
foreach var of varlist * {
	replace `var'=0 if `var'<10 & `var'>0
	}

mkmat _all, mat(matr)
local row=3*(`yr'-1996)+2
putexcel A1=("Statistics on all tax filers with AGI above $10m (using PUF NBER variable names layout), years 1996-2013") using "$diroutput/outsheetsoi.xlsx", sh("toprecords") modify
putexcel A`row'=(`yr') using "$diroutput/outsheetsoi.xlsx", sh("toprecords") modify
local row=`row'+1
putexcel A`row'=matrix(matr, colnames) using "$diroutput/outsheetsoi.xlsx", sh("toprecords") modify
}
local row=`row'+3
putexcel A`row'=("This table provides statistics for tax returns with AGI $10m+ in the SOI individual file for all PUF variables") using "$diroutput/outsheetsoi.xlsx", sh("toprecords") modify
local row=`row'+3
putexcel A`row'=("All variables display the sum of each variable across all records with AGI above $10m. The number of records is included in the variable dweght") using "$diroutput/outsheetsoi.xlsx", sh("toprecords") modify
local row=`row'+1
putexcel A`row'=("All binary variables where less than 10 records have a positive number have been set to zero.") using "$diroutput/outsheetsoi.xlsx", sh("toprecords") modify
local row=`row'+1
putexcel A`row'=("PUF variable names follow the NBER convention. ") using "$diroutput/outsheetsoi.xlsx", sh("toprecords") modify
local row=`row'+1
putexcel A`row'=("These statistics can be used to restore representativity at the top in the PUF, which is lost due to exclusion of extreme records from PUF sampling starting in 1996.") using "$diroutput/outsheetsoi.xlsx", sh("toprecords") modify




* 2a. wages earnings split 1999-2014 for married filers (based on W2 split from databank merged to SOI files)
* matrices wagspintYYYY.xls created by program sharefbuild.do
foreach yr of numlist 1999/2014 {
*foreach yr of numlist 2014 {
	insheet using "$dirmatrix/wagmat/wagspint`yr'.xls", clear
	foreach var of varlist * {
		replace `var'=round(10000*`var')/10000
	 }
	local name = "wagspint`yr'"
	mkmat _all, mat(`name')
	putexcel A1=("Share of female wage income among married tax filers with positive wage income, by family wage income percentiles, year `yr'") using "$diroutput/outsheetsoi.xlsx", sh("wagesplit`yr'") modify
	putexcel A2=matrix(`name') using "$diroutput/outsheetsoi.xlsx", sh("wagesplit`yr'") modify
	putexcel C2=(0) using "$diroutput/outsheetsoi.xlsx", sh("wagesplit`yr'") modify
	putexcel A3=("wage percentile (lower)") using "$diroutput/outsheetsoi.xlsx", sh("wagesplit`yr'") modify
	putexcel B2=("share female wages (lower)") using "$diroutput/outsheetsoi.xlsx", sh("wagesplit`yr'") modify
	putexcel B3=("(upper)") using "$diroutput/outsheetsoi.xlsx", sh("wagesplit`yr'") modify
	putexcel A19=("Notes: this table displays the wage earnings split among married filers by total wage income fractiles for year `yr'") using "$diroutput/outsheetsoi.xlsx", sh("wagesplit`yr'") modify
	putexcel A20=("Statistics based on the SOI individual tax file linked to W2 individual data, married joint filers with positive wage income") using "$diroutput/outsheetsoi.xlsx", sh("wagesplit`yr'") modify
	putexcel A21=("Tax returns are ranked by percentiles of family wage income across rows") using "$diroutput/outsheetsoi.xlsx", sh("wagesplit`yr'") modify
	putexcel A22=("For each row, columns show fraction of families with share of female wage income in various bins (columns sum to 1 for each row)") using "$diroutput/outsheetsoi.xlsx", sh("wagesplit`yr'") modify
	putexcel A23=("For same sex couples, female wages are defined as the wages of the secondary filer regardless of gender") using "$diroutput/outsheetsoi.xlsx", sh("wagesplit`yr'") modify
	putexcel A24=("All statistics are based on cells that include at least 10 records") using "$diroutput/outsheetsoi.xlsx", sh("wagesplit`yr'") modify
	* review counts
	if $review==1 {
	insheet using "$dirmatrix/wagmat/wagspintN`yr'.xls", clear
	local name = "wagspintN`yr'"
	mkmat _all, mat(`name')
	putexcel L1=("Population weighted counts in each cell (review only)") using "$diroutput/outsheetsoi.xlsx", sh("wagesplit`yr'") modify
	putexcel L2=matrix(`name') using "$diroutput/outsheetsoi.xlsx", sh("wagesplit`yr'") modify	
	      } 
		  * end of review counts
	}
	


	
* 2b. self-employment earnings split 1979-2014 for married filers (based on seyprimirs and seysecirs in SOI files)
* matrices sespintYYYY.xls created by program sharefbuild.do
foreach yr of numlist 1979/2014 {
   * foreach yr of numlist 1985 {
	insheet using "$dirmatrix/wagmat/sespint`yr'.xls", clear
	foreach var of varlist * {
		replace `var'=round(10000*`var')/10000
	 }
	local name = "sespint`yr'"
	local xlsname="selfempsplit`yr'"
	mkmat _all, mat(`name')
	putexcel A1=("Share of female self-employment income among married tax filers with positive self-employment income, by family self-employment income percentiles, year `yr'") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
	putexcel A2=matrix(`name') using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
	putexcel C2=(0) using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
	putexcel A3=("se income percentile (lower)") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
	putexcel B2=("share female se income (lower)") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
	putexcel B3=("(upper)") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
	putexcel A19=("Notes: this table displays the self-employment earnings split among married filers by total self-employment income fractiles for year `yr'") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
	putexcel A20=("Statistics based on the SOI individual tax file, married joint filers with positive self-employment income") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
	putexcel A21=("Tax returns are ranked by percentiles of family self-employment income across rows") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
	putexcel A22=("For each row, columns show fraction of families with share of female self-employment income in various bins (columns sum to 1 for each row)") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
	putexcel A23=("For same sex couples, female self-employment are defined as the self-employment income of the secondary filer regardless of gender") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
	putexcel A24=("All statistics are based on cells that include at least 10 records") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
	* review counts
	if $review==1 {
	insheet using "$dirmatrix/wagmat/sespintN`yr'.xls", clear
	local name = "sespintN`yr'"
	mkmat _all, mat(`name')
	putexcel L1=("Population weighted counts in each cell  (review only)") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
	putexcel L2=matrix(`name') using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify	
		}
	* end of review counts
	}
		

		
	
* 3a. gender split for single filers 1979, create 3 tables agibin*shwag based on kidold
* dataset xcollgender1979 created by program sharefbuild.do

foreach num of numlist 0/2 { 
use $dirsmall/collapse/xcollgender1979.dta, clear
foreach var of varlist * {
		replace `var'=round(10000*`var')/10000
	 }
keep if kidold==`num'
keep agibin shwag female dweght
replace shwag=round(100*shwag)
sort agibin shwag
reshape wide female dweght, i(agibin) j(shwag)
gen agibin2=agibin[_n+1]
replace agibin2=1 if agibin2==.
gen gap=. 
order agibin agibin2 female* gap dweght*
if $review!=1 drop gap dweght*
mkmat _all, mat(gender1979_`num')
}
local row=1
putexcel A`row'=("Fraction female among single filers by AGI percentiles and share of wages in AGI") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify

if $review==1 putexcel I`row'=("Population weighted counts in each cell (review only)") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
local row=`row'+1
putexcel C`row'=("less than 1%") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
putexcel D`row'=("1% to 25%") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
putexcel E`row'=("25% to 50%") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
putexcel F`row'=("50% to 75%") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
putexcel B`row'=("Share of wages in AGI") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
putexcel G`row'=("over 75%") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
local row=`row'+1
putexcel A`row'=("AGI fractile (lower)") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
putexcel B`row'=("AGI fractile (upper)") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
local row=`row'+1
putexcel A`row'=("Age less than 65 and no children") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
local row=`row'+1
putexcel A`row'=matrix(gender1979_0) using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify

local row=`row'+10
putexcel A`row'=("Age less than 65 and with children") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
local row=`row'+1

putexcel A`row'=matrix(gender1979_1) using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
local row=`row'+10
putexcel A`row'=("Age 65 and above") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
local row=`row'+1
putexcel A`row'=matrix(gender1979_2) using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
local row=`row'+10
putexcel A`row'=("Notes: this table displays the fraction female by AGI percentiles and share of wage income in AGI among non-married joint filers for year 1979") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
local row=`row'+1
putexcel A`row'=("Statistics based on the SOI individual tax file, excluding married joint filers") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
local row=`row'+1
putexcel A`row'=("Tax returns are ranked by AGI percentiles across rows (fractiles defined for returns with AGI>0, category -1 is returns with negative or zero AGI)") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
local row=`row'+1
putexcel A`row'=("Tax returns are ranked by share of wage income in AGI across columns") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
local row=`row'+1
putexcel A`row'=("Top panel is for filers less than 65 year old and with no children dependents") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
local row=`row'+1
putexcel A`row'=("Middle panel is for filers less than 65 year old and with children dependents") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
local row=`row'+1
putexcel A`row'=("Bottom panel is for filers aged 65 or more") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify
local row=`row'+1
putexcel A`row'=("All cells include at least 10 records") using "$diroutput/outsheetsoi.xlsx", sh("gender1979") modify




global years "1979/2014"

*global years "1986"

* 3b. gender*agebin by agibin*shwag*kidold for single filers
* dataset xcollsinglecoarseYYYY created by program impute.do

foreach yr of numlist $years {
use $dirsmall/collapse/xcollsinglecoarse`yr'.dta, clear
foreach var of varlist * {
		replace `var'=round(10000*`var')/10000
	 }
keep if kidold==2
* renormalize aggregate cell to respect 65+ information (not needed in next run)
gen tot=age65f+age65m
replace age65f=age65f/tot if aggcell==2
replace age65m=age65m/tot if aggcell==2
rename age65f female
set seed 434351
gen randu=uniform()
replace randu=0
replace female=female-randu/50 if female>=1
replace female=female+randu/50 if female<=0
replace female=female+randu/100
keep agibin shwag female onew
rename agibin agibinold
gen double agibin=round(agibinold,.0001)
drop agibinold
replace shwag=round(100*shwag)
sort agibin shwag
reshape wide female onew, i(agibin) j(shwag)
gen double agibin2=agibin[_n+1]
replace agibin2=1 if agibin2==.
gen gap=.
order agibin agibin2 female* gap onew*
if $review!=1 drop onew*
mkmat _all, mat(aux2)
matrix list aux2


use $dirsmall/collapse/xcollsinglecoarse`yr'.dta, clear
foreach var of varlist * {
		replace `var'=round(10000*`var')/10000
	 }
keep if kidold!=2
set seed 434350
gen randu=uniform()
replace randu=0
* renormalize aggregate cell to respect 65+ information (not needed in next run)
gen tot=age0m+age0f+age45m+age45f
gen ind=0
foreach var of varlist  age0m age0f age45m age45f {
	replace `var'=`var'/tot if aggcell==2
	gen ind`var'=(`var'==0)	
	replace `var'=randu/50 if ind`var'==1	
	replace ind=ind+ind`var'
	}
foreach var of varlist  age0m age0f age45m age45f {
    replace `var'=`var'-(ind/4)*(randu/50)
	}
		
preserve

foreach ko of numlist 0/1 {
foreach var of varlist  age0m age0f age45m age45f {
  keep if kidold==`ko'
  keep agibin shwag `var' onew
  rename agibin agibinold
  gen double agibin=round(agibinold,.0001)
  drop agibinold
  replace shwag=round(100*shwag)
	sort agibin shwag
	reshape wide `var' onew, i(agibin) j(shwag)
    gen double agibin2=agibin[_n+1]
	replace agibin2=1 if agibin2==.
	gen gap=.
	order agibin agibin2 `var'* gap onew*
	if $review!=1 drop onew*
	mkmat _all, mat(aux`var'_`ko')
	restore
	preserve
	}
}

restore
local xlsname="single`yr'"	
if $review==1 putexcel J1=("Population weighted counts in each cell (review only)") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
local row=1
putexcel A`row'=("Age and gender for single filers by AGI percentiles and share of wages in AGI, year `yr'") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify	
local row=`row'+1	

local cc=0
foreach mat in aux2 auxage0m_0 auxage0f_0 auxage45m_0 auxage45f_0 auxage0m_1 auxage0f_1 auxage45m_1 auxage45f_1 {
local cc=`cc'+1
if `cc'==1 putexcel A`row'=("Fraction female among single filers aged 65+") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
if `cc'==2 putexcel A`row'=("Fraction male and aged less than 45 among single filers with no children dependents and aged less than 65") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
if `cc'==3 putexcel A`row'=("Fraction female and aged less than 45 among single filers with no children dependents and aged less than 65") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
if `cc'==4 putexcel A`row'=("Fraction male and aged over 45 among single filers with no children dependents and aged less than 65") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
if `cc'==5 putexcel A`row'=("Fraction female and aged less than 45 among single filers with no children dependents and aged less than 65") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
if `cc'==6 putexcel A`row'=("Fraction male and aged less than 45 among single filers with children dependents and aged less than 65") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
if `cc'==7 putexcel A`row'=("Fraction female and aged less than 45 among single filers with children dependents and aged less than 65") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
if `cc'==8 putexcel A`row'=("Fraction male and aged over 45 among single filers with children dependents and aged less than 65") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
if `cc'==9 putexcel A`row'=("Fraction female and aged less than 45 among single filers with children dependents and aged less than 65") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify

 
local row=`row'+1
putexcel B`row'=("Share of wages in AGI") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
putexcel C`row'=("less than 10%") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
putexcel D`row'=("10% to 25%") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
putexcel E`row'=("25% to 50%") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
putexcel F`row'=("50% to 75%") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
putexcel G`row'=("75% to 95%") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
putexcel H`row'=("over 95%") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
local row=`row'+1
putexcel A`row'=("AGI fractile (lower)") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
putexcel B`row'=("AGI fractile (upper)") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
local row=`row'+1
putexcel A`row'=matrix(`mat') using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
local row=`row'+12
}

local row=`row'+2
putexcel A`row'=("Notes: this table displays the age and gender composition by AGI percentiles and share of wage income in AGI among non-married joint filers for year `yr'") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
local row=`row'+1
putexcel A`row'=("Statistics based on the SOI individual tax file, non-married joint filers") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
local row=`row'+1
putexcel A`row'=("Tax returns are ranked by AGI percentiles across rows (fractiles defined for returns with AGI>0, category -1 is returns with negative or zero AGI)") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
local row=`row'+1
putexcel A`row'=("Tax returns are ranked by share of wage income in AGI across columns") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
local row=`row'+1
putexcel A`row'=("Top panel is for filers aged 65+. Next four panels are tax filers aged less than 65 and no children dependents. Next four panels are tax filers aged less than 65 and with children dependents.") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
local row=`row'+1
putexcel A`row'=("All statistics are based on cells of (AGI fractiles)*(share wages in AGI)*(indicator for age<65 no kids, age<65 with kids, age>=65) that include at least 10 records. Cells with less than 10 records are aggregated to coarser cells till they all have at 10 records.") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify




}
	
*/
/*

* 4. agebin*agesecbin by agibin*shwag*old*oldsec for married filers
* dataset xcollmarriedcoarseYYYY created by program impute.do


foreach yr of numlist $years {
use $dirsmall/collapse/xcollmarriedcoarse`yr'.dta, clear
foreach var of varlist * {
		replace `var'=round(10000*`var')/10000
	 }

keep if oldexm!=1 | oldexf!=1
gen kidold=0
replace kidold=1 if oldexm==1
replace kidold=2 if oldexf==1


set seed 434351
gen randu=uniform()
replace randu=0
gen ind=0 if kidold==0
* renormalize aggregate cell to respect 65+ information (not needed in next run)
gen tot=age_m0f0+age_m0f45+age_m45f0+age_m45f45
foreach var of varlist  age_m0f0 age_m0f45 age_m45f0 age_m45f45 {
	replace `var'=`var'/tot if aggcell==2
	gen ind`var'=(`var'==0)	if kidold==0
	replace `var'=randu/50 if ind`var'==1	
	replace ind=ind+ind`var'
	}
foreach var of varlist  age_m0f0 age_m0f45 age_m45f0 age_m45f45 {
    replace `var'=`var'-(ind/4)*(randu/50) if ind>=1 & kidold==0
	}

replace tot=age_m0f65+age_m45f65
replace age_m0f65=age_m0f65/tot if aggcell==2
replace age_m45f65=age_m45f65/tot if aggcell==2
replace age_m0f65=randu/100 if age_m0f65==0 & kidold==2
replace age_m45f65=age_m45f65-randu/100 if age_m45f65==1 & kidold==2


replace tot=age_m65f0+age_m65f45
replace age_m65f0=age_m65f0/tot if aggcell==2
replace age_m65f45=age_m65f45/tot if aggcell==2
replace age_m65f0=randu/100 if age_m65f0==0 & kidold==1
replace age_m65f45=age_m65f45-randu/100 if age_m65f45==1 & kidold==1
		
preserve

keep if kidold==1
keep agibin shwag age_m65f45 onew
rename agibin agibinold
  gen double agibin=round(agibinold,.0001)
  drop agibinold     
  replace shwag=round(100*shwag)
	sort agibin shwag
	reshape wide age_m65f45 onew, i(agibin) j(shwag)
    gen double agibin2=agibin[_n+1]
	replace agibin2=1 if agibin2==.
	gen gap=.
	order agibin agibin2 age_m65f45* gap onew*
	if $review!=1 drop onew*
	mkmat _all, mat(auxoldexm)
	matrix list auxoldexm
restore
preserve

keep if kidold==2
keep agibin shwag age_m45f65 onew
  rename agibin agibinold
  gen double agibin=round(agibinold,.0001)
  drop agibinold
  replace shwag=round(100*shwag)
	sort agibin shwag
	reshape wide age_m45f65 onew, i(agibin) j(shwag)
    gen double agibin2=agibin[_n+1]
	replace agibin2=1 if agibin2==.
	gen gap=.
	order agibin agibin2 age_m45f65* gap onew*
	if $review!=1 drop onew*
	mkmat _all, mat(auxoldexf)
	matrix list auxoldexf
	restore
	preserve

foreach var of varlist age_m0f0 age_m0f45 age_m45f0 age_m45f45 {
  keep if kidold==0
  keep agibin shwag `var' onew
  replace shwag=round(100*shwag)
  rename agibin agibinold
  gen double agibin=round(agibinold,.0001)
  drop agibinold
	sort agibin shwag
	reshape wide `var' onew, i(agibin) j(shwag)
    gen double agibin2=agibin[_n+1]
	replace agibin2=1 if agibin2==.
	gen gap=.
	order agibin agibin2 `var'* gap onew*
	if $review!=1 drop onew*
	mkmat _all, mat(aux`var')
	matrix list aux`var'
	restore
	preserve
	}


restore
local xlsname="married`yr'"	
local row=1
if $review==1 putexcel J1=("Population weighted counts in each cell (review only)") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
putexcel A`row'=("Age of married spouses by AGI percentiles and share of wages in AGI, year `yr'") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify	
local row=`row'+1	

local cc=0
foreach mat in auxoldexm auxoldexf auxage_m0f0  auxage_m45f45 auxage_m45f0 auxage_m0f45 {
local cc=`cc'+1
if `cc'==1 putexcel A`row'=("Fraction with wife aged 45-64 among married filers with husband aged 65+ and wife aged less than 65") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
if `cc'==2 putexcel A`row'=("Fraction with husband aged 45-64 among married filers with husband aged less than 65 and wife aged 65+") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
if `cc'==3 putexcel A`row'=("Fraction with wife aged less than 45 and husband aged less than 45 among married filers with both spouses aged less than 65") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
if `cc'==4 putexcel A`row'=("Fraction with wife aged 45-64 and husband aged 45-64 among married filers with both spouses aged less than 65") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
if `cc'==5 putexcel A`row'=("Fraction with wife aged less than 45 and husband aged 45-64 among married filers with both spouses aged less than 65") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
if `cc'==6 putexcel A`row'=("Fraction with wife aged 45-64 and husband aged less than 45 among married filers with both spouses aged less than 65") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify

local row=`row'+1
putexcel B`row'=("Share of wages in AGI") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
putexcel C`row'=("less than 10%") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
putexcel D`row'=("10% to 25%") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
putexcel E`row'=("25% to 50%") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
putexcel F`row'=("50% to 75%") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
putexcel G`row'=("75% to 95%") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
putexcel H`row'=("over 95%") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
local row=`row'+1
putexcel A`row'=("AGI fractile (lower)") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
putexcel B`row'=("AGI fractile (upper)") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
local row=`row'+1
putexcel A`row'=matrix(`mat') using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
local row=`row'+12
}

local row=`row'+2
putexcel A`row'=("Notes: this table displays the age of spouses composition by AGI percentiles and share of wage income in AGI among married joint filers for year `yr'") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
local row=`row'+1
putexcel A`row'=("Statistics based on the SOI individual tax file, married joint filers") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
local row=`row'+1
putexcel A`row'=("Tax returns are ranked by AGI percentiles across rows (fractiles defined for returns with AGI>0, category -1 is returns with negative or zero AGI)") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
local row=`row'+1
putexcel A`row'=("Tax returns are ranked by share of wage income in AGI across columns") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
local row=`row'+1
putexcel A`row'=("Top panel is for filers where husband is aged 65+ and wife is aged less than 65 and displays fraction with wife aged 45-64.") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
local row=`row'+1
putexcel A`row'=("Second panel is for filers where wife is aged 65+ and husband is aged less than 65 and displays fraction with husband aged 45-64.") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
local row=`row'+1
putexcel A`row'=("Next four panels is for filers where both spouses are aged less than 65.") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
local row=`row'+1
putexcel A`row'=("All statistics are based on cells of (AGI fractiles)*(share wages in AGI)*(dummy husband aged<65)*(dummy wife aged<65) that include at least 10 records. Cells with less than 10 records are aggregated to coarser cells till they all have at 10 records.") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify
local row=`row'+1
putexcel A`row'=("For same sex couples, husband is defined as primary filer and wife as secondary filer.") using "$diroutput/outsheetsoi.xlsx", sh("`xlsname'") modify


}



/* NON FILERS NOT IN FIRST DISCLOSED REVIEW TO SPEED UP PROCESS

* 5. basic nonfilers statistics, start from large tab nonfilerabout.dta is created by SAS program nonfiler_tab.sas 
* both files are in internalIRS/pufimprove/population/rawdata
* then collapse into coarser bins
* note nonfilerabout_v2.dta removes people dying during the tax year [which is the sample used for aggregate pop stats]
* revised 11/2016 to add tax withheld

* compute tax withheld from PUF 2010
use $dirirs/x2010.dta, clear
keep if wages>0 & wages<60000 & agi>=0 & abs(wages-agi)/abs(agi)<=.1 & mars!=2
global w2binl "1 2000 5000 10000 20000 30000 40000 50000"
matrix input perc = (1, 2000, 5000, 10000, 20000, 30000, 40000, 50000 \ 2000, 5000, 10000, 20000, 30000, 40000, 50000, 60000 \ 0, 0, 0, 0, 0, 0, 0, 0);

foreach num of numlist 1/8 {
	sum wages [w=dweght] if wages>=perc[1,`num'] & wages<perc[2,`num']
	local wag=r(mean) 
	sum withld [w=dweght] if wages>=perc[1,`num'] & wages<perc[2,`num']
	local tax=r(mean)
	matrix perc[3,`num']=`tax'/`wag'
	}
	
matrix list perc

   


cd $root
use ../internalIRS/pufimprove/population/rawdata/nonfilertabout_v2.dta, clear
rename *, lower
drop if age<20
gen age=20
replace age=45 if agebin>=45
replace age=65 if agebin>=65
rename x_freq_ count

* remove those who die (not longer needed in nonfilerabout_v2)
replace count=count*(1-dies)
global ssbinl "1 5000 10000 15000 20000"
global w2binl "1 2000 5000 10000 20000 30000 40000 50000"

gen ssbin=0
foreach num of numlist $ssbinl {
   replace ssbin=`num' if ssincbin>=`num'
   }
gen w2bin=0

foreach num of numlist $w2binl {
   replace w2bin=`num' if wagbin>=`num'
   }
rename ssinc_mean ssinc
rename wages_mean w2inc
rename attend_college_mean student
rename claimed_mean claimed
rename uidum uidum
rename uiinc uiinc
gen one=1

drop if wagbin==100000

sum w2inc [w=count]
display r(sum)

collapse (sum) one (mean) w2inc ssinc uidum uiinc student claimed [iw=count], by(tax_yr female age ssbin w2bin)
rename one count
replace count=round(count)
tab tax_yr w2bin [w=count]
table tax_yr w2bin [w=count], c(mean w2inc)

* cut the # of high wage nonfilers in 1999 and 2014 due to missing 1040s in databank (align 1999 to 2000 and assume 10% growth from 2013 to 2014)
gen one=1
foreach num of numlist 10000 20000 30000 40000 50000 {
 if `num'>=10000 {
 quietly sum one [w=count] if w2bin==`num' & tax_yr==1999
 local aux99=r(sum)
 quietly  sum one [w=count] if w2bin==`num' & tax_yr==2000
 local aux00=r(sum)
 replace count=(`aux00'/`aux99')*count if tax_yr==1999 & w2bin==`num'
 quietly sum one [w=count] if w2bin==`num' & tax_yr==2014
 local aux14=r(sum)
 quietly  sum one [w=count] if w2bin==`num' & tax_yr==2013
 local aux13=r(sum)
 replace count=1.1*(`aux13'/`aux14')*count if tax_yr==2014 & w2bin==`num'
    }
 }
 
replace count=round(count)
tab tax_yr w2bin [w=count]

gen wagdum=(w2bin>0) 
gen ssdum=(ssbin>0)

bys tax_yr: sum w2inc ssinc uiinc wagdum ssdum uidum student claimed [w=count] 
drop claimed one
drop wagdum ssdum

count if count<10
drop if count<10

* added 11/2016, add imputed tax withheld
set seed 452352
gen randu=.02*(uniform()-.5)
gen withldtax=0
local ii=0
foreach num of numlist $w2binl {
   local ii=`ii'+1
   local taxrate=perc[3,`ii']
   replace withldtax=max(0,w2inc*(`taxrate'+randu)) if w2bin==`num'
   }
drop randu   
foreach var of varlist withldtax w2inc ssinc uiinc {
replace `var'=round(`var')
	}

mkmat _all, mat(nfmat)
putexcel A1=matrix(nfmat, colnames) using "$diroutput/outsheetsoi.xlsx", sh("nonfilers1999-2014") modify


*/

 

