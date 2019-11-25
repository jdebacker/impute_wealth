* This do file produces the CPS and IRS small files summary stats by tax filer status, marital status, age, etc., used in TaxFilerStatus Excel file
* Code written by Juliana Londoño Vélez
* Updated March 2016 to integrate into DINA architecture 

foreach yr of numlist 1960/2014 {
	insheet using "$parameters", clear names
	keep if yr==`yr'
	keep tottaxunits
	rename tottaxunits tottaxunits`yr'
		local tottaxunits`yr'= tottaxunits`yr'
		di "NUMBER OF TAX UNITS IN YEAR `yr' = `tottaxunits`yr''"
}

******************************************
* Totals in CPS raw files (variables not harmonized)
******************************************

* Need to harmonize variable names before 2001 using code in use_cps.do
* resnss1 not available before 2001

local years = "2001/2015"
local numyears = 15
matrix results = J(`numyears',60,.)	
local yy=0

foreach year of numlist `years' {
local ii=1

use "$dircps/cpsmar`year'.dta", clear
cap gen resnss1=0

matrix results[`numyears'*(`ii'-1)+`yy'+1,1]=`year'
quietly: sum ws_val [w = marsupwt]
matrix results[`numyears'*(`ii'-1)+`yy'+1,2] = 1e-6*r(sum)
quietly: sum ern_val [w = marsupwt] if ern_srce==1
matrix results[`numyears'*(`ii'-1)+`yy'+1,3] = 1e-6*r(sum)
quietly: sum ern_val [w = marsupwt] if ern_srce==2
matrix results[`numyears'*(`ii'-1)+`yy'+1,4] = 1e-6*r(sum)
quietly: sum se_val [w = marsupwt] 
matrix results[`numyears'*(`ii'-1)+`yy'+1,5] = 1e-6*r(sum)
quietly: sum ern_val [w = marsupwt] if ern_srce==3
matrix results[`numyears'*(`ii'-1)+`yy'+1,6] = 1e-6*r(sum)
quietly: sum frm_val [w = marsupwt] 
matrix results[`numyears'*(`ii'-1)+`yy'+1,7] = 1e-6*r(sum)
quietly: sum int_val [w = marsupwt] 
matrix results[`numyears'*(`ii'-1)+`yy'+1,8] = 1e-6*r(sum)
quietly: sum div_val [w = marsupwt]
matrix results[`numyears'*(`ii'-1)+`yy'+1,9] = 1e-6*r(sum)
quietly: sum rnt_val [w = marsupwt]
matrix results[`numyears'*(`ii'-1)+`yy'+1,10] = 1e-6*r(sum)

quietly: sum sur_val1 [w = marsupwt] if sur_sc1==8  
matrix results[`numyears'*(`ii'-1)+`yy'+1,11] = 1e-6*r(sum)
quietly: sum sur_val2 [w = marsupwt] if sur_sc2==8  
matrix results[`numyears'*(`ii'-1)+`yy'+1,12] = 1e-6*r(sum)
quietly: sum ss_val [w = marsupwt] 
matrix results[`numyears'*(`ii'-1)+`yy'+1,13] = 1e-6*r(sum)
quietly: sum ss_val [w = marsupwt] if resnss1==5 
matrix results[`numyears'*(`ii'-1)+`yy'+1,14] = 1e-6*r(sum)

quietly: sum sur_val1 [w = marsupwt] if sur_sc1==5 
matrix results[`numyears'*(`ii'-1)+`yy'+1,15] = 1e-6*r(sum)
quietly: sum sur_val2 [w = marsupwt] if sur_sc2==5 
matrix results[`numyears'*(`ii'-1)+`yy'+1,16] = 1e-6*r(sum)
quietly: sum dis_val1 [w = marsupwt] if dis_sc1==6 
matrix results[`numyears'*(`ii'-1)+`yy'+1,17] = 1e-6*r(sum)
quietly: sum dis_val2 [w = marsupwt] if dis_sc2==6 
matrix results[`numyears'*(`ii'-1)+`yy'+1,18] = 1e-6*r(sum)
quietly: sum ret_val1 [w = marsupwt] if ret_sc1==5
matrix results[`numyears'*(`ii'-1)+`yy'+1,19] = 1e-6*r(sum)
quietly: sum ret_val2 [w = marsupwt] if ret_sc2==5
matrix results[`numyears'*(`ii'-1)+`yy'+1,20] = 1e-6*r(sum)

quietly: sum ssi_val [w = marsupwt] 
matrix results[`numyears'*(`ii'-1)+`yy'+1,21] = 1e-6*r(sum)
quietly: sum paw_val [w = marsupwt] 
matrix results[`numyears'*(`ii'-1)+`yy'+1,22] = 1e-6*r(sum)
quietly: sum uc_val [w = marsupwt] 
matrix results[`numyears'*(`ii'-1)+`yy'+1,23] = 1e-6*r(sum)

quietly: sum wc_val [w = marsupwt] 
matrix results[`numyears'*(`ii'-1)+`yy'+1,24] = 1e-6*r(sum)
quietly: sum dis_val1 [w = marsupwt] if dis_sc1==1 | dis_sc1==8
matrix results[`numyears'*(`ii'-1)+`yy'+1,25] = 1e-6*r(sum)
quietly: sum dis_val2 [w = marsupwt] if dis_sc2==1 | dis_sc2==8
matrix results[`numyears'*(`ii'-1)+`yy'+1,26] = 1e-6*r(sum)
quietly: sum sur_val1 [w = marsupwt] if sur_sc1==6 | sur_sc1==7
matrix results[`numyears'*(`ii'-1)+`yy'+1,27] = 1e-6*r(sum)
quietly: sum sur_val2 [w = marsupwt] if sur_sc2==6 | sur_sc2==7
matrix results[`numyears'*(`ii'-1)+`yy'+1,28] = 1e-6*r(sum)

quietly: sum vet_val [w = marsupwt] 
matrix results[`numyears'*(`ii'-1)+`yy'+1,29] = 1e-6*r(sum)
quietly: sum sur_val1 [w = marsupwt] if sur_sc1==1 | sur_sc1==10
matrix results[`numyears'*(`ii'-1)+`yy'+1,30] = 1e-6*r(sum)
quietly: sum sur_val2 [w = marsupwt] if sur_sc2==1 | sur_sc2==10
matrix results[`numyears'*(`ii'-1)+`yy'+1,31] = 1e-6*r(sum)
quietly: sum ret_val1 [w = marsupwt] if ret_sc1==1 | ret_sc1==7 | ret_sc1==8
matrix results[`numyears'*(`ii'-1)+`yy'+1,32] = 1e-6*r(sum)
quietly: sum ret_val2 [w = marsupwt] if ret_sc2==1 | ret_sc2==7 | ret_sc2==8
matrix results[`numyears'*(`ii'-1)+`yy'+1,33] = 1e-6*r(sum)
quietly: sum dis_val1 [w = marsupwt] if dis_sc1==2 | dis_sc1==10
matrix results[`numyears'*(`ii'-1)+`yy'+1,34] = 1e-6*r(sum)
quietly: sum dis_val2 [w = marsupwt] if dis_sc2==2 | dis_sc2==10
matrix results[`numyears'*(`ii'-1)+`yy'+1,35] = 1e-6*r(sum)

quietly: sum ret_val1 [w = marsupwt] if ret_sc1==2 
matrix results[`numyears'*(`ii'-1)+`yy'+1,36] = 1e-6*r(sum)
quietly: sum ret_val2 [w = marsupwt] if ret_sc2==2 
matrix results[`numyears'*(`ii'-1)+`yy'+1,37] = 1e-6*r(sum)
quietly: sum dis_val1 [w = marsupwt] if dis_sc1==3
matrix results[`numyears'*(`ii'-1)+`yy'+1,38] = 1e-6*r(sum)
quietly: sum dis_val2 [w = marsupwt] if dis_sc2==3
matrix results[`numyears'*(`ii'-1)+`yy'+1,39] = 1e-6*r(sum)
quietly: sum sur_val1 [w = marsupwt] if sur_sc1==2
matrix results[`numyears'*(`ii'-1)+`yy'+1,40] = 1e-6*r(sum)
quietly: sum sur_val2 [w = marsupwt] if sur_sc2==2
matrix results[`numyears'*(`ii'-1)+`yy'+1,41] = 1e-6*r(sum)

quietly: sum ret_val1 [w = marsupwt] if ret_sc1==3
matrix results[`numyears'*(`ii'-1)+`yy'+1,42] = 1e-6*r(sum)
quietly: sum ret_val2 [w = marsupwt] if ret_sc2==3
matrix results[`numyears'*(`ii'-1)+`yy'+1,43] = 1e-6*r(sum)
quietly: sum dis_val1 [w = marsupwt] if dis_sc1==4
matrix results[`numyears'*(`ii'-1)+`yy'+1,44] = 1e-6*r(sum)
quietly: sum dis_val2 [w = marsupwt] if dis_sc2==4
matrix results[`numyears'*(`ii'-1)+`yy'+1,45] = 1e-6*r(sum)
quietly: sum sur_val1 [w = marsupwt] if sur_sc1==3
matrix results[`numyears'*(`ii'-1)+`yy'+1,46] = 1e-6*r(sum)
quietly: sum sur_val2 [w = marsupwt] if sur_sc2==3
matrix results[`numyears'*(`ii'-1)+`yy'+1,47] = 1e-6*r(sum)

quietly: sum ret_val1 [w = marsupwt] if ret_sc1==4
matrix results[`numyears'*(`ii'-1)+`yy'+1,48] = 1e-6*r(sum)
quietly: sum ret_val2 [w = marsupwt] if ret_sc2==4
matrix results[`numyears'*(`ii'-1)+`yy'+1,49] = 1e-6*r(sum)
quietly: sum dis_val1 [w = marsupwt] if dis_sc1==5
matrix results[`numyears'*(`ii'-1)+`yy'+1,50] = 1e-6*r(sum)
quietly: sum dis_val2 [w = marsupwt] if dis_sc2==5
matrix results[`numyears'*(`ii'-1)+`yy'+1,51] = 1e-6*r(sum)
quietly: sum sur_val1 [w = marsupwt] if sur_sc1==4
matrix results[`numyears'*(`ii'-1)+`yy'+1,52] = 1e-6*r(sum)
quietly: sum sur_val2 [w = marsupwt] if sur_sc2==4
matrix results[`numyears'*(`ii'-1)+`yy'+1,53] = 1e-6*r(sum)

quietly: sum ss_val [w = marsupwt] if resnss1==1 
matrix results[`numyears'*(`ii'-1)+`yy'+1,54] = 1e-6*r(sum)
quietly: sum ss_val [w = marsupwt] if resnss1==2 
matrix results[`numyears'*(`ii'-1)+`yy'+1,55] = 1e-6*r(sum)
quietly: sum ss_val [w = marsupwt] if resnss1==3 
matrix results[`numyears'*(`ii'-1)+`yy'+1,56] = 1e-6*r(sum)
quietly: sum ss_val [w = marsupwt] if resnss1==4 
matrix results[`numyears'*(`ii'-1)+`yy'+1,57] = 1e-6*r(sum)
quietly: sum ss_val [w = marsupwt] if resnss1==6 
matrix results[`numyears'*(`ii'-1)+`yy'+1,58] = 1e-6*r(sum)
quietly: sum ss_val [w = marsupwt] if resnss1==7 
matrix results[`numyears'*(`ii'-1)+`yy'+1,59] = 1e-6*r(sum)
quietly: sum ss_val [w = marsupwt] if resnss1==8 
matrix results[`numyears'*(`ii'-1)+`yy'+1,60] = 1e-6*r(sum)

local ii=`ii'+1
local yy=`yy'+1
}

matrix list results

*svmat results

*keep results*
*format * %12.0g
*outsheet using "$root/output/temp/cps/cps_aggregates.xls", replace
putexcel A2=matrix(results, colnames) using "$root/output/temp/cps/cps_aggregates.xls", replace 
putexcel A1=("Totals from raw CPS files, computed by cps_sumstats.do") using "$root/output/temp/cps/cps_aggregates.xls", modify 


******************************************
* Totals in CPS clean
******************************************

local years "1962/2009"
	numlist "`years'"
	local fullyears = "`r(numlist)'"
	di "EXPANDED LIST OF YEARS: `fullyears'"
	local numyears : list sizeof local(fullyears)
	di "NUMBER OF YEARS: `numyears'"

matrix results = J(`numyears',87,.)	
local yy=0

foreach year of numlist `years' {

	use $dirnonfilers/cpsmar`year'.dta, clear

	local ii=1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,1]=`year'

	quietly: sum h_seq [w=dweght] 
	local tunit_tot=r(sum_w)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,2] = 1e-3*r(sum_w)

	quietly: sum h_seq [w=dweght] if filingst<6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,3] = 1e-3*r(sum_w)

	quietly: sum h_seq [w=dweght] if filingst==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,4] = 1e-3*r(sum_w)
	quietly: sum h_seq [w=dweght] if filingst==2
	matrix results[`numyears'*(`ii'-1)+`yy'+1,5] = 1e-3*r(sum_w)
	quietly: sum h_seq [w=dweght] if filingst==3
	matrix results[`numyears'*(`ii'-1)+`yy'+1,6] = 1e-3*r(sum_w)
	quietly: sum h_seq [w=dweght] if filingst==4
	matrix results[`numyears'*(`ii'-1)+`yy'+1,7] = 1e-3*r(sum_w)
	quietly: sum h_seq [w=dweght] if filingst==5
	matrix results[`numyears'*(`ii'-1)+`yy'+1,8] = 1e-3*r(sum_w)
	quietly: sum h_seq [w=dweght] if filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,9] = 1e-3*r(sum_w)

	quietly: sum h_seq [w=dweght] if filingst==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,10] = r(sum_w)/`tunit_tot'
	quietly: sum h_seq [w=dweght] if filingst==2
	matrix results[`numyears'*(`ii'-1)+`yy'+1,11]= r(sum_w)/`tunit_tot'
	quietly: sum h_seq [w=dweght] if filingst==3
	matrix results[`numyears'*(`ii'-1)+`yy'+1,12] = r(sum_w)/`tunit_tot'
	quietly: sum h_seq [w=dweght] if filingst==4
	matrix results[`numyears'*(`ii'-1)+`yy'+1,13] = r(sum_w)/`tunit_tot'
	quietly: sum h_seq [w=dweght] if filingst==5
	matrix results[`numyears'*(`ii'-1)+`yy'+1,14]= r(sum_w)/`tunit_tot'
	quietly: sum h_seq [w=dweght] if filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,15] = r(sum_w)/`tunit_tot'

	quietly: sum h_seq [w = dweght] if filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,16] = 1e-3*r(sum_w)

	quietly: sum h_seq [w = dweght] if filingst==6 & oldexm==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,17] = 1e-3*r(sum_w)

	quietly: sum h_seq [w = dweght] if filingst==6 & young==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,18] = 1e-3*r(sum_w)

	quietly: sum h_seq [w = dweght] if filingst==6 & student==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,19] = 1e-3*r(sum_w)

	quietly: sum h_seq [w = dweght] if filingst==6 & married==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,20] = 1e-3*r(sum_w)

	quietly: sum age [w = dweght] if filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,21] = r(mean)

	quietly: sum oldexm [w = dweght] if filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,22] = r(mean)

	quietly: sum young [w = dweght] if filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,23] = r(mean)

	quietly: sum student [w = dweght] if filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,24]= r(mean)

	quietly: sum married [w = dweght] if filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,25] = r(mean)

	quietly: sum age [w = dweght] 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,26] = r(mean)

	quietly: sum h_seq [w = dweght] if married==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,27]= 1e-3*r(sum_w)

	quietly: sum h_seq [w = dweght] if single==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,28] = 1e-3*r(sum_w)

	quietly: sum h_seq [w = dweght] if head==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,29] = 1e-3*r(sum_w)

	quietly: sum xkids [w = dweght] 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,30] = r(mean)

	quietly: sum h_seq [w = dweght] if oldexm==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,31] = 1e-3*r(sum_w)

	quietly: sum wages [w = dweght] 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,32] = r(mean)

	quietly: sum peninc [w = dweght] 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,33]= r(mean)

	quietly: sum ssinc [w = dweght] 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,34] = r(mean)

	quietly: sum uiinc [w = dweght] 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,35] = r(mean)

	quietly: sum seinc [w = dweght] 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,36] = r(mean)

	quietly: sum age [w = dweght] if filingst<6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,37] = r(mean)

	quietly: sum h_seq [w = dweght] if married==1 & filingst<6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,38] = 1e-3*r(sum_w)

	quietly: sum h_seq [w = dweght] if single==1 & filingst<6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,39] = 1e-3*r(sum_w)

	quietly: sum h_seq [w = dweght] if head==1 & filingst<6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,40] = 1e-3*r(sum_w)

	quietly: sum xkids [w = dweght] if filingst<6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,41] = r(mean)

	quietly: sum h_seq [w = dweght] if filingst<6 & oldexm==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,42] = 1e-3*r(sum_w)

	quietly: sum wages [w = dweght] if filingst<6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,43]= r(mean)

	quietly: sum peninc [w = dweght] if filingst<6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,44] = r(mean)

	quietly: sum ssinc [w = dweght] if filingst<6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,45] = r(mean)

	quietly: sum uiinc [w = dweght] if filingst<6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,46]= r(mean)

	quietly: sum seinc [w = dweght] if filingst<6 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,47]= r(mean)

	quietly: sum wages [w = dweght] if filingst<6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,48] = r(max)

	quietly: sum peninc [w = dweght] if filingst<6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,49]= r(max)

	quietly: sum ssinc [w = dweght] if filingst<6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,50] = r(max)

	quietly: sum uiinc [w = dweght] if filingst<6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,51] = r(max)

	quietly: sum seinc [w = dweght] if filingst<6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,52] = r(max)

	quietly: sum age [w = dweght] if filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,53] = r(mean)

	quietly: sum h_seq [w = dweght] if married==1 & filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,54] = 1e-3*r(sum_w)

	quietly: sum h_seq [w = dweght] if single==1 & filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,55] = 1e-3*r(sum_w)

	quietly: sum h_seq [w = dweght] if head==1 & filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,56] = 1e-3*r(sum_w)

	quietly: sum xkids [w = dweght] if filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,57] = r(mean)

	quietly: sum h_seq [w = dweght] if filingst==6 & oldexm==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,58] = 1e-3*r(sum_w)

	quietly: sum wages [w = dweght] if filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,59] = r(mean)

	quietly: sum peninc [w = dweght] if filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,60] = r(mean)

	quietly: sum ssinc [w = dweght] if filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,61] = r(mean)

	quietly: sum uiinc [w = dweght] if filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,62]= r(mean)

	quietly: sum seinc [w = dweght] if filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,63] = r(mean)

	quietly: sum wages [w = dweght] if filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,64] = r(max)

	quietly: sum peninc [w = dweght] if filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,65] = r(max)

	quietly: sum ssinc [w = dweght] if filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,66] = r(max)

	quietly: sum uiinc [w = dweght] if filingst==6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,67]= r(max)

	quietly: sum seinc [w = dweght] if filingst==6 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,68] = r(max)

	quietly: sum h_seq [w = dweght] if dependent==1 & filingst<6
	matrix results[`numyears'*(`ii'-1)+`yy'+1,69] =  1e-3*r(sum_w)

	quietly: sum h_seq [w = dweght] if (oldexm==1 | oldexf==1) & married==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,70] = 1e-3*r(sum_w)
	quietly: sum h_seq [w = dweght] if filingst<6 & (oldexm==1 | oldexf==1) & married==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,71] = 1e-3*r(sum_w)
	quietly: sum h_seq [w = dweght] if filingst==6 & (oldexm==1 | oldexf==1) & married==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,72] = 1e-3*r(sum_w)

	quietly: sum h_seq [w = dweght] if (oldexm==0 & oldexf==0) & married==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,73] = 1e-3*r(sum_w)
	quietly: sum h_seq [w = dweght] if filingst<6 & (oldexm==0 & oldexf==0) & married==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,74] = 1e-3*r(sum_w)
	quietly: sum h_seq [w = dweght] if filingst==6 & (oldexm==0 & oldexf==0) & married==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,75] = 1e-3*r(sum_w)

	quietly: sum h_seq [w = dweght] if oldexm==1 & married==0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,76] = 1e-3*r(sum_w)
	quietly: sum h_seq [w = dweght] if filingst<6 & oldexm==1 & married==0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,77] = 1e-3*r(sum_w)
	quietly: sum h_seq [w = dweght] if filingst==6 & oldexm==1 & married==0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,78] = 1e-3*r(sum_w)

	quietly: sum h_seq [w = dweght] if oldexm==0 & married==0 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,79] = 1e-3*r(sum_w)
	quietly: sum h_seq [w = dweght] if filingst<6 & oldexm==0 & married==0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,80] = 1e-3*r(sum_w)
	quietly: sum h_seq [w = dweght] if filingst==6 & oldexm==0 & married==0 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,81] = 1e-3*r(sum_w)

	quietly: sum h_seq [w = dweght] if oldexm==0 & married==0 & (ssinc+dsab)>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,82] = 1e-3*r(sum_w)
	quietly: sum h_seq [w = dweght] if filingst<6 & oldexm==0 & married==0 & (ssinc+dsab)>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,83] = 1e-3*r(sum_w)
	quietly: sum h_seq [w = dweght] if filingst==6 & oldexm==0 & married==0 & (ssinc+dsab)>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,84] = 1e-3*r(sum_w)

	quietly: sum h_seq [w = dweght] if oldexm==0 & married==0 & ssinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,85] = 1e-3*r(sum_w)
	quietly: sum h_seq [w = dweght] if filingst<6 & oldexm==0 & married==0 & ssinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,86] = 1e-3*r(sum_w)
	quietly: sum h_seq [w = dweght] if filingst==6 & oldexm==0 & married==0 & ssinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,87] = 1e-3*r(sum_w)

	local ii=`ii'+1
	local yy=`yy'+1
}


matrix list results
svmat results
keep results*

outsheet using $diroutput/temp/cps/cpstaxunits_4.xls, replace


***********************************************************************************************************************
* Totals in IRS small files 
***********************************************************************************************************************


local years  "1962 1964 1966/2009"
	numlist "`years'"
	local fullyears = "`r(numlist)'"
	di "EXPANDED LIST OF YEARS: `fullyears'"
	local numyears : list sizeof local(fullyears)
	di "NUMBER OF YEARS: `numyears'"
matrix results = J(`numyears',24,.)
local yy=0

foreach year of numlist `years' {

use $dirsmall/small`year'.dta, clear
keep if filer == 1 // small now include non-filers
gen taxunits = `tottaxunits`year''
gen seinc = max(0,schcinc)+max(0,partinc)+max(0,scorinc)

local ii=1
matrix results[`numyears'*(`ii'-1)+`yy'+1,1]=`year'
quietly: sum taxunits [w=dweght] 
matrix results[`numyears'*(`ii'-1)+`yy'+1,2] = 1e-8*r(sum_w)
quietly: sum taxunits [w = dweght] if dependent==1 
matrix results[`numyears'*(`ii'-1)+`yy'+1,3] = 1e-8*r(sum_w)
quietly: sum taxunits [w = dweght] if marriedsep==1
matrix results[`numyears'*(`ii'-1)+`yy'+1,4] = 1e-8*r(sum_w)
quietly: sum taxunits [w = dweght] if married==1
matrix results[`numyears'*(`ii'-1)+`yy'+1,5] = 1e-8*r(sum_w)
quietly: sum taxunits [w = dweght] if single==1
matrix results[`numyears'*(`ii'-1)+`yy'+1,6] = 1e-8*r(sum_w)
quietly: sum taxunits [w = dweght] if head==1
matrix results[`numyears'*(`ii'-1)+`yy'+1,7] = 1e-8*r(sum_w)
quietly: sum xkids [w = dweght] 
matrix results[`numyears'*(`ii'-1)+`yy'+1,8]  = r(mean)
quietly: sum taxunits [w = dweght] if oldexm==1 
matrix results[`numyears'*(`ii'-1)+`yy'+1,9] = 1e-8*r(sum_w)
quietly: sum wages [w = dweght] 
matrix results[`numyears'*(`ii'-1)+`yy'+1,10] = r(mean)
matrix results[`numyears'*(`ii'-1)+`yy'+1,11] = r(max)
quietly: sum peninc [w = dweght] 
matrix results[`numyears'*(`ii'-1)+`yy'+1,12] = r(mean)
matrix results[`numyears'*(`ii'-1)+`yy'+1,13] = r(max)
quietly: sum ssinc [w = dweght] 
matrix results[`numyears'*(`ii'-1)+`yy'+1,14] = r(mean)
matrix results[`numyears'*(`ii'-1)+`yy'+1,15] = r(max)
quietly: sum uiinc [w = dweght] 
matrix results[`numyears'*(`ii'-1)+`yy'+1,16] = r(mean)
matrix results[`numyears'*(`ii'-1)+`yy'+1,17] = r(max)
quietly: sum seinc [w = dweght] 
matrix results[`numyears'*(`ii'-1)+`yy'+1,18] = r(mean)
matrix results[`numyears'*(`ii'-1)+`yy'+1,19] = r(max)

quietly: sum taxunits [w = dweght] if (oldexm==1 | oldexf==1) & married==1
matrix results[`numyears'*(`ii'-1)+`yy'+1,20] = 1e-8*r(sum_w)
quietly: sum taxunits [w = dweght] if oldexm==0 & oldexf==0 & married==1 
matrix results[`numyears'*(`ii'-1)+`yy'+1,21] = 1e-8*r(sum_w)
quietly: sum taxunits [w = dweght] if oldexm==1 & married==0
matrix results[`numyears'*(`ii'-1)+`yy'+1,22] = 1e-8*r(sum_w)
quietly: sum taxunits [w = dweght] if oldexm==0 & married==0 
matrix results[`numyears'*(`ii'-1)+`yy'+1,23] = 1e-8*r(sum_w)
quietly: sum taxunits [w = dweght] if oldexm==0 & married==0 & ssinc>0
matrix results[`numyears'*(`ii'-1)+`yy'+1,24] = 1e-8*r(sum_w)

local ii=`ii'+1
local yy=`yy'+1
}
matrix list results
svmat results
keep results*
rename results1 year
rename results2 taxunits
rename results3 dependent
rename results4 marriedsep
rename results5 married
rename results6 single
rename results7 head
rename results8 xkids
rename results9 oldexm
rename results10 wagesmean
rename results11 wagesmax
rename results12 penincmean
rename results13 penincmax
rename results14 ssincmean
rename results15 ssincmax
rename results16 uiincmean
rename results17 uiincmax
rename results18 seincmean
rename results19 seincmax

outsheet using $diroutput/temp/cps/irssmall_2.xls, replace

*/

******************************************
* CPS-IRS comparison
******************************************
*/

clear 
local numyears=48
matrix results = J(`numyears',94,.)
local yy=0
foreach year of numlist 1962 1963 1964 1965 1966 1967 1968 1969 1970 1971 1972 1973 1974 1975 1976 1977 1978 1979 1980 1981 1982 1983 1984 1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 {
use $dirnonfilers/cpsmar`year'.dta, clear

quietly: sum h_seq [w=dweght] 
local hhtotal=r(sum_w)
local ii=1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,1]=`year'
	quietly: sum h_seq [w=dweght] if wages>0 & wages!=. & files==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,2]=r(sum_w)/`hhtotal'
	quietly: sum wages [w= dweght] if files==1, det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,3]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,4]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,5]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,6]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,7]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,8]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,9]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if peninc>0 & peninc!=. & files==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,10]=r(sum_w)/`hhtotal'
	quietly: sum peninc [w= dweght] if files==1, det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,11]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,12]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,13]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,14]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,15]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,16]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,17]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if ssinc>0 & ssinc!=. & files==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,18]=r(sum_w)/`hhtotal'
	quietly: sum ssinc [w= dweght] if files==1, det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,19]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,20]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,21]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,22]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,23]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,24]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,25]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if uiinc>0 & uiinc!=. & files==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,26]=r(sum_w)/`hhtotal'
	quietly: sum uiinc [w= dweght] if files==1, det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,27]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,28]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,29]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,30]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,31]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,32]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,33]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if seinc>0 & seinc!=. & files==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,34]=r(sum_w)/`hhtotal'
	quietly: sum seinc [w= dweght] if files==1, det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,35]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,36]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,37]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,38]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,39]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,40]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,41]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if intinc>0 & intinc!=. & files==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,42]=r(sum_w)/`hhtotal'
	quietly: sum intinc [w= dweght] if files==1, det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,43]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,44]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,45]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,46]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,47]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,48]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,49]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if divinc>0 & divinc!=. & files==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,50]=r(sum_w)/`hhtotal'
	quietly: sum divinc [w= dweght] if files==1, det  
	matrix results[`numyears'*(`ii'-1)+`yy'+1,51]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,52]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,53]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,54]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,55]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,56]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,57]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if farminc>0 & farminc!=. & files==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,58]=r(sum_w)/`hhtotal'
	quietly: sum farminc [w= dweght] if files==1, det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,59]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,60]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,61]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,62]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,63]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,64]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,65]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if alminc>0 & alminc!=. & files==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,66]=r(sum_w)/`hhtotal'
	quietly: sum alminc [w= dweght] if files==1, det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,67]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,68]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,69]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,70]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,71]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,72]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,73]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if inctot>0 & inctot!=. & files==1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,74]=r(sum_w)/`hhtotal'
	quietly: sum inctot [w= dweght] if files==1, det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,75]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,76]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,77]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,78]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,79]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,80]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,81]=1e-3*r(sum)
	
	quietly: sum wages [w= dweght] if files==0, det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,82]=1e-3*r(sum)
	quietly: sum peninc [w= dweght] if files==0, det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,83]=1e-3*r(sum)
	quietly: sum ssinc [w= dweght] if files==0, det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,84]=1e-3*r(sum)
	quietly: sum uiinc [w= dweght] if files==0, det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,85]=1e-3*r(sum)
	quietly: sum seinc [w= dweght] if files==0, det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,86]=1e-3*r(sum)
	
	quietly: sum wages [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,87]=1e-3*r(sum)
	quietly: sum peninc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,88]=1e-3*r(sum)
	quietly: sum ssinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,89]=1e-3*r(sum)
	quietly: sum uiinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,90]=1e-3*r(sum)
	quietly: sum seinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,91]=1e-3*r(sum)
	
	quietly: sum dsab [w= dweght] if files==1, det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,92]=1e-3*r(sum)
	quietly: sum dsab [w= dweght] if files==0, det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,93]=1e-3*r(sum)
	quietly: sum dsab [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,94]=1e-3*r(sum)
local ii=`ii'+1
local yy=`yy'+1
}

matrix list results
svmat results
keep results*
format * %12.0g
outsheet using $diroutput/temp/cps/cps_stataoutput.xls, replace




clear 
local numyears=46
matrix results = J(`numyears',57,.)
local yy=0
foreach year of numlist 1962 1964 1966/2009 {
use $dirsmall/small`year'.dta, clear
keep if filer == 1 // small now include non-filers
gen taxunits = `tottaxunits`year''
gen seinc = max(0,schcinc)+max(0,partinc)+max(0,scorinc)
quietly: sum id [w=dweght] 
local hhtotal=r(sum_w)
local ii=1

	matrix results[`numyears'*(`ii'-1)+`yy'+1,1]=`year'
	quietly: sum id [w=dweght] if wages>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,2]=r(sum_w)/`hhtotal'
	quietly: sum wages [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,3]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,4]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,5]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,6]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,7]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,8]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,9]=1e-8*r(sum)
	quietly: sum id [w=dweght] if peninc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,10]=r(sum_w)/`hhtotal'
	quietly: sum peninc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,11]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,12]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,13]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,14]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,15]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,16]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,17]=1e-8*r(sum)
	quietly: sum id [w=dweght] if ssinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,18]=r(sum_w)/`hhtotal'
	quietly: sum ssinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,19]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,20]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,21]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,22]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,23]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,24]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,25]=1e-8*r(sum)
	quietly: sum id [w=dweght] if uiinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,26]=r(sum_w)/`hhtotal'
	quietly: sum uiinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,27]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,28]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,29]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,30]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,31]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,32]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,33]=1e-8*r(sum)
	quietly: sum id [w=dweght] if seinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,34]=r(sum_w)/`hhtotal'
	quietly: sum seinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,35]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,36]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,37]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,38]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,39]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,40]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,41]=1e-8*r(sum)
	quietly: sum id [w=dweght] if intinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,42]=r(sum_w)/`hhtotal'
	quietly: sum intinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,43]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,44]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,45]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,46]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,47]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,48]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,49]=1e-8*r(sum)
	quietly: sum id [w=dweght] if divinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,50]=r(sum_w)/`hhtotal'
	quietly: sum divinc [w= dweght], det  
	matrix results[`numyears'*(`ii'-1)+`yy'+1,51]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,52]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,53]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,54]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,55]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,56]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,57]=1e-8*r(sum)

local ii=`ii'+1
local yy=`yy'+1
}

matrix list results

svmat results

keep results*
format * %12.0g
outsheet using $diroutput/temp/cps/irs_stataoutput.xls, replace

********************
* IDEM FOR MARRIED *
********************


clear 
local numyears=48
matrix results = J(`numyears',81,.)
local yy=0
foreach year of numlist 1962 1963 1964 1965 1966 1967 1968 1969 1970 1971 1972 1973 1974 1975 1976 1977 1978 1979 1980 1981 1982 1983 1984 1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 {
use $dirnonfilers/cpsmar`year'.dta, clear
keep if files==1
keep if married==1
quietly: sum h_seq [w=dweght] 
local hhtotal=r(sum_w)
local ii=1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,1]=`year'
	quietly: sum h_seq [w=dweght] if wages>0 & wages!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,2]=r(sum_w)/`hhtotal'
	quietly: sum wages [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,3]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,4]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,5]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,6]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,7]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,8]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,9]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if peninc>0 & peninc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,10]=r(sum_w)/`hhtotal'
	quietly: sum peninc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,11]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,12]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,13]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,14]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,15]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,16]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,17]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if ssinc>0 & ssinc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,18]=r(sum_w)/`hhtotal'
	quietly: sum ssinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,19]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,20]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,21]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,22]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,23]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,24]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,25]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if uiinc>0 & uiinc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,26]=r(sum_w)/`hhtotal'
	quietly: sum uiinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,27]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,28]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,29]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,30]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,31]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,32]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,33]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if seinc>0 & seinc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,34]=r(sum_w)/`hhtotal'
	quietly: sum seinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,35]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,36]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,37]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,38]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,39]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,40]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,41]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if intinc>0 & intinc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,42]=r(sum_w)/`hhtotal'
	quietly: sum intinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,43]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,44]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,45]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,46]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,47]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,48]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,49]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if divinc>0 & divinc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,50]=r(sum_w)/`hhtotal'
	quietly: sum divinc [w= dweght], det  
	matrix results[`numyears'*(`ii'-1)+`yy'+1,51]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,52]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,53]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,54]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,55]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,56]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,57]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if farminc>0 & farminc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,58]=r(sum_w)/`hhtotal'
	quietly: sum farminc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,59]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,60]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,61]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,62]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,63]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,64]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,65]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if alminc>0 & alminc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,66]=r(sum_w)/`hhtotal'
	quietly: sum alminc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,67]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,68]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,69]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,70]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,71]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,72]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,73]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if inctot>0 & inctot!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,74]=r(sum_w)/`hhtotal'
	quietly: sum inctot [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,75]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,76]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,77]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,78]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,79]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,80]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,81]=1e-3*r(sum)
	
local ii=`ii'+1
local yy=`yy'+1
}

matrix list results
svmat results
keep results*
format * %12.0g
outsheet using $diroutput/temp/cps/cps_stataoutput_married.xls, replace




clear 
local numyears=46
matrix results = J(`numyears',57,.)
local yy=0
foreach year of numlist 1962 1964 1966/2009{

use $dirsmall/small`year'.dta, clear
keep if filer == 1 // small now include non-filers
gen taxunits = `tottaxunits`year''
gen seinc = max(0,schcinc)+max(0,partinc)+max(0,scorinc)
keep if married==1
quietly: sum id [w=dweght] 
local hhtotal=r(sum_w)
local ii=1

	matrix results[`numyears'*(`ii'-1)+`yy'+1,1]=`year'
	quietly: sum id [w=dweght] if wages>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,2]=r(sum_w)/`hhtotal'
	quietly: sum wages [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,3]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,4]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,5]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,6]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,7]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,8]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,9]=1e-8*r(sum)
	quietly: sum id [w=dweght] if peninc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,10]=r(sum_w)/`hhtotal'
	quietly: sum peninc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,11]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,12]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,13]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,14]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,15]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,16]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,17]=1e-8*r(sum)
	quietly: sum id [w=dweght] if ssinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,18]=r(sum_w)/`hhtotal'
	quietly: sum ssinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,19]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,20]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,21]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,22]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,23]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,24]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,25]=1e-8*r(sum)
	quietly: sum id [w=dweght] if uiinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,26]=r(sum_w)/`hhtotal'
	quietly: sum uiinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,27]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,28]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,29]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,30]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,31]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,32]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,33]=1e-8*r(sum)
	quietly: sum id [w=dweght] if seinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,34]=r(sum_w)/`hhtotal'
	quietly: sum seinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,35]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,36]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,37]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,38]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,39]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,40]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,41]=1e-8*r(sum)
	quietly: sum id [w=dweght] if intinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,42]=r(sum_w)/`hhtotal'
	quietly: sum intinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,43]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,44]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,45]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,46]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,47]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,48]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,49]=1e-8*r(sum)
	quietly: sum id [w=dweght] if divinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,50]=r(sum_w)/`hhtotal'
	quietly: sum divinc [w= dweght], det  
	matrix results[`numyears'*(`ii'-1)+`yy'+1,51]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,52]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,53]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,54]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,55]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,56]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,57]=1e-8*r(sum)

local ii=`ii'+1
local yy=`yy'+1
}

matrix list results

svmat results

keep results*
format * %12.0g
outsheet using $diroutput/temp/cps/irs_stataoutput_married.xls, replace


************************
* IDEM FOR NON-MARRIED *
************************


clear 
local numyears=48
matrix results = J(`numyears',81,.)
local yy=0
foreach year of numlist 1962 1963 1964 1965 1966 1967 1968 1969 1970 1971 1972 1973 1974 1975 1976 1977 1978 1979 1980 1981 1982 1983 1984 1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 {
use $dirnonfilers/cpsmar`year'.dta, clear
keep if files==1
keep if married==0
quietly: sum h_seq [w=dweght] 
local hhtotal=r(sum_w)
local ii=1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,1]=`year'
	quietly: sum h_seq [w=dweght] if wages>0 & wages!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,2]=r(sum_w)/`hhtotal'
	quietly: sum wages [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,3]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,4]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,5]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,6]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,7]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,8]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,9]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if peninc>0 & peninc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,10]=r(sum_w)/`hhtotal'
	quietly: sum peninc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,11]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,12]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,13]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,14]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,15]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,16]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,17]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if ssinc>0 & ssinc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,18]=r(sum_w)/`hhtotal'
	quietly: sum ssinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,19]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,20]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,21]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,22]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,23]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,24]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,25]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if uiinc>0 & uiinc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,26]=r(sum_w)/`hhtotal'
	quietly: sum uiinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,27]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,28]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,29]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,30]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,31]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,32]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,33]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if seinc>0 & seinc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,34]=r(sum_w)/`hhtotal'
	quietly: sum seinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,35]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,36]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,37]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,38]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,39]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,40]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,41]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if intinc>0 & intinc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,42]=r(sum_w)/`hhtotal'
	quietly: sum intinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,43]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,44]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,45]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,46]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,47]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,48]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,49]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if divinc>0 & divinc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,50]=r(sum_w)/`hhtotal'
	quietly: sum divinc [w= dweght], det  
	matrix results[`numyears'*(`ii'-1)+`yy'+1,51]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,52]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,53]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,54]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,55]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,56]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,57]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if farminc>0 & farminc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,58]=r(sum_w)/`hhtotal'
	quietly: sum farminc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,59]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,60]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,61]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,62]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,63]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,64]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,65]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if alminc>0 & alminc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,66]=r(sum_w)/`hhtotal'
	quietly: sum alminc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,67]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,68]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,69]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,70]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,71]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,72]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,73]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if inctot>0 & inctot!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,74]=r(sum_w)/`hhtotal'
	quietly: sum inctot [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,75]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,76]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,77]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,78]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,79]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,80]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,81]=1e-3*r(sum)
	
local ii=`ii'+1
local yy=`yy'+1
}

matrix list results
svmat results
keep results*
format * %12.0g
outsheet using $diroutput/temp/cps/cps_stataoutput_nonmarried.xls, replace




clear 
local numyears=46
matrix results = J(`numyears',57,.)
local yy=0
foreach year of numlist 1962 1964 1966/2009 {

use $dirsmall/small`year'.dta, clear
keep if filer == 1 // small now include non-filers
gen taxunits = `tottaxunits`year''
gen seinc = max(0,schcinc)+max(0,partinc)+max(0,scorinc)
keep if married==0
quietly: sum id [w=dweght] 
local hhtotal=r(sum_w)
local ii=1

	matrix results[`numyears'*(`ii'-1)+`yy'+1,1]=`year'
	quietly: sum id [w=dweght] if wages>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,2]=r(sum_w)/`hhtotal'
	quietly: sum wages [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,3]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,4]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,5]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,6]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,7]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,8]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,9]=1e-8*r(sum)
	quietly: sum id [w=dweght] if peninc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,10]=r(sum_w)/`hhtotal'
	quietly: sum peninc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,11]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,12]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,13]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,14]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,15]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,16]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,17]=1e-8*r(sum)
	quietly: sum id [w=dweght] if ssinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,18]=r(sum_w)/`hhtotal'
	quietly: sum ssinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,19]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,20]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,21]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,22]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,23]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,24]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,25]=1e-8*r(sum)
	quietly: sum id [w=dweght] if uiinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,26]=r(sum_w)/`hhtotal'
	quietly: sum uiinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,27]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,28]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,29]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,30]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,31]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,32]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,33]=1e-8*r(sum)
	quietly: sum id [w=dweght] if seinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,34]=r(sum_w)/`hhtotal'
	quietly: sum seinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,35]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,36]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,37]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,38]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,39]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,40]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,41]=1e-8*r(sum)
	quietly: sum id [w=dweght] if intinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,42]=r(sum_w)/`hhtotal'
	quietly: sum intinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,43]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,44]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,45]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,46]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,47]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,48]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,49]=1e-8*r(sum)
	quietly: sum id [w=dweght] if divinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,50]=r(sum_w)/`hhtotal'
	quietly: sum divinc [w= dweght], det  
	matrix results[`numyears'*(`ii'-1)+`yy'+1,51]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,52]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,53]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,54]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,55]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,56]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,57]=1e-8*r(sum)

local ii=`ii'+1
local yy=`yy'+1
}

matrix list results

svmat results

keep results*
format * %12.0g
outsheet using $diroutput/temp/cps/irs_stataoutput_nonmarried.xls, replace



*********************
* IDEM FOR OLDEXM=1 *
*********************


clear 
local numyears=48
matrix results = J(`numyears',81,.)
local yy=0
foreach year of numlist 1962/2009 {
use $dirnonfilers/cpsmar`year'.dta, clear
keep if files==1
keep if oldexm==1
quietly: sum h_seq [w=dweght] 
local hhtotal=r(sum_w)
local ii=1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,1]=`year'
	quietly: sum h_seq [w=dweght] if wages>0 & wages!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,2]=r(sum_w)/`hhtotal'
	quietly: sum wages [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,3]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,4]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,5]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,6]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,7]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,8]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,9]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if peninc>0 & peninc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,10]=r(sum_w)/`hhtotal'
	quietly: sum peninc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,11]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,12]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,13]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,14]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,15]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,16]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,17]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if ssinc>0 & ssinc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,18]=r(sum_w)/`hhtotal'
	quietly: sum ssinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,19]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,20]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,21]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,22]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,23]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,24]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,25]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if uiinc>0 & uiinc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,26]=r(sum_w)/`hhtotal'
	quietly: sum uiinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,27]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,28]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,29]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,30]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,31]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,32]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,33]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if seinc>0 & seinc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,34]=r(sum_w)/`hhtotal'
	quietly: sum seinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,35]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,36]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,37]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,38]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,39]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,40]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,41]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if intinc>0 & intinc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,42]=r(sum_w)/`hhtotal'
	quietly: sum intinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,43]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,44]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,45]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,46]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,47]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,48]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,49]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if divinc>0 & divinc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,50]=r(sum_w)/`hhtotal'
	quietly: sum divinc [w= dweght], det  
	matrix results[`numyears'*(`ii'-1)+`yy'+1,51]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,52]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,53]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,54]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,55]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,56]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,57]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if farminc>0 & farminc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,58]=r(sum_w)/`hhtotal'
	quietly: sum farminc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,59]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,60]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,61]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,62]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,63]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,64]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,65]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if alminc>0 & alminc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,66]=r(sum_w)/`hhtotal'
	quietly: sum alminc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,67]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,68]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,69]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,70]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,71]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,72]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,73]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if inctot>0 & inctot!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,74]=r(sum_w)/`hhtotal'
	quietly: sum inctot [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,75]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,76]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,77]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,78]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,79]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,80]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,81]=1e-3*r(sum)
	
local ii=`ii'+1
local yy=`yy'+1
}

matrix list results
svmat results
keep results*
format * %12.0g
outsheet using $diroutput/temp/cps/cps_stataoutput_oldexm.xls, replace




clear 
local numyears=46
matrix results = J(`numyears',57,.)
local yy=0
foreach year of numlist 1962 1964 1966/2009 {

use $dirsmall/small`year'.dta, clear
keep if filer == 1 // small now include non-filers
gen taxunits = `tottaxunits`year''
gen seinc = max(0,schcinc)+max(0,partinc)+max(0,scorinc)
keep if oldexm==1
quietly: sum id [w=dweght] 
local hhtotal=r(sum_w)
local ii=1

	matrix results[`numyears'*(`ii'-1)+`yy'+1,1]=`year'
	quietly: sum id [w=dweght] if wages>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,2]=r(sum_w)/`hhtotal'
	quietly: sum wages [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,3]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,4]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,5]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,6]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,7]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,8]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,9]=1e-8*r(sum)
	quietly: sum id [w=dweght] if peninc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,10]=r(sum_w)/`hhtotal'
	quietly: sum peninc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,11]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,12]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,13]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,14]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,15]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,16]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,17]=1e-8*r(sum)
	quietly: sum id [w=dweght] if ssinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,18]=r(sum_w)/`hhtotal'
	quietly: sum ssinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,19]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,20]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,21]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,22]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,23]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,24]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,25]=1e-8*r(sum)
	quietly: sum id [w=dweght] if uiinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,26]=r(sum_w)/`hhtotal'
	quietly: sum uiinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,27]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,28]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,29]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,30]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,31]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,32]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,33]=1e-8*r(sum)
	quietly: sum id [w=dweght] if seinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,34]=r(sum_w)/`hhtotal'
	quietly: sum seinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,35]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,36]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,37]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,38]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,39]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,40]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,41]=1e-8*r(sum)
	quietly: sum id [w=dweght] if intinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,42]=r(sum_w)/`hhtotal'
	quietly: sum intinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,43]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,44]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,45]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,46]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,47]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,48]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,49]=1e-8*r(sum)
	quietly: sum id [w=dweght] if divinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,50]=r(sum_w)/`hhtotal'
	quietly: sum divinc [w= dweght], det  
	matrix results[`numyears'*(`ii'-1)+`yy'+1,51]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,52]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,53]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,54]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,55]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,56]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,57]=1e-8*r(sum)

local ii=`ii'+1
local yy=`yy'+1
}

matrix list results

svmat results

keep results*
format * %12.0g
outsheet using $diroutput/temp/cps/irs_stataoutput_oldexm.xls, replace


******************
* IDEM FOR YOUNG *
******************


clear 
local numyears=48
matrix results = J(`numyears',81,.)
local yy=0
foreach year of numlist 1962/2009 {
use $dirnonfilers/cpsmar`year'.dta, clear
keep if files==1
keep if oldexm==0
quietly: sum h_seq [w=dweght] 
local hhtotal=r(sum_w)
local ii=1
	matrix results[`numyears'*(`ii'-1)+`yy'+1,1]=`year'
	quietly: sum h_seq [w=dweght] if wages>0 & wages!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,2]=r(sum_w)/`hhtotal'
	quietly: sum wages [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,3]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,4]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,5]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,6]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,7]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,8]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,9]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if peninc>0 & peninc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,10]=r(sum_w)/`hhtotal'
	quietly: sum peninc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,11]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,12]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,13]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,14]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,15]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,16]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,17]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if ssinc>0 & ssinc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,18]=r(sum_w)/`hhtotal'
	quietly: sum ssinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,19]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,20]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,21]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,22]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,23]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,24]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,25]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if uiinc>0 & uiinc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,26]=r(sum_w)/`hhtotal'
	quietly: sum uiinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,27]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,28]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,29]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,30]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,31]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,32]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,33]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if seinc>0 & seinc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,34]=r(sum_w)/`hhtotal'
	quietly: sum seinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,35]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,36]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,37]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,38]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,39]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,40]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,41]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if intinc>0 & intinc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,42]=r(sum_w)/`hhtotal'
	quietly: sum intinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,43]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,44]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,45]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,46]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,47]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,48]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,49]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if divinc>0 & divinc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,50]=r(sum_w)/`hhtotal'
	quietly: sum divinc [w= dweght], det  
	matrix results[`numyears'*(`ii'-1)+`yy'+1,51]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,52]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,53]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,54]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,55]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,56]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,57]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if farminc>0 & farminc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,58]=r(sum_w)/`hhtotal'
	quietly: sum farminc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,59]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,60]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,61]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,62]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,63]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,64]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,65]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if alminc>0 & alminc!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,66]=r(sum_w)/`hhtotal'
	quietly: sum alminc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,67]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,68]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,69]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,70]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,71]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,72]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,73]=1e-3*r(sum)
	quietly: sum h_seq [w=dweght] if inctot>0 & inctot!=.
	matrix results[`numyears'*(`ii'-1)+`yy'+1,74]=r(sum_w)/`hhtotal'
	quietly: sum inctot [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,75]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,76]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,77]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,78]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,79]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,80]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,81]=1e-3*r(sum)
	
local ii=`ii'+1
local yy=`yy'+1
}

matrix list results
svmat results
keep results*
format * %12.0g
outsheet using $diroutput/temp/cps/cps_stataoutput_young.xls, replace




clear 
local numyears=46
matrix results = J(`numyears',57,.)
local yy=0
foreach year of numlist 1962 1964 1966/2009 {

use $dirsmall/small`year'.dta, clear
keep if filer == 1 // small now include non-filers
gen taxunits = `tottaxunits`year''
gen seinc = max(0,schcinc)+max(0,partinc)+max(0,scorinc)
keep if oldexm==0
quietly: sum id [w=dweght] 
local hhtotal=r(sum_w)
local ii=1

	matrix results[`numyears'*(`ii'-1)+`yy'+1,1]=`year'
	quietly: sum id [w=dweght] if wages>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,2]=r(sum_w)/`hhtotal'
	quietly: sum wages [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,3]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,4]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,5]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,6]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,7]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,8]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,9]=1e-8*r(sum)
	quietly: sum id [w=dweght] if peninc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,10]=r(sum_w)/`hhtotal'
	quietly: sum peninc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,11]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,12]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,13]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,14]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,15]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,16]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,17]=1e-8*r(sum)
	quietly: sum id [w=dweght] if ssinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,18]=r(sum_w)/`hhtotal'
	quietly: sum ssinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,19]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,20]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,21]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,22]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,23]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,24]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,25]=1e-8*r(sum)
	quietly: sum id [w=dweght] if uiinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,26]=r(sum_w)/`hhtotal'
	quietly: sum uiinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,27]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,28]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,29]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,30]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,31]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,32]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,33]=1e-8*r(sum)
	quietly: sum id [w=dweght] if seinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,34]=r(sum_w)/`hhtotal'
	quietly: sum seinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,35]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,36]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,37]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,38]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,39]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,40]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,41]=1e-8*r(sum)
	quietly: sum id [w=dweght] if intinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,42]=r(sum_w)/`hhtotal'
	quietly: sum intinc [w= dweght], det 
	matrix results[`numyears'*(`ii'-1)+`yy'+1,43]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,44]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,45]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,46]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,47]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,48]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,49]=1e-8*r(sum)
	quietly: sum id [w=dweght] if divinc>0
	matrix results[`numyears'*(`ii'-1)+`yy'+1,50]=r(sum_w)/`hhtotal'
	quietly: sum divinc [w= dweght], det  
	matrix results[`numyears'*(`ii'-1)+`yy'+1,51]=r(mean)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,52]=r(p25)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,53]=r(p50)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,54]=r(p75)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,55]=r(p90)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,56]=r(p99)
	matrix results[`numyears'*(`ii'-1)+`yy'+1,57]=1e-8*r(sum)

local ii=`ii'+1
local yy=`yy'+1
}

matrix list results

svmat results

keep results*
format * %12.0g
outsheet using $diroutput/temp/cps/irs_stataoutput_young.xls, replace

clear 
global years="1962/2009"
local numyears=48
matrix results = J(3*`numyears',12,.)
local yy=0
foreach year of numlist $years {
use $dirnonfilers/cpsmar`year'.dta, clear
keep if files==1
rename dweght dweght_old
gen dweght = int(dweght_old)
foreach var of varlist wages peninc ssinc uiinc seinc intinc divinc farminc alminc inctot {
	quietly: sum `var' [w= dweght]
	local `var'_tot=r(sum)
	cumul `var' [w= dweght], gen(rank`var')
	}
local ii=1
foreach fract of numlist .9 .99 .999 {
	matrix results[`numyears'*(`ii'-1)+`yy'+1,1]=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,2]=`year'
	quietly: sum wages [w= dweght] if rankinctot>=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,3]=r(sum)/`wages_tot'
	quietly: sum peninc [w= dweght] if rankpeninc>=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,4]=r(sum)/`peninc_tot'
	quietly: sum ssinc [w= dweght] if rankssinc>=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,5]=r(sum)/`ssinc_tot'
	quietly: sum uiinc [w= dweght] if rankuiinc>=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,6]=r(sum)/`uiinc_tot'
	quietly: sum seinc [w= dweght] if rankseinc>=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,7]=r(sum)/`seinc_tot'
	quietly: sum intinc [w= dweght] if rankintinc>=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,8]=r(sum)/`intinc_tot'
	quietly: sum divinc [w= dweght] if rankdivinc>=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,9]=r(sum)/`divinc_tot'
	quietly: sum farminc [w= dweght] if rankfarminc>=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,10]=r(sum)/`farminc_tot'
	quietly: sum alminc [w= dweght] if rankalminc>=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,11]=r(sum)/`alminc_tot'
	quietly: sum inctot [w= dweght] if rankinctot>=`fract'
	matrix results[`numyears'*(`ii'-1)+`yy'+1,12]=r(sum)/`inctot_tot'
	local ii=`ii'+1
}
local yy=`yy'+1
}

matrix list results

svmat results

keep results*
rename results1 fractile 
rename results2 year
rename results3 wages
rename results4 peninc
rename results5 ssinc
rename results6 uiinc
rename results7 seinc
rename results8 intinc
rename results9 divinc
rename results10 farminc
rename results11 alminc
rename results12 inctot

format * %12.0g
outsheet using $diroutput/temp/cps/cpsshares_stataoutput.xls, replace
