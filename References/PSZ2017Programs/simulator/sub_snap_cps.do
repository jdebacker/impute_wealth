/*
*******************************************************************************
* Juliana Londono Velez, RA for Emmanuel Saez, Fall 2015
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

Notes:
1. SNAP receipt is report at the household-level on the CPS ASEC.
2. SNAP eligibility requirements and benefits vary by fiscal year (I am still waiting for pre-2005 data)
3. SNAP should be calculated monthly.
4. Use of fiscal -not calendar- year would suggest the need to use two CPS ASEC files (covering Oct-Dec; then Jan-Sept of following year). I have not done this yet...
5. I assume SNAP thresholds for 48 states (includes DC, Guam, and the Virgin Islands), i.e. I ignore Alaska and Hawaii special thresholds
6. SNAP has existed since 1980
*/

/*
STEP 1: Counting number of children and household members
*/


sort h_seq
gen one=1

gen kid_pov=(a_age<18)
by h_seq: egen numkid = sum(kid_pov)

gen baby_pov=(a_age<2)
by h_seq: egen numbaby = sum(baby_pov)

by h_seq: egen famnum = sum(one)


* STEP 2: Determining Eligibility

* 1) Resources: There is no information about assets in CPS ASEC. Others have imputed using simulations from SIPP

gen asset=.
replace asset=(hintval*43.8135)+hdivval*(32.3193) if year==2009
replace asset=(hintval*34.2339)+hdivval*(37.2777) if year==2008
replace asset=(hintval*37.2034)+hdivval*(40.3104) if year==2007
replace asset=(hintval*46.8369)+hdivval*(41.5262) if year==2006
replace asset=(hintval*51.414)+hdivval*(43.6434) if year==2005

* 2) Special Rules for Elderly or Disabled

gen elder_aux=(a_age>=60)
by h_seq: egen eldernum=sum(elder_aux)

gen disable_temp=(ssi_val>0 | dis_val1>0 | dis_val2>0)
gen disable_aux=.
cap replace disable_aux=(disable_temp==1 | prdisflg==1 | dis_yn==1 | dsab_val>0 | dis_hp==1) if year==2009
replace disable_aux=(disable_temp==1 | dis_yn==1 | dsab_val>0 | dis_hp==1) if year!=2009
by h_seq: egen disablenum=sum(disable_aux)

gen exception_aux=(ssi_val>0 | paw_typ==1) // this is not ideal because SSI and TANF are mis/under-reported in CPS ASEC. Others have simulated and calibrated it to fit SSA totals
by h_seq: egen exception_temp=sum(exception_aux)
gen hasexception=(exception_temp==famnum)

gen haselder=(eldernum>0)
gen hasdisable=(disablenum>0)
replace haselder=0 if hasdisable==1 // so that haselder and hasdisable are mutually exclusive

* DETERMINE SSI ELIGIBILITY
gen snapinc=htotval

gen married_temp=(a_spouse!=0)
by h_seq: egen hmarried_aux=sum(married_temp)
gen hmarried=(hmarried_aux>0)

gen ssi_pop=(haselder==1 | hasdisable==1)
gen ssi_inc=(snapinc/12)-20-65*(hearnval/12>0)-0.5*(hearnval/12)*((hearnval/12)>65)
gen ssi_assettest=(asset<2000)*(hmarried==0)+(asset<3000)*(hmarried==1)

gen ssicuts=.
replace ssicuts=637 if year==2009
replace ssicuts=623 if year==2008
replace ssicuts=603 if year==2007
replace ssicuts=579 if year==2006
replace ssicuts=564 if year==2005

gen ssicutc=.
replace ssicutc=956 if year==2009
replace ssicutc=934 if year==2008
replace ssicutc=904 if year==2007
replace ssicutc=869 if year==2006
replace ssicutc=846 if year==2005

gen ssi_inctest=(ssi_inc<ssicuts)*(hmarried==0)+(ssi_inc<ssicutc)*(hmarried==1)

gen ssi_eligible=(ssi_pop==1 & ssi_assettest==1 & ssi_inctest==1)

gen ssi_ben=ssi_eligible*(max(0,(ssicuts-ssi_inc)*(hmarried==0)+(ssicutc-ssi_inc)*(hmarried==1)))
replace ssi_ben=(12*ssi_ben) // to get annual values


/*
3) Monthly Deductions

Notes:
1. I allow 20% earned income deduction, standard deduction that varies with family size, and dependent care deduction for children (capped before 2008 Farm Bill)
2. I ignore deductions for medical expenses for elderly or disabled members, child support payments, and shelter costs.
3. Note year CPS t is SNAP deduction amount in year t-1
*/


gen deductions=.
replace deductions=(0.2*hearnval/12)+(famnum<4)*134+(famnum==4)*143+(famnum==5)*167+(famnum>=6)*191+175*(numkid)+200*(numbaby) if year==2009
replace deductions=(0.2*hearnval/12)+(famnum<4)*134+(famnum==4)*139+(famnum==5)*162+(famnum>=6)*186+175*(numkid)+200*(numbaby) if year==2008
replace deductions=(0.2*hearnval/12)+(famnum<4)*134+(famnum==4)*134+(famnum==5)*157+(famnum>=6)*179+175*(numkid)+200*(numbaby) if year==2007
replace deductions=(0.2*hearnval/12)+(famnum<4)*134+(famnum==4)*134+(famnum==5)*153+(famnum>=6)*175+175*(numkid)+200*(numbaby) if year==2006
replace deductions=(0.2*hearnval/12)+(famnum<4)*134+(famnum==4)*134+(famnum==5)*149+(famnum>=6)*171+175*(numkid)+200*(numbaby) if year==2005 // must confirm pre-2005

gen htotval_month=htotval/12
gen htotval_net_month=htotval_month-deductions
replace htotval_net_month=. if htotval==-9999

* 4) Gross and Net Income:

gen hpovcut=.
replace hpovcut=851*(famnum==1)+1141*(famnum==2)+1431*(famnum==3)+1721*(famnum==4)+2011*(famnum==5)+2301*(famnum==6)+2591*(famnum==7)+2881*(famnum==8) if year==2009
replace hpovcut=817*(famnum==1)+1100*(famnum==2)+1384*(famnum==3)+1667*(famnum==4)+1950*(famnum==5)+2234*(famnum==6)+2517*(famnum==7)+2800*(famnum==8) if year==2008
replace hpovcut=798*(famnum==1)+1070*(famnum==2)+1341*(famnum==3)+1613*(famnum==4)+1885*(famnum==5)+2156*(famnum==6)+2428*(famnum==7)+2700*(famnum==8) if year==2007
replace hpovcut=776*(famnum==1)+1041*(famnum==2)+1306*(famnum==3)+1571*(famnum==4)+1836*(famnum==5)+2101*(famnum==6)+2366*(famnum==7)+2631*(famnum==8) if year==2006
replace hpovcut=749*(famnum==1)+1010*(famnum==2)+1272*(famnum==3)+1534*(famnum==4)+1795*(famnum==5)+2057*(famnum==6)+2319*(famnum==7)+2580*(famnum==8) if year==2005


forvalues i=1(1)20{
replace hpovcut=2881+`i'*290 if famnum==8+`i' & year==2009
replace hpovcut=2800+`i'*284 if famnum==8+`i' & year==2008
replace hpovcut=2700+`i'*272 if famnum==8+`i' & year==2007
replace hpovcut=2631+`i'*265 if famnum==8+`i' & year==2006
replace hpovcut=2580+`i'*262 if famnum==8+`i' & year==2005
}

gen snap_inctest_gro=(htotval_month<1.3*hpovcut) // Note that states are allowed to increase the gross income eligbility threshold to up to 200% of poverty threshold. In practice, some do

gen snap_inctest_net=(htotval_net_month<hpovcut)

* 5) Employment Requirements // Ignored for the moment

* 6) Creating SNAP Eligibility Indicator
gen snap_assettest=(asset<2000)*(haselder==0)+(asset<3000)*(haselder==1)

gen snap_eligible=0
replace snap_eligible=1 if snap_inctest_gro==1 & snap_inctest_net==1 & snap_assettest==1 // "Households must meet both the gross and net income tests"
replace snap_eligible=1 if snap_inctest_net==1 & snap_assettest==1 & (haselder==1 | hasdisable==1) // "A household with an elderly person or a person who is receiving certain types of disability payments only has to meet the net income test"
replace snap_eligible=1 if hasexception==1 // "Households have to meet income tests unless all members are receiving TANF, SSI, or in some places general assistance. "

/*
STEP 3: SNAP Benefit Computation

Note: Year CPS t is SNAP amount t-1
*/
gen snap_benm=.
replace snap_benm=162*(famnum==1)+298*(famnum==2)+426*(famnum==3)+542*(famnum==4)+643*(famnum==5)+772*(famnum==6)+853*(famnum==7)+975*(famnum==8) if year==2009
replace snap_benm=155*(famnum==1)+284*(famnum==2)+408*(famnum==3)+518*(famnum==4)+615*(famnum==5)+738*(famnum==6)+816*(famnum==7)+932*(famnum==8) if year==2008
replace snap_benm=152*(famnum==1)+278*(famnum==2)+399*(famnum==3)+506*(famnum==4)+601*(famnum==5)+722*(famnum==6)+798*(famnum==7)+912*(famnum==8) if year==2007
replace snap_benm=149*(famnum==1)+274*(famnum==2)+393*(famnum==3)+499*(famnum==4)+592*(famnum==5)+711*(famnum==6)+786*(famnum==7)+898*(famnum==8) if year==2006
replace snap_benm=141*(famnum==1)+259*(famnum==2)+371*(famnum==3)+471*(famnum==4)+560*(famnum==5)+672*(famnum==6)+743*(famnum==7)+849*(famnum==8) if year==2005

forvalues i=1(1)20{
replace snap_benm=975+`i'*122 if famnum==8+`i' & year==2009
replace snap_benm=932+`i'*117 if famnum==8+`i' & year==2008
replace snap_benm=912+`i'*114 if famnum==8+`i' & year==2007
replace snap_benm=898+`i'*112 if famnum==8+`i' & year==2006
replace snap_benm=849+`i'*106 if famnum==8+`i' & year==2005
}

gen snap_ben=(snap_benm-ceil(htotval_net_month*0.3))*(snap_eligible)

gen snap_minben=.
replace snap_minben=10*(famnum<3) if year>=2005 & year<2009
replace snap_minben=14*(famnum<3) if year==2009

replace snap_ben=snap_minben if snap_ben<=0
replace snap_eligible=0 if snap_ben<=0

gen wgt=hsup_wgt/famnum

preserve

matrix results = J(1,19,.)

matrix results[1,1]=`1'

qui: sum h_seq [w= hsup_wgt] if hfoodsp==1
matrix results[1,2]=1e-3*r(sum_w)
qui: sum h_seq [w= wgt] if hfoodsp==1
matrix results[1,3]=1e-3*r(sum_w)
qui: sum f_mv_fs [w= wgt]
matrix results[1,4]=1e-3*r(sum)

qui: sum h_seq [w= hsup_wgt] if snap_eligible==1
matrix results[1,5]=1e-3*r(sum_w)
qui: sum h_seq [w= wgt] if snap_eligible==1
matrix results[1,6]=1e-3*r(sum_w)
qui: sum snap_ben [w= wgt]
matrix results[1,7]=1e-3*r(sum)

qui: sum h_seq [w= hsup_wgt] if ssi_eligible==1
matrix results[1,8]=1e-3*r(sum_w)
qui: sum ssi_ben [w= hsup_wgt]
matrix results[1,9]=1e-3*r(sum)

qui: sum h_seq [w= hsup_wgt] if ssi_eligible==1 & filingst==6
matrix results[1,10]=1e-3*r(sum_w)
qui: sum ssi_ben [w= hsup_wgt] if filingst==6
matrix results[1,11]=1e-3*r(sum)

qui: sum h_seq [w= hsup_wgt] if ssi_eligible==1 & haselder==1
matrix results[1,12]=1e-3*r(sum_w)
qui: sum ssi_ben [w= hsup_wgt] if haselder==1
matrix results[1,13]=1e-3*r(sum)

qui: sum h_seq [w= hsup_wgt] if ssi_eligible==1 & haselder==1 & filingst==6
matrix results[1,14]=1e-3*r(sum_w)
qui: sum ssi_ben [w= hsup_wgt] if haselder==1 & filingst==6
matrix results[1,15]=1e-3*r(sum)

qui: sum h_seq [w= hsup_wgt] if ssi_eligible==1 & hasdisable==1
matrix results[1,16]=1e-3*r(sum_w)
qui: sum ssi_ben [w= hsup_wgt] if hasdisable==1
matrix results[1,17]=1e-3*r(sum)

qui: sum h_seq [w= hsup_wgt] if ssi_eligible==1 & hasdisable==1 & filingst==6
matrix results[1,18]=1e-3*r(sum_w)
qui: sum ssi_ben [w= hsup_wgt] if hasdisable==1 & filingst==6
matrix results[1,19]=1e-3*r(sum)

matrix list results
svmat results

keep results*
rename results1 year
rename results2 snapoff_e_ind
rename results3 snapoff_e_hh
rename results4 snapoff_b
rename results5 snap_e_ind
rename results6 snap_e_hh
rename results7 snap_b
rename results8 ssi_e
rename results9 ssi_b
rename results10 ssi_e_nf
rename results11 ssi_b_nf
rename results12 ssi_e_s
rename results13 ssi_b_s
rename results14 ssi_e_snf
rename results15 ssi_b_snf
rename results16 ssi_e_d
rename results17 ssi_b_d
rename results18 ssi_e_dnf
rename results19 ssi_b_dnf

format snapoff_b %12.0f
format snap_b %12.0f
format ssi_b %12.0f
format ssi_b_nf %12.0f
format ssi_b_s %12.0f
format ssi_b_snf %12.0f
format ssi_b_d %12.0f
format ssi_b_dnf %12.0f

outsheet using "$root/output/temp/cps/snapssi_`1'.xls", replace
restore
