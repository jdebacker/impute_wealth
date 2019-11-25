/*
*******************************************************************************
* Juliana Londo–o VŽlez, RA for Emmanuel Saez, Fall 2015
* 						
*				Determining SNAP and SSI Eligibility and Benefits Received
*					
*******************************************************************************

Resources: 			http://www.fns.usda.gov/snap/eligibility
			http://www.fns.usda.gov/snap/cost-living-adjustment-cola-information
			http://www.cbpp.org/sites/default/files/atoms/files/3-23-10fa.pdf
https://www.census.gov/hhes/www/income/publications/Parker%20snap%20paper%201_2012.pdf
			http://www.fns.usda.gov/sites/default/files/Trends2002-09.pdf
				http://www.fns.usda.gov/sites/default/files/pd/SNAPsummary.pdf
http://www1.nyc.gov/assets/hra/downloads/pdf/facts/snap/USDASNAPParticipationFY2010.2011.pdf
		http://harris.uchicago.edu/sites/default/files/working-papers/wp_09_03.pdf
		http://www.ssa.gov/policy/docs/statcomps/ssi_asr/2013/sect01.html
		
Notes: 
1. SNAP receipt is report at the household-level. I treat tax units as households, except tax units where filer is dependent
2. SNAP eligibility requirements and benefits vary by fiscal year 
3. SNAP should be calculated monthly.
4. Use of fiscal -not calendar- year would suggest the need to use two IRS files (covering Oct-Dec; then Jan-Sept of following year). I use IRS t file for FY t (Oct 1, t-1 to Sept 30, t).
5. I assume SNAP thresholds for 48 states (includes DC, Guam, and the Virgin Islands), i.e. I ignore Alaska and Hawaii special thresholds
6. SNAP has existed since 1980

*/

****************************************************
* INPUTS PARAMETERS AND CONVERTS INTO MACRO
****************************************************



cd "$root/CPSMarchSupplement"

local years "2004 2005 2006 2007 2008"

local numyears=5
matrix results = J(`numyears',10,.)
local yy=0

foreach yr of numlist `years' { 
insheet using "$parametersposttax", clear names
keep if yr==`yr'
foreach var of varlist _all {
local `var'=`var'
}

use $dirsmall/small`yr'cps.dta, clear 
local ii=1

replace rentincp=max(0,rentinc) if files==0

egen snapinc=rsum(waginc peninc divinc intinc seinc ssinc uiinc intexm rentincp rylinc alminc)
replace snapinc=max(0, snapinc) // snapinc can be negative if ryling is negative
egen earned=rsum(waginc seinc)
gen asset=(intinc*`fintinctax')+divinc*(`fdivinc')

/*
STEP 1: Counting number tax unit members: filer, spouse (if married), and dependents. 
*/

gen tu=_n
gen famnum = 1*(single==1 | head==1 | marriedsep==1)+2*(married==1)+xded 

* Special Rules for Elderly or Disabled: 

gen eldernum=(oldexm==1)+(oldexf==1) // SNAP's age threshold is 60, but I only have 65+ coded for primary filer or spouse (i.e. not grandpa/ma) in IRS data
gen haselder=(eldernum>0)
replace hasdisable=(ssinc>0 & haselder==0) if files==1 // For IRS data: I assume non-senior tax units receiving ssinc are disabled 

if `yr'==2004 replace hasdisable=1 if earned<=400 & files==1 // For IRS data: I assume non-senior tax units with low positive wages are disabled 
if `yr'==2005 replace hasdisable=1 if earned<=400 & files==1 // For IRS data: I assume non-senior tax units with low positive wages are disabled 
if `yr'==2006 replace hasdisable=1 if earned==0 & files==1 // For IRS data: I assume non-senior tax units with low positive wages are disabled 
if `yr'==2007 replace hasdisable=1 if earned<=400 & files==1 // For IRS data: I assume non-senior tax units with low positive wages are disabled 
*if `yr'==2008 replace hasdisable=1 if earned==0 & files==1 // For IRS data: I assume non-senior tax units with low positive wages are disabled 

replace haselder=0 if hasdisable==1 // so that haselder and hasdisable are mutually exclusive

* Note that disability payments are reported as waginc for those below the minimum retirement age 
* Determine SSI eligibility

gen ssi_pop=((haselder==1 | hasdisable==1) & dependent==0) 
gen ssi_inc=(snapinc/12)-20-65*((earned/12)>0)-0.5*(earned/12)*((earned/12)>65) 
gen ssi_assettest=(asset<`ssiress')*(single==1 | head==1 | marriedsep==1)+(asset<`ssiresc')*(married==1)
gen ssi_inctest=(ssi_inc<`ssicuts')*(single==1 | head==1 | marriedsep==1)+(ssi_inc<`ssicutc')*(married==1)
gen ssi_eligible=(ssi_pop==1 & ssi_assettest==1 & ssi_inctest==1)
replace ssi_eligible=1 if (ssiinc>0 & files==0)

gen ssi_ben=(ssi_eligible)*(max(0,(`ssicuts'-ssi_inc)*(single==1 | head==1 | marriedsep==1)+(`ssicutc'-ssi_inc)*(married==1)))
replace ssi_ben=(12*ssi_ben) // to get annual payments

* STEP 2: Determining Eligibility

* 1) Resources: Since there is no information about assets in IRS, I capitalize interest and dividend income. Therefore I ignore vehicle market value limit.

gen snap_assettest=(asset<`snapassn')*(haselder==0)+(asset<`snapasse')*(haselder==1)

/*
2) Monthly Deductions

Notes:
1. I allow 20% earned income deduction, standard deduction that varies with family size, and dependent care deduction for children (capped before 2008 Farm Bill)
2. I ignore deductions for medical expenses for elderly or disabled members, child support payments, and shelter costs.
3. Note year CPS t is SNAP deduction amount in year t-1
*/

gen deductions=(0.2*(earned/12))+(famnum<4)*`snapded3'+(famnum==4)*`snapded4'+(famnum==5)*`snapded5'+(famnum>=6)*`snapded6'+xkids*`snapdedkid'

gen snapinc_month=snapinc/12 // strong assumption?
gen snapinc_net_month=snapinc_month-deductions


* 3) Gross and Net Income:
  
gen hpovcut=`povcut1'*(famnum==1)+`povcut2'*(famnum==2)+`povcut3'*(famnum==3)+`povcut4'*(famnum==4)+`povcut5'*(famnum==5)+`povcut6'*(famnum==6)+`povcut7'*(famnum==7)+`povcut8'*(famnum==8) 

forvalues i=1(1)20{
replace hpovcut=`povcut8'+`i'*`povcutadd' if famnum==8+`i' 
}

gen snap_inctest_gro=(snapinc_month<(1.3*hpovcut)) // Note that states are allowed to increase the gross income eligbility threshold to up to 200% of poverty threshold. In practice, some do.

gen snap_inctest_net=(snapinc_net_month<hpovcut)

* 4) Employment Requirements // Ignored for the moment

* 5) Creating SNAP Eligibility Indicator

gen snap_eligible=0
replace snap_eligible=1 if snap_inctest_gro==1 & snap_inctest_net==1 & snap_assettest==1 // "Households must meet both the gross and net income tests"
replace snap_eligible=1 if snap_inctest_net==1 & snap_assettest==1 & (haselder==1 | hasdisable==1) // "A household with an elderly person or a person who is receiving certain types of disability payments only has to meet the net income test"
replace snap_eligible=0 if dependent==1
*replace snap_eligible=1 if hasexception==1 // "Households have to meet income tests unless all members are receiving TANF, SSI, or in some places general assistance. " //  We cannot know this using IRS data

/*
STEP 3: SNAP Benefit Computation (Monthly)

Note: Year IRS t is SNAP amount t
*/
gen snap_benm=`snapben1'*(famnum==1)+`snapben2'*(famnum==2)+`snapben3'*(famnum==3)+`snapben4'*(famnum==4)+`snapben5'*(famnum==5)+`snapben6'*(famnum==6)+`snapben7'*(famnum==7)+`snapben8'*(famnum==8)

forvalues i=1(1)20{
replace snap_benm=`snapben8'+`i'*`snapbenadd' if famnum==8+`i' 
}

gen snap_ben=(snap_benm-ceil(snapinc_net_month*0.3))*(snap_eligible)

gen snap_minben=`snapbenmin'*(famnum<3) 
replace snap_ben=max(snap_minben, snap_ben) if snap_eligible==1 // some eligible households (famnum<3) have a minimum SNAP benefit
replace snap_eligible=0 if snap_ben<=0 // done in other papers; barely affects estimates

set seed 12345
gen rannum =uniform() if snap_eligible==1 
sort rannum
egen aux=total(dweght) if snap_eligible==1 
gen aux2=sum(dweght) if snap_eligible==1 
format aux %20.0f
format aux2 %20.0f
replace snap_eligible=0 if (aux2>`snapparticip'*aux)  // randomly allocates overall participation rate 
replace snap_eligible=0 if (aux2>.35*aux) & haselder==1 // randomly allocates 35% participation rate for seniors
replace snap_eligible=0 if (aux2>.55*aux) & xkids==0 // randomly allocates 55% participation rate for tax units without kids
replace snap_eligible=0 if (aux2>.55*aux) & married==1 & xkids>0 // randomly allocates 55% participation rate for married tax units with kids
replace snap_eligible=0 if (aux2>.35*aux) & (snapinc_month>hpovcut) // randomly allocates 35% participation rate for tax units about poverty line
replace snap_eligible=0 if (aux2>.30*aux) & (snap_ben<=(0.25*snap_benm)) // randomly allocates 30% participation rate for tax units receiving less than 25% max benefit
replace snap_eligible=0 if (aux2>.55*aux) & ((0.25*snap_benm)<snap_ben<=(0.5*snap_benm)) // randomly allocates 55% participation rate for tax units receiving between 25% and 50% max benefit
replace snap_eligible=0 if (aux2>.65*aux) & (earned>0) // randomly allocates 65% participation rate for tax units with earnings
replace snap_eligible=0 if (aux2>.55*aux) & (ssinc>0) // randomly allocates 55% participation rate for tax units with social security income

replace snap_eligible=0 if snap_ben<170 // assumes households with less than $100 monthly benefits don't bother participating

replace snap_ben=0 if snap_eligible==0 // updates benefits amount

matrix results[`numyears'*(`ii'-1)+`yy'+1,1]=`yr'
sum famnum [w= dweght] if snap_eligible==1 
matrix results[`numyears'*(`ii'-1)+`yy'+1,2]=1e-8*r(sum)
sum tu [w= dweght] if snap_eligible==1 
matrix results[`numyears'*(`ii'-1)+`yy'+1,3]=1e-8*r(sum_w)
sum snap_ben [w= dweght] 
matrix results[`numyears'*(`ii'-1)+`yy'+1,4]=1e-8*r(sum)
sum famnum [w= dweght] if ssi_eligible==1 
matrix results[`numyears'*(`ii'-1)+`yy'+1,5]=1e-8*r(sum)
sum ssi_ben [w=dweght]
matrix results[`numyears'*(`ii'-1)+`yy'+1,6]=1e-8*r(sum)
sum famnum [w= dweght] if ssi_eligible==1 & haselder==1
matrix results[`numyears'*(`ii'-1)+`yy'+1,7]=1e-8*r(sum)
sum ssi_ben [w=dweght] if haselder==1
matrix results[`numyears'*(`ii'-1)+`yy'+1,8]=1e-8*r(sum)
sum famnum [w= dweght] if ssi_eligible==1 & hasdisable==1
matrix results[`numyears'*(`ii'-1)+`yy'+1,9]=1e-8*r(sum)
sum ssi_ben [w=dweght] if hasdisable==1
matrix results[`numyears'*(`ii'-1)+`yy'+1,10]=1e-8*r(sum)

local ii=`ii'+1
local yy=`yy'+1
}
matrix list results
svmat results

keep results*
rename results1 year
rename results2 snap_ep
rename results3 snap_e
rename results4 snap_b
rename results5 ssi_e_all
rename results6 ssi_b_all
rename results7 ssi_e_senior
rename results8 ssi_b_senior
rename results9 ssi_e_disable
rename results10 ssi_b_disable

format snap_ep %12.0f
format snap_e %12.0f
format snap_b %20.0f
format ssi_e_all %12.0f
format ssi_b_all %20.0f
format ssi_e_senior %12.0f
format ssi_b_senior %20.0f
format ssi_e_disable %12.0f
format ssi_b_disable %20.0f


outsheet using "$root/output/temp/cps/snapssi_irs.xls", replace
