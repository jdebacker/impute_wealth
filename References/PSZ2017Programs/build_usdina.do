* 2014-2016: construction of US DINA micro-files
* Updated Fall 2018 to improve tax incidence assumptions
* Id identifies a tax unit; id and second uniquely identify an individual

****************************************************************************************************************************************************************
*
* PRELIMINARIES: LOAD PARAMETERS & SMALL FILES
*
****************************************************************************************************************************************************************

 * Define income and wealth core concepts and their composition
	global 	y     	"fiinc fninc fainc flinc fkinc ptinc plinc pkinc diinc princ peinc poinc hweal" 
	global 	fiinc 	"fiwag fibus firen fiint fidiv fikgi"
	global 	fninc 	"fiwag fibus firen fiint fidiv"
	global 	itinc 	"itlab itcap"
	global 	flinc 	"flemp flmil flprl" 
	global 	fkinc 	"fkhou fkequ fkfix fkbus fkpen fkdeb"
	global 	fainc 	"$flinc $fkinc"  
	global 	plinc 	"$flinc plcon plbel"
	global 	pkinc 	"$fkinc pkpen pkbek"
	global 	ptinc 	"$plinc $pkinc"
	global 	diinc 	"dicsh inkindinc colexp"
	global  princ   "$fainc govin npinc"
	global  peinc	"$ptinc govin npinc prisupen 		invpen"
	global  poinc	"$diinc govin npinc prisupenprivate invpen prisupgov"
	global 	hweal 	"hwequ hwfix hwhou hwbus hwpen hwdeb"

* Memo items 
	global 	mfiinc	 "fnps peninc schcinc scorinc partinc rentinc estinc rylinc othinc" // careful: includes nonfilers
	global  mflinc   "flwag flsup waghealth wagpen"
	global  mfkinc   "fkhoumain fkhourent fkmor fknmo fkprk proprestax propbustax"
	global  mplinc   "plpco ploco plpbe plobe plben plpbl plnin"
	global  mpkinc   "pkpbk pknin"
	global  mptinc	 "ptnin"	
	global  mhweal   "rental rentalhome rentalmort ownerhome ownermort housing partw soleprop scorw equity taxbond muni currency nonmort hwealnokg hwfin hwnfa "
	global  mdiinc	 "tax ditax ditaf ditas salestax corptax proprestax propbustax estatetax govcontrib ssuicontrib othercontrib ssinc_oa ssinc_di uiinc ben dicab dicred difoo disup divet diwco dicao tanfinc othben medicare medicaid otherkin pell vethealth"
	global  capfac   "fdivinc fdivkg fintinctax fintexm fbus fscorpinc2 fmortded fresttax"


* Load matrices used for imputations. Careful: need to have rownames in col. 1 & colnames in col. 1
	local yearmat : dir "$dirmatrix" files "*${yr}.xlsx"
	local 1966mat : dir "$dirmatrix" files "*1966.xlsx"
	local 2000mat : dir "$dirmatrix" files "*2000.xlsx"
	foreach mat in `yearmat' `1966mat' `2000mat' {
		import excel "$dirmatrix/`mat'", firstrow clear
		local name = substr("`mat'",1,length("`mat'")-5)
		de _all, varlist
		tokenize `r(varlist)' 	
		local row `1'
        macro shift
        local cells `*'
		mkmat `cells', mat(`name') rownames(`row')
	}

	* import excel using "$root/DINA(Aggreg).xlsx", sheet(ParametersStata) clear  firstrow  
	*  import delimited using "$parameters", clear varnames(1) delimiter(";")
	insheet using "$parameters", clear names
		keep if yr==$yr
		keep tt* frac* private_saving
		foreach var of varlist _all {
			local `var'=`var'
		}	

* Macros with small file variables we keep
	global		sociocharac		"married female femalesec age agesec filer xkids xkidspop oldexm oldexf item owner oldmar" 
	if $yr>=1999 global 		laborinc_irs "waginc wagincsec sey seysec share_f share_f2 share_ftrue"
	if $yr<1999 global 			laborinc_irs "waginc wagincsec sey seysec share_f share_ftrue"
	global 		peninc_irs 		"peninc penincnt penira"
	global 		kinc_irs 		"divinc kginc kgpos intinc intexm estincp divest busest rentest intest kgest rentinc rentincp rentincl othinc mortrental"
	global 		businc_irs 		"schcinc schcincp schcincl scorinc scorpinc scorpinc2 scorlinc scorlinc2  partinc partpinc partpinc2 partlinc partlinc2 rylinc"
	global  	item_irs		"realestatetax mortded intdedoth"
	global		tax_irs			"fedtax setax statetax charit"
	global 		benefits_irs 	"ssinc uiinc eictot eicrefn ctctot ctcrefn" 

	
use "$dirsmall/small$yr.dta", clear

* define impute.do variables if missing [to save time and not have to rerun impute.do internally]
	if $data==1 {
	* cap gen ageimp=age
	* cap gen agesecimp=agesec if married==1
	* cap gen femaleimp=female if married==0
	* if $yr>=1999 cap gen earnsplitimp=share_ftrue if married==1 & wages>0
	* added 10/2018: need to revert to imputed share_f when databankyear<yr
	if $yr>$databankyear replace share_ftrue=share_f
	* end added 10/2018
	cap gen share_f2=share_ftrue if married==1 & wages>0 & filer==1
	cap replace wagincsec=waginc*share_f2 if married==1 & wages>0 & filer==1
	}

* Blow-up estinc to match total undistributed trust income, and divide into components
	qui replace estinc = 0 if estinc == .
	qui gen estincp=0
		qui replace estincp=estinc if estinc>0
		label variable estincp "Positive estate and trust income"
	qui su estincp [w=dweght] 
		local ttestincp=r(sum)/10e10
		di "TOTAL POSITIVE ESTATE AND TRUST INCOME = `ttestincp'"
	qui su estinc [w=dweght] 
		local ttestinc=r(sum)/10e10
		di "TOTAL (POSITIVE AND NEGATIVE) ESTATE AND TRUST INCOME = `ttestinc'"
	foreach var in div bus rent int kg {
		qui gen `var'est=estincp*`ttundtr_`var''/`ttestinc' 
		qui replace `var'est=0 if `var'est==.
		label variable `var'est "Undistributed `var' trust income"
	}

* Missing data in small files that we fix here for now. NB: scorpinc2 is missing in 1968 (not fixed here)
	qui replace statetax = max(0,statetax)
	qui gen kgpos=max(0,kginc)
		label variable kgpos "Positive part of realized capital gains"	
	* share waginc female among married sophisticated tab does not exist pre-1999, create it here
	cap gen share_f = .
	cap gen share_f2=share_f
	cap gen share_ftrue=share_f
	cap gen wagincsec = .
	cap gen xkidspop = .
	foreach var in $laborinc_irs $peninc_irs $kinc_irs $businc_irs $item_irs $tax_irs $benefits_irs xkids xkidspop xded {
		replace `var' = 0 if `var' ==.  // Some vars are missing in small, e.g., rylinc in 1962, etc. 
	}	
	if $yr==1967 | $yr==1969 | $yr==1971 {
		qui replace intdedoth=-intdedoth
	}
	
	* qui gen netfedtax=fedtax-eicrefn-ctcrefn
	* 	label variable netfedtax "Federal income tax net of refundable part of EITC and CTC (can be negative)"
	* label variable id "Tax unit ID"
	
****************************************************************************************************************************************************************
*
* CREATE WEALTH VARIABLES BY CAPITALIZING INCOME TAX RETURNS
*
****************************************************************************************************************************************************************


foreach var in $kinc_irs $businc_irs $item_irs {
	qui su `var' [w=dweght], meanonly
	local tt`var'=r(sum)/10e10
}	

********************************************************************************
* Rental housing
********************************************************************************

qui gen rentalmort=0
	label variable rentalmort "Mortgages on tenant-occupied houses"
qui gen rentalhome=0
	label variable rentalhome "Gross tenant-occupied housing"

* Imputation of Schedule E mortage interest payments pre-1990: based on 1990 cross-tabs
	if $yr<1990 {
		if el("frqhasmortrental1990",1,1)==. {
		preserve
			use "$root/output/small/small1990.dta", clear
			qui gen hasrental=(rentinc!=0 & rentinc!=.)
			qui gen hasmortrental=(mortrental!=0 & mortrental !=.)
			cap qui egen oldmar=group(married oldexm), label
			crosstab income hasmortrental [w=dweght] if hasrental==1, by(oldmar) matname(frqhasmortrental1990)
				mat list frqhasmortrental1990
				di "FRACTION OF RENTAL HOME OWNERS WITH MORTGAGES IN 1990, BY INCOME DECILE X MARRIED X 65+"			
				clear
				svmat frqhasmortrental1990, names(col)
				foreach var of varlist _all {
					replace `var' = 0 if `var' == .
				}
				qui gen decile = _n
				order decile				
				export excel using "$dirmatrix/frqhasmortrental1990.xlsx", first(var) replace
			use "$root/output/small/small1990.dta", clear
			qui gen hasrental=(rentinc!=0 & rentinc!=.)
			qui gen hasmortrental=(mortrental!=0 & mortrental !=.)
			crosstab income mortrental [w=dweght] if hasmortrental==1, by(oldmar) matname(avgmortrental1990)
				mat list avgmortrental1990
				di "AVERAGE SCHEDULE E MORTGAGE INTEREST PAYMENTS IN 1990, BY INCOME DECILE X MARRIED X 65+"			
				clear
				svmat avgmortrental1990, names(col) 
				foreach var of varlist _all {
					replace `var' = 0 if `var' == .
				}
				qui gen decile = _n
				order decile
				export excel using 	"$dirmatrix/avgmortrental1990.xlsx", first(var) replace			
		restore			
		}
		qui {	
		cap drop mortrental
		gen mortrental=0
			qui gen hasrental=(rentinc!=0 & rentinc!=.)
			qui xtile rank_inc = income [w=dweght] if income >= 0, nq(10)
			set seed 354
			forval i = 1/10 { 
				forval j = 1/4 { 
					qui replace mortrental=(runiform()<=frqhasmortrental1990[`i',`j'])*avgmortrental1990[`i',`j'] if rank_inc==`i' & oldmar==`j' & hasrental==1
				}
			}
			drop rank_inc
		}
	}

* Gross rental housing and mortgages on rental houses
	qui su mortrental [w=dweght]
		local ttmortrental=r(sum)/10e10
		local frentalmort=`ttrentmortw'/`ttmortrental'
			di "CAP FACTOR MORTGAGES RENTAL HOUSING IN $yr =`frentalmort'"
	qui replace rentalmort=mortrental*`frentalmort'
	qui sum rentalmort [w=dweght], meanonly
		local total_rentalmort = r(sum) / 10e10
		* assert round(`total_rentalmort') == round(`ttrentmortw')

	qui replace rentalhome=-rentalmort if rentinc!=0 & mortrental>0
		qui su rentalhome [w=dweght]
			local remaining_rental_wealth=(`ttrentw'-`ttrentmortw')-r(sum)/10e10
		qui egen positive_rents=rsum(rentincp rentest)
		qui su positive_rents [w=dweght] 
			local fremaining=`remaining_rental_wealth'/(r(sum)/10e10)
		qui replace rentalhome=rentalhome+`fremaining'*positive_rents
		qui drop positive_rents

	qui gen rental=0
		label variable rental "Tenant-occupied housing wealth, net of mortgage debt"
		qui replace rental=rentalhome+rentalmort

********************************************************************************
* Owner-occupied housing
********************************************************************************
 
* Itemizers: capitalize property taxes & mortgage payments
	qui gen ownerhome=0
		label variable ownerhome "Gross owner-occupied housing wealth"
		local shareproptaxitemizers=0.75
		local fresttax=`ttrestw'/(`ttrealestatetax'/`shareproptaxitemizers')
		di "CAP FACTOR GROSS OWNER HOUSING=`fresttax'"
		qui replace realestatetax=0 if realestatetax==.
		qui replace ownerhome=realestatetax*`fresttax' 
	qui gen ownermort=0
		label variable ownermort "Mortgages on owner-occupied houses"
		local sharemortdeditemizers=0.80
		qui replace mortded = 0 if mortded == .
		qui sum mortded [w=dweght], meanonly
			local total_mortded = r(sum) / 10e10
		local fmortded = - `ttmortw'/ (`total_mortded'/`sharemortdeditemizers')
		di "CAP FACTOR MORTGAGE DEBT = `fmortded'"
		qui replace ownermort = - mortded * `fmortded' 
		qui sum ownermort [w=dweght], meanonly
			local total_owner_mort = r(sum) / 10e10
			assert round(`total_owner_mort') == round(`ttmortw' * 0.80)

* Impute home ownership & mortgage dummies & average values for non-itemizers: same as in SCF within each income x married x old cell
	qui gen hashome=(ownerhome!=0 & ownerhome!=.)
	qui gen hasmort=(ownermort!=0 & ownermort!=.)
		set seed 30983
		qui replace income=income+rnormal()
		qui xtile rank_inc = income [w=dweght] if income >= 0, nq(10)
		qui tab rank_inc
		local I=r(r)
		qui tab oldmar
		local J=r(r)
	set seed 9683	
	forval i = 1/`I' { 
		forval j = 1/`J' { 
			qui replace hashome = runiform() <= frqhome${yr}[`i',`j'] if rank_inc == `i' & oldmar == `j' & item == 0	
			qui replace ownerhome = avghome${yr}[`i', `j'] if rank_inc == `i' & oldmar == `j' & item == 0 & hashome == 1
			}
		}
	set seed 248	
	forval i = 1/`I' { 
		forval j = 1/`J' { 
			qui replace hasmort = runiform() <= frqmort${yr}[`i',`j'] if rank_inc == `i' & oldmar == `j' & item == 0 & hashome == 1
			qui replace ownermort = avgmort${yr}[`i', `j'] if rank_inc == `i' & oldmar == `j' & item == 0 & hasmort == 1		
			}
		}	

* Adjust home & mortgage values to match:
* (i) cell-by-cell totals for non-itemizers in SCF (necessary adjustment because of different pop. totals SCF vs. tax)
* (ii) macro wealth of non-itemizers (necessary adjustment because of different Financial Accounts vs. SCF totals)  	
	local tthomenonitemscf${yr} = 0
	local ttmortnonitemscf${yr} = 0
	forval i = 1/`I' { 
		forval j = 1/`J' {
			local tthomenonitemscf${yr} =  `tthomenonitemscf${yr}'  + sumhome${yr}[`i', `j']
			local ttmortnonitemscf${yr} =  `ttmortnonitemscf${yr}'  + summort${yr}[`i', `j']
		}
	}			
	di "TOTAL HOME WEALTH OF NON ITEMIZERS IN $yr = `tthomenonitemscf${yr}'"		
	local blowupvalhome${yr} = `ttrestw'*(1-`shareproptaxitemizers')/`tthomenonitemscf${yr}'
		di "RATIO HOME WEALTH OF NON-ITEMIZERS DINA / HOME WEALTH OF NON-ITEMIZERS SCF in $yr = `blowupvalhome${yr}'"
	di "TOTAL MORT WEALTH OF NON ITEMIZERS IN $yr = `ttmortnonitemscf${yr}'"	
	local blowupvalmort${yr} = `ttmortw'*(1-`sharemortdeditemizers')/`ttmortnonitemscf${yr}'
		di "RATIO MORT WEALTH OF NON-ITEMIZERS DINA / MORT WEALTH OF NON-ITEMIZERS SCF in $yr = `blowupvalmort${yr}'"
	forval i = 1/`I' { 
		forval j = 1/`J' { 
			qui su ownerhome [w=dweght] if rank_inc == `i' & oldmar == `j' & item == 0
			qui replace ownerhome = ownerhome* (sumhome$yr[`i',`j'] / (r(sum)/10e10)) * `blowupvalhome${yr}' if rank_inc == `i' & oldmar == `j' & item == 0 & hashome == 1
			qui su ownermort [w=dweght] if rank_inc == `i' & oldmar == `j' & item == 0
			qui replace ownermort = ownermort* (summort$yr[`i',`j'] / (r(sum)/10e10)) * `blowupvalmort${yr}' if rank_inc == `i' & oldmar == `j' & item == 0 & hasmort == 1
		}
	}
	drop rank_inc

	qui sum ownermort [w=dweght], meanonly	
		local tot_owner_mort = r(sum) / 10e10
		* assert round(`tot_owner_mort') == round(`ttmortw') 
		// tiny pb, unclear why, quick fix here
		qui replace ownermort = ownermort * `ttmortw' / `tot_owner_mort'
	qui egen housing = rsum(ownerhome ownermort rentalhome rentalmort)
		label variable housing "Housing wealth, net of mortgage debt"	
	qui egen hwhou = rsum(rentalhome ownerhome)
		label variable hwhou "Housing assets"


********************************************************************************
* Business assets (excl. S corp)
********************************************************************************

* Excludes S corp. Assigns 0 value when negative business income

gen bus_inc_pos = partpinc2 + busest + schcincp + max(0, rylinc)
	qui sum bus_inc_pos [w=dweght], meanonly
	local total_bus_inc_pos = r(sum) / 10e10
	local fbus = `ttschcpartw'/ `total_bus_inc_pos'
	di "CAP FACTOR PARTNERSHIP AND SOLE PROP = `fbus'"

qui gen partw=0 
	label variable partw "Partnership wealth"
	qui replace partw = (partpinc2 + busest) * `fbus'
qui gen soleprop=0 
	label variable soleprop "Sole proprietorship wealth"
	gen sole_inc_pos = schcincp + max(0, rylinc)
	qui replace soleprop = sole_inc_pos * `fbus'

qui egen hwbus=rsum(partw soleprop)
	label variable hwbus "Business assets"
	qui sum hwbus [w=dweght], meanonly
		local total_hwbus = r(sum) / 10e10
		* assert round(`total_hwbus') == round(`ttschcpartw')		

********************************************************************************
* Equities (incl. S corp)
********************************************************************************

qui gen scorw = 0
	label variable scorw "S-corporations equities"
	local fscorpinc2=`ttscorw'/`ttscorpinc2'
		di "CAP FACTOR S CORP=`fscorpinc2'"
	qui replace scorw=scorpinc2*`fscorpinc2'
	qui replace scorw=0 if scorw==.

qui gen hwequ = 0
	label variable hwequ "Equity assets (div+KG capitalized)"
	qui gen equity_income_pos = divinc + kgpos + divest + kgest
		qui sum equity_income_pos [w=dweght], meanonly
		local total_equity_income_pos = r(sum) / 10e10
		local fdivkg = `ttdivw' / `total_equity_income_pos'
		di "CAP FACTOR EQUITY (DIV+KG) = `fdivkg'"
	qui replace hwequ = equity_income_pos * `fdivkg' + scorw 
	qui sum hwequ [w=dweght], meanonly
		local total_hwequ = r(sum) / 10e10
		local ttequ = `ttdivw' + `ttscorw'
	 if $yr == 1968 qui replace hwequ = hwequ * `ttequ'  / `total_hwequ'	// scor missing in 1968 in small files
	qui sum hwequ [w=dweght], meanonly
		local total_hwequ = r(sum) / 10e10
	* assert round(`total_hwequ') == round(`ttequ')

qui gen equity = 0
	label variable equity "Equity assets (only div. capitalized)"
	local fdivinc=`ttdivw'/(`ttdivinc'+`ttdivest')
		di "CAP FACTOR EQUITY (DIV ONLY)=`fdivinc'"
	qui replace equity=(divinc+divest)*`fdivinc'+scorw 

********************************************************************************
* Pensions
********************************************************************************

* to match SCF, assume that bottom 60% wage earners have no pension wealth and that pension wealth proportional to wages above percentile 60
* loading more pension wealth on wages (instead of pensions) actually decreases pension concentration

qui gen hwpen=0
	label variable hwpen "Pension and life-insurance assets"
if filer == 1 {	
	gen wagetop60=0
		cumul waginc [w=dweght] if waginc>0, gen(rankwage)
		qui replace rankwage=1-(1-rankwage)*`fracfiling'
		qui replace rankwage=0 if rankwage==.
		qui egen aux=min(waginc) if rankwage>0.5
		qui replace wagetop60=waginc-aux if rankwage>0.5
		cap drop aux
		qui su wagetop60 [w=dweght] 
			local sumwagetop60=r(sum)/10e10
	gen totpeninc=peninc+penincnt
		qui su totpeninc [w=dweght] 
			local sumtotpeninc=r(sum)/10e10
	qui replace hwpen=wagetop60*(`ttpenw'+`ttpeniraw')*0.4/`sumwagetop60'+totpeninc*(`ttpenw'+`ttpeniraw')*0.6/`sumtotpeninc' 
}	
	drop wagetop60 rankwage totpeninc
	qui sum hwpen [w=dweght], meanonly
		local total_hwpen = r(sum) / 10e10
		local ttpen = `ttpenw' + `ttpeniraw'
		* assert round(`total_hwpen') == round(`ttpen')		

********************************************************************************
* Fixed income claims & non-mortgage debt
********************************************************************************

* Taxable fixed income claims
	qui gen taxbond=0
		label variable taxbond "Taxable fixed-income claims"
		local fintinctax=`ttinttaxw'/(`ttintinc'+`ttintest')
			di "CAP FACTOR TAXABLE FIXED INCOME=`fintinctax'"
		qui replace taxbond=(intinc+intest)*`fintinctax' 

* Impute intexm pre-1987 based on 1987 cross-tab	
	if $yr<=1986 {
		matrix define cumul=(-1\ .50\ .75\ .90\ .95\ .99\ .995\ .999\ .9999\ 1)
		local I = rowsof(cumul)-1
		if el("frqintexm1987",1,1)==. {
		preserve
			use "$root/output/small/small1987.dta", clear
			qui cumul income [w=dweght], gen(rank_inc)
			qui gen hasintexm=(intexm!=0 & intexm!=.)
		 	cap qui egen oldmar=group(married oldexm), label
			qui tab oldmar
				local J=r(r)
			mat frqintexm1987 = J(`I', `J', 0)
			mat avgintexm1987	= J(`I', `J', 0)
			forval i = 1/`I' { 	
				forval j = 1/`J' { 
					qui su hasintexm [w=dweght] if rank_inc > cumul[`i',1] & rank_inc <= cumul[`i'+1,1] & oldmar == `j', meanonly
					mat frqintexm1987[`i',`j'] = r(mean)
					qui su intexm 	  [w=dweght] if rank_inc > cumul[`i',1] & rank_inc <= cumul[`i'+1,1] & oldmar == `j' & hasintexm == 1, meanonly	
					mat avgintexm1987[`i',`j'] = r(mean)
			 			}
			 		}
			foreach mat in frqintexm1987 avgintexm1987 {
				mat rownames `mat'	= 0 50 75 90 95 99 995 999 9999
				clear
				svmat `mat', names(col)
				gen group = _n // n=1 is bottom 50, n=2 is P50-P75 etc.
				order group
				export excel using "$dirmatrix/`mat'.xlsx", first(var) replace
				}
		restore	
		}	
		cap drop intexm
			gen intexm=0
			gen hasintexm=0
			cumul income [w=dweght], gen(rank_inc)
		 	cap qui egen oldmar=group(married oldexm), label
			qui tab oldmar
				local J=r(r)			
			set seed 1354
			forval i = 1/`I' { 
				forval j = 1/`J' { 
					qui replace intexm=(runiform()<=frqintexm1987[`i',`j'])*avgintexm1987[`i',`j'] if rank_inc > cumul[`i',1] & rank_inc <= cumul[`i'+1,1] & oldmar == `j'
				}
			}
			drop rank_inc
	}

* Muni wealth
	qui gen muni=0
		label variable muni "Tax-exempt municipal bonds"
		qui su intexm [w=dweght]
		local ttintexm=r(sum)/10e10
		local fintexm=`ttintexmw'/`ttintexm'
		di "CAP FACTOR TAX-EXEMPT BONDS=`fintexm'"
		qui replace muni = intexm*`fintexm'

* Impute currency and non-mortgage debt using SCF tabs
	qui gen currency=0
		label variable currency "Currency and non-interest bearing deposits"
	qui gen nonmort=0
		label variable nonmort "Non-mortgage debt"
	qui xtile rank_inc = income [w=dweght] if income >= 0, nq(10)
	qui tab rank_inc
		local I=r(r)
	qui tab oldmar
		local J=r(r)
	set seed 536
	forval i = 1/`I' { 
		forval j = 1/`J' { 
			qui replace currency = (runiform() <= frqcurr$yr[`i',`j']) * avgcurr$yr[`i',`j'] if rank_inc==`i' & oldmar==`j'
		}
	}
	set seed 53098
	forval i = 1/`I' { 
		forval j = 1/`J' { 
			qui replace nonmort = (runiform() <= frqothd$yr[`i',`j']) * avgothd$yr[`i',`j'] if rank_inc==`i' & oldmar==`j'
		}
	}

* Adjust currency and non-mortgage debt to match Financial Accounts total
	local ttcurrscf${yr} = 0
	local ttothdscf${yr} = 0
	forval i = 1/`I' { 
		forval j = 1/`J' {
			local ttcurrscf${yr} =  `ttcurrscf${yr}'  + sumcurr${yr}[`i', `j']
			local ttothdscf${yr} =  `ttothdscf${yr}'  + sumothd${yr}[`i', `j']
		}
	}			
	di "TOTAL CURRENCY WEALTH IN SCF IN $yr = `ttcurrscf${yr}'"		
	local blowupvalcurr${yr} = `ttcurrency'/`ttcurrscf${yr}'
		di "RATIO CURRENCY WEALTH DINA / CURRENCY WEALTH SCF in $yr = `blowupvalcurr${yr}'"
	di "TOTAL NON-MORT DEBT WEALTH IN SCF IN $yr = `ttothdscf${yr}'"	
	local blowupvalothd${yr} = `ttothdebt'/`ttothdscf${yr}'
		di "RATIO NON-MORT DEBT WEALTH DINA / NON-MORT DEBT WEALTH SCF in $yr = `blowupvalothd${yr}'"
	forval i = 1/`I' { 
		forval j = 1/`J' { 
			qui su currency [w=dweght] if rank_inc == `i' & oldmar == `j' 
			qui replace currency =  currency * (sumcurr$yr[`i',`j'] / (r(sum)/10e10)) * `blowupvalcurr${yr}' if rank_inc == `i' & oldmar == `j' 
			qui su nonmort  [w=dweght] if rank_inc == `i' & oldmar == `j' 
			qui replace nonmort  =   nonmort * (sumothd$yr[`i',`j'] / (r(sum)/10e10)) * `blowupvalothd${yr}' if rank_inc == `i' & oldmar == `j' 
		}
	}
	qui drop rank_inc	
	qui replace nonmort = 0 if nonmort == .
	
	
********************************************************************************
* Saves DINA wealth and its components
********************************************************************************
	
	qui egen hwfix = rsum(taxbond muni currency)
		label variable hwfix "Currency, deposits, bonds and loans of households"	
		qui sum hwfix [w=dweght], meanonly
		local total_hwfix = r(sum) / 10e10
		local ttfix = `ttintw' + `ttcurrency'
		* assert round(`total_hwfix') == round(`ttfix')	
	qui egen hwfin = rsum(hwequ hwfix hwpen)
		label variable hwfin "Financial assets of households"
	qui egen hwnfa = rsum(hwhou hwbus)
		label variable hwnfa "Non-financial assets of households"	
	qui egen hwdeb = rsum(ownermort rentalmort nonmort) 
		label variable hwdeb "Liabilities of households" 
	qui egen hweal = rsum($hweal)
		label variable hweal "Net personal wealth"
	qui egen hwealnokg = rsum(equity hwfix hwhou hwbus hwpen hwdeb)
		label variable hwealnokg "Net personal wealth (KG not capitalized)"
	qui drop hasmort hashome 
	qui sum hweal [w=dweght], meanonly
		local total_wealth = r(sum) / 10e10
		* assert round(`ttwealth') == round(`total_wealth')


****************************************************************************************************************************************************************
*
* BRING BENEFITS FROM CPS (TAX UNIT LEVEL)
*
****************************************************************************************************************************************************************


* Social Security benefits (retirement + DI)
* Impute ssinc dummy so that frequency of ssinc>0  = max(freq CPS, freq small) in each income decile x married x old cell; blow up amounts to match macro totals
	qui gen hasssinc=(ssinc!=0 & ssinc!=.)
	qui xtile rank_inc = income [w=dweght] if income >= 0, nq(10)
		qui tab rank_inc
		local I=r(r)
	qui tab oldmar
		local J=r(r)
	crosstab income hasssinc [w=dweght], by(oldmar) matname(frqssincsmall${yr})
	set seed 87
	qui gen imput = 0
	forval i = 1/`I' { 
		forval j = 1/`J' { 
			mat frqssinc${yr}[`i', `j'] = max(0, (frqssinc${yr}[`i', `j'] - frqssincsmall${yr}[`i', `j']) / (1 - frqssincsmall${yr}[`i', `j']) )
			qui replace imput = runiform() <= frqssinc${yr}[`i',`j'] if rank_inc == `i' & oldmar == `j' & hasssinc == 0
			qui replace hasssinc = imput if hasssinc == 0
			qui replace ssinc = avgssinc${yr}[`i',`j'] if rank_inc == `i' & oldmar == `j' & imput == 1	
			}
		}
		drop imput rank_inc hasssinc
		mat list frqssinc${yr} 
			di "FRACTION OF TAX UNITS WITH IMPUTED SSINC>0 IN SMALL"
	qui su ssinc [w=dweght], meanonly
		local ttssinc = r(sum)/10e10
		local blowupss = `ttssben' / `ttssinc'
			di "BLOW UP FACTOR FOR SOCIAL SECURITY INCOME (RETIREMENT + DI) IN YEAR $yr : `blowupss'"
	qui replace ssinc = ssinc * `blowupss'
* Split ssinc into old-age and DI: to simplify assume that all ssinc to 65- is DI and all ssinc to 65+ is retirement	
	qui gen ssinc_oa = 0
		label variable ssinc_oa "Social Security income (old age)"
	qui replace ssinc_oa = ssinc if oldexm == 1 | oldexf == 1
	qui gen ssinc_di = 0
		label variable ssinc_di "Social Security income (disability)"
	qui replace ssinc_di = ssinc if oldexm == 0 & oldexf == 0
		
* UI: no info in small before 1979; impute pre-1979 UI based on cross-tab for post-1979 year with closest unemp. rate	
	if $yr<1979 { 
		* Create UI matrixes from small if do not already exist
		if el("frquiinc$yr",1,1)==. {  
			preserve
				* First, post-1979 matrices	
				foreach year of numlist 1979/2009 {		
					use "$root/output/small/small`year'.dta", clear
						qui gen hasuiinc = (uiinc>0 & uiinc!=.)
						crosstab income hasuiinc [w=dweght], by(oldmar) matname(frquiinc`year')
						mat list frquiinc`year'
							di "FRACTION OF TAX UNITS WITH UIINC IN $yr BY INCOME DECILE X MARRIED X 65+"
						clear
						svmat frquiinc`year', names(col)
						foreach var of varlist _all {
							replace `var' = 0 if `var' == .
						}
						qui gen decile = _n
						order decile
						export excel using "$dirmatrix/frquiinc`year'.xlsx", first(var) replace			
					use "$root/output/small/small`year'.dta", clear
						qui gen hasuiinc = (uiinc>0 & uiinc!=.)
						crosstab income uiinc [w=dweght] if hasuiinc == 1, by(oldmar) matname(avguiinc`year')				
						mat list avguiinc`year'
							di "AVERAGE UIINC OF TAX UNITS WITH POSITIVE UIINC IN $yr BY INCOME DECILE X MARRIED X 65+"
						clear
						svmat avguiinc`year', names(col)
						foreach var of varlist _all {
							replace `var' = 0 if `var' == .
						}
						qui gen decile = _n
						order decile
						export excel using "$dirmatrix/avguiinc`year'.xlsx", first(var) replace					
				}
				* Second pre-1979 matrices by matching each pre-1979 year to the post-1979 year with closest unemployment rate
				insheet using "$direxcel/unrate.csv", clear 
				qui keep if year>=1962			
				tempfile unemp
				save `unemp'
				foreach year of numlist 1962/2009 {
					use `unemp', clear
					qui keep if year==`year'
					local unrate`year'=unrate
					use `unemp', clear
					qui gen gap`year'= abs(unrate - `unrate`year'')
					save `unemp', replace	
				}
				qui keep year gap1979-gap2009
				reshape long gap, i(year) j(closest)
				gsort year gap closest 
				save `unemp', replace 
				foreach year of numlist 1962/1978 {
					use `unemp', clear
					qui keep if year==`year'
					qui keep if _n==1
					local closest = closest
					di "YEAR = `year' UNEMPLOYMENT RATE = `unrate`year'' POST 1979 YEAR WITH CLOSEST UENMPLOYMENT RATE = `closest' WHEN UNEMP WAS `unrate`closest'' "
					foreach mat in frquiinc avguiinc {
						matrix `mat'`year'= `mat'`closest'
						clear
						svmat `mat'`year', names(col)
						foreach var of varlist _all {
							replace `var' = 0 if `var' == .
						}
						qui gen decile = _n
						order decile
						export excel using "$dirmatrix/`mat'`year'.xlsx", first(var) replace							
					}
				}
			restore
			}	
		* Generate uiinc pre-1979
		cap drop uiinc 
		qui gen uiinc=0
		qui xtile rank_inc = income [w=dweght] if income >= 0, nq(10)
		set seed 1074 
		forval i = 1/10 { 
			forval j = 1/4 { 
				qui replace uiinc = (runiform() <= frquiinc$yr[`i',`j']) * avguiinc$yr[`i',`j'] if rank_inc==`i' & oldmar==`j' 
			}
		}
		replace uiinc = 0 if uiinc == .
		drop rank_inc
	}
	* Adjust UI to match macro totals
	qui su uiinc [w=dweght], meanonly
		local ttuiinc = r(sum)/10e10
		local blowupui = `ttuiben' / `ttuiinc'
			di "BLOW UP FACTOR FOR UI BENEFITS IN YEAR $yr : `blowupui'"
	qui replace uiinc = uiinc * `blowupui'
		label variable uiinc "Unemployment insurance benefits"

* Supplemental security income: not taxable; impute from CPS and blow up amounts to match macro totals
	qui gen supinc = 0
	qui xtile rank_inc = income [w=dweght] if income >= 0, nq(10)
		qui tab rank_inc
		local I=r(r)
	qui tab oldmar
		local J=r(r)
	set seed 3052
	forval i = 1/`I' { 
		forval j = 1/`J' { 
			qui replace supinc = (runiform() <= frqssiinc$yr[`i',`j']) * avgssiinc$yr[`i',`j'] if rank_inc==`i' & oldmar==`j'
		}
	}
	drop rank_inc
	qui su supinc [w=dweght], meanonly
		local ttsupinc = r(sum)/10e10
		local blowupssi = `ttssiben' / `ttsupinc'
			di "BLOW UP FACTOR FOR SUPPLEMENTAL SECURITY INCOME IN YEAR $yr : `blowupssi'"
	qui replace supinc = supinc * `blowupssi'

* SNAP (since 1966): impute from CPS; blow up frequency in each cell so that amounts match macro total
	qui gen snapinc = 0
	if $yr>=1966 {
		qui xtile rank_inc = income [w=dweght] if income >= 0, nq(10)
			qui tab rank_inc
			local I=r(r)
		qui tab oldmar
			local J=r(r)
		local totsnapcps = 0
		forval i = 1/`I' { 
			forval j = 1/`J' { 
				qui su dweght if rank_inc==`i' & oldmar==`j', meanonly 
				if el("avgsnapinc${yr}",`i',`j')!=. {
					local totsnapcps = `totsnapcps' + avgsnapinc${yr}[`i', `j'] * frqsnapinc${yr}[`i',`j'] * r(sum)/10e10 
				}		
			}
		}
		local blowupsnap = `ttsnapben' / `totsnapcps'
		di "BLOW UP FACTOR FOR SNAP BENEFITS IN YEAR $yr : `blowupsnap'"
		set seed 3052
		forval i = 1/`I' { 
			forval j = 1/`J' { 
				mat frqsnapinc$yr[`i',`j'] = frqsnapinc$yr[`i',`j'] * `blowupsnap'
				if el("frqsnapinc$yr",`i',`j') > 1 {
					di "WARNING: FREQUENCY GREATER THAN 1 IN frqsnapinc$yr" 
					mat frqsnapinc$yr[`i',`j'] = 1
				}
				qui replace snapinc = (runiform() <= frqsnapinc$yr[`i',`j']) * avgsnapinc$yr[`i',`j'] if rank_inc==`i' & oldmar==`j'
			}
		}
		drop rank_inc
		qui su snapinc [w=dweght], meanonly
			local ttsnapinc = r(sum)/10e10
			local blowupsnap2 = `ttsnapben' / `ttsnapinc'
				di "RESIDUAL BLOW UP FACTOR FOR SNAP IN YEAR $yr : `blowupsnap2'"
		qui replace snapinc = snapinc * `blowupsnap2'
		qui replace snapinc = 0 if snapinc == .
	}
* Worker's compensation: like UI benefits in 2000 (when total workers comp = 65% of UI benefits = highest fraction)
	qui {
	cap drop workcomp  
		gen workcomp = 0
		qui xtile rank_inc = income [w=dweght] if income >= 0, nq(10)
		set seed 938 
		forval i = 1/10 { 
			forval j = 1/4 { 
				qui replace workcomp = (runiform() <= frquiinc2000[`i',`j']) * avguiinc2000[`i',`j'] if rank_inc==`i' & oldmar==`j' 
			}
		}
		drop rank_inc	
	}	
	qui su workcomp [w=dweght], meanonly
		local ttworkcomp = r(sum)/10e10
		local blowupworkcomp = `ttworkcompben' / `ttworkcomp'
			di "BLOW UP FACTOR FOR WORKER COMPENSATION BENEFITS IN YEAR $yr : `blowupworkcomp'"
	qui replace workcomp = workcomp * `blowupworkcomp'

* Veteran benefits: imputed from CPS
	qui {
	cap drop vetben  
		gen vetben = 0
		qui xtile rank_inc = income [w=dweght] if income >= 0, nq(10)
		set seed 309853
		forval i = 1/10 { 
			forval j = 1/4 { 
				qui replace vetben = (runiform() <= frqvetinc${yr}[`i',`j']) * avgvetinc${yr}[`i',`j'] if rank_inc==`i' & oldmar==`j' 
			}
		}
		drop rank_inc	
	}	
	qui su vetben [w=dweght], meanonly
		local ttvet = r(sum)/10e10
		local blowupvetben = `ttvetben' / `ttvet'
			di "BLOW UP FACTOR FOR VETERANS' BENEFITS IN YEAR $yr : `blowupvetben'"
	qui replace vetben = vetben * `blowupvetben'

* TANF / AFDC: imputed from CPS, blow-up frequencies to match macro amounts
	qui gen tanfinc = 0
		label variable tanfinc "TANF / AFDC benefits"
	qui xtile rank_inc = income [w=dweght] if income >= 0 & xkidspop > 0 & xkidspop !=., nq(10)
		qui tab rank_inc
		local I=r(r)
	qui tab oldmar
		local J=r(r)
	local tottanfcps = 0
	forval i = 1/`I' { 
		forval j = 1/`J' { 
			qui su dweght if income >= 0 & rank_inc==`i' & oldmar==`j' & xkidspop > 0 & xkidspop !=., meanonly 
			if el("avgtanfinc${yr}",`i',`j')!=. {
				local tottanfcps = `tottanfcps' + avgtanfinc${yr}[`i', `j'] * frqtanfinc${yr}[`i',`j'] * r(sum)/10e10 
			}		
		}
	}
	local blowuptanf = `tttanfben' / `tottanfcps'
	di "BLOW UP FACTOR FOR AFDC / TANF BENEFITS IN YEAR $yr : `blowuptanf'"
	set seed 9687
	forval i = 1/`I' { 
		forval j = 1/`J' { 
			mat frqtanfinc$yr[`i',`j'] = frqtanfinc$yr[`i',`j'] * `blowuptanf'
			if el("frqtanfinc$yr",`i',`j') > 1 {
				di "WARNING: FREQUENCY GREATER THAN 1 IN frqtanfinc$yr" 
				mat frqtanfinc$yr[`i',`j'] = 1
			}
			qui replace tanfinc = (runiform() <= frqtanfinc$yr[`i',`j']) * avgtanfinc$yr[`i',`j'] if rank_inc==`i' & oldmar==`j' & xkidspop > 0 & xkidspop !=.
		}
	}
	drop rank_inc
	qui su tanfinc [w=dweght], meanonly
		local tttanfinc = r(sum)/10e10
		local blowuptanf2 = `tttanfben' / `tttanfinc'
			di "RESIDUAL BLOW UP FACTOR FOR AFDC / TANF IN YEAR $yr : `blowuptanf2'"
	qui replace tanfinc = tanfinc * `blowuptanf2'
	qui replace tanfinc = 0 if tanfinc == .

* Other cash benefits: dstributed like SNAP (= various State and local benefits similar to SNAP; reduction in utility bills for low-income families)
* NB: this does not include housing subsidies (which are netted from property taxes)
	qui {
		cap drop othben 
			gen othben = 0
				label variable othben "Other cash benefits (State and local benefits similar to SNAP, etc.)"
			qui xtile rank_inc = income [w=dweght] if income >= 0, nq(10)
			set seed 3408 
			local yr = $yr
			if $yr<1966 local yr = 1966 // SNAP starts in 1966
			forval i = 1/10 { 
				forval j = 1/4 { 
					qui replace othben = (runiform() <= frqsnapinc`yr'[`i',`j']) * avgsnapinc`yr'[`i',`j'] if rank_inc==`i' & oldmar==`j' 
				}
			}
			drop rank_inc	
		}	
		qui su othben [w=dweght], meanonly
			local ttoth = r(sum)/10e10
			local blowupothben = `ttothben' / `ttoth'
				di "BLOW UP FACTOR FOR OTHER CASH BENEFITS IN YEAR $yr : `blowupothben'"
		qui replace othben = othben * `blowupothben'
		qui replace othben = 0 if othben == .

* Medicaid: number of beneficiaries in each tax unit imputed from CPS collapse by incgroup x married x nbkids x nb beneficiaries
* Blow up frequency in each cell so that enrollment matches macro total (blow up typically around 1.2)
* Then flat amount per beneficiary
* 1966-1979 = use 1979 frequencies by cell (with adjustment in 1966, 1967, 1968 and 1969 when enrollement freq were lower)
	qui gen nbmaid = 0
	if $yr>= 1966 {
		qui cumul income [w=dweght] if income>=0, gen(rank_inc)
		matrix define cumul=(-1 \ 0.05 \ 0.1 \ 0.15 \ 0.2 \ 0.25 \ 0.50 \ .90 \ 1)
		local I = rowsof(cumul)-1
		qui gen incgroup = 0
		forval i = 1/`I' { 	
			qui replace incgroup = `i' if rank_inc > cumul[`i',1] & rank_inc <= cumul[`i'+1,1]
		}	
		qui replace xkids=3 if xkids>=3 
		if $yr>= 1979 qui merge m:1 incgroup married xkids using "$diroutput/temp/cps/medicaidcollapse$yr.dta"
		if $yr>= 1966 & $yr < 1979 qui merge m:1 incgroup married xkids using "$diroutput/temp/cps/medicaidcollapse1979.dta"
		set seed 209411
		qui gen random  = uniform()
		qui gen cum = 0
		forval i = 0/5 {			
			qui replace nbmaid = `i' if random >= cum & random < cum + freq`i' 
			qui replace cum = cum + freq`i' 
		}
		qui su nbmaid [w=dweght], meanonly
		local nbbenef = r(sum)/10e10 
		di "NUMBER OF ALLOCATED MEDICAID BENEFICIARIES IN $YR = `nbbenef' MILLION"
		local missing = `ttmedicaidenroll' - `nbbenef'
		di "NUMBER OF MISSING MEDICAID BENEFICIARIES IN $YR = `missing' MILLION"
		local blowupmedicaid = `ttmedicaidenroll' / `nbbenef'
		di "BLOW UP FACTOR MEDICAID BENEFICIARIES IN $YR = `blowupmedicaid'"
		qui rename freq0 nobenef
		foreach var of varlist freq* {
			replace `var' = `var' * `blowupmedicaid'
		}
		qui egen aux=rsum(freq*)
		qui replace nobenef = 1 - aux
		qui drop aux 
		qui rename nobenef freq0
		qui drop nbmaid cum		
		qui gen nbmaid = 0
			label variable nbmaid "Number of medicaid beneficiaries in tax unit"
		qui gen cum = 0
		forval i = 0/5 {			
			qui replace nbmaid = `i' if random >= cum & random < cum + freq`i' 
			qui replace cum = cum + freq`i' 
		}
		drop if dweght==.
		qui drop freq* cum random rank_inc  _merge
	}
	qui su nbmaid [w=dweght], meanonly
		local nbbenef = r(sum)/10e10 
		di "NUMBER OF MEDICAID BENEFICIARIES IN $YR = `nbbenef' MILLION"
	qui gen medicaid = nbmaid * `ttmedicaid' / `nbbenef'
		label variable medicaid "Amount of medicaid benefits received by tax unit"
	qui replace medicaid = 0 if medicaid == .	
	mat medicaid$yr = ($yr, `nbbenef')
	mat medicaid = (nullmat(medicaid) \medicaid${yr})
	mat list medicaid
		di "NUMBER OF MEDICAID BENEFICIARIES"
	if $yr>=1966 {
		table incgroup  xkids [w=dweght], c(mean nbmaid) row col
		drop incgroup
	}	

****************************************************************************************************************************************************************
*
* MOVE TO INDIVIDAL LEVEL
*
****************************************************************************************************************************************************************


* create two records for each obs with married==1
	qui gen second=1
		qui replace second=2 if married==1
	expand second
	    cap drop count
		bys id: gen count=_n
		qui replace second=count-1
	sort id second
	qui gen old = 0
		label variable old "Aged 65+"
		qui replace old = 1 if second == 0 & oldexm == 1
		qui replace old = 1 if second == 1 & oldexf == 1
	*	drop oldexm oldexf
	qui rename age ageprim
	qui gen age = .
		label variable age "Age (20=20-44, 45=45-64, 65=65+, 0=20-64 pre 1979)"
		label variable ageprim "Age of primary earner in tax unit (20=20-44, 45=45-64, 65=65+, 0=20-64 pre 1979)"
		label variable agesec "Age of secondary earner in tax unit (20=20-44, 45=45-64, 65=65+, 0=20-64 pre 1979), =age if single"
		label define age 0 "20-64" 20 "20-44" 45 "45-64" 65 "65plus"
		label values age age
		label values ageprim age
		label values agesec age
		qui replace age = ageprim if second == 0
		qui replace age = agesec  if second == 1
	*	drop ageprim agesec
    * gender, added 4/2016
		qui replace female = femalesec  if second == 1
		drop femalesec

	save "$dirusdina/usdina$yr.dta", replace


******************************************************************************************
*
* INCOME SPLITTING
*
******************************************************************************************

***************************************************************************************************************
* SPLITS TAXABLE WAGE INCOME BETWEEN SPOUSES USING SHARE_F (and SHARE_F2 sophisticated split for 1999+ external)
* and share_ftrue for 1999+ internal
* SPLITS SELF-EMPLOYMENT INCOME using share_fse (share_fse is based on internal tab and sey seysec
***************************************************************************************************************

    cap drop wagind 
	gen wagind=waginc
	* gen share_fold=share_f
	* pre-1999, use the share_f basic tabulations CPS (and tax based at the top 5%)
	* after 1999, externally use share_f2, more sophisticated imputation using bigger table
	* after 1999, internally use share_ftrue, based on true W2 split
	* 10/2016 comment out this line [as I use only rough earnings split]
	* replace share_f=share_f2 if $yr>=1999 & $data==0 & filer==1
	replace share_f=share_ftrue if $yr>=1999 & $data==1 & filer==1
	replace wagind=(1-share_f)*waginc if married==1 & second==0  & filer==1
	replace wagind=share_f*waginc if married==1 & second==1  & filer==1
	
	* use direct info from CPS for individual wages of nonfilers (in principle this is redundant)
	cap replace wagind=waginc-wagincsec if filer==0 & married==1 & second==0
    cap replace wagind=wagincsec if filer==0 & married==1 & second==1
    cap replace share_f=wagincsec/waginc if filer==0 & married==1
	* clean up share_f share_fse
	replace share_f=0 if share_f==. & married==1
    replace share_f=0 if married==0	
	replace share_f=min(1,share_f)
	replace share_f=max(0,share_f)
	
	replace share_fse=0 if married==0
		
******************************************************************************************
* SPLITS PENSION, POSITIVE BUSINESS INC & BENEFITS
******************************************************************************************
	
* Splits pension income 50/50
	foreach var of global peninc_irs {
		qui replace `var'=`var'/2 if married==1
	}
	
* Splits positive business income  50/50 for capital component (assumed to be 30%) and according to share_fse for labor component (assumed to be 70%)
	foreach var of varlist schcincp partpinc partpinc2 rylinc {
		* spliting the labor income according to share_fse
		qui gen `var'_l = 0.7*`var'
		qui replace `var'_l = 0.7*(1-share_fse)*`var' if married==1 & second==0
		qui replace `var'_l = 0.7*share_fse*`var' if married==1 & second==1
		* spliting the labor income according to share_fse + capital component 50/50
		qui replace `var' = 0.3*0.5*`var'+0.7*(1-share_fse)*`var' if married==1 & second==0
		qui replace `var' = 0.3*0.5*`var'+0.7*share_fse*`var' if married==1 & second==1
	}	
		
* Splits benefits 50/50 (to be improved with CPS)
	foreach var in $benefits_irs ssinc_oa ssinc_di supinc snapinc workcomp vetben tanfinc othben medicaid {
		qui replace `var'=`var'/2 if married==1
	}


********************************************************************************
* Split other IRS income
********************************************************************************

* Splits wealth 50/50
	foreach var in hweal $hweal $mhweal {
		qui replace `var'=`var'/2 if married==1
	}

* Splits IRS capital income 50/50
	foreach var in scorpinc scorpinc2 {
    qui replace `var'=`var'/2 if married==1
	}			
	foreach var of global kinc_irs  {
    qui replace `var'=`var'/2 if married==1
	}	
		
* Splits business losses 50/50 (since this can be seen as negative capital income)
	foreach var of varlist schcincl scorlinc scorlinc2 partlinc partlinc2 {
	qui replace `var'=`var'/2 if married==1
	}

* Splits itemized deductions 50/50
	foreach var of global item_irs {
	qui replace `var'=`var'/2 if married==1
	}

* Reconstruct net business components
	qui replace schcinc=schcincp-schcincl if married==1
	qui replace scorinc=scorpinc-scorlinc if married==1
	qui replace partinc=partpinc-partlinc if married==1
	qui replace partinc=partpinc2-partlinc2 if id==0
	qui replace scorinc=scorpinc2-scorlinc2 if id==0	

* Reconstruct IRS income variables
	qui replace income=wagind+peninc+schcinc+scorinc+partinc+divinc+intinc+rentinc+estinc+rylinc+othinc if married==1
	gen incomekg=income+kginc
		label variable incomekg "IRS income, including KG"
	qui replace incomeps=incomeps/2 if married==1&filer==0
	qui replace incomeps=income if married==1&filer==1
				
* Splits taxes: proportionnally to income (positive parts only to avoid infinite shares)
	qui gen incomepos = wagind+peninc+schcincp+scorpinc+partpinc+divinc+intinc+rentincp+max(0,estinc)+max(0,rylinc)+max(0,othinc)
	qui bysort id: egen coupleinc=sum(incomepos)
	gen shinc=incomepos/coupleinc
	* added 3/2018 to fix missing problem when shinc=., also replaced estinc by max(0,estinc) to avoid negative
	replace shinc=.5 if shinc==. & married==1
	replace shinc=1 if shinc==. & married==0
	
	foreach var of global tax_irs {
		cap qui replace `var'=`var'*shinc if married==1
	}
	drop incomepos coupleinc
	drop sey seysec


****************************************************************************************************************************************************************	
*
* CREATE FISCAL INCOME
*
****************************************************************************************************************************************************************


* Fiscal income components
	qui egen fiwag=rsum(wagind peninc)
		label variable fiwag "Fiscal income, wages and pensions"
	qui egen fibus=rsum(schcinc scorinc partinc)
		label variable fibus "Fiscal income, business inc"
	qui egen firen=rsum(rentinc estinc rylinc othinc)
		label variable firen "Fiscal income, rents"
	qui gen fidiv = divinc
		label variable fidiv "Fiscal income, dividends"
	qui gen fiint = intinc 
		label variable fiint "Fiscal income, interest"
	qui gen fikgi = kginc 
		label variable fikgi "Fiscal income, capital gains"	
	qui egen fiinc=rsum(${fiinc})
		label variable fiinc "Fiscal income (incl. KG)"
	qui egen fninc=rsum(${fninc})
		label variable fninc "Fiscal income (excl. KG)"	
	qui rename incomeps fnps
		label variable fnps "Fiscal income (excl. KG), flat income for non-filers, matching PS shares"	


****************************************************************************************************************************************************************	
*
* CREATE INTUITIVE INCOME
*
****************************************************************************************************************************************************************

* Not used for now
*	gen itlab=fiwag+fibus
*	gen itcap=fidiv+fiint+firen+0.04*owner*1e6



****************************************************************************************************************************************************************
*
* PERSONAL FACTOR INCOME
*
****************************************************************************************************************************************************************

********************************************************************************
* Factor capital income
********************************************************************************

foreach w in $hweal $mhweal {
	qui su `w' [w=dweght]
	local tt`w'=r(sum)/10e10
}

* Factor capital income = wealth x return gross of all taxes (incl. sales taxes)
	qui gen fkhoumain = 0
		label variable fkhoumain "Main housing asset income"
		qui replace fkhoumain = ownerhome * `ttfkhoumain' / `ttrestw'	
	qui gen fkhourent = 0
		label variable fkhourent "Rental housing asset income"
		qui replace fkhourent = rentalhome * `ttfkhourent' / (`ttrentw'-`ttrentmortw')		
	qui gen fkhou=0
		label variable fkhou "Housing asset income" 
		qui replace fkhou = fkhoumain + fkhourent
	qui gen fkequ=0
		label variable fkequ "Equity asset income" 
		qui replace fkequ=hwequ*`ttfkequ'/`tthwequ'
	qui gen fkfix=0
		label variable fkfix "Interest income"
		qui replace fkfix=hwfix*`ttfkfix'/`tthwfix'
	qui gen fkbus=0
		label variable fkbus "Business asset income" 
		qui replace fkbus=hwbus*`ttfkbus'/`tthwbus'	
	qui gen fkpen=0
		label variable fkpen "Pension and insurance asset income" 
		qui replace fkpen=hwpen*`ttfkpen'/`tthwpen'	
	qui gen fkmor=0
		label variable fkmor "Mortgage interest payments" 
		qui replace fkmor=(ownermort+rentalmort)*`ttfkmor'/(`ttownermort'+`ttrentalmort')
	qui gen fknmo=0
		label variable fknmo "Non-mortgage interest payments" 
		qui replace fknmo=nonmort*`ttfknmo'/`ttnonmort'
	qui egen fkdeb=rsum(fkmor fknmo)
		label variable fkdeb "Interest payments"	

	qui egen fkinc=rsum(${fkinc})
		label variable fkinc "Personal factor capital income"	
	
	qui gen fkprk = 0 
		label variable fkprk "Sales and excise taxes falling on capital"
		qui su fkinc [w=dweght], meanonly
		local total_fkinc = r(sum) / 10e10
		di "TOTAL FACTOR CAPITAL INCOME INCLUDING SALES TAXES = `total_fkinc'"
		qui replace fkprk = `ttfkprk' * fkinc / `total_fkinc'
	qui sum fkprk [w=dweght], meanonly
		assert round(`ttfkprk') == round(r(sum)/10e10)
	qui sum fkinc [w=dweght], meanonly	
	 	* assert round(`ttfkinc') == round(r(sum)/10e10)

compress
save "$dirusdina/usdina$yr.dta", replace

********************************************************************************
* Factor labor income
********************************************************************************

* Compensation of employees	
	do "programs/sub_factorinc_0"

* Other labor components
	qui gen flmil=0
		label variable flmil "Labor share of net mixed income"
	    gen businc = partpinc_l + schcincp_l + rylinc_l
		qui su businc [w=dweght]
		qui replace flmil = businc *`ttfllbu'/(r(sum)/10e10)
		drop businc partpinc_l schcincp_l rylinc_l
		qui gen flprl=0
		label variable flprl "Sales and excise taxes falling on labor"
			qui replace flprl=`ttflprl'*(flemp+flmil)/(`ttflemp'+`ttfllbu')
	qui egen flinc = rsum(${flinc})
		label variable flinc "Personal factor labor income"
		
	qui egen fainc = rsum(flinc fkinc)
		label variable 	fainc "Personal factor income"	
	 qui sum fainc [w=dweght], meanonly	
	 local total_factorinc = r(sum) / 10e10
	 	* assert round(`ttfainc') == round(`total_factorinc') 
	

****************************************************************************************************************************************************************	
*
* PERSONAL PRE-TAX INCOME
*
****************************************************************************************************************************************************************

* Split self-employment payroll taxes into old age , disability insurance, & hospital insurance
	replace setax = 0 if setax == .
	qui su setax [w=dweght]
		local ttsetax = r(sum)*1e-11
	qui gen oacont_se = 0
		qui replace oacont_se = setax * `ttsecont_oa' / `ttsetax'
	qui gen dicont_se = 0
		qui replace dicont_se = setax * `ttsecont_di' / `ttsetax'
	qui gen hicont_se = 0
		qui replace hicont_se = setax * `ttsecont_hi' / `ttsetax'
		qui replace hicont_se = 0 if hicont_se == .

* Pre-tax labor income
	qui gen plpco = 0
		label variable plpco "(Minus) pension contributions (employer + employee + self-employed, SS + non-SS)"
		qui replace plpco = - wagpen - oacont - oacont_se
		qui su plpco [w=dweght], meanonly 
		local totplpco = r(sum)*1e-11		
	qui gen ploco = 0
		label variable ploco "(Minus) DI and UI contributions (employer + employee + self-employed)"
		qui replace ploco = - dicont - uicont - dicont_se 
	qui gen plcon = 0 
		label variable plcon "(Minus) social contributions (pensions + DI + UI, employers + employees + self-employed)"
		qui replace plcon = plpco + ploco
		qui su plcon [w=dweght], meanonly 
		local totplcon = r(sum)*1e-11
		di "CHECK TOTAL SOCIAL CONTRIBUTIONS (PENSIONS + DI + UI) in $yr DINA = `totplcon' NIPA = `ttplcon'"
	qui gen plpbe = 0
		label variable plpbe "Pension benefits (SS + non-SS)"
		qui replace plpbe = peninc + penincnt + ssinc_oa   
		qui su plpbe [w=dweght]
		local blowuppenben = `ttpenben' / (r(sum)*1e-11)	// For now crude adjustment to match total NIPA pension benefits
		di "BLOW UP FACTOR FOR PENSION BENEFITS IN YEAR $yr: `blowuppenben'"
		qui replace plpbe = plpbe * `blowuppenben'
	qui gen plobe = 0
		label variable plobe "UI and DI benefits"
		qui replace plobe = uiinc + ssinc_di 	
		qui su plobe [w=dweght], meanonly
		local blowupuidiben = `ttuidiben' / (r(sum)*1e-11)	
		di "BLOW UP FACTOR FOR UI AND DI BENEFITS IN YEAR $yr: `blowupuidiben'"
		qui replace plobe = plobe * `blowupuidiben'		
	qui gen plben = 0	
		label variable plben "Social insurance income (pensions + DI + UI)"
		qui replace plben = plpbe + plobe 
	qui gen pkpen = 0
		label variable pkpen "(Minus) Investment income payable to pension funds (DB + DC + IRA, but excluding life insurance)"
		qui replace pkpen = fkpen
		qui su pkpen [w=dweght], meanonly
		local blowuppkpen = `ttinvincpen' / (r(sum)*1e-11) 
		qui replace pkpen = - pkpen * `blowuppkpen'
		qui su pkpen [w=dweght], meanonly
		local totpkpen = r(sum)*1e-11
	qui gen plbel = 0
		label variable plbel "Labor share of social insurance income (pensions + DI + UI)"
		qui replace plbel = plben * `totplcon' / (`totplcon' + `totpkpen') 
	qui gen plpbl = 0
		label variable plpbl "Labor share of pension benefits" 	
		qui replace plpbl = plpbe * `totplpco' / (`totplpco' + `totpkpen')
	qui egen plinc = rsum($plinc)
		label variable 	plinc "Personal pre-tax labor income (broad definition: pension + UI + DI)"	
	qui egen plnin = rsum($flinc plpco plpbl)	
		label variable 	plnin "Personal pre-tax labor income (narrow definition: pensions only)"	


* pre-tax capital income 
	qui gen pkbek = 0 
		label variable pkbek "Capital share of social insurance income (pensions + DI + UI)"
		qui replace pkbek = plben * `totpkpen' / (`totplcon' + `totpkpen') 
	qui gen pkpbk = 0
		label variable pkpbk "Capital share of pension benefits"
		qui replace pkpbk = plpbe * `totpkpen' / (`totplpco' + `totpkpen') 
	qui egen pkinc = rsum($pkinc)
		label variable 	pkinc "Personal pre-tax capital income (broad definition: pension + UI + DI)"			
	qui egen pknin = rsum($fkinc pkpen pkpbk)
		label variable 	pknin "Personal pre-tax capital income (narrow definition: pensions only)"

* Pre-tax income
	qui egen ptinc = rsum($ptinc)
		label variable ptinc "Personal pre-tax income (broad definition: pension + UI + DI)"
	qui egen ptnin = rsum(plnin pknin)	
		label variable 	ptnin "Personal pre-tax income (narrow definition: pensions only)"	

save "$dirusdina/usdina$yr.dta", replace


****************************************************************************************************************************************************************	
*
* DISPOSABLE INCOME
*
****************************************************************************************************************************************************************

* Taxes 
	gen eic = eictot - eicrefn
	qui egen ditaf = rsum(fedtax  eic) 
		label variable ditaf "Federal personal income tax (before EITC, additional CTC, and other refundable tax credits). Cannot be negative"
		* assert ditaf >= 0	
		qui su ditaf [w=dweght]	
			local blowupfedtax = `ttfedtax' / (r(sum)*1e-11)	// to be immproved with taxsim; for now adjustment to match total NIPA fed tax receipts (which are gross of refundable credits, see http://www.bea.gov/scb/pdf/2015/06%20June/0615_preview_of_2015_annual_revision_of_national_income_and_product_accounts.pdf)
			di "ADJUSTMENT FACTOR FOR FEDERAL INCOME TAX PAYMENTS IN YEAR $yr: `blowupfedtax'"
		qui replace ditaf = ditaf * `blowupfedtax'
	qui gen ditas = 0 // State tax: reported by itemizers, proportional to federal income tax for non-itemizers
		label variable ditas "State personal income tax"
		qui replace ditas = statetax if item == 1
		qui su ditas [w=dweght] if item == 1	
		local totstateitem = r(sum)*1e-11
		local totstatenonitem = `ttstatetax' - `totstateitem'
		qui su ditaf [w=dweght] if item == 0	
		local totfednonitem = r(sum)*1e-11
		qui replace ditas = ditaf * `totstatenonitem' / `totfednonitem' if item == 0
		// Check ratio State tax paid by itemizers / total State tax paid (and ratio federal tax paid by itemizers / total fed tax: check both ratios look the same)
			local ratio_state = `totstateitem' / `ttstatetax'
			mat check_ratio_statetax_item_$yr = ($yr, `ratio_state')
			mat check_ratio_statetax_item = (nullmat(check_ratio_statetax_item) \ check_ratio_statetax_item_$yr)
			qui su ditaf [w=dweght] if item == 1, meanonly
			local ratio_fed = `r(sum)'*1e-11 / `ttfedtax'
			mat check_ratio_fedtax_item_$yr = ($yr, `ratio_fed')
			mat check_ratio_fedtax_item = (nullmat(check_ratio_fedtax_item) \ check_ratio_fedtax_item_$yr)
	qui gen ditax = ditaf + ditas
		label variable ditax "Current personal taxes on income and wealth"
	qui gen estatetax = 0
		label variable estatetax "Estate tax" // uses frac estate tax paid by fractiles of decedents and assume prop. to wealth within wealth group
		qui cumul hweal [w=dweght], gen(rankwealth)
		qui su hweal [w=dweght] if rankwealth < .9, meanonly
			qui replace estatetax = (hweal / r(mean)) * `ttestatetax' * `fracestp0p90' / (r(sum_w)/10e10) if rankwealth < .9
		qui su hweal [w=dweght] if rankwealth >= .9 & rankwealth < .95, meanonly
			qui replace estatetax = (hweal / r(mean)) *`ttestatetax' * `fracestp90p95' / (r(sum_w)/10e10) if rankwealth>= .9 & rankwealth < .95	 
		qui su hweal [w=dweght] if rankwealth >= .95 & rankwealth < .99, meanonly
			qui replace estatetax = (hweal / r(mean)) *`ttestatetax' * `fracestp95p99' / (r(sum_w)/10e10) if rankwealth>= .95 & rankwealth < .99	
		qui su hweal [w=dweght] if rankwealth >= .99 & rankwealth < .995, meanonly
			qui replace estatetax = (hweal / r(mean)) *`ttestatetax' * `fracestp99p995' / (r(sum_w)/10e10) if rankwealth>= .99 & rankwealth < .995						
		qui su hweal [w=dweght] if rankwealth >= .995 & rankwealth < .999, meanonly
			qui replace estatetax = (hweal / r(mean)) *`ttestatetax' * `fracestp995p999' / (r(sum_w)/10e10) if rankwealth>= .995 & rankwealth < .999		
		qui su hweal [w=dweght] if rankwealth >= .999 & rankwealth < .9999, meanonly
			qui replace estatetax = (hweal / r(mean)) *`ttestatetax' * `fracestp999p9999' / (r(sum_w)/10e10) if rankwealth>= .999 & rankwealth < .9999				
		qui su hweal [w=dweght] if rankwealth >= .9999, meanonly
			qui replace estatetax = (hweal / r(mean)) *`ttestatetax' * `fracesttop001' / (r(sum_w)/10e10) if rankwealth>= .9999					
		qui drop rankwealth
	qui gen proprestax = 0
		label variable proprestax "Residential property tax (prop. to housing assets)"	
		qui su hwhou [w=dweght]
		qui replace proprestax = hwhou * `ttproptax_res' / (r(sum)/10e10)
	// Corporate tax, various incidence scenarios
		qui gen c_corp_equ = hwequ - scorw + `fraceqpen' * hwpen
			qui su c_corp_equ [w=dweght], meanonly
			local total_c_corp_equity = r(sum)/10e10
		qui gen wealth_exc_housing = hweal - housing
			qui su wealth_exc_housing [w=dweght], meanonly
			local total_wealth_exc_housing = r(sum)/10e10
		foreach incidence of numlist 0 60 100 {
			qui gen corptax`incidence' = (`incidence'/100)  * `ttfkcot' * c_corp_equ  / `total_c_corp_equity'	+ (1 - `incidence'/100) * `ttfkcot' * wealth_exc_housing / `total_wealth_exc_housing' 
				label variable corptax`incidence' "Corporate tax (`incidence'% on corporate equity)"	
				qui sum corptax`incidence' [w=dweght], meanonly
				assert round(`ttfkcot') == round(r(sum)/10e10)
		}	
		qui drop wealth_exc_housing
		qui gen corptax = corptax100
			label variable corptax "Corporate tax (100% on C-corporate equity)"

	qui gen propbustax = 0	
		label variable propbustax "Business property tax (prop. to equity & business assets)"	
		qui gen prop_wealth = c_corp_equ + scorw + hwbus
			qui su prop_wealth [w=dweght], meanonly
			local total_prop_wealth = r(sum)/10e10		
		qui replace propbustax = prop_wealth * `ttproptax_bus' / `total_prop_wealth'
		qui drop prop_wealth
	qui gen othercontrib = 0
		label variable othercontrib "Contributions for government social insurance other than pension, UI, DI"
		qui replace othercontrib = hicont + hicont_se 
		qui su othercontrib [w=dweght]
		local rest =`ttothcon' - (r(sum) * 1e-11) // the rest = supplemental medical insurance, veterans, etc. = assume prop. to compensation of employee
		qui su flemp [w=dweght]
		qui replace othercontrib = othercontrib + flemp * `rest' / (r(sum) * 1e-11)

* Social assistance benefits in cash 
	qui gen dicred = 0
		label variable dicred "Refundable tax credits"
		qui replace dicred = eictot + ctcrefn
		// post 2008: need to add 2008 Economic Stimulus Payments, American Opportunity Tax Credit, Making Work Pay Tax Credit, Health Insurance Premium Assistance Credits 
		// refundable credits attached to t-1 income are treated as social  benefits paid in t in the NIPAs, hence a one year lag between tax data/NIPAs that needs to be fixed (not obvious how, but the NIPA timing makes more sense: 2008 Economic stimulus payments should be treated as 2008, not 2007, transfers)
		qui su dicred [w=dweght]
		local blowupcred = `ttcred' / (r(sum)*1e-11) // See whether this can be improved with taxsim  (right now pb of one year gap NIPA vs IRS)
			di "ADJUSTMENT FACTOR FOR REFUNDABLE TAX CREDITS IN YEAR $yr: `blowupcred'"
		qui replace dicred = dicred * `blowupcred'	
		qui replace dicred = 0 if dicred == .
	qui gen difoo = snapinc
		label variable difoo "Food stamps (SNAP)" 
	qui gen disup = supinc
		label variable disup "Supplemental security income"	
	qui gen divet = vetben
		label variable divet "Veteran benefits" 
	qui gen diwco = workcomp
		label variable diwco "Workers' compensation benefits" 
	qui gen dicao = othben + tanfinc
		label variable dicao "Other social assistance benefits in cash"	
	qui gen dicab = 0
		label variable dicab "Social assitance benefits in cash"
		qui replace dicab = dicred + divet + diwco + difoo + disup + dicao
	qui gen dicsh = 0
		qui gen salestax = flprl + fkprk
		label variable dicsh "Disposable cash income"
		qui replace dicsh = ptinc - salestax - propbustax - proprestax - corptax - ditax - estatetax - othercontrib + dicab
	
* In-kind transfers					
	qui gen medicare = 0 
		label variable medicare "Medicare = capitation for 65+ individuals"
		qui su dweght if old == 1
		local totold = r(sum)/10e10
		di "TOTAL NUMBER OF 65+ INDIVIDUALS IN $yr = `totold' MILLION"
		replace medicare = `ttmedicare' / `totold' if old == 1
		replace medicare = 0 if medicare == .
	* Medicaid constructed above
	qui gen otherkin = 0 // 50% = pell grant; 50% = veterans health care
		label variable otherkin "Other in-kind transfers (pell grants + state schships + veterans' health care + other)"
		bysort id: egen faminc = sum(income)
		qui cumul faminc [w=dweght] if faminc >= 0, gen(rank_inc) 
		set seed 539459
		qui gen random = uniform() if xkidspop > 0 & rank_inc <= 0.5
		qui gen haspell = (random >= 0.85 & random!=.) // assume 15% of bottom 50% families with kids have pell grant; to be improved
		qui gen pell = 0
			label variable pell "Pell grants received"
		qui su haspell [w=dweght] 
		local avgpell =  0.5 * `ttothinkind' / (r(sum)/10e10)
		qui replace pell = `avgpell' * haspell
		di "AVERAGE PELL GRANT IN YEAR $yr = `avgpell'"
		qui drop random rank_inc 
		qui cumul income [w=dweght] if income >= 0, gen(rank_inc) 
		set seed 389700
		qui gen random = uniform() if rank_inc <= 0.5
		qui gen vet = (random >= 0.8 & random!=.) // assume vet = 10% of adult population and all in bottom 50%; to be improved with CPS and gender info
		gen vethealth = 0
			label variable vethealth "Veteran in-kind health benefits"
		qui su vet [w=dweght] 
		local avgvethealth =  0.5 * `ttothinkind' / (r(sum)/10e10)
		qui replace vethealth = `avgvethealth' * vet
		di "AVERAGE VET HEALTH IN KIND BENEFITS IN YEAR $yr = `avgvethealth'"
		qui replace otherkin = pell + vethealth
		qui drop random rank_inc 
	qui gen inkindinc = 0
		label variable inkindinc "Social transfers in kind"
		replace inkindinc = medicare + medicaid + otherkin
	qui gen dikin = 0
		label variable dikin "Disposable cash + in-kind income" 
		replace dikin = dicsh + inkindinc
	qui gen colexp = 0
		label variable colexp "Collective consumption expenditure"
		qui su dicsh [w=dweght]
		replace colexp = dicsh * `ttcolexp' / (r(sum)/10e10)
	qui gen educ = 0
		label variable educ "Education collective consumption expenditure"
		qui su xkidspop [w=dweght] if second == 0
		local totkids = r(sum)/10e10
		di "TOTAL NUMBER OF CHILDREN IN $yr = `totkids' MILLION"
		qui replace educ = xkidspop * `tteducexp' / `totkids'
		qui replace educ = educ/2 if married==1
	qui gen colexp2 = 0
		label variable colexp2 "Collective consumption exp. (with lump sum educ.)"
		qui su dicsh [w=dweght]
		replace colexp2 = dicsh * (`ttcolexp' - `tteducexp') / (r(sum)/10e10) + educ
		qui su colexp2, meanonly
	qui egen diinc = rsum($diinc)
		label variable diinc "Extended disposable income (cash + kind + col. exp)"
	qui gen diinc2 = diinc - colexp + colexp2	
save "$dirusdina/usdina$yr.dta", replace




* Sales and excise taxes incidence: create variable salestax (for taxes paid), same total as (flprl + fkprk) but different distribution 
* Variable salestax: assume 70% shifted to prices, 30% to factors 
* Taxes shifted to prices fall on consumption as in ITEP "Who Pays What" https://itep.org/whopays/
* Specifically, we apply their sales tax rate by bins of disposable cash income + Fed + state individual taxes (excluding food stamps as groceries generally exempt)
	// Start with portion on prices
		qui drop salestax
		qui gen salestax = 0
		collapse (sum) dicsh ditax difoo (mean) dweght dweghttaxu, by(id)
			qui gen dicsh2 = dicsh + ditax - difoo
			qui cumul dicsh2 [w=dweght], gen(rank_dicsh2)
			qui gen salestax = 0
				label variable salestax "Sales and excise taxes" 
				qui replace salestax = dicsh2 * 0.0712 if rank_dicsh2 < .2
				qui replace salestax = dicsh2 * 0.0594 if rank_dicsh2>= .2 & rank_dicsh2 < .4	 
				qui replace salestax = dicsh2 * 0.0475 if rank_dicsh2>= .4 & rank_dicsh2 < .6	
				qui replace salestax = dicsh2 * 0.0376 if rank_dicsh2>= .6 & rank_dicsh2 < .8						
				qui replace salestax = dicsh2 * 0.0274 if rank_dicsh2>= .8 & rank_dicsh2 < .95		
				qui replace salestax = dicsh2 * 0.0170 if rank_dicsh2>= .95 & rank_dicsh2 < .99				
				qui replace salestax = dicsh2 * 0.0087 if rank_dicsh2>= .99				
			qui drop rank_dicsh2
			qui drop dicsh2
			qui su salestax [w=dweght], meanonly
			local totsalestax_itep = r(sum)/10e10
			qui replace salestax = salestax * (0.7 * `ttsalestax' / `totsalestax_itep')
			keep id salestax
		save "$diroutput/temp/salestax$yr.dta", replace
		use "$dirusdina/usdina$yr.dta", clear
		drop salestax
		merge m:1 id using "$diroutput/temp/salestax$yr.dta"
	qui replace salestax = salestax * shinc 
	// Add portion on factors
		qui gen salestax_on_factor = 0
		qui sum fainc [w=dweght], meanonly
		local total_fainc = r(sum) / 10e10
		qui replace salestax_on_factor = (0.3 * `ttsalestax') * fainc / `total_fainc'
		qui replace salestax = salestax + salestax_on_factor
		qui sum salestax [w=dweght], meanonly
		assert round(`ttsalestax') == round(r(sum)/10e10)


****************************************************************************************************************************************************************	
*
* FACTOR NATIONAL INCOME VS PRE-TAX NATIONAL INCOME VS POST-TAX NATIONAL INCOME (SAME AGGREGATE)
*
****************************************************************************************************************************************************************

* Total taxes and benefits (used to allocate deficit)
	qui gen ssuicontrib = oacont + oacont_se + dicont + dicont_se + uicont
		label variable ssuicontrib "Contributions for government social insurance: pensions, UI, DI"
	qui gen govcontrib = ssuicontrib + othercontrib 
		label variable govcontrib "Total contributions for government social insurance"
	qui gen tax = salestax + proprestax + propbustax + ditax + corptax + estatetax + govcontrib
		label variable tax "Total taxes and social contributions paid"
			qui su tax [w=dweght], meanonly
			local tottax = r(sum)/10e10
			di "CHECK: TOTAL TAXES AND SOCIAL CONTRIB in $yr DINA = `tottax' NIPA = `tttax'"		
	qui gen ben = dicab + inkindinc + colexp
		label variable ben "Total benefits (cash + kind + coll, excl. pensions, UI, DI)" 
		qui su ben [w=dweght], meanonly
		local totben = r(sum)/10e10
		di "CHECK: TOTAL BENEFITS (CASH + KIND + COLL) in $yr DINA = `totben' NIPA = `ttben'"

* Factor national income (matching national income)
	qui gen govin = 0
		label variable govin "(Minus) Net property income paid by gov. (allocted 50% prop. to taxes, 50% to benefits) "
		*qui su dweght
		*local totadult = r(sum)/10e10
		*di "TOTAL NUMBER OF ADULTS IN $yr = `totadult' MILLION"
		*replace govin = - `ttgovint' / `totadult'
		replace govin = - (0.5 * `ttgovint' / `tottax' * tax + 0.5 * `ttgovint' / `totben' * ben) 
	qui gen npinc = 0
		label variable npinc "Net primary income of non-profit institutions (prop. to disposable income)"
		qui su dikin [w=dweght]
		replace npinc = dikin * `ttnpishinc' / (r(sum)/10e10)
	qui gen invpen = - pkpen
		label variable invpen "Investment income payable to pension funds (DB + DC + IRA, but excluding life insurance)"
	qui egen princ = rsum($princ)
		label variable princ "Factor national income (matching macro NI)"	

* Pre-tax national income (matching national income)
	qui gen prisupss = 0
		label variable prisupss "Primary surplus (= contrib - distrib) of Social Security + UI (allocted 50% prop. to taxes, 50% to benefits)"
		qui replace prisupss = 0.5 * `ttprisupss' / `tottax' * tax + 0.5 * `ttprisupss' / `totben' * ben 
	qui gen prisupenprivate = 0
		label variable prisupenprivate "Primary surplus (= contrib - distrib) of private pension system (allocted prop. to wages)"
		qui su flemp [w=dweght]
		local totflemp = r(sum)/10e10
		qui replace prisupenprivate = flemp * `ttprisupenprivate' / `totflemp ' 
	qui gen prisupen = 0
		label variable prisupen "Primary surplus (= contrib - distrib) of pension system "
		qui replace prisupen = prisupss + prisupenprivate		
	qui egen peinc = rsum($peinc)
		label variable peinc "Pre-tax national income (matching macro NI)"
	qui egen peinck = rsum(pkinc  govin  npinc  invpen)
		label variable peinck "Pre-tax national capital income (matching macro NI)"
	qui egen peincl = rsum(plinc  prisupen)	
		label variable peincl "Pre-tax national labor income (matching macro NI)"

* Post tax national income
	qui gen prisupgov = 0
		label variable prisupgov "Government primary surplus (= taxes - benefits) (allocted 50% prop. to taxes, 50% to benefits)"
		qui replace prisupgov = 0.5 * `ttprimsupgov' / `tottax' * tax + 0.5 * `ttprimsupgov' / `totben' * ben 
	qui egen poinc = rsum($poinc)
		label variable poinc "Post-tax national income (matching macro NI)"	
	
* Post tax national income with education lump sum
	qui gen ben2 = dicab + inkindinc + colexp2
		qui su ben2 [w=dweght], meanonly
		local totben2 = r(sum)/10e10
	qui gen prisupgov2 = 0
		qui replace prisupgov2 = 0.5 * `ttprimsupgov' / `tottax' * tax + 0.5 * `ttprimsupgov' / `totben2' * ben2 
	qui egen poinc2 = rsum(diinc2 govin npinc prisupenprivate invpen prisupgov2)
		label variable poinc2 "Post-tax national income (matching macro NI) (education lump sum)"
		
		
****************************************************************************************************************************************************************	
*
* SAVE
*
****************************************************************************************************************************************************************

* added 3/2019, keep fringe benefits for computation

if $data==1 & $yr==2015 {
  gen w2health=w2healthprim
  replace w2health=w2healthsec if second==1
  replace w2health=0 if w2health==.
  gen w2pension=w2pensionprim
  replace w2pension=w2pensionsec if second==1
  replace w2pension=0 if w2pension==.
  replace w2health=min(w2health,100000)
  gen w2hind=(w2health>0)
  gen w2pind=(w2pension>0)
  sum w2pension w2health w2pind w2hind agi wages [w=dweght]
  keep id dweght dweghttaxu female age* old* married second xkidspop filer $y $fiinc $fninc $mfiinc $fainc $flinc $fkinc $plinc $pkinc $ptinc $hweal $mflinc $mfkinc $mhweal $mplinc $mpkinc $mptinc $diinc $princ $peinc peinck peincl $poinc educ colexp2 poinc2 $mdiinc corptax* w2pension w2health w2pind w2hind
  order id dweght dweghttaxu female age* old* married second xkidspop filer $y $fiinc $fninc $mfiinc $fainc $flinc $fkinc $plinc $pkinc $ptinc $hweal $mflinc $mfkinc $mhweal $mplinc $mpkinc $mptinc $diinc $princ $peinc peinck peincl $poinc educ colexp2 poinc2 $mdiinc corptax* w2pension w2health w2pind w2hind
  label variable w2health "Fringe Health on W2"
  label variable w2pension "Fringe Elective Employee Pension on W2" 
  }


if $data==0 | $yr!=2015 {
keep  id dweght dweghttaxu female age* old* married second xkidspop filer $y $fiinc $fninc $mfiinc $fainc $flinc $fkinc $plinc $pkinc $ptinc $hweal $mflinc $mfkinc $mhweal $mplinc $mpkinc $mptinc $diinc $princ $peinc peinck peincl $poinc educ colexp2 poinc2 $mdiinc corptax*
order id dweght dweghttaxu female age* old* married second xkidspop filer $y $fiinc $fninc $mfiinc $fainc $flinc $fkinc $plinc $pkinc $ptinc $hweal $mflinc $mfkinc $mhweal $mplinc $mpkinc $mptinc $diinc $princ $peinc peinck peincl $poinc educ colexp2 poinc2 $mdiinc corptax*
}
	label variable second "Secondary filer"
cap drop ageimp agesecimp oldmar

* Added 1/1/2017 (edited 3/2018): for online use, we bin the ages of non-filers as we do for filers
	if $data==0 {
	foreach var of varlist age ageprim agesec {
	  replace `var'=20 if `var'<45 & `var'!=.
	  replace `var'=45 if `var'>45 & `var'<65 & `var'!=.
	  replace `var'=65 if `var'>65 & `var'!=.
		}
	}
	
* added 3/2018, fixing age for pre-1979 and set agesec to age for single filers (avoids having missing)
	if $yr<1979 {
	foreach var of varlist age ageprim agesec {
		replace `var'=0  if `var'==. | `var'==20 | `var'==45
	  }
	}
	replace agesec=age if married==0
  

  
  
compress
saveold "$dirusdina/usdina$yr.dta", replace


****************************************************************************************************************************************************************	
*
* CHECKS
*
****************************************************************************************************************************************************************

* Ouputs blow-up factors
	if $data == 0 {
		if $yr<=1966 {
			local blowupsnap = 0
			local blowupsnap2 = 0
			local blowupmedicaid = 0
		}
		global blowup  "blowupvalhome${yr} blowupvalmort${yr} blowupvalcurr${yr} blowupvalothd${yr} blowupss blowupui blowupssi blowupsnap blowupsnap2 blowuptanf blowuptanf2 blowuppenben blowupuidiben blowuppkpen blowupfedtax blowupcred blowupworkcomp blowupvetben blowupothben blowupmedicaid"
	  		local nbblowup : list sizeof global(blowup)			
	  		di "NUMBER OF BLOW UP FACTORS: `nbblowup'"
		matrix blowup$yr = J(1,(`nbblowup'+1),.)
			matrix colnames blowup$yr = year $blowup
			matrix blowup$yr[1,1]=$yr
			local jj=2
			foreach blow of global blowup {
				global blowfac="`blow'"
				matrix blowup$yr[1,`jj']=`${blowfac}'
				local jj=`jj'+1
			}
		matrix blowup = (nullmat(blowup) \ blowup$yr)		
		clear
		svmat blowup, names(col)
		qui compress
		export excel using "$diroutput/temp/blowup.xlsx", first(var) replace
	}

* Outputs capitalization factors
	if $data == 0 {
		local nbcapfac : list sizeof global(capfac)
		matrix capfac$yr = J(1,(`nbcapfac'+1),.)
			matrix colnames capfac$yr = year $capfac
			matrix capfac$yr[1,1]=$yr
			local jj=2
			foreach fac of global capfac {
				global factor="`fac'"
				matrix capfac$yr[1,`jj']=`${factor}'
				local jj=`jj'+1
			}
		matrix capfac = (nullmat(capfac) \ capfac$yr)
		clear
		svmat capfac, names(col)
		qui compress
		export excel using "$diroutput/temp/capfac.xlsx", first(var) replace
	}
