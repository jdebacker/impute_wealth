* Program that constructs CPS datasets at tax unit level & constructs matrices used for imputation into DINA
* Version of November 18, 2016 (last GZ version) 
* Updated Jan. 2018 for DINA update 2015/16

****************************************************************************************************************************************************************
*
* BUILDS CPS-ASEC DATASETS AT TAX UNIT LEVEL
* Code written by Juliana Londono Velez and Antoine Arnould
*
****************************************************************************************************************************************************************
/*


* Converts CPS-ASEC units to tax units to prepare append of CPS non-filers to IRS small files.
* Calls in the raw CPS .dta files in rawdata/cps and uses sub routines:
* 	a) sub_grossthres.do generates the filing threshold variables
* 	b) sub_deptest.do generates the income threshold for dependency test
* 	c) sub_snap_irs.do and snap_cps.do determine SNAP and SSI eligibility for recent years, and output matrices snapssi_irs.xls and snapssi_`year�.xls

* References:
* post-1994:
* http://www.irs.gov/publications/p501/ar02.html#en_US_2013_publink1000220702
* http://www.irs.gov/pub/irs-prior/p501--2009.pdf
* pre-1994:
* http://www.irs.gov/pub/irs-prior/i1040--1993.pdf

* Memo: CPS year = actual earnings year +1


global indiv_sum = 0 // 1 if tax-unit level files are created by summing up variables for all members of tax unit (Antoine)
					 // 0 if tax-unit level files are created by keeping the highest earner/couple variables (Juliana)
* WARNING: indiv_sum = 1 does not work for computing DINA matrices (it was created by Antoine to test alternative method of constructing tax units, not for DINA purposes)
foreach year of numlist 1962/$cpsendyear {
* foreach year of numlist 2000 {
local year=`year'+1

if `year'<=1979 use $dircps/cpsunicon/work/full/mar`year'.dta, clear
if `year'> 1979 use $dircps/cpsmar`year'.dta, clear

/*
        ----------------------------------------------------------------
		Renaming variables to make comparable across years
        ----------------------------------------------------------------
*/


if `year'<1976 drop if wgt<0
if (`year'<=1971 | `year'>1975 & `year'<=1979) encode hhid, generate(h_seq)
if `year'>1971 & `year'<=1975 egen h_seq = group(hhid fnumper hdage)
if `year'<=1987 & `year'>1979 rename hhseqnum h_seq
if (`year'<=1975 | `year'>1979 & `year'<=1987) rename lineno a_lineno
if `year'>1975 & `year'<=1979 rename perid a_lineno
if `year'<=1987 rename age a_age
if `year'<=1987 rename sex a_sex
if (`year'<=1967 | `year'>1975 & `year'<=1979) rename head head_old
if `year'>1962 & `year'<=1971 rename year year_old
if `year'<=1979 gen spouseln=.
if `year'<=1987 rename spouseln a_spouse
if (`year'<=1979 & `year'!=1966 & `year'!=1963) gen marsupwt = wgt/100
if `year'==1963 gen marsupwt = wgt/75 // abritrary
if `year'==1966 gen marsupwt = wgt/200
if `year'> 1979 & `year'<=1987 rename marsuppw marsupwt
if `year'<=1979 rename incwag wsal_val
if `year'>1967 & `year'<1976 replace wsal_val=0 if wsal_val==99999
if `year'> 1979 & `year'<=1987 rename i51a wsal_val
if `year'<=1967 gen int_val = 0
if `year'<=1967 replace int_val=0.5*incuer if a_age<65
if `year'<=1967 replace int_val=0.25*incuer if a_age>=65
if `year'> 1967 & `year'< 1976 gen int_val=0.9*incint
if `year'> 1967 & `year'< 1976 replace int_val=0 if incint==99999
if `year'>=1976 & `year'<=1979 gen int_val=incint
if `year'>=1976 & `year'<=1979 replace int_val=0 if incint==99999
if `year'> 1979  & `year'<=1987 rename i53b int_val
if `year'<=1967 gen div_val= 0
if `year'<=1967 replace div_val=0.5*incuer if a_age<65
if `year'<=1967 replace div_val=0.25*incuer if a_age>=65
if `year'> 1967 & `year'<1976 gen div_val=0.1*incint
if `year' >1967 & `year'<1976 replace div_val=0 if incint==99999
if `year'>=1976 & `year'<=1979 rename incdiv div_val
if `year'> 1979 & `year'<=1987 rename i53c div_val
if `year'< 1968 gen alm_val = 0
if `year'>=1968 & `year'<1976 gen alm_val = 0.2*incoth
if `year'>1967 & `year'<1976 replace alm_val=0 if incoth==99999
if `year'>=1976 & `year'<=1979 gen alm_val = incalc
if `year'> 1979 & `year'<=1987 rename i53f alm_val
if `year'> 2013 cap gen alm_val=0
if `year'<=1979 rename incse semp_val
if `year'>1967 & `year'<1976 replace semp_val=0 if semp_val==99999
if `year'> 1979 & `year'<=1987 rename i51b semp_val
if `year'<=1967 gen rtm_val = 0
if `year'>=1968 & `year'<1976 gen rtm_val = 0.8*incoth
if `year'>=1968 & `year'<1976 replace rtm_val=0 if incoth==99999
if `year'>=1976 & `year'<=1979 rename incret rtm_val
if `year'> 1979 & `year'<=1987 rename i53e rtm_val
if `year'<=1979 rename incfrm frse_val
if `year'>1967 & `year'<1976 replace frse_val=0 if frse_val==99999
if `year'> 1979 & `year'<=1987 rename i51c frse_val
if `year'<=1987 gen uc_val = 0
*if `year'< 1968 gen uc_val = 0
*if `year'>=1968 & `year'<=1979 gen uc_val = incomp
*if `year'>1967 & `year'<1976 replace uc_val=0 if incomp==99999
*if `year'> 1979 & `year'<=1987 rename i53d uc_val
if `year'<=1967 gen ss_val=0
if `year'<=1967 replace ss_val=0.5*incuer if a_age>=65
if `year'>=1968 & `year'<=1979 gen ss_val= incss
if `year'>1967 & `year'<1976 replace ss_val=0 if incss==99999
if `year'> 1979 & `year'<=1987 rename i52a ss_val
if `year'<=1987 gen rnt_val = 0
if `year'<=1987 gen dsab_val = 0
if `year'<=1987 gen ed_val = 0
if `year'<=1987 gen sur_val1=0
if `year'<=1987 gen sur_val2=0
if `year'<=1987 gen sur_sc1=0
if `year'<=1987 gen sur_sc2=0
if `year'<=1979 gen ptotval= income
if `year'>1967 & `year'<1976 replace ptotval=0 if income==99999
if `year'> 1979 & `year'<=1987 rename pinctot ptotval
if `year'< 1976 gen ssi_val=0
if `year'>=1976 & `year'<=1979 rename incsec ssi_val
if `year'>1979 & `year'<=1987 rename i52b ssi_val
if `year'<1980 gen hmcaid=0
if `year'>=1980 & `year'<1988 bysort h_seq: egen hmcaid=min(covmedcd) //because medicaid status is recorded at the individual level
if `year'<1976 gen hpublic=0
if `year'>=1976 & `year'<=1987 rename public hpublic
if `year'<1980 gen hfoodsp=0
if `year'<1980 gen f_mv_fs=0
if `year'>=1980 & `year'<=1987 gen f_mv_fs= hvalllefs // careful: household - not family-level!
if `year'> 1987 & `year'<=1991 gen f_mv_fs= hfdval // careful: household - not family-level!
if `year'<1980 gen hflunch=0
if `year'>=1980 & `year'<1988 rename hfreelun hflunch
if `year'<1980 gen henrgyas=0
if `year'>=1988 rename hengast henrgyas
if `year'<1980 gen henrgyva=0
if `year'>=1988 rename hengval henrgyva
if `year'<2001 gen hrwicyn=0
if `year'<=1967 gen welfr_val=0 // welfare is included in incunern together with other stuff, which we will ignore
if `year'> 1967 & `year'< 1976 gen welfr_val = incpa
if `year'> 1967 & `year'< 1976 replace welfr_val=0 if incpa==99999
if `year'>=1976 & `year'<=1979 gen welfr_val = incpa+ssi_val
if `year'> 1979 & `year'<=1987 gen welfr_val = i53a+ssi_val // note that starting 1980 welfare will include food stamps value - which will be added later to avoid double counting
if `year'> 1987 gen welfr_val = paw_val+ssi_val+dsab_val
if `year'<=1975 gen afdc= 0
if `year'>1975 & `year'<=1979 gen afdc= (_incs22 == 1)
if `year'> 1979 & `year'<=1987 gen afdc =(i53aadc==1)
if `year'>1987 gen afdc=(paw_typ==1)
if `year'<1980 gen penplan=0
if `year'>=1980 & `year'<=1987 rename pensplan penplan
if `year'<1980 gen hiemp=0
if `year'>=1980 & `year'<=1987 rename inclingh hiemp
if `year'<=1967 gen a_famtyp = .
if `year'<=1967 replace a_famtyp = 1 if famtyp==0
if `year'<=1967 replace a_famtyp = 3 if famtyp==1
if `year'<=1967 replace a_famtyp = 4 if famtyp==2
if `year'<=1967 replace a_famtyp = 2 if famtyp==3
if `year'<=1967 replace a_famtyp = 5 if famtyp==4
if `year'>=1968 & `year'<=1975 gen a_famtyp=.
if `year'>=1968 & `year'<=1975 replace a_famtyp=1 if (famdesc==1 | famdesc==2)
if `year'>=1968 & `year'<=1975 replace a_famtyp=2 if famdesc==5
if `year'>=1968 & `year'<=1975 replace a_famtyp=3 if famdesc==3
if `year'>=1968 & `year'<=1975 replace a_famtyp=4 if famdesc==4
if `year'>=1968 & `year'<=1975 replace a_famtyp=5 if (famdesc>=6 & famdesc<=9)
if `year'>=1976 & `year'<=1979 gen a_famtyp = .
if `year'>=1976 & `year'<=1979 replace a_famtyp = 1 if famknd==1
if `year'>=1976 & `year'<=1979 replace a_famtyp = 2 if famknd==4
if `year'>=1976 & `year'<=1979 replace a_famtyp = 3 if famknd==2
if `year'>=1976 & `year'<=1979 replace a_famtyp = 4 if famknd==3
if `year'>=1976 & `year'<=1979 replace a_famtyp = 5 if famknd==5
if `year'> 1979 & `year'<=1987 gen a_famtyp = .
if `year'> 1979 & `year'<=1987 replace a_famtyp = 1 if fkind==1
if `year'> 1979 & `year'<=1987 replace a_famtyp = 2 if fkind==4
if `year'> 1979 & `year'<=1987 replace a_famtyp = 3 if fkind==2
if `year'> 1979 & `year'<=1987 replace a_famtyp = 4 if fkind==3
if `year'> 1979 & `year'<=1987 replace a_famtyp = 5 if fkind==5
if `year'> 1979 & `year'<=1987 drop fkind
if `year'==1962 gen a_famrel=.
if `year'==1962 replace a_famrel=0 if (hhrel==4 | hhrel==5)
if `year'==1962 replace a_famrel=1 if hhrel==0
if `year'==1962 replace a_famrel=2 if hhrel==1
if `year'==1962 replace a_famrel=3 if hhrel==2
if `year'==1962 replace a_famrel=4 if hhrel==3
if `year'>1962 & `year'<=1967 gen a_famrel=.
if `year'>1962 & `year'<=1967 replace a_famrel=0 if famrel==4
if `year'>1962 & `year'<=1967 replace a_famrel=1 if famrel==0
if `year'>1962 & `year'<=1967 replace a_famrel=2 if famrel==1
if `year'>1962 & `year'<=1967 replace a_famrel=3 if famrel==2
if `year'>1962 & `year'<=1967 replace a_famrel=4 if famrel==3
if `year'>1967 & `year'<=1979 gen a_famrel=.
if `year'>1967 & `year'<=1979 replace a_famrel=0 if (hhrel3==10 | hhrel3==11)
if `year'>1967 & `year'<=1979 replace a_famrel=1 if hhrel3==1
if `year'>1967 & `year'<=1979 replace a_famrel=2 if hhrel3==2
if `year'>1967 & `year'<=1979 replace a_famrel=3 if (hhrel3==3 | hhrel3==4 | hhrel3==5)
if `year'>1967 & `year'<=1979 replace a_famrel=4 if (hhrel3==6 | hhrel3==7 | hhrel3==8 | hhrel3==9)
if `year'> 1979 & `year'<=1987 gen a_famrel = 0
if `year'> 1979 & `year'<=1987 replace a_famrel = 1 if rfamst == 1
if `year'> 1979 & `year'<=1987 replace a_famrel = 2 if rfamst == 2
if `year'> 1979 & `year'<=1987 replace a_famrel = 3 if (rfamst == 3 | rfamst == 4)
if `year'> 1979 & `year'<=1987 replace a_famrel = 4 if rfamst == 5
if `year'<=1975 gen a_parent_temp=a_lineno if a_famrel==1
if `year'<=1975 sort h_seq a_lineno
if `year'<=1975 bysort h_seq: carryforward a_parent_temp, gen(a_parent)
if `year'<=1975 replace a_parent=0 if a_famrel!=3
if `year'<=1975 drop a_parent_temp
if `year'> 1975 & `year'<=1979 gen a_parent = 0
if `year'> 1975 & `year'<=1979 replace a_parent = idxper if a_famrel == 3
if `year'> 1979 & `year'<=1987 gen a_parent = 0
if `year'> 1979 & `year'<=1987 replace a_parent = ppindind if a_famrel == 3
if `year'> 1979 & `year'<=1987 rename bshlftpt a_ftpt //note: 1984 this variable doesnt exist. Must correct.
if `year'<=1967 gen rsnnotw=. // Not sure of this one... Pretty sure about students though.
if `year'<=1967 replace rsnnotw=0 if _rnowrk==0
if `year'<=1967 replace rsnnotw=1 if _rnowrk==1
if `year'<=1967 replace rsnnotw=2 if _rnowrk==7
if `year'<=1967 replace rsnnotw=3 if _rnowrk==2
if `year'<=1967 replace rsnnotw=4 if _rnowrk==3
if `year'<=1967 replace rsnnotw=5 if _rnowrk==4
if `year'<=1967 replace rsnnotw=6 if _rnowrk==6
if `year'> 1967 & `year'<=1979 rename rnowrk i137
if `year'> 1967 & `year'<=1987 gen rsnnotw=.
if `year'> 1967 & `year'<=1987 replace rsnnotw=0 if i137==0
if `year'> 1967 & `year'<=1987 replace rsnnotw=1 if i137==1
if `year'> 1967 & `year'<=1987 replace rsnnotw=2 if i137==6
if `year'> 1967 & `year'<=1987 replace rsnnotw=3 if i137==2
if `year'> 1967 & `year'<=1987 replace rsnnotw=4 if i137==3
if `year'> 1967 & `year'<=1987 replace rsnnotw=5 if i137==4
if `year'> 1967 & `year'<=1987 replace rsnnotw=6 if (i137==7 | i137==5)
if `year'<=1975 gen h_tenure=.
if `year'> 1975 & `year'<=1987 rename tenure h_tenure
if `year'==1962 gen a_maritl=marstat+1
if `year'>1962 & `year'<= 1967 gen a_maritl = marstat
if `year'> 1967 & `year'<=1975 gen a_maritl = .
if `year'> 1967 & `year'<=1975 replace a_maritl=1 if marstat==2
if `year'> 1967 & `year'<=1975 replace a_maritl=2 if marstat==4
if `year'> 1967 & `year'<=1975 replace a_maritl=3 if marstat==5
if `year'> 1967 & `year'<=1975 replace a_maritl=4 if marstat==6
if `year'> 1967 & `year'<=1975 replace a_maritl=5 if marstat==7
if `year'> 1967 & `year'<=1975 replace a_maritl=6 if marstat==3
if `year'> 1967 & `year'<=1975 replace a_maritl=7 if (marstat==0 | marstat==1)
if `year'> 1975 & `year'<=1987 gen a_maritl = .
if `year'> 1975 & `year'<=1987 replace a_maritl=1 if marstat==1
if `year'> 1975 & `year'<=1987 replace a_maritl=2 if marstat==2
if `year'> 1975 & `year'<=1987 replace a_maritl=3 if (marstat==3 | marstat==4)
if `year'> 1975 & `year'<=1987 replace a_maritl=4 if marstat==5
if `year'> 1975 & `year'<=1987 replace a_maritl=5 if marstat==6
if `year'> 1975 & `year'<=1987 replace a_maritl=6 if marstat==7
if `year'> 1975 & `year'<=1987 replace a_maritl=7 if marstat==8
if (`year'==1994 | `year'==1995) rename pulineno a_lineno
if `year'==1995 rename prmarsta a_maritl
if `year'==1995 rename pespouse a_spouse
if `year'==1995 rename peparent a_parent
if `year'==1995 rename peage a_age
if `year'==1995 rename prfamrel a_famrel
if `year'==1995 rename prfamtyp a_famtyp
if `year'==1995 rename peschft a_ftpt
if `year'==1995 rename pesex a_sex
if `year'<1963 gen povcut=0
if `year'<1980  rename povcut fpovcut
if `year'>=1980 & `year'<1988 rename flowinc fpovcut
sort h_seq a_lineno
if `year'<=1982 rename a_spouse a_spouse_old
if `year'<=1982 gen a_spouse = 0
if `year'<=1982 by h_seq: replace a_spouse = a_lineno[_n+1] if (a_maritl==1 | a_maritl==2) & a_famrel==1
if `year'<=1982 by h_seq: replace a_spouse = a_lineno[_n-1] if (a_maritl==1 | a_maritl==2) & a_famrel==2
* Add GZ March 2016
	qui gen veteran = 0
		label variable veteran "Receives veterans' payments"
		if `year'>1987 qui replace veteran = (vet_val > 0 & vet_val != .)
		if `year'> 1979 & `year'<=1987 qui replace veteran = (i53dvp == 1)
		if `year'>1968 & `year'<=1979 qui replace veteran = (_incs09 == 1) // no info before 1969
	if `year'<1988 qui gen vet_val = 0
		label variable vet_val "Amounts of veterans' benefits received (separated from UI and workers' comp since 1988 only)"
	qui gen hasmaid = 0
		label variable hasmaid "Individual receives medicaid"
		if `year'>1987 replace hasmaid = (mcaid == 1)
		if `year'> 1979 & `year'<=1987 replace hasmaid = (covmedcd == 1)
	qui gen tanf_val = 0
		label variable tanf_val "Amount of AFDC/TANF received"
		if `year'>1987 					qui replace tanf_val = paw_val if paw_typ == 1
		if `year'> 1979 & `year'<=1987  qui replace tanf_val = i53a    if i53aadc == 1
	qui gen healthben = 0
		label variable healthben "Employer health benefits"
		if `year'>1991 qui replace healthben = emcontrb
	qui gen hashealth = 0
		label variable hashealth "Has employer health benefits"
		if `year'> 1979 qui replace hashealth = (hiemp == 1)
	qui gen haspplan = 0
		label variable haspplan "Enrolled in employer-provided pension plan"
		if `year' > 1987 qui replace haspplan = (penincl == 1)
		if `year'> 1979 & `year'<=1987 	qui replace haspplan = (inclinpp == 1)
	qui gen oldexm=(a_age >= 65)
		cap label drop old
		label define old 0 "65less" 1 "65plus"
		label values oldexm old
	cap label drop matstatus
		label define matstatus 0 "sing" 1 "marr"
		gen married = (a_spouse!=0)
		label values married matstatus
	qui egen oldmar=group(married oldexm), label
		label variable oldmar "Married x 65+ dummy"

* For Antoine: creer money income (individual) as used by Census Bureau in Income and Poverty publications
* -> already defined in variables (different names for different years) as it is the default definition of income of Census Bureau (AA)


gen year=`year'

* Save indiv-level CPS
	preserve
		egen earned = rsum(wsal_val semp_val frse_val ed_val dsab_val) // earned income is the sum of wage, self-employment, farm income, educational assistance and disability income
		egen unearned = rsum(int_val div_val alm_val rtm_val rnt_val uc_val) // unearned income is the sum of interest income, dividend income, alimony income, pension income, rent income, and unemployment compensation
		egen grossinc = rsum(earned unearned)
		egen inctotal = rsum(wsal_val semp_val frse_val int_val div_val alm_val rtm_val rnt_val)

*		Addition of ptotval (personal money income) to individual-level CPS saved files (Antoine - Oct 2016)
*		keep year h_seq marsupwt a_age a_sex a_spouse inctotal earned unearned grossinc
		keep year h_seq marsupwt a_age a_sex a_spouse inctotal earned unearned grossinc  ptotval ///
		wsal_val semp_val frse_val ed_val dsab_val ///
		int_val div_val alm_val rtm_val rnt_val uc_val vet_val tanf_val  ///
		veteran hasmaid healthben hashealth haspplan oldmar

		compress
		saveold $diroutput/cpsindiv/cpsmar`year'indiv.dta, replace
	restore



/*
        ----------------------------------------------------------------
		Calculate aged exemptions and generate age of spouse variable
        ----------------------------------------------------------------
*/

sort h_seq a_lineno
gen ages=0
by h_seq: replace ages=a_age[a_spouse] if a_spouse!=0

label var ages "Spouse's age"

gen age=a_age if a_spouse==0
replace age=a_age if a_spouse!=0 & a_sex==1
replace age=ages if a_spouse!=0 & a_sex==2

gen age_spouse=.
replace age_spouse=ages if a_spouse!=0 & a_sex==1
replace age_spouse=a_age if a_spouse!=0 & a_sex==2

gen senior=(a_age>=65)
gen seniors=(ages>=65)
egen agede=rsum(senior seniors)

label var agede "Number of aged exemptions"

* FIXME: check below is right (AA)
* if male: age records own age and age_spouse records spouse's age if married
* if female: age records own age if unmarried, and spouse's age if married. age_spouse records own age if married
* that way both variables age and age_spouse have the same values for both observations in a married couple



/*     ----------------------------------------------------------------
		Calculate income variables for the tax unit:
		sum of primary and spouse (if applicable)
        ----------------------------------------------------------------
*/

sort h_seq a_lineno // sort according to household id and line number (main earner, spouse,...)

gen tu_wages = wsal_val if a_spouse==0
gen tu_interest = int_val if a_spouse==0
gen tu_dividends = div_val if a_spouse==0
gen tu_alimony = alm_val if a_spouse==0
gen tu_business = max(0,semp_val) if a_spouse==0
gen tu_retirement = rtm_val if a_spouse==0
gen tu_rents = rnt_val if a_spouse==0
gen tu_farm = frse_val if a_spouse==0
gen tu_unemp = uc_val if a_spouse==0
gen tu_ss = ss_val if a_spouse==0
gen tu_totinc = ptotval if a_spouse==0
gen tu_dsab = dsab_val if a_spouse==0
gen tu_ssi = ssi_val if a_spouse==0
gen tu_welfr = welfr_val + f_mv_fs if a_spouse==0 // note the difference in the definition - we want to avoid doubling the value of food stamps
gen sur_temp=sur_val1*(sur_sc1==8)+sur_val2*(sur_sc2==8)
gen tu_estinc = sur_temp if a_spouse==0


by h_seq: replace tu_wages = wsal_val + wsal_val[a_spouse] if a_spouse!=0
by h_seq: replace tu_interest = int_val + int_val[a_spouse] if a_spouse!=0
by h_seq: replace tu_dividends = div_val + div_val[a_spouse] if a_spouse!=0
by h_seq: replace tu_alimony = alm_val + alm_val[a_spouse] if a_spouse!=0
by h_seq: replace tu_business = max(0,semp_val) + max(0,semp_val[a_spouse]) if a_spouse!=0
by h_seq: replace tu_retirement = rtm_val + rtm_val[a_spouse] if a_spouse!=0
by h_seq: replace tu_rents = rnt_val + rnt_val[a_spouse] if a_spouse!=0
by h_seq: replace tu_farm = frse_val + frse_val[a_spouse] if a_spouse!=0
by h_seq: replace tu_unemp = uc_val + uc_val[a_spouse] if a_spouse!=0
by h_seq: replace tu_ss = ss_val + ss_val[a_spouse] if a_spouse!=0
by h_seq: replace tu_totinc = ptotval + ptotval[a_spouse] if a_spouse!=0
by h_seq: replace tu_dsab = dsab_val + dsab_val[a_spouse] if a_spouse!=0
by h_seq: replace tu_ssi = ssi_val + ssi_val[a_spouse] if a_spouse!=0
by h_seq: replace tu_welfr = welfr_val + welfr_val[a_spouse] + f_mv_fs if a_spouse!=0 // note the difference in the definition - we want to avoid doubling the value of food stamps
by h_seq: replace tu_estinc = sur_temp + sur_temp[a_spouse] if a_spouse!=0


egen earned = rsum(wsal_val semp_val frse_val ed_val dsab_val) // earned income is the sum of wage, self-employment, farm income, educational assistance and disability income
egen unearned = rsum(int_val div_val alm_val rtm_val rnt_val uc_val) // unearned income is the sum of interest income, dividend income, alimony income, pension income, rent income, and unemployment compensation
egen grossinc = rsum(earned unearned)
egen inctotal = rsum(wsal_val semp_val frse_val int_val div_val alm_val rtm_val rnt_val)
if `year'<1976 gen inctotal2 = wsal_val+semp_val+frse_val+max(0,int_val)+max(0,div_val)+max(0,alm_val)+rtm_val+rnt_val

gen tu_income  = grossinc if a_spouse==0
by h_seq: replace tu_income = grossinc + grossinc[a_spouse] if a_spouse!=0

gen tu_inctotal  = inctotal if a_spouse==0
by h_seq: replace tu_inctotal = inctotal + inctotal[a_spouse] if a_spouse!=0

if `year'<1976 gen tu_inctotal2  = inctotal2 if a_spouse==0
if `year'<1976 by h_seq: replace tu_inctotal2 = inctotal2 + inctotal2[a_spouse] if a_spouse!=0

gen eitc = .
replace eitc = (wsal_val + semp_val + frse_val + ed_val + dsab_val) if senior==0
replace eitc = (wsal_val + semp_val + frse_val + ed_val) if senior==1
gen tu_eitcinc = eitc if a_spouse==0
by h_seq: replace tu_eitcinc = eitc + eitc[a_spouse] if a_spouse!=0

gen tu_ssfile = 0 if tu_income==0
replace tu_ssfile = tu_income + 0.5*tu_ss if tu_income>0 & tu_ss>0
replace tu_ssfile = 0 if tu_ssfile==.

gen tu_oldcred = 0
replace tu_oldcred = tu_ss if agede>0

/*
        ----------------------------------------------------------------
		Sets the thresholds at which tax units are required to file a
		return for each of the filing status.
        ----------------------------------------------------------------

Definitions:

gross1n: single under 65
gross1a: single 65+
gross2n0: married filing jointly both under 65
gross2a1: married filing jointly one 65+
gross2a2: married filing jointly both 65+
gross3n: head of household under 65
gross3a: head of household 65+

*/
gen tax_year = year-1

*generates the filing threshold variables
	gen gross1n = .
		replace gross1n = 9500*((1.025)^5) if tax_year>=2016
		replace gross1n = 9500*((1.025)^4) if tax_year==2015
		replace gross1n = 9500*((1.025)^3) if tax_year==2014
		replace gross1n = 9500*((1.025)^2) if tax_year==2013
		replace gross1n = 9500*(1.025) if tax_year==2012
		replace gross1n = 9500 if tax_year==2011
		replace gross1n = 9350 if tax_year==2010
		replace gross1n = 9350 if tax_year==2009
		replace gross1n = 8950 if tax_year==2008
		replace gross1n = 8750 if tax_year==2007
		replace gross1n = 8450 if tax_year==2006
		replace gross1n = 8200 if tax_year==2005
		replace gross1n = 7950 if tax_year==2004
		replace gross1n = 7800 if tax_year==2003
		replace gross1n = 7700 if tax_year==2002
		replace gross1n = 7450 if tax_year==2001
		replace gross1n = 7200 if tax_year==2000
		replace gross1n = 7050 if tax_year==1999
		replace gross1n = 6950 if tax_year==1998
		replace gross1n = 6800 if tax_year==1997
		replace gross1n = 6550 if tax_year==1996
		replace gross1n = 6400 if tax_year==1995
		replace gross1n = 6250 if tax_year==1994
		replace gross1n = 6050 if tax_year==1993
		replace gross1n = 5900 if tax_year==1992
		replace gross1n = 5500 if tax_year==1991
		replace gross1n = 5300 if tax_year==1990
		replace gross1n = 5100 if tax_year==1989
		replace gross1n = 4950 if tax_year==1988
		replace gross1n = 4440 if tax_year==1987
		replace gross1n = 3560 if tax_year==1986
		replace gross1n = 3430 if tax_year==1985
		replace gross1n = 3300 if tax_year<=1984 & tax_year>1978
		replace gross1n = 2950 if tax_year<=1978 & tax_year>1976
		replace gross1n = 2450 if tax_year==1976
		replace gross1n = 2350 if tax_year==1975
		replace gross1n = 2050 if (tax_year<=1974 & tax_year>1971)
		replace gross1n = 1700 if (tax_year<=1971 & tax_year>1969)
		replace gross1n = 600 if tax_year<=1969
	gen gross1a = .
		replace gross1a = 10950*((1.025)^5) if tax_year>=2016
		replace gross1a = 10950*((1.025)^4) if tax_year==2015
		replace gross1a = 10950*((1.025)^3) if tax_year==2014
		replace gross1a = 10950*((1.025)^2) if tax_year==2013
		replace gross1a = 10950*(1.025) if tax_year==2012
		replace gross1a = 10950 if tax_year==2011
		replace gross1a = 10750 if tax_year==2010
		replace gross1a = 10750 if tax_year==2009
		replace gross1a = 10300 if tax_year==2008
		replace gross1a = 10050 if tax_year==2007
		replace gross1a = 9700 if tax_year==2006
		replace gross1a = 9450 if tax_year==2005
		replace gross1a = 9150 if tax_year==2004
		replace gross1a = 8950 if tax_year==2003
		replace gross1a = 8850 if tax_year==2002
		replace gross1a = 8550 if tax_year==2001
		replace gross1a = 8300 if tax_year==2000
		replace gross1a = 8100 if tax_year==1999
		replace gross1a = 8000 if tax_year==1998
		replace gross1a = 7800 if tax_year==1997
		replace gross1a = 7550 if tax_year==1996
		replace gross1a = 7350 if tax_year==1995
		replace gross1a = 7200 if tax_year==1994
		replace gross1a = 6950 if tax_year==1993
		replace gross1a = 6800 if tax_year==1992
		replace gross1a = 6400 if tax_year==1991
		replace gross1a = 6100 if tax_year==1990
		replace gross1a = 5850 if tax_year==1989
		replace gross1a = 5700 if tax_year==1988
		replace gross1a = 5650 if tax_year==1987
		replace gross1a = 4640 if tax_year==1986
		replace gross1a = 4470 if tax_year==1985
		replace gross1a = 4300 if tax_year<=1984 & tax_year>1978
		replace gross1a = 3700 if tax_year<=1978 & tax_year>1976
		replace gross1a = 3200 if tax_year==1976
		replace gross1a = 3100 if tax_year==1975
		replace gross1a = 2800 if (tax_year<=1974 & tax_year>1971)
		replace gross1a = 2300 if (tax_year<=1971 & tax_year>1969)
		replace gross1a = 1200 if tax_year<=1969
	gen gross3n = .
		replace gross3n = 12200*((1.025)^5) if tax_year>=2016
		replace gross3n = 12200*((1.025)^4) if tax_year==2015
		replace gross3n = 12200*((1.025)^3) if tax_year==2014
		replace gross3n = 12200*((1.025)^2) if tax_year==2013
		replace gross3n = 12200*(1.025) if tax_year==2012
		replace gross3n = 12200  if tax_year==2011
		replace gross3n = 12000 if tax_year==2010
		replace gross3n = 12000 if tax_year==2009
		replace gross3n = 11500 if tax_year==2008
		replace gross3n = 11250 if tax_year==2007
		replace gross3n = 10850 if tax_year==2006
		replace gross3n = 10500 if tax_year==2005
		replace gross3n = 10250 if tax_year==2004
		replace gross3n = 10050 if tax_year==2003
		replace gross3n = 9900 if tax_year==2002
		replace gross3n = 9550 if tax_year==2001
		replace gross3n = 9250 if tax_year==2000
		replace gross3n = 9100 if tax_year==1999
		replace gross3n = 8950 if tax_year==1998
		replace gross3n = 8700 if tax_year==1997
		replace gross3n = 8450 if tax_year==1996
		replace gross3n = 8250 if tax_year==1995
		replace gross3n = 8050 if tax_year==1994
		replace gross3n = 7800 if tax_year==1993
		replace gross3n = 7550 if tax_year==1992
		replace gross3n = 7150 if tax_year==1991
		replace gross3n = 6800 if tax_year==1990
		replace gross3n = 6550 if tax_year==1989
		replace gross3n = 6350 if tax_year==1988
		replace gross3n = 4440 if tax_year==1987
		replace gross3n = 3560 if tax_year==1986
		replace gross3n = 3430 if tax_year==1985
		replace gross3n = 3300 if tax_year<=1984 & tax_year>1978
		replace gross3n = 2950 if tax_year<=1978 & tax_year>1976
		replace gross3n = 2450 if tax_year==1976
		replace gross3n = 2350 if tax_year==1975
		replace gross3n = 2050 if (tax_year<=1974 & tax_year>1971)
		replace gross3n = 1700 if (tax_year<=1971 & tax_year>1969)
		replace gross3n = 600 if tax_year<=1969
	gen gross3a = .
		replace gross3a = 13650*((1.025)^5) if tax_year>=2016
		replace gross3a = 13650*((1.025)^4) if tax_year==2015
		replace gross3a = 13650*((1.025)^3) if tax_year==2014
		replace gross3a = 13650*((1.025)^2) if tax_year==2013
		replace gross3a = 13650*(1.025) if tax_year==2012
		replace gross3a = 13650  if tax_year==2011
		replace gross3a = 13400 if tax_year==2010
		replace gross3a = 13400 if tax_year==2009
		replace gross3a = 12850 if tax_year==2008
		replace gross3a = 12500 if tax_year==2007
		replace gross3a = 12100 if tax_year==2006
		replace gross3a = 11750 if tax_year==2005
		replace gross3a = 11450 if tax_year==2004
		replace gross3a = 11200 if tax_year==2003
		replace gross3a = 11050 if tax_year==2002
		replace gross3a = 10650 if tax_year==2001
		replace gross3a = 10350 if tax_year==2000
		replace gross3a = 10150 if tax_year==1999
		replace gross3a = 10000 if tax_year==1998
		replace gross3a = 9700 if tax_year==1997
		replace gross3a = 9450 if tax_year==1996
		replace gross3a = 9200 if tax_year==1995
		replace gross3a = 9000 if tax_year==1994
		replace gross3a = 8700 if tax_year==1993
		replace gross3a = 8450 if tax_year==1992
		replace gross3a = 8000 if tax_year==1991
		replace gross3a = 7600 if tax_year==1990
		replace gross3a = 7300 if tax_year==1989
		replace gross3a = 7100 if tax_year==1988
		replace gross3a = 7050 if tax_year==1987
		replace gross3a = 4640 if tax_year==1986
		replace gross3a = 4470 if tax_year==1985
		replace gross3a = 4300 if tax_year<=1984 & tax_year>1978
		replace gross3a = 3700 if tax_year<=1978 & tax_year>1976
		replace gross3a = 3200 if tax_year==1976
		replace gross3a = 3100 if tax_year==1975
		replace gross3a = 2800 if (tax_year<=1974 & tax_year>1971)
		replace gross3a = 2300 if (tax_year<=1971 & tax_year>1969)
		replace gross3a = 1200 if tax_year<=1969
	gen gross2n0 = .
		replace gross2n0 = 19000*((1.025)^5) if tax_year>=2016
		replace gross2n0 = 19000*((1.025)^4) if tax_year==2015
		replace gross2n0 = 19000*((1.025)^3) if tax_year==2014
		replace gross2n0 = 19000*((1.025)^2) if tax_year==2013
		replace gross2n0 = 19000*(1.025) if tax_year==2012
		replace gross2n0 = 19000 if tax_year==2011
		replace gross2n0 = 18700 if tax_year==2010
		replace gross2n0 = 18700 if tax_year==2009
		replace gross2n0 = 17900 if tax_year==2008
		replace gross2n0 = 17500 if tax_year==2007
		replace gross2n0 = 16900 if tax_year==2006
		replace gross2n0 = 16400 if tax_year==2005
		replace gross2n0 = 15900 if tax_year==2004
		replace gross2n0 = 15600 if tax_year==2003
		replace gross2n0 = 13850 if tax_year==2002
		replace gross2n0 = 13400 if tax_year==2001
		replace gross2n0 = 12950 if tax_year==2000
		replace gross2n0 = 12700 if tax_year==1999
		replace gross2n0 = 12500 if tax_year==1998
		replace gross2n0 = 12200 if tax_year==1997
		replace gross2n0 = 11800 if tax_year==1996
		replace gross2n0 = 11550 if tax_year==1995
		replace gross2n0 = 11250 if tax_year==1994
		replace gross2n0 = 10900 if tax_year==1993
		replace gross2n0 = 10600 if tax_year==1992
		replace gross2n0 = 10000 if tax_year==1991
		replace gross2n0 = 9550 if tax_year==1990
		replace gross2n0 = 9200 if tax_year==1989
		replace gross2n0 = 8900 if tax_year==1988
		replace gross2n0 = 7560 if tax_year==1987
		replace gross2n0 = 5830 if tax_year==1986
		replace gross2n0 = 5620 if tax_year==1985
		replace gross2n0 = 5400 if tax_year<=1984 & tax_year>1978
		replace gross2n0 = 4700 if tax_year<=1978 & tax_year>1976
		replace gross2n0 = 3600 if tax_year==1976
		replace gross2n0 = 3400 if tax_year==1975
		replace gross2n0 = 2800 if (tax_year<=1974 & tax_year>1971)
		replace gross2n0 = 2300 if (tax_year<=1971 & tax_year>1969)
		replace gross2n0 = 600 if tax_year<=1969
	gen gross2a1 = .
		replace gross2a1 = 20150*((1.025)^5) if tax_year>=2016
		replace gross2a1 = 20150*((1.025)^4) if tax_year==2015
		replace gross2a1 = 20150*((1.025)^3) if tax_year==2014
		replace gross2a1 = 20150*((1.025)^2) if tax_year==2013
		replace gross2a1 = 20150*(1.025) if tax_year==2012
		replace gross2a1 = 20150 if tax_year==2011
		replace gross2a1 = 19800 if tax_year==2010
		replace gross2a1 = 19800 if tax_year==2009
		replace gross2a1 = 18950 if tax_year==2008
		replace gross2a1 = 18550 if tax_year==2007
		replace gross2a1 = 17900 if tax_year==2006
		replace gross2a1 = 17400 if tax_year==2005
		replace gross2a1 = 16850 if tax_year==2004
		replace gross2a1 = 16550 if tax_year==2003
		replace gross2a1 = 14750 if tax_year==2002
		replace gross2a1 = 14300 if tax_year==2001
		replace gross2a1 = 13800 if tax_year==2000
		replace gross2a1 = 13550 if tax_year==1999
		replace gross2a1 = 13350 if tax_year==1998
		replace gross2a1 = 13000 if tax_year==1997
		replace gross2a1 = 12600 if tax_year==1996
		replace gross2a1 = 12300 if tax_year==1995
		replace gross2a1 = 12000 if tax_year==1994
		replace gross2a1 = 11600 if tax_year==1993
		replace gross2a1 = 11300 if tax_year==1992
		replace gross2a1 = 10650 if tax_year==1991
		replace gross2a1 = 10200 if tax_year==1990
		replace gross2a1 = 9800 if tax_year==1989
		replace gross2a1 = 9500 if tax_year==1988
		replace gross2a1 = 9400 if tax_year==1987
		replace gross2a1 = 6910 if tax_year==1986
		replace gross2a1 = 6660 if tax_year==1985
		replace gross2a1 = 6400 if tax_year<=1984 & tax_year>1978
		replace gross2a1 = 5450 if tax_year<=1978 & tax_year>1976
		replace gross2a1 = 4350 if tax_year==1976
		replace gross2a1 = 4150 if tax_year==1975
		replace gross2a1 = 3550 if (tax_year<=1974 & tax_year>1971)
		replace gross2a1 = 2900 if (tax_year<=1971 & tax_year>1969)
		replace gross2a1 = 1200 if tax_year<=1969
	gen gross2a2 = .
		replace gross2a2 = 21300*((1.025)^5) if tax_year>=2016
		replace gross2a2 = 21300*((1.025)^4) if tax_year==2015
		replace gross2a2 = 21300*((1.025)^3) if tax_year==2014
		replace gross2a2 = 21300*((1.025)^2) if tax_year==2013
		replace gross2a2 = 21300*(1.025) if tax_year==2012
		replace gross2a2 = 21300 if tax_year==2011
		replace gross2a2 = 20900 if tax_year==2010
		replace gross2a2 = 20900 if tax_year==2009
		replace gross2a2 = 20000 if tax_year==2008
		replace gross2a2 = 19600 if tax_year==2007
		replace gross2a2 = 18900 if tax_year==2006
		replace gross2a2 = 18400 if tax_year==2005
		replace gross2a2 = 17800 if tax_year==2004
		replace gross2a2 = 17500 if tax_year==2003
		replace gross2a2 = 15650 if tax_year==2002
		replace gross2a2 = 15200 if tax_year==2001
		replace gross2a2 = 14650 if tax_year==2000
		replace gross2a2 = 14400 if tax_year==1999
		replace gross2a2 = 14200 if tax_year==1998
		replace gross2a2 = 13800 if tax_year==1997
		replace gross2a2 = 13400 if tax_year==1996
		replace gross2a2 = 13050 if tax_year==1995
		replace gross2a2 = 12750 if tax_year==1994
		replace gross2a2 = 12300 if tax_year==1993
		replace gross2a2 = 12000 if tax_year==1992
		replace gross2a2 = 11300 if tax_year==1991
		replace gross2a2 = 10850 if tax_year==1990
		replace gross2a2 = 10400 if tax_year==1989
		replace gross2a2 = 10100 if tax_year==1988
		replace gross2a2 = 10000 if tax_year==1987
		replace gross2a2 = 7990 if tax_year==1986
		replace gross2a2 = 7700 if tax_year==1985
		replace gross2a2 = 7400 if tax_year<=1984 & tax_year>1978
		replace gross2a2 = 6200 if tax_year<=1978 & tax_year>1976
		replace gross2a2 = 5100 if tax_year==1976
		replace gross2a2 = 4900 if tax_year==1975
		replace gross2a2 = 4300 if (tax_year<=1974 & tax_year>1971)
		replace gross2a2 = 3500 if (tax_year<=1971 & tax_year>1969)
		replace gross2a2 = 1200 if tax_year<=1969

gen ssincths = .
replace ssincths = 25000
*replace ssincths = 25000 if tax_year<=2009 & tax_year>1986

gen ssincthm = .
replace ssincthm = 32000
*replace ssincthm = 32000 if tax_year<=2009 & tax_year>1986

gen ssincth = .
replace ssincth = ssincthm if a_spouse!=0
replace ssincth = ssincths if a_spouse==0

gen oldth = 7500 // I am ignoring issues of whether married/single and how many seniors


/*
        ----------------------------------------------------------------
		Modify tax unit:
		Start with reference person. Add spouse, children below age 15,
		and foster children below age 20.
        ----------------------------------------------------------------

*/

sort h_seq a_lineno			// sort by hh id and line number

gen tunit=_n

sort h_seq a_famtyp a_famrel a_age
by h_seq: replace tunit = tunit[_n-1] if a_spouse != 0 & a_famrel==2 // adds spouse
* the above assumes that spouse of non-reference earner is in previous line. This might need to be checked. Fixme
* Would the following be safer? (AA):
* by h_seq: replace tunit = tunit[a_spouse] if a_spouse != 0 & a_famrel == 2 // a_famrel at 2 means spouse of refenrence earner
by h_seq: replace tunit = tunit[_n-1] if a_age<15 & a_parent!=0  // adds children below 15
* the above assumes that parents are just above the child. Not true if several children?
* what is a_parent? father or morhter? (AA):  fixme
* Would the following be safer? (AA)
* by h_seq: replace tunit = tunit[a_parent] if a_age < 15 & a_parent != 0
if `year'>1987 by h_seq: replace tunit = tunit[_n-1] if a_exprrp==11 & a_age<20 // foster child

/*
       ----------------------------------------------------------------
		Dependent test:

		Generate income threshold and wage & non-wage income filing
		thresholds
       ----------------------------------------------------------------

*/


* Income test for dependents

gen inctest=.
replace inctest = 3700*((1.025)^5) if tax_year>=2016
replace inctest = 3700*((1.025)^4) if tax_year==2015
replace inctest = 3700*((1.025)^3) if tax_year==2014
replace inctest = 3700*((1.025)^2) if tax_year==2013
replace inctest = 3700*(1.025) if tax_year==2012
replace inctest=3700 if tax_year==2011
replace inctest=3650 if tax_year==2010
replace inctest=3650 if tax_year==2009
replace inctest=3500 if tax_year==2008
replace inctest=3400 if tax_year==2007
replace inctest=3300 if tax_year==2006
replace inctest=3200 if tax_year==2005
replace inctest=3100 if tax_year==2004
replace inctest=3050 if tax_year==2003
replace inctest=3000 if tax_year==2002
replace inctest=2900 if tax_year==2001
replace inctest=2800 if tax_year==2000
replace inctest=2750 if tax_year==1999
replace inctest=2700 if tax_year==1998
replace inctest=2650 if tax_year==1997
replace inctest=2550 if tax_year==1996
replace inctest=2500 if tax_year==1995
replace inctest=2450 if tax_year==1994
replace inctest=2350 if tax_year==1993
replace inctest=2300 if tax_year==1992
replace inctest=2150 if tax_year==1991
replace inctest=2050 if tax_year==1990
replace inctest=2000 if tax_year==1989
replace inctest=1950 if tax_year==1988
replace inctest=1900 if tax_year==1987
replace inctest=1080 if tax_year==1986
replace inctest=1050 if tax_year==1985
replace inctest=1000 if tax_year<=1984 & tax_year>1978
replace inctest=750 if tax_year<=1978 & tax_year>1971
replace inctest=675 if tax_year==1971
replace inctest=625 if tax_year==1970
replace inctest=600 if tax_year<=1969


* Filing requirement thresholds for dependents

gen depwages=.
replace depwages = 5900*((1.025)^5) if tax_year>=2016
replace depwages = 5900*((1.025)^4) if tax_year==2015
replace depwages = 5900*((1.025)^3) if tax_year==2014
replace depwages = 5900*((1.025)^2) if tax_year==2013
replace depwages = 5900*(1.025) if tax_year==2012
replace depwages=5900 if tax_year==2011
replace depwages=5700 if tax_year==2010
replace depwages=5700 if tax_year==2009
replace depwages=5450 if tax_year==2008
replace depwages=5350 if tax_year==2007
replace depwages=5150 if tax_year==2006
replace depwages=5000 if tax_year==2005
replace depwages=4850 if tax_year==2004
replace depwages=4750 if tax_year==2003
replace depwages=4700 if tax_year==2002
replace depwages=4550 if tax_year==2001
replace depwages=4400 if tax_year==2000
replace depwages=4300 if tax_year==1999
replace depwages=4250 if tax_year==1998
replace depwages=4150 if tax_year==1997
replace depwages=4000 if tax_year==1996
replace depwages=3900 if tax_year==1995
replace depwages=3800 if tax_year==1994
replace depwages=3700 if tax_year==1993
replace depwages=3600 if tax_year==1992
replace depwages=3400 if tax_year==1991
replace depwages=3250 if tax_year==1990
replace depwages=3100 if tax_year==1989
replace depwages=3000 if tax_year==1988
replace depwages=2540 if tax_year==1987

gen depnwage=.
replace depnwage = 1000*((1.025)^5) if tax_year>=2016
replace depnwage = 1000*((1.025)^4) if tax_year==2015
replace depnwage = 1000*((1.025)^3) if tax_year==2014
replace depnwage = 1000*((1.025)^2) if tax_year==2013
replace depnwage = 1000*(1.025) if tax_year==2012
replace depnwage=1000 if tax_year==2011
replace depnwage=950 if tax_year==2010
replace depnwage=950 if tax_year==2009
replace depnwage=900 if tax_year==2008
replace depnwage=850 if tax_year==2007
replace depnwage=850 if tax_year==2006
replace depnwage=800 if tax_year==2005
replace depnwage=800 if tax_year==2004
replace depnwage=750 if tax_year==2003
replace depnwage=750 if tax_year==2002
replace depnwage=750 if tax_year==2001
replace depnwage=700 if tax_year==2000
replace depnwage=700 if tax_year==1999
replace depnwage=700 if tax_year==1998
replace depnwage=650 if tax_year==1997
replace depnwage=650 if tax_year==1996
replace depnwage=650 if tax_year==1995
replace depnwage=600 if tax_year==1994
replace depnwage=600 if tax_year==1993
replace depnwage=600 if tax_year==1992
replace depnwage=550 if tax_year==1991
replace depnwage=500 if tax_year<=1990 & tax_year>=1987


/*
        ----------------------------------------------------------------
		Search for dependents among the relatives (i.e. famtyp 1 and 3).
		Assign any new dependent tax units to the tax unit with the highest income.
        ----------------------------------------------------------------
        ----------------------------------------------------------------
		Skip this search if the highest income tax unit in the household
		is a dependent filer or if no tax unit has positive income.
        ----------------------------------------------------------------

*/

by h_seq, sort: egen highest=max(tu_totinc) if (a_famtyp==1 | a_famtyp==3)

gen idxhigh = 1
* flag individuals (single or spouses, and children <15 if any) in tax unit with highest income, if family or subfamily.
* Question: if not a_famtype =1 or 3, does it mean dependent filler? Fixme.
by h_seq: replace idxhigh = 0 if tu_totinc!=highest & highest!=.
by h_seq: replace idxhigh = 0 if highest==0

/*
        ----------------------------------------------------------------
		If the individual is not the highest income tax unit, is unmarried,
		and is related (primary or subfamily), he or she is flagged
		as a potential dependent.
        ----------------------------------------------------------------
*/

gen dflag2=0

by h_seq: replace dflag2=1 if idxhigh==0 & highest>0 & a_spouse==0 & (a_famtyp==1 | a_famtyp==3)

gen tunit_temp = .
replace tunit_temp=tunit if idxhigh==1

sort h_seq tunit_temp a_lineno
by h_seq: carryforward tunit_temp, gen(tunit_new)


/*
        ----------------------------------------------------------------
		Tests for dependency using the five tests:
		1) Relationship test,
		2) Marital test,
		3) Citizen test,
		4) Income test, and
		5) Support test
        ----------------------------------------------------------------
*/

gen test1 = 0
gen test2 = 0
gen test3 = 0
gen test4 = 0
gen test5 = 0





/*
        ----------------------------------------------------------------
		Relationship Test. Since at this phase of the program, we are
		only looking within families, i.e. a_famrel = 1, 3, this test is passed.
        ----------------------------------------------------------------
*/

replace test1 = 1

/*
        ----------------------------------------------------------------
		Marital Test. In general, married individuals filing a joint
		return cannot be dependents unless they file a return only to
		receive a refund. Again, since we are looking at families no
		married couples will be tested.
        ----------------------------------------------------------------
*/

replace test2 = 1

/*
        ----------------------------------------------------------------
		Citizen Test. Assume this is always met.
        ----------------------------------------------------------------
*/

replace test3 = 1

/*
        ----------------------------------------------------------------
		Income Test. In general, a person's income must be less than
		$3,100 (3700 for 2011) to be eligible to be a dependent. There are exceptions
		for young children and students.
        ----------------------------------------------------------------

*/

gen famkid=0
by h_seq: replace famkid=1 if a_famrel == 3

gen student=0 // generate student indicator
if `year'>1987 by h_seq: replace student=1 if a_ftpt==1 | (a_ftpt==0 & (pyrsn==3 | rsnnotw==4))
if (`year'==1986 | `year'==1987) by h_seq: replace student=1 if a_ftpt==1 | (a_ftpt==0 & rpyrsn==4)
if `year'>1979 & `year'<1986 by h_seq: replace student=1 if (rpyrsn==4 | i145==3 | besr==5 | rsnnotw==4 | bitem19x==5) //not sure if this is ok
if `year'>1967 & `year'<=1979 by h_seq: replace student=1 if (majact==5 | rsnnotw==4)
if `year'<=1967 by h_seq: replace student=1 if rsnnotw==4

replace test4=1 if grossinc<inctest & dflag2==1
if `year'>1987 replace test4=1 if a_age<=18 & (a_exprrp==5|famkid==1)
if `year'<=1987 replace test4=1 if a_age<=18 & famkid==1
if `year'>1987 replace test4=1 if a_age<=23 & (a_exprrp==5|famkid==1) & student==1
if `year'<=1987 replace test4=1 if a_age<=23 & famkid==1 & student==1

/*
        ----------------------------------------------------------------
		Support Test. Taxpayer and, if married, spouse must provide more
		than half of the support for the individual in order for him/her
		to qualify as a dependent. Note that this assumption means all qualifying
		children for the EITC are also dependents.
        ----------------------------------------------------------------

[This definition is very shaky...]

*/

replace test5=1 if ptotval==0 & highest==.
replace test5=1 if ptotval+highest<=0
replace test5=1 if (ptotval/highest)<=0.5

/*
        ----------------------------------------------------------------
		Dependency determination: must meet the five tests.
        ----------------------------------------------------------------
*/

gen dtest=test1+test2+test3+test4+test5
gen dflag=(dtest==5)

/*
        ----------------------------------------------------------------
		Determine if a dependent needs to file a tax return. Note that
		the measure of income used excludes Social Security income,
		unless it is greater than a certain threshold (ssincth).
		----------------------------------------------------------------
*/

gen dependent=(dflag==1 & a_spouse==0)

gen depfile = .
replace depfile=0 if dependent == 1
if `year'>= 1987 replace depfile=1 if (earned>=depwages | unearned>=depnwage) & dependent == 1
if `year'< 1987 replace depfile=1 if grossinc>=inctest & dependent == 1
replace depfile=0 if depfile==.
replace depfile = 1 if tu_ssfile>=ssincth & dependent==1

/*
	    ----------------------------------------------------------------
		Link all non-married individuals age 20+ with highest income tax unit
		if dependent not required to file separately.
        ----------------------------------------------------------------
*/

sort h_seq tunit a_lineno

by h_seq: replace tunit = tunit_new if dependent==1  & a_age>=20 & depfile==0


/*
	    ----------------------------------------------------------------
		Link all non-married children below age 20 with highest income tax unit
		if they do not live with their parents and do not file return.

		Link all non-married children below age 20 with their parents' tax unit
		if they do live with their parents
        ----------------------------------------------------------------

*/
by h_seq: replace tunit = tunit_new if dependent==1 & a_age<20 & a_parent==0 & depfile==0
drop tunit_temp tunit_new

sort h_seq a_famtyp a_famrel
by h_seq: replace tunit = tunit[a_parent] if dependent==1 & a_age<20 & a_age>=15 & a_parent!=0 & depfile==0

if `year'>1962 & `year'<1968 by h_seq: egen depminor_temp = sum(dependent) if (a_famtyp==1 | a_famtyp==3) & a_age<18 // Correction for ignoring dependents below age 14.
if `year'>1962 & `year'<1968 by h_seq: egen depminor = max(depminor_temp)
if `year'>1962 & `year'<1968 replace depminor = 0 if depminor==.




by h_seq: egen depne = sum(dependent) if (a_famtyp==1 | a_famtyp==3)  // determine number of dependents
replace depne =0 if depne==.
if `year'>1962 & `year'<1968 replace depne=depne+child18-depminor
replace depne =0 if depfile==1 // dependents who file separately do not count as dependents in their own tax file
replace depne =0 if idxhigh==0
label var depne "Number of dependents (includes those filing separately)"

gen depkid=(dependent==1 & a_age<=23 & a_famrel==3) // determine number of dependent kids below age 24
by h_seq: egen xkids = sum(depkid) if (a_famtyp==1 | a_famtyp==3)
replace xkids =0 if xkids==.
if `year'>1962 & `year'<1968 replace xkids=xkids+child18-depminor
replace xkids =0 if depfile==1 // dependents who file separately do not count as dependents in their own tax file
replace xkids =0 if idxhigh==0
label var xkids "Number of dependent kids (includes those filing separately)"

by tunit, sort: egen totstudent = sum(student) //  number of students in tax unit

gen childcred_temp = (dependent==1 & a_age<17)
by tunit, sort: egen childcred = sum(childcred_temp) // number of children aged 16 and under in tax unit
replace childcred =0 if childcred ==.



/*
        ----------------------------------------------------------------
		Generate marital status and set filing status
        ----------------------------------------------------------------
*/
cap drop married
gen married = (a_spouse!=0)
gen head = (married==0 & depne!=0 & idxhigh==1)
gen single = (married==0 & head==0)

gen amount = .
replace amount = gross1n if single==1 & agede==0
replace amount = gross1a if single==1 & agede!=0
replace amount = gross2n0 if married==1 & agede==0
replace amount = gross2a1 if married==1 & agede==1
replace amount = gross2a2 if married==1 & agede==2
replace amount = gross3n if head==1 & agede==0
replace amount = gross3a if head==1 & agede!=0


/*
	    ----------------------------------------------------------------
		Calculate tax unit weight as the average person weight.
        ----------------------------------------------------------------

Note: I will be using "marsupwt" as weight for each person.

*/
by tunit: egen numpersons = count(a_lineno) // fixme: does this really give the number of individuals in tax unit?
by tunit: egen tot_wt = sum(marsupwt)
by tunit: gen dweght=tot_wt/numpersons

* Modifications Antoine (Nov 2016)
* we compute the weight for the main earner: we will keep the value of the first observation in collapse
* if couple: average of both spouses'weights
cap drop dweght
*sort h_seq a_famtyp a_famrel a_age
sort tunit a_famtyp a_famrel a_age
by tunit : gen dweght = marsupwt if a_spouse == 0
by tunit : replace dweght = (marsupwt + marsupwt[a_spouse])/2 if a_spouse !=0
/*
        ----------------------------------------------------------------
		Calculates total income for the tax unit.
        ----------------------------------------------------------------

Tax Policy Center creates its own total income variable, not ptotval. They are different in that
ptotval includes more sources of income.

Note that income differs from totinc in that it excludes social security benefits,
as defined by tax law to define filing thresholds.

*/

egen ptotinc=rsum(wsal_val int_val div_val alm_val semp_val rtm_val rnt_val frse_val uc_val ss_val)
by tunit: egen totincx = sum(ptotinc)

/*
        ----------------------------------------------------------------
		Determine eligibility for head of household filing status.
        ----------------------------------------------------------------

This procedure follows a mixture between tax law definition and Tax Policy Center,
which are not exactly the same. Recall that IRS's 3 conditions for being a
head of household are (i) unmarried individuals, (ii) paying >50% of cost
of keeping up a home for the year, and (iii) living with a "qualifying person" - or
having a dependent parent.

*/

*replace js = 3 if js==1 & (ptotinc/totincx > 0.25) & depne>0 & dependent==0  & ptotinc>0

gen filst_temp = 0
replace filst_temp = 1 if tu_income >= amount
if `year'<=1975 replace filst_temp = 1 if tu_inctotal2>= amount //because pre-1976 CPS codes negative too much stuff
* SAEZ: remove this line 2/2016 to get more small wage earners
* if `year'>=1964 & `year'<1976 replace filst_temp = 1 if tu_wages>0 // if income is withheld, files to get tax refund
replace filst_temp = 1 if (a_maritl==3 & tu_income >= inctest) // threshold for married filing separately
replace filst_temp = 1 if (tu_business < 0 | tu_farm < 0 | tu_rents < 0) // files if has negative self-employment income, farm income or rents
if `year'>=1964 & `year'<1976 replace filst_temp = 1 if tu_interest<0 // since rents are included in interest these years
replace filst_temp = 1 if depfile == 1 // by construction,  dependent who must file files
replace filst_temp = 1 if tu_business>=400 // files if self-employment income is more than $400 (IRS tax law)
replace filst_temp = 1 if tu_ssfile>=ssincth // files if social security income is above a threshold (IRS tax law)
* SAEZ: modify this following EITC line 2/2016 to add xkids>0 condition to get single wage earners with no kids as non-filers
if `year'>=1976 replace filst_temp = 1 if tu_eitcinc>0 & xkids>0 // because post IRS year 1975 you can file to receive EITC
if `year'>=1997 replace filst_temp = 1 if childcred>0 // refundable child tax credit
replace filst_temp = 1 if agede>0 & (tu_retirement>0 | tu_dsab>0) // senior adjustment (varies by year)
if `year'>=1971 & `year'<1976 replace filst_temp = 1 if agede>0 & tu_income>1500
if `year'>=1980 & `year'<1987 replace filst_temp = 1 if agede>0 & tu_income>7500
if `year'>=1987 & `year'<1994 replace filst_temp = 1 if agede>0 & tu_income>5500
if `year'>=1994 & `year'<1998 replace filst_temp = 1 if agede>0 & tu_income>3500
if `year'>=1998 & `year'<2001 replace filst_temp = 1 if agede>0 & tu_income>2000
if `year'>=2001 & `year'<2004 replace filst_temp = 1 if agede>0 & tu_income>500
if `year'>=2004 & `year'<2007 replace filst_temp = 1 if agede>0 & tu_income>250
if `year'>=2007 replace filst_temp = 1 if agede>0 & tu_income>0

gen filingst = . // tax filer status
replace filingst = 1 if married==1 & filst_temp==1 & agede==0
replace filingst = 2 if married==1 & filst_temp==1 & agede==1
replace filingst = 3 if married==1 & filst_temp==1 & agede==2
replace filingst = 4 if head==1 & filst_temp==1
replace filingst = 5 if single==1 & filst_temp==1
replace filingst = 6 if filst_temp==0
label var filingst "Tax Filer Status - filing thresholds"
label define filingst_temp  1 "Joint, both <65" 2 "Joint, one <65 &  one 65+" 3 "Joint, both 65+" 4 "Head of household" 5 "Single" 6 "Nonfiler"
label values filingst filingst_temp

gen filenotunit = 0 // filer aged under 20 is not a tax unit
replace filenotunit = 1 if a_age<20 & a_spouse==0 & filingst!=6 & a_parent!=0
label var filenotunit "Tax filers who are not tax units"

if `year'>=2005 do $dirprograms/simulator/sub_snap_cps `year' // determines SNAP/SSI eligibility (currently from 2005 onwards)
if `year'<2005 gen numkid=.
if `year'<2005 gen hasdisable=.
if `year'<2005 gen snap_eligible=.
if `year'<2005 gen ssi_eligible=.
if `year'<2005 gen haselder=.
if `year'<2005 gen snap_ben=.
if `year'<2005 gen ssi_ben=.


gen young = (a_age<20)
gen wages = tu_wages
gen peninc = tu_retirement
gen ssinc = tu_ss
gen dsab=tu_dsab
gen uiinc = tu_unemp
gen seinc = tu_business
gen intinc = tu_interest
gen divinc = tu_dividends
gen farminc = tu_farm
gen alminc = tu_alimony
gen inctot = tu_inctotal

gen moneyinctot = tu_totinc // (AA)
cap drop agi
gen agi = inctot
gen owner = 0
replace owner = 1 if (h_tenure==1 & (a_famrel==1 | a_famrel==0))
gen files = (filingst<6)
gen female=(a_sex==2)
gen xded = depne
gen marriedsep=(a_maritl==3)
gen rentinc = tu_rents
gen ssiinc = tu_ssi
gen welfrinc = tu_welfr
gen estinc=tu_estinc

/*
        ----------------------------------------------------------------
		Generate top coding indicator for income variables
		----------------------------------------------------------------
*/

gen topcode=.
replace topcode=99900 if year<1968
replace topcode=50000 if year>=1968 & year<1982
replace topcode=75000 if year>=1982 & year<1985
replace topcode=99999 if year>=1985 & year<1988
replace topcode=199998 if year>=1988 & year<1996

foreach var in wage peninc seinc dsab divinc intinc rentinc{
gen topcoded_`var' = 0
}
if `year'>=1996 replace topcoded_wage = tcwsval
if `year'<1996 replace topcoded_wage = (wsal_val==topcode)

if `year'>=1999 replace topcoded_peninc = (tretval1==1 | tretval2==1)
if `year'<1999 replace topcoded_peninc = (rtm_val==topcode)

if `year'>=1996 replace topcoded_seinc = tcseval
if `year'<1996 replace topcoded_seinc = (semp_val==topcode)

if `year'>=1999 replace topcoded_divinc = tdiv_val
if `year'<1999 replace topcoded_divinc = (div_val==topcode)

if `year'>=1999 replace topcoded_intinc = tint_val
if `year'<1999 replace topcoded_intinc = (int_val==topcode)

if `year'>=1999 replace topcoded_rentinc = trnt_val
if `year'<1999 replace topcoded_rentinc = (rnt_val==topcode)

if `year'>=1999 replace topcoded_dsab = (tdisval1==1 | tdisval2==1)
if `year'<1999 replace topcoded_dsab = (dsab_val==topcode)

/*
        ----------------------------------------------------------------
		For married tax units, split income variables between spouses.
		Code missing if single.
        ----------------------------------------------------------------
*/
sort tunit married a_sex

foreach var in wage peninc ssinc uiinc seinc dsab{
gen `var'_husband = .
gen `var'_wife = .
}

replace wage_husband = wsal_val if a_sex==1 & a_spouse!=0
replace peninc_husband = rtm_val if a_sex==1 & a_spouse!=0
replace ssinc_husband = ss_val if a_sex==1 & a_spouse!=0
replace uiinc_husband = uc_val if a_sex==1 & a_spouse!=0
replace seinc_husband = max(0,semp_val) if a_sex==1 & a_spouse!=0
replace dsab_husband = dsab_val if a_sex==1 & a_spouse!=0

by tunit: replace wage_husband = wsal_val[_n-1] if a_sex==2 & a_spouse!=0
by tunit: replace peninc_husband = rtm_val[_n-1] if a_sex==2 & a_spouse!=0
by tunit: replace ssinc_husband = ss_val[_n-1] if a_sex==2 & a_spouse!=0
by tunit: replace uiinc_husband = uc_val[_n-1] if a_sex==2 & a_spouse!=0
by tunit: replace seinc_husband = max(0,semp_val[_n-1]) if a_sex==2 & a_spouse!=0
by tunit: replace dsab_husband = dsab_val[_n-1] if a_sex==2 & a_spouse!=0

foreach var in wage peninc seinc dsab divinc intinc rentinc{
gen topcoded_`var'_husband = .
replace topcoded_`var'_husband = topcoded_`var' if a_sex==1 & a_spouse!=0
by tunit: replace topcoded_`var'_husband = topcoded_`var'[_n-1] if a_sex==2 & a_spouse!=0
}

gsort tunit married -a_sex

replace wage_wife = wsal_val if a_sex==2 & a_spouse!=0
replace peninc_wife = rtm_val if a_sex==2 & a_spouse!=0
replace ssinc_wife = ss_val if a_sex==2 & a_spouse!=0
replace uiinc_wife = uc_val if a_sex==2 & a_spouse!=0
replace seinc_wife = max(0,semp_val) if a_sex==2 & a_spouse!=0
replace dsab_wife = dsab_val if a_sex==2 & a_spouse!=0

by tunit: replace wage_wife = wsal_val[_n-1] if a_sex==1 & a_spouse!=0
by tunit: replace peninc_wife = rtm_val[_n-1] if a_sex==1 & a_spouse!=0
by tunit: replace ssinc_wife = ss_val[_n-1] if a_sex==1 & a_spouse!=0
by tunit: replace uiinc_wife = uc_val[_n-1] if a_sex==1 & a_spouse!=0
by tunit: replace seinc_wife = max(0,semp_val[_n-1]) if a_sex==1 & a_spouse!=0
by tunit: replace dsab_wife = dsab_val[_n-1] if a_sex==1 & a_spouse!=0

foreach var in wage peninc seinc dsab divinc intinc rentinc{
gen topcoded_`var'_wife = .
replace topcoded_`var'_wife = topcoded_`var' if a_sex==2 & a_spouse!=0
by tunit: replace topcoded_`var'_wife = topcoded_`var'[_n-1] if a_sex==1 & a_spouse!=0
}

/*
        ----------------------------------------------------------------
		Age of dependent kids (agedepk) and dependents (agedep)
        ----------------------------------------------------------------
*/
sort h_seq a_age
by h_seq: gen depk_temp=_n if depkid==1 // Note that for previous years no info for kids below age 14...
forvalues i = 1/11{
by h_seq: egen agedepk`i' = max(cond(depk_temp == `i', a_age, .))
}

gsort h_seq -dependent a_age
by h_seq: gen dep_temp=_n if dependent==1
forvalues i=1/13{
by h_seq: egen agedep`i' = max(cond(dep_temp == `i', a_age, .))
}

forvalues i=1/11{
replace agedepk`i'=. if depfile==1
replace agedep`i'=. if depfile==1
replace agedepk`i'=. if idxhigh==0
replace agedep`i'=. if idxhigh==0
replace agedep12=. if depfile==1
replace agedep13=. if depfile==1
replace agedep12=. if idxhigh==0
replace agedep13=. if idxhigh==0
}

sort tunit a_famrel

cap drop oldexm
by tunit: egen oldexm =max(cond(a_age>=65 & ( a_sex==1 | (a_sex==2 & a_spouse==0) ) & dependent==0, 1, 0))
by tunit: egen oldexf =max(cond(a_age>=65 & a_sex==2 & a_spouse!=0 & dependent==0, 1, 0))
by tunit: replace oldexf=. if ( (a_sex==2 & a_spouse==0) | (a_sex==1 & a_spouse==0) )

by tunit: egen adc=max(afdc)

by tunit: egen penplanm =max(cond(a_sex==1 | (a_sex==2 & a_spouse==0)),penplan,.)
by tunit: egen penplanf =max(cond(a_sex==2 & a_spouse!=0), penplan,.)
by tunit: replace penplanf=. if ( (a_sex==2 & a_spouse==0) | (a_sex==1 & a_spouse==0) )

by tunit: egen hiempm =max(cond(a_sex==1 | (a_sex==2 & a_spouse==0)),hiemp,.)
by tunit: egen hiempf =max(cond(a_sex==2 & a_spouse!=0), hiemp,.)
by tunit: replace hiempf=. if ( (a_sex==2 & a_spouse==0) | (a_sex==1 & a_spouse==0) )

* Add GZ March 2016
	cap drop vet
	by tunit: egen vet = sum(veteran)
	replace vet = min(1, vet)
	by tunit: egen tu_vet = sum(vet_val)
	by tunit: egen nbmaid = sum(hasmaid)
	by tunit: egen tu_tanf = sum(tanf_val)


gen waginc = wages
egen othinc_imp_temp=rsum(seinc waginc peninc intinc divinc rentinc farminc alminc estinc)
gen othinc_imp=agi-othinc_imp_temp
drop othinc_imp_temp
gen aux=.
	replace aux=1 if (filingst==1 | filingst==2| filingst==3)
	replace aux=2 if filingst==4
	replace aux=3 if filingst==5
	replace aux=4 if filingst==6

* Tax-unit level collapse
*(comment one of the two collapse commands. First keeps the first observation variables; second sum over members of tax unit)
*(comment one of the two saveold commands at the end of the file, line 1677)
	sort tunit aux a_famrel

if $indiv_sum == 0{ // 0 if tax unit incomes are only income of main earner / spouses.
* Addition of moneyinctot (tax unit money income) to the tax-unit-level CPS saved files (antoine - Oct 2016)
* Note: inctot is equal to tu_inctotal which is not the same definition of income as totinc (money income)

	collapse (first) h_seq year married single head female age age_spouse marriedsep ///
	wages waginc peninc ssinc uiinc seinc intinc agi inctot moneyinctot divinc rentinc farminc estinc alminc othinc_imp numkid ///
	xkids dweght marsupwt agedep* oldex* files young filenotunit filingst dependent ///
	depfile *_husband *_wife a_sex student owner xded hmcaid ssiinc ///
	hpublic hfoodsp f_mv_fs hflunch henrgyas henrgyva hrwicyn welfrinc adc dsab vet tu_vet tu_tanf nbmaid ///
	penplanm penplanf hiempm hiempf hasdisable snap_eligible ssi_eligible haselder snap_ben ssi_ben (sum) ptotval, by(tunit)

	by tunit: assert _N == 1 // check that there is only one observation per tax unit after collapse

	* Added tu_totinc (renamed moneyinctot) in collapse in order to save it
}
if $indiv_sum == 1{ // 1 if computing incomes by summing over all members
* Tax-unit level collapse with sum of individual variables (instead of first obersavtion only) / AA Nov 2016
gen semp_val_positive = max(0,semp_val) // self employment (business income), only if positive
gen welfare_perso = welfr_val + f_mv_fs // individual welfare benefits
gen wage_inc_val = wsal_val
gen agi_val = inctotal

	collapse (first) dweght marsupwt h_seq  year married single head female age age_spouse marriedsep agedep* oldex* files young filenotunit filingst  ///
	(sum) wsal_val wage_inc_val rtm_val ss_val uc_val semp_val_posit int_val agi_val inctotal ptotval div_val rnt_val frse_val sur_temp alm_val othinc_imp numkid ///
	xkids  dependent ///
	depfile *_husband *_wife a_sex student owner xded hmcaid ///
	ssi_val ///
	hpublic hfoodsp f_mv_fs hflunch henrgyas henrgyva hrwicyn ///
	welfare_perso ///
	adc dsab vet ///
	vet_val tanf_val nbmaid ///
	penplanm penplanf hiempm hiempf hasdisable snap_eligible ssi_eligible haselder snap_ben ssi_ben, by(tunit)

	by tunit: assert _N == 1 // check that there is only one observation per tax unit after collapse
}



/*
        ----------------------------------------------------------------
		Adjust weights to match IRS microdata
		XX abandonned; weight adjustment now done in nonfilerappend.do XX
        ----------------------------------------------------------------
*/

/*
gen dweght_adj=.
replace dweght_adj=dweght if oldexm==0 & oldexf==0 & married==1 & filingst==6
replace dweght_adj=dweght if oldexm==0 & married==0 & filingst==6
*/

/*
gen dweght_adj=dweght
if `year'==1963 replace dweght_adj=dweght*1.9220202479 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1965 replace dweght_adj=dweght*1.5379100569 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1967 replace dweght_adj=dweght*1.8526352672 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1968 replace dweght_adj=dweght*1.0892050472 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1969 replace dweght_adj=dweght*1.1349540972 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1970 replace dweght_adj=dweght*1.1300459421 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1971 replace dweght_adj=dweght*1.0906321949 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1972 replace dweght_adj=dweght*1.3364435994 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1973 replace dweght_adj=dweght*1.2821531832 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1974 replace dweght_adj=dweght*1.2728274461 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1975 replace dweght_adj=dweght*1.3563155179 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1976 replace dweght_adj=dweght*1.3031570024 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1977 replace dweght_adj=dweght*1.2600859536 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1978 replace dweght_adj=dweght*1.3371930802 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1979 replace dweght_adj=dweght*1.3046890335 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1980 replace dweght_adj=dweght*1.3077955025 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1981 replace dweght_adj=dweght*1.3947688476 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1982 replace dweght_adj=dweght*1.2908378410 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1983 replace dweght_adj=dweght*1.2547127215 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1984 replace dweght_adj=dweght*1.2327803248 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1985 replace dweght_adj=dweght*1.1285505101 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1986 replace dweght_adj=dweght*1.0784588939 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1987 replace dweght_adj=dweght*1.1552989730 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1988 replace dweght_adj=dweght*1.3653145823 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1989 replace dweght_adj=dweght*1.3650671514 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1990 replace dweght_adj=dweght*1.3069188345 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1991 replace dweght_adj=dweght*1.2810356866 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1992 replace dweght_adj=dweght*1.2928377493 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1993 replace dweght_adj=dweght*1.2879671888 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1994 replace dweght_adj=dweght*1.3301674778 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1995 replace dweght_adj=dweght*1.2538936357 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1996 replace dweght_adj=dweght*1.2858958959 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1997 replace dweght_adj=dweght*0.9740477408 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1998 replace dweght_adj=dweght*1.0292877229 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==1999 replace dweght_adj=dweght*1.1481048788 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==2000 replace dweght_adj=dweght*1.0921684250 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==2001 replace dweght_adj=dweght*0.9451277089 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==2002 replace dweght_adj=dweght*0.9535555130 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==2003 replace dweght_adj=dweght*0.8955888872 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==2004 replace dweght_adj=dweght*0.9730781173 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==2005 replace dweght_adj=dweght*0.8331179486 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==2006 replace dweght_adj=dweght*0.7548836732 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==2007 replace dweght_adj=dweght*0.7306163901 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'==2008 replace dweght_adj=dweght*0.5781843517 if (oldexm==1 | oldexf==1) & married==1 & filingst==6
if `year'>=2009 replace dweght_adj=dweght*0.6633914837 if (oldexm==1 | oldexf==1) & married==1 & filingst==6

if `year'==1963 replace dweght_adj=dweght*1.4166581315 if oldexm==1 & married==0 & filingst==6
if `year'==1965 replace dweght_adj=dweght*0.9507415037 if oldexm==1 & married==0 & filingst==6
if `year'==1967 replace dweght_adj=dweght*0.9266147145 if oldexm==1 & married==0 & filingst==6
if `year'==1968 replace dweght_adj=dweght*1.0201370238 if oldexm==1 & married==0 & filingst==6
if `year'==1969 replace dweght_adj=dweght*1.0570637588 if oldexm==1 & married==0 & filingst==6
if `year'==1970 replace dweght_adj=dweght*1.0399970132 if oldexm==1 & married==0 & filingst==6
if `year'==1971 replace dweght_adj=dweght*1.0365121725 if oldexm==1 & married==0 & filingst==6
if `year'==1972 replace dweght_adj=dweght*1.1204050940 if oldexm==1 & married==0 & filingst==6
if `year'==1973 replace dweght_adj=dweght*1.0693703317 if oldexm==1 & married==0 & filingst==6
if `year'==1974 replace dweght_adj=dweght*1.0832304866 if oldexm==1 & married==0 & filingst==6
if `year'==1975 replace dweght_adj=dweght*1.0864739398 if oldexm==1 & married==0 & filingst==6
if `year'==1976 replace dweght_adj=dweght*1.1169255794 if oldexm==1 & married==0 & filingst==6
if `year'==1977 replace dweght_adj=dweght*1.1385046093 if oldexm==1 & married==0 & filingst==6
if `year'==1978 replace dweght_adj=dweght*1.1464184936 if oldexm==1 & married==0 & filingst==6
if `year'==1979 replace dweght_adj=dweght*1.1597551643 if oldexm==1 & married==0 & filingst==6
if `year'==1980 replace dweght_adj=dweght*1.1223509433 if oldexm==1 & married==0 & filingst==6
if `year'==1981 replace dweght_adj=dweght*1.1212359606 if oldexm==1 & married==0 & filingst==6
if `year'==1982 replace dweght_adj=dweght*1.0663910598 if oldexm==1 & married==0 & filingst==6
if `year'==1983 replace dweght_adj=dweght*1.0191420782 if oldexm==1 & married==0 & filingst==6
if `year'==1984 replace dweght_adj=dweght*1.0290753411 if oldexm==1 & married==0 & filingst==6
if `year'==1985 replace dweght_adj=dweght*1.0754237780 if oldexm==1 & married==0 & filingst==6
if `year'==1986 replace dweght_adj=dweght*1.0589362883 if oldexm==1 & married==0 & filingst==6
if `year'==1987 replace dweght_adj=dweght*0.9892481263 if oldexm==1 & married==0 & filingst==6
if `year'==1988 replace dweght_adj=dweght*0.9616127303 if oldexm==1 & married==0 & filingst==6
if `year'==1989 replace dweght_adj=dweght*0.9604231165 if oldexm==1 & married==0 & filingst==6
if `year'==1990 replace dweght_adj=dweght*0.9734872208 if oldexm==1 & married==0 & filingst==6
if `year'==1991 replace dweght_adj=dweght*0.9838772644 if oldexm==1 & married==0 & filingst==6
if `year'==1992 replace dweght_adj=dweght*0.9547914650 if oldexm==1 & married==0 & filingst==6
if `year'==1993 replace dweght_adj=dweght*0.9389780003 if oldexm==1 & married==0 & filingst==6
if `year'==1994 replace dweght_adj=dweght*1.0044975968 if oldexm==1 & married==0 & filingst==6
if `year'==1995 replace dweght_adj=dweght*0.9978016647 if oldexm==1 & married==0 & filingst==6
if `year'==1996 replace dweght_adj=dweght*0.9996198844 if oldexm==1 & married==0 & filingst==6
if `year'==1997 replace dweght_adj=dweght*1.0327696895 if oldexm==1 & married==0 & filingst==6
if `year'==1998 replace dweght_adj=dweght*1.1073579956 if oldexm==1 & married==0 & filingst==6
if `year'==1999 replace dweght_adj=dweght*1.0448272807 if oldexm==1 & married==0 & filingst==6
if `year'==2000 replace dweght_adj=dweght*1.0319369518 if oldexm==1 & married==0 & filingst==6
if `year'==2001 replace dweght_adj=dweght*1.0730003313 if oldexm==1 & married==0 & filingst==6
if `year'==2002 replace dweght_adj=dweght*1.1214357795 if oldexm==1 & married==0 & filingst==6
if `year'==2003 replace dweght_adj=dweght*1.1289328081 if oldexm==1 & married==0 & filingst==6
if `year'==2004 replace dweght_adj=dweght*1.1592201704 if oldexm==1 & married==0 & filingst==6
if `year'==2005 replace dweght_adj=dweght*1.1920361305 if oldexm==1 & married==0 & filingst==6
if `year'==2006 replace dweght_adj=dweght*1.1992714681 if oldexm==1 & married==0 & filingst==6
if `year'==2007 replace dweght_adj=dweght*1.3255169545 if oldexm==1 & married==0 & filingst==6
if `year'==2008 replace dweght_adj=dweght*1.1682289616 if oldexm==1 & married==0 & filingst==6
if `year'>=2009 replace dweght_adj=dweght*1.1845814653 if oldexm==1 & married==0 & filingst==6


rename dweght dweght_old
rename dweght_adj dweght
*/

if $indiv_sum == 0{
label var h_seq "Household id"
label var year "CPS year"
label var married "Married dummy"
label var single "Single dummy"
label var head "Head dummy"
label var female "Dummy for being female"
label var age "Age (male)"
label var age_spouse "Age of spouse (female)"
label var marriedsep "Married with spouse absent"
label var wages "Wages"
label var peninc "Retirement income"
label var intinc "Interest income"
label var divinc "Dividend income"
label var ssinc "Social security income (includes SS disability)"
label var uiinc "Unemployment income"
label var seinc "Self-employed income (positive)"
label var rentinc "Rent income (Rent+Royalties+Estates+Trusts)"
label var farminc "Farm income"
label var alminc "Alimony income"
label var estinc "Survivor income: Regular payments from estates or trusts"
label var inctot "Total income (exc. uiinc & ssinc)"
label var othinc_imp "Other income (imputed)"
label var agi "Total income (exc. uiinc & ssinc) - same as inctot"
* label var ssa "Social security income (excludes DSAB)"
label var dsab "Disability income (excludes SS disability payments)"
label var xkids "Total number children at home among dependents"
label var dweght "Tax unit weight (average)"
*label var dweght_old "Tax unit weight (average)"
label var marsupwt "March Supplement Weight"
label var agedepk1 "Age of 1st dependent kid"
label var agedepk2 "Age of 2nd dependent kid"
label var agedepk3 "Age of 3rd dependent kid"
label var agedepk4 "Age of 4th dependent kid"
label var agedepk5 "Age of 5th dependent kid"
label var agedepk6 "Age of 6th dependent kid"
label var agedepk7 "Age of 7th dependent kid"
label var agedepk8 "Age of 8th dependent kid"
label var agedepk9 "Age of 9th dependent kid"
label var agedepk10 "Age of 10th dependent kid"
label var agedepk11 "Age of 11th dependent kid"
label var agedep1 "Age of 1st dependent"
label var agedep2 "Age of 2nd dependent"
label var agedep3 "Age of 3rd dependent"
label var agedep4 "Age of 4th dependent"
label var agedep5 "Age of 5th dependent"
label var agedep6 "Age of 6th dependent"
label var agedep7 "Age of 7th dependent"
label var agedep8 "Age of 8th dependent"
label var agedep9 "Age of 9th dependent"
label var agedep10 "Age of 10th dependent"
label var agedep11 "Age of 11th dependent"
label var agedep12 "Age of 12th dependent"
label var agedep13 "Age of 13th dependent"
label var oldexm "Dummy for primary filer being 65+"
label var oldexf "Dummy for secondary filer being 65+"
label var files "Tax filer dummy"
label var young "Under age 20"
label var filenotunit "Filer not considered a tax unit (old)"
label var filingst "Filing status"
label var dependent "Dummy for primary filer being a dependent on somebody else's return"
label var depfile "Dependent filer"
label var wage_husband "Husband wage income (missing if single)"
label var wage_wife "Wife wage income (missing if single)"
label var peninc_husband "Husband pension income (missing if single)"
label var peninc_wife "Wife pension income (missing if single)"
label var ssinc_husband "Husband social security income (missing if single)"
label var ssinc_wife "Wife social security income (missing if single)"
label var uiinc_husband "Husband unemployment income (missing if single)"
label var uiinc_wife "Wife unemployment income (missing if single)"
label var seinc_husband "Husband self-employment income (missing if single)"
label var seinc_wife "Wife self-employment income (missing if single)"
label var dsab_husband "Husband disability income (missing if single)"
label var dsab_wife "Wife disability income (missing if single)"
label var topcoded_wage_husband "Topcoded husband wage dummy"
label var topcoded_wage_wife "Topcoded wife wage dummy"
label var topcoded_peninc_husband "Topcoded husband pension inc dummy"
label var topcoded_peninc_wife "Topcoded wife pension income dummy"
label var topcoded_seinc_husband "Topcoded husband self-employment income dummy"
label var topcoded_seinc_wife "Topcoded wife self-employment income dummy"
label var topcoded_dsab_husband "Topcoded husband disability income dummy"
label var topcoded_dsab_wife "Topcoded wife disability income dummy"
label var topcoded_divinc_husband "Topcoded husband dividend income dummy"
label var topcoded_divinc_wife "Topcoded wife dividend income dummy"
label var topcoded_intinc_husband "Topcoded husband interest income dummy"
label var topcoded_intinc_wife "Topcoded wife interest income dummy"
label var topcoded_rentinc_husband "Topcoded husband rent income dummy"
label var topcoded_rentinc_wife "Topcoded wife rent income dummy"
label var xded "Number of dependents at home"
label var a_sex "Sex of CPS reference person (1 male, 2 female)"
label var owner "Owner or becoming owner of house dummy"
* label var a_age "Age of CPS reference person"
label var student "Student dummy"
label var hmcaid "Anyone in hh covered by Medicaid"
label var nbmaid "Number of individuals covered by Medicaid in tax unit"
label var ssiinc "Supplemental Security Income"
label var hpublic "Public housing project"
label var hfoodsp "Food stamp recipient hh"
label var f_mv_fs "Family market value food stamps"
label var hflunch "Children in hh receiving free lunch"
label var henrgyas "Energy assistance hh benefits"
label var henrgyva "Energy assistance hh income"
label var hrwicyn "WIC benefits in hh"
label var welfrinc "Welfare income"
label var adc "AFDC/ADC"
label var penplanm "Pension plan filer"
label var penplanf "Pension plan wife"
label var hiempm "Health insurance by employer filer"
label var hiempf "Health insurance by employer wife"
label var numkid "Number of related children under age 18"
label var hasdisable "Has disabled member"
label var waginc "Wage income (same as wages)"
label var snap_eligible "Dummy for eligible to receive SNAP"
label var ssi_eligible "Dummy for eligible to receive SSI"
label var haselder "Dummy for having elder member"
label var snap_ben "Amount of SNAP benefits"
label var ssi_ben "Amount of SSI benefits"
label variable vet "Receives veterans' benefit payments"
label variable tu_vet "Amounts of veterans' benefit payments (separated from UI and workers' comp since 1988 only)"
label variable tu_tanf "Amount of AFDC / TANF benefit payments"
* Addition of label for moneyinctot (AA, Oct 2016)
label variable moneyinctot  "Money income (summed over tax unit members)" // sumed over tax-unit line 391.
}

* Old x married variable used to construct matrices below
	cap gen oldexm=(age>=65)
		cap label drop old
		label define old 0 "65less" 1 "65plus"
		label values oldexm old
	cap label drop matstatus
		label define matstatus 0 "sing" 1 "marr"
		label values married matstatus
	cap drop oldmar
	egen oldmar=group(married oldexm), label
		label variable oldmar "Married x 65+ dummy"

compress
*XX add pinctot summed over members of tax unit (GZ)
* -> pinctot is the name from 1980 to 1897. In previous years the name is income. After 1987, new name is ptotval. (AA)
* -> summation over tax units -> "tu_totinc" -> renamed moneyinctot (AA)
if $indiv_sum == 0 saveold $dirnonfilers/cpsmar`year'.dta, replace // save tax-unit level CPS
if $indiv_sum == 1 saveold $dirnonfilers/indiv_variables/cpsmar`year'.dta, replace // save tax-unit level CPS with sum of individual data (AA)
}
*

* Observations:
* In CPS, married single and head are mutually excludable, while they are not in IRS:
* IRS married dummy includes  qualifying widowers since 2000, while these would be either single or head in CPS
* IRS xkids uses total deps pre-78





*/


****************************************************************************************************************************************************************
*
* CREATE MATRICES FOR IMPUTATIONS INTO DINA
*
****************************************************************************************************************************************************************

* All loops run over yr = year CPS was conducted (yr = 2006 means CPS March 2006)
* At the end we save matrices in .xlsx using income_yr = yr - 1 (income_yr = 2005 means 2005 income, as registered in 2006 CPS)

********************************************************************************
* SPOUSAL SPLIT FOR WAGES
********************************************************************************



foreach yr of numlist 1962/$cpsendyear {
*foreach yr of numlist 2000 {

matrix input perc = (0 .1 .2 .3 .4 .5 .6 .7 .8 .9 .95 .99 .999 .9999 1)
matrix input shfem = (-.01 0 .05 .25 .5 .75 .9999 1)
local shnum=colsof(shfem)
local percnum=colsof(perc)

matrix wagsp`yr' = J(`percnum'+1,`shnum'+1,.)
matrix wagsp`yr'[1,1]=`yr'-1
local percnum2=`percnum'-1
local shnum2=`shnum'-1
foreach pc of numlist 1/`percnum2' {
    matrix wagsp`yr'[`pc'+2,1]=perc[1,`pc']
    matrix wagsp`yr'[`pc'+2,2]=perc[1,`pc'+1]
    }

use $dirnonfilers/cpsmar`yr'.dta, clear
keep if married==1
rename wage_husband wage_m
rename wage_wife wage_f
replace dweght=round(dweght)

* XX need to add a top code here, looks like top code is always above P95 for males
replace wage_m=0 if wage_m==.
replace wage_f=0 if wage_f==.
replace wages=wage_m+wage_f
quietly: sum wage_m [w=dweght] if wage_m>0, detail
display "MARCH `yr' CPS"   "Male P99 = " r(p99) "Male P95 = " r(p95)
gen share_fcps=wage_f/wages
gen aux=wages
set seed 4343241
replace aux=aux+runiform()/2 if wages>0
cumul aux [w=dweght] if married==1 & wages>0, gen(rankw)

foreach sh of numlist 1/`shnum2' {
    local shmin=shfem[1,`sh']
    local shmax=shfem[1,`sh'+1]
    matrix wagsp`yr'[1,2+`sh']=`shmin'
    matrix wagsp`yr'[2,2+`sh']=`shmax'
    foreach pc of numlist 1/`percnum2' {
        local pcmin=perc[1,`pc']
        local pcmax=perc[1,`pc'+1]
        quietly sum wage_f [w=dweght] if rankw!=. & rankw>`pcmin' & rankw<=`pcmax'
        local denom=r(sum_w)
        quietly sum wage_f [w=dweght] if rankw!=. & rankw>`pcmin' & rankw<=`pcmax' & wage_f/wages>`shmin' & wage_f/wages<=`shmax'
        matrix wagsp`yr'[2+`pc',2+`sh']=r(sum_w)/`denom'
        }
    }

matrix list wagsp`yr'
xsvmat double wagsp`yr', fast names(col)
mkmat _all, mat(wagsp`yr')
local income_yr=`yr'-1
outsheet using  "$dirmatrix/wagmat/wagcps`income_yr'.xls", replace


}



********************************************************************************
* Distribution of cash benefits: Social security, SSI, SNAP, Veteran benefits, TANF/AFDC
********************************************************************************

* Load total benefits for CPS income year 
global end_income_yr= $cpsendyear - 1
foreach income_yr of numlist 1961/$end_income_yr  {
	* import excel using "$root/DINA(Aggreg).xlsx", sheet(ParametersStata) clear  firstrow
	insheet using "$parameters", clear names
		local yr = `income_yr' + 1
		keep if yr == `income_yr'
		keep tt*
		foreach var of varlist _all {
			local `var'`yr'=`var'
		}
	}

* Create matrices when data exist
	foreach compo in ss ssi snap vet tanf {
		local first = 1962
		if 	"`compo'" == "ssi" {
			local first = 1976
		}
		if 	"`compo'" == "snap" {
			local first = 1980
		}
		if 	"`compo'" == "vet" {
			local first = 1988
		}
		if 	"`compo'" == "tanf" {
			local first = 1980
		}
		foreach yr of numlist `first'/$cpsendyear {
			use $dirnonfilers/cpsmar`yr'.dta, clear
			quietly {
				rename inctot  income
				rename tu_vet  vetinc
				rename tu_tanf tanfinc
				cap rename f_mv_fs snapinc
				replace dweght=round(dweght)
				* memo: inctot = agi = waginc + peninc + seinc + intinc + divinc + rentinc + farminc + estinc + othinc_imp
				gen has`compo'inc = (`compo'inc>0 & `compo'inc!=.)
				if "`compo'" == "tanf" keep if xkids>0 & xkids!=.
				crosstab income has`compo'inc [w=dweght] if income >=0, by(oldmar) matname(frq`compo'inc`yr')
				crosstab income `compo'inc [w=dweght] if has`compo'inc == 1 & income >=0, by(oldmar) matname(avg`compo'inc`yr')
			}
			mat list frq`compo'inc`yr'
			di "FRACTION OF TAX UNITS WITH `compo' IN `yr' BY INCOME DECILE X MARRIED X 65+"
			mat list avg`compo'inc`yr'
			di "AVERAGE `compo'INC OF TAX UNITS WITH POSITIVE `compo' IN `yr' BY INCOME DECILE X MARRIED X 65+"

		}
	
	if 	"`compo'" == "vet" { // Dummy for receipt of veterans' benefits exists before 1987
		foreach yr of numlist 1969 1971/1987 {
			use $dirnonfilers/cpsmar`yr'.dta, clear
			quietly {
				rename inctot income
				replace dweght=round(dweght)
				crosstab income vet [w=dweght], by(oldmar) matname(frqvetinc`yr')
			}
			mat list frqvetinc`yr'
			di "FRACTION OF TAX UNITS RECEIVING VETERANS' BENEFITS IN `yr' BY INCOME DECILE X MARRIED X 65+"
		}
	}
	}

* Missing years. SNAP starts in 1966 but in CPS sicnce 1980 only; SSI starts in 1947 (State-level only until 1975); AFDC/TANF in CPS only since 1980
	foreach compo in ssi snap tanf  {
		local lastmiss = `first' - 1
		foreach yr of numlist 1962/`lastmiss' {
			mat frq`compo'inc`yr' = frq`compo'inc`first'
			local adjust`yr' = `tt`compo'ben'`yr' / `tt`compo'ben'`first'
			mat avg`compo'inc`yr' = avg`compo'inc`first' * `adjust`yr''
		}
	}
	* Missing veteran benefits
		foreach yr of numlist 1962/1968 1970 {
			mat frqvetinc`yr' = frqvetinc1969
		}
		foreach yr of numlist 1962/1987 {
			local adjust`yr' = `ttvetben'`yr' / `ttvetben1988'
			mat avgvetinc`yr' = avgvetinc1988 * `adjust`yr''
		}

* 1962 and 1963 CPS files seem corrupt; replace by 1964
	foreach compo in ss ssi snap vet tanf  {
		foreach yr of numlist 1962 1963 {
			mat frq`compo'inc`yr' = frq`compo'inc1964
			local adjust`yr' = `tt`compo'ben'`yr' / `tt`compo'ben1964'
			mat avg`compo'inc`yr' = avg`compo'inc1964 * `adjust`yr''
		}
	}


*Replace missing values by 0 in matrix and save matrices 
	mat colnames avgtanfinc1999 = _0_65less  _0_65plus  _1_65less  _1_65plus // obscure bug that sometimes replaces 65plus by 65less
	mat colnames avgtanfinc2014 = _0_65less  _0_65plus  _1_65less  _1_65plus
	foreach compo in ss ssi snap vet tanf {
		foreach yr of numlist 1962/$cpsendyear  {
			local income_yr = `yr' - 1
				foreach m in frq`compo'inc avg`compo'inc  {
					forval j = 1/4 {
						forval i = 1/10 {
							if `m'`yr'[`i', `j'] == . {
		 						matrix `m'`yr'[`i', `j']= 0
		 					}
		 				}
		 			}
					clear
					svmat `m'`yr', names(col)
					gen decile = _n
					order decile
					export excel using "$dirmatrix/`m'`income_yr'.xlsx", first(var) replace
				}
			}
	}


********************************************************************************
* Medicaid
********************************************************************************

	foreach yr of numlist 1980/$cpsendyear {
		use $dirnonfilers/cpsmar`yr'.dta, clear
		qui replace dweght=round(dweght)
		qui rename inctot income
		* 	qui xtile decile = income [w=dweght], nq(10)
		qui cumul income [w=dweght], gen(rank_inc)
		matrix define cumul=(-1 \ 0.05 \ 0.1 \ 0.15 \ 0.2 \ 0.25 \ 0.50 \ .90 \ 1)
		local I = rowsof(cumul)-1
		qui gen incgroup = 0
		forval i = 1/`I' {
			qui replace incgroup = `i' if rank_inc > cumul[`i',1] & rank_inc <= cumul[`i'+1,1]
		}
		qui replace xkids=3 if xkids>=3
		qui replace nbmaid = 5 if nbmaid >=5
		cap qui egen cell = group(incgroup married xkids nbmaid)
		collapse (first) incgroup married xkids nbmaid (sum) dweght, by(cell)
		gsort incgroup married xkids nbmaid
		bysort incgroup married xkids: egen nb = sum(dweght)
		gen freq = dweght/nb
		drop cell dweght nb
		reshape wide freq, i(incgroup married xkids) j(nbmaid)
		foreach var of varlist freq* {
			replace `var' = 0 if `var' == .
		}
		local yearinc = `yr' - 1
		saveold $diroutput/temp/cps/medicaidcollapse`yearinc'.dta, replace
	}


********************************************************************************
* Employee fringe health and pension benefits (at individual worker level)
********************************************************************************

/*
* Health benefits in CPS
Benefits paid by employers is emcontrb
Whether covered or not is hiemp

Check total number of employees covered in macro data: use medical expenditure panel survey, Tables II.B.2. and II.B.2b
https://meps.ahrq.gov/data_stats/summ_tables/insr/state/series_2/2015/tiib2.pdf
https://meps.ahrq.gov/data_stats/summ_tables/insr/state/series_2/2015/tiib2b.pdf

In 2015, 47.8% of private sector employees are covered
There are 120m private sector employees
�> A bit less than 60 million have health insurance
Plus there are 23 million public sector employees (almost all of which have coverage)
�> total = about 80 million
hiemp == 1 for 87 million in 2015
but hipaid == 3 (i.e employer paid none of the health insurance) for 7 million ==> consistent with 80 million totals being effectively covered by employer
However, out of these 80 million, 7 million report having emcontrb = 0 �> we have emcontrb > 0 for 73 million only
We take encomtrb amounts with no correction (i.e., about 14 million are going to have emcontrb = 0 despite being enrolled in a group plan; this is dealt with by scaling the amounts to match macro); for frequencies take hiemp

* Pensions benefits in CPS
No data on amounts
Variable for being covered by company pension pan: penplan (company has pension plan for any of the employees) and penincl (pension plan participant)
�> correct variable is penincl
penincl from 1980 to 1987 = inclinpp

*/
*/
mat drop _all

* Load total benefits for CPS year (= income year + 1)
global end_income_yr= $cpsendyear - 1
foreach income_yr of numlist 1961/$end_income_yr {
	insheet using "$parameters", clear names
		local yr = `income_yr' + 1
		keep if yr==`income_yr'
		keep yr healthcont pensioncont
		foreach var of varlist _all {
			local `var'`yr'=`var'
		}
	}

* Create matrices when data exist
		foreach yr of numlist 1980/$cpsendyear {

			use $diroutput/cpsindiv/cpsmar`yr'indiv.dta, clear

			quietly {
				replace marsupwt = round(marsupwt)
				keep if wsal_val > 0 // need to drop non-wage earngers because crosstab x y if wsal > 0 ranks everybody
				crosstab wsal_val hashealth [fw=marsupwt], by(oldmar) matname(frqhealth`yr')
				crosstab wsal_val haspplan  [fw=marsupwt], by(oldmar) matname(frqpplan`yr')
			}
			mat list frqhealth`yr'
			di "FRACTION OF WAGE EARNERS WITH HEALTH BENEFITS IN `yr' BY INCOME DECILE X MARRIED X 65+"
			mat list frqpplan`yr'
			di "FRACTION OF WAGE EARNERS WITH PENSION BENEFITS IN `yr' BY INCOME DECILE X MARRIED X 65+"
		}
		foreach yr of numlist 1992/$cpsendyear {
			use $diroutput/cpsindiv/cpsmar`yr'indiv.dta, clear
			quietly {
				replace marsupwt = round(marsupwt)
				keep if wsal_val > 0
				crosstab wsal_val healthben [fw=marsupwt] if hashealth == 1, by(oldmar) matname(avghealth`yr')
			}
			mat list avghealth`yr'
			di "AVERAGE HEALTH BENEFITS OF WORKERS WITH HEALTH BENEFITS IN `yr' BY INCOME DECILE X MARRIED X 65+"
		}

* Missing years.
		foreach yr of numlist 1964/1979 {
			mat frqhealth`yr' = frqhealth1980
			mat frqpplan`yr'  = frqpplan1980
		}
		foreach yr of numlist 1964/1991 {
			local adjust`yr' = `healthcont`yr'' / `healthcont1992'
			mat avghealth`yr' = avghealth1992 * `adjust`yr''
		}
		foreach yr of numlist 1962 1963 { // 1962 and 1963 CPS files seem corrupt; replace by 1964
			mat frqhealth`yr' = frqhealth1964
			mat frqpplan`yr'  = frqpplan1964
			local adjust`yr' = `healthcont`yr'' / `healthcont1992'
			mat avghealth`yr' = avghealth1992 * `adjust`yr''
		}

* No data on healt benefits in 2004 and 2015
	forval i = 1/10 {
		forval j = 1/4 {
			mat avghealth2004[`i', `j'] = (avghealth2003[`i', `j'] + avghealth2005[`i', `j']) / 2
			mat avghealth2015[`i', `j'] = avghealth2014[`i', `j']
		}
	}

*Replace missing values by 0 in matrix and save matrices 
		foreach yr of numlist 1962/$cpsendyear  {
			local income_yr = `yr' - 1
				foreach m in frqhealth frqpplan avghealth  {
					forval j = 1/4 {
						forval i = 1/10 {
							if `m'`yr'[`i', `j'] == . {
		 						matrix `m'`yr'[`i', `j']= 0
		 					}
		 				}
		 			}
					clear
					svmat `m'`yr', names(col)
					gen decile = _n
					order decile
					export excel using "$dirmatrix/`m'`income_yr'.xlsx", first(var) replace
				}
			}
