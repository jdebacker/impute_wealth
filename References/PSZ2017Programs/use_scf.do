* Feb. 2016: Program that constructs SCF datasets with relevant & harmonized variables & constructs matrices used for imputation into DINA 


****************************************************************************************************************************************************************	
*
* BUILDS HOMOGENEOUS SCF DATASETS
* Re-uses code from Saez-Zucman QJE 2016 scf.do (itself building on scf_juliana.do) and updates
*
****************************************************************************************************************************************************************

global scfyears "1989 1992 1995 1998 2001 2004 2007 2010 2013"


	foreach year of numlist $scfyears {

* merging the full public data with the summary extract public data (ID variable is Y1 except for 1989 when it is X1)
* 5 records for each respondent (for imputation of missing variables), population weights is variable wg
		use "$dirscfraw/fullp`year'.dta", clear
		gen year=`year'
		cap rename Y1 y1 
		cap rename X1 y1 
		sort y1
		merge 1:1 y1 using "$dirscfraw/rscfp`year'.dta"
		gen cpi=1
		gen cpi_wealth=1
		save "$dirscfclean/SCF`year'.dta", replace


	************************************************
	* defining capital income and wealth variables using the same names as in /SaezZucman2014/Data/irs_small/smallYYYY.dta files  
	* We use the naming convention of income variables from smallYYYY.dta files and use suffix _wscf for the corresponding wealth measures in SCF
	************************************************

	* cpi is cpi adjustment for income variables (year - 1 relative to file year)
	* cpi_wealth is cpi adjustment for wealth variables (same year as file year)
	* careful, the cpi adjustments in the summary extract are adjusted with each new wave 
	* 1989-2010 downloaded before 2013 was available so we used the 2010 old adjustment then
	replace cpi=(3208/1902)*(1886/1808) if year==1989
	replace cpi=(3208/2116)*(2103/2051) if year==1992
	replace cpi=(3208/2265)*(2254/2201) if year==1995
	replace cpi=(3208/2405)*(2397/2364) if year==1998
	replace cpi=(3208/2618)*(2600/2529) if year==2001
	replace cpi=(3208/2788)*(2774/2701) if year==2004
	replace cpi=(3208/3062)*(3045/2961) if year==2007
	replace cpi=(3208/3208)*(3202/3150) if year==2010
	replace cpi=(3438/3438)*(3421/3372) if year==2013

	replace cpi_wealth=(3208/1902) if year==1989
	replace cpi_wealth=(3208/2116) if year==1992
	replace cpi_wealth=(3208/2265) if year==1995
	replace cpi_wealth=(3208/2405) if year==1998
	replace cpi_wealth=(3208/2618) if year==2001
	replace cpi_wealth=(3208/2788) if year==2004
	replace cpi_wealth=(3208/3062) if year==2007
	replace cpi_wealth=(3208/3208) if year==2010
	replace cpi_wealth=(3438/3438) if year==2013

	* test of cpi with kginc and X5712
	gen test=kginc-X5712*cpi
	* sum test, det
	drop test

	* integer weight
	gen wgint=round(wgt*10000)


	* Age and marital status
	cap drop age
	rename X14 age
	rename X19 agespouse
	rename X8023 marstatus

	* oldmar interaction for imputations
		gen oldexm=(age>=65)
		cap drop married
		gen married=(marstatus==1)
		gen partner=(marstatus==2)
			label variable partner "lives with partner but not married"
		label define old 0 "65less" 1 "65plus"
		label values oldexm old
		label define matstatus 0 "sing" 1 "marr"
		label values married matstatus
		egen oldmar=group(married oldexm), label
			label variable oldmar "Married x 65+ dummy"
		*gen oldmar=1 if oldexm==0 & married==0
		*replace oldmar=2 if oldexm==1 & married==0
		*replace oldmar=3 if oldexm==0 & married==1
		*replace oldmar=4 if oldexm==1 & married==1

	* filed or will file tax return
	gen filedtax=0
	replace filedtax=1 if X5744==1 | X5744==6
	* tax returns in the unit, set to 2 when 2 spouses/partners file separate returns
	gen numbertaxreturns=filedtax
	replace numbertaxreturns=2 if X5746==2


	* itemized deduction dummy for respondent or spouse (X7369==1) is when spouse/partner filing separately itemized, only since 1995
	gen item=0
	cap gen X7367=0
	cap gen X7368=0
	cap gen X7369=0
	replace item=1 if X7367==1 | X7368==1 | X7369==1

	* A. Corporate equities (excluding pensions)
	* dividend income
	gen divinc=X5710*cpi
	* capital gains, kginc already exists
	* equity wealth sum of direct stock holdings + mutual funds stock holdings
	gen kgdivinc=max(0,kginc)+divinc
	gen divinc_wscf=stocks+stmutf+.5*comutf
	gen kgdivinc_wscf=stocks+stmutf+.5*comutf

	* B. Fixed claim assets
	* non-taxable bonds (munis)
	gen intexm=X5706*cpi
	gen intexm_wscf=notxbnd+tfbmutf

	* taxable fixed claim assets
	gen intinc=X5708*cpi
	gen intinc_wscf=liq+cds+savbnd+bond-notxbnd+nmmf-stmutf-tfbmutf-.5*comutf

	* C. Unincorporated businesses
	* aggregates schedC+farm+schedE (schedE=rental, partnership, S-corp, royalties, trust income)
	gen businc=max(0,bussefarminc)
	gen businc_wscf=bus+othfin+nnresre

	* D. Pension income
	* ssretinc also includes social security so need to calculate social security income ssinc to subtract it
	* ssinc is reported either monthly or annually so need to calculate this
	gen ssinc=0
	replace ssinc=ssinc+X5306*cpi if X5307==6
	replace ssinc=ssinc+12*X5306*cpi if X5307==4
	replace ssinc=ssinc+X5311*cpi if X5312==6
	replace ssinc=ssinc+12*X5311*cpi if X5312==4
	gen peninc= max(0,ssretinc-ssinc)
	* peninc includes IRAs, 401(k) distributions and annuities from DBs
	replace penacctwd=0 if penacctwd==.
	gen penincdb=max(0,peninc-penacctwd)
	gen penincdc=peninc-penincdb
	* penincdb should be DB pension income
	* penincdc should be DC pension income

	* presence of DB plan
	gen db=0
	replace db=1 if dbplant==1

	sum pen* [w=wgint]

	* E. Housing wealth
	gen nethousing=houses+oresre-mrthel-resdbt

	* real estate taxes on owner occupied housing (need to adjust for periodicity)
	gen realestatetax=X721*cpi
	replace realestatetax=12*realestatetax if X722==4
	replace realestatetax=4*realestatetax if X722==5
	replace realestatetax=2*realestatetax if X722==11
	replace realestatetax=max(0,realestatetax)

	* mortgage payments per month variable is mortpay, create annualized variable
	replace mortpay=12*mortpay

	* generating total income variable totinc consistent with Piketty-Saez income definition (i.e. excluding SS and govt transfers and non-taxable interest)
	gen othinc=X5724*cpi
	gen totinc=wageinc+bussefarminc+intinc+divinc+kginc+peninc+othinc
	gen capinc=max(0,bussefarminc)+intinc+divinc+max(0,kginc)
	gen capincnokg=max(0,bussefarminc)+intinc+divinc
	* no way to get passive capital income from SCF as schedule E income is not broken down (partnership+S-corp profits with rents, royalties, trust+estate)
	gen intdivkinc=intinc+divinc
	gen capinc_wscf=kgdivinc_wscf+businc_wscf+intinc_wscf+0*intexm_wscf 

	gen kgdivbusinc=kgdivinc+businc 
	gen inttotinc=intinc+intexm 
	gen kgdivbusinc_wscf=kgdivinc_wscf+businc_wscf
	gen inttotinc_wscf=intinc_wscf+intexm_wscf 

	* gen test=wageinc+bussefarminc+intdivinc+kginc+ssretinc+transfothinc-income



	/*
	* variables definition in summary file
	WAGEINC=X5702;
	BUSSEFARMINC=X5704+X5714;
	INTDIVINC=X5706+X5708+X5710; X5706 is non-taxable interest, X5708 is taxable interest, X5710 is dividends 
	KGINC=X5712;
	SSRETINC=X5722+PENACCTWD; X5722 includes both SSA benefits and other pension benefits but not IRA distributions or 401K after 2004
	PENACCTWD includes IRA+401(k) distributions
	TRANSFOTHINC=X5716+X5718+X5720+X5724; X5716 is UI/workers comp, X5718 is child support/alimony, X5720 is TANF/SSI/Foodstamps, X5724 is other income on income tax return
	*/

	* note: income (reported total income) is not the same as income2 (sum of reported income components) because of imputations, income leads to a top income share in 1992 that seems too low
	gen income2=cpi*(X5702+X5704+X5714+X5706+X5708+X5710+X5722+X5716+X5718+X5720+X5724)


	* WEALTH COMPONENTS
	* total networth Kennickell definition is variable networth, used to replicate Kennickell (2009b) wealth shares
	gen equitywealth=stocks+stmutf+.5*comutf+.5*othma
	gen bondwealth=liq-checking+cds+savbnd+bond-notxbnd+nmmf-stmutf-tfbmutf-.5*comutf+.5*othma
	gen muniwealth=notxbnd+tfbmutf
	gen currencywealth=checking
	gen otherdebtwealth=-(install+othloc+ccbal+odebt)
	gen housingwealth=houses+oresre
	gen mortgagedebtwealth=-(mrthel+resdbt)
	gen fixclaimwealth= bondwealth+muniwealth+currencywealth+otherdebtwealth
	gen netrentalwealth=nnresre
	gen businesswealth=bus+othfin
	gen busrentwealth=businesswealth+netrentalwealth
	* SCF pensionwealth does not include DB plans
	gen pensionwealth=retqliq+cashli
	gen vehicartwealth=vehic+othnfin
	* wealth excluding housing and durables
	gen nonhousingwealth=networth-housingwealth-vehicartwealth-mortgagedebtwealth
	* wealth excluding housing, durables, and pensions (used to test capitalization method in SCF)
	gen nhousingpenwealth=networth-housingwealth-pensionwealth-vehicartwealth-mortgagedebtwealth
	* net housing wealth in SCF
	gen nethousingwealth=housingwealth+mortgagedebtwealth+netrentalwealth


	gen networth2=equitywealth+bondwealth+muniwealth+currencywealth+otherdebtwealth+housingwealth+mortgagedebtwealth+netrentalwealth+businesswealth+pensionwealth+vehicartwealth

	keep wgt wgint *_wscf *wealth wageinc divinc kginc kgdivinc intexm intinc businc totinc othinc capinc capincnokg intdivkinc  income* filedtax item ssretinc peninc* ssinc cpi cpi_wealth kgdivbusinc inttotinc networth* retqliq irakh nethousing year realestatetax mortpay bussefarminc age marstatus married oldexm oldmar
	* sum [w=wgt]

	*********************************
	* moving back to nominal values
	*********************************

	* wealth variables
	foreach var of varlist *_wscf networth* equitywealth bondwealth muniwealth currencywealth otherdebtwealth housingwealth mortgagedebtwealth netrentalwealth businesswealth pensionwealth vehicartwealth nonhousingwealth nhousingpenwealth busrentwealth fixclaimwealth nethousingwealth retqliq irakh nethousing  {
		replace `var'=`var'/cpi_wealth
		}
	* income variables	
	foreach var of varlist wageinc divinc kginc kgdivinc intexm intinc businc totinc othinc capinc capincnokg intdivkinc income* ssretinc peninc* ssinc kgdivbusinc inttotinc realestatetax mortpay {
			replace `var'=`var'/cpi
			}	


	/*	
	* computing the SCF wealth rescaling based on Saez-Zucman (_sz) aggregates obtained above from parameters(SZ).csv file
	foreach var in equity bond muni currency otherdebt housing mortgagedebt netrental business pension vehicart nonhousing nhousingpen nethousing fixclaim busrent {
	quietly: sum `var'wealth [w=wgt]
	local `var'_tot=r(sum)*1e-6
	gen `var'_sz=`var'wealth*``var'_totsz'/``var'_tot'
	display "YEAR = " `year' " `var' "   ``var'_totsz'/``var'_tot'
	}
	gen networth_sz=equity_sz+bond_sz+muni_sz+currency_sz+otherdebt_sz+housing_sz+mortgagedebt_sz+netrental_sz+business_sz+pension_sz+vehicart_sz
	*/

	/* computing the SCF capital income rescaling based on Saez-Zucman (_sz) aggregates obtained above from parameters(SZ).csv file, added 8/2015
	foreach var in kginc divinc intinc bussefarminc  {
	quietly: sum `var' [w=wgt]
	local `var'_tot=r(sum)*1e-6
	gen `var'_sz=`var'*``var'_totsz'/``var'_tot'
	display "YEAR = " `year' " `var' "   ``var'_totsz'/``var'_tot'
	}


	gen capinc_sz=max(0,bussefarminc_sz)+intinc_sz+divinc_sz+max(0,kginc_sz)
	gen capincnokg_sz=max(0,bussefarminc_sz)+intinc_sz+divinc_sz



	/*
	gen networthscf_sz=networth_sz+vehicartwealth
	gen networth_sz2=equity_sz+fixclaim_sz+nethousing_sz+business_sz+pension_sz+vehicart_sz
	gen networthscf_sz2=networth_sz2+vehicartwealth
	*/

	cap drop test
	gen test=networth-networth2
	sum test [w=wgt], det
	sum networth* [w=wgt]

	* calculating capitalization factors by asset class
	foreach var of varlist divinc kgdivinc intexm intinc businc  {
	quietly: sum `var' [w=wgt]
	local `var'_tot=r(sum)*1e-9 
	quietly: sum `var'_wscf [w=wgt]
	local `var'_wscf_tot=r(sum)*1e-9 
	local `var'_cap=``var'_wscf_tot'/``var'_tot'
	display "`var' " ``var'_cap'
	gen `var'_w=`var'*``var'_cap'
	}

	* wealth definition for capitalization test: does not include pensions nor net housing wealth (for lack of as good info on asset or income side for housing and pensions)
	* actual wealth directly measured in scf
	gen wealth_scf=kgdivinc_wscf+intexm_wscf+intinc_wscf+businc_wscf
	* capitalized wealth using only dividends and ignoring capital gains when capitalizing equities
	gen wealth_cap=divinc_w+intexm_w+intinc_w+businc_w
	* capitalized wealth including both dividends and capital gains when capitalizing equities
	gen wealthkg_cap=kgdivinc_w+intexm_w+intinc_w+businc_w

	foreach var of varlist wealth_scf wealthkg_cap wealth_cap income totinc capinc capincnokg intdivkinc networth retqliq irakh nethousing networth_sz capinc_sz capincnokg_sz intinc {
		cumul `var' [w=wgint], gen(rank`var')
		}

	cumul wageinc [w=wgint] if wageinc>0, gen(rankwageinc) 
	replace rankwageinc=0 if rankwageinc==.

	gen one=1
	quietly: sum one [w=wgt]
	local num_tot=r(sum)

	* Piketty-Saez total tax units (in millions) from year t-1 (1988 for SCF 1989 etc.), this comes from Table A0 in Piketty-Saez income series
	gen totfam=0
	replace totfam=114.656  if year==1989
	replace totfam=120.453  if year==1992
	replace totfam=124.716  if year==1995
	replace totfam=129.301  if year==1998
	replace totfam=134.473  if year==2001
	replace totfam=141.843  if year==2004
	replace totfam=148.361  if year==2007
	replace totfam=153.543  if year==2010
	replace totfam=160.681  if year==2013
	replace totfam=totfam*1e+6
	* ranking assuming the Piketty-Saez total number of tax units (assumes that at the top, each household is a single tax unit, a reasonable assumption)
	foreach var of varlist wealth_scf wealthkg_cap wealth_cap income totinc capinc capincnokg intdivkinc networth retqliq irakh nethousing networth_sz capinc_sz capincnokg_sz intinc {
		gen rank`var'_ps=1-(1-rank`var')*`num_tot'/totfam
		}


	* Forbes 400 total nominal wealth (in $bn) from year t, see numbers in appendix table C3, column 2
	gen forbes400=0
	replace forbes400=268 if year==1989
	replace forbes400=301 if year==1992
	replace forbes400=394 if year==1995
	replace forbes400=738 if year==1998
	replace forbes400=951 if year==2001
	replace forbes400=1005 if year==2004
	replace forbes400=1540 if year==2007
	replace forbes400=1370 if year==2010
	replace forbes400=2000 if year==2013

	*/
	compress
	saveold $dirscfclean/SCF`year'.dta, replace

	}


****************************************************************************************************************************************************************	
*
* CREATE MATRICES FOR IMPUTATIONS INTO DINA
*
****************************************************************************************************************************************************************

foreach compo in home mort curr othd {

* Itemizer dummy only since 1995 in SCF
	if 	"`compo'" == "home" | "`compo'" == "mort" {
		local scfyears = "1995 1998 2001 2004 2007 2010 2013"
		local first = 1995
		local between = "1996 1997 1999 2000 2002 2003 2005 2006 2008 2009 2011 2012"
	}
	if 	"`compo'" == "curr" | "`compo'" == "othd" {
		local scfyears = "$scfyears"
		local first = 1989
		local between = "1990 1991 1993 1994 1996 1997 1999 2000 2002 2003 2005 2006 2008 2009 2011 2012"
	}

	foreach year of local scfyears {
		use $dirscfclean/SCF`year'.dta, clear
		rename housingwealth homewealth
		rename mortgagedebtwealth mortwealth
		rename currencywealth currwealth
		rename otherdebtwealth othdwealth
		gen hashome = (homewealth!=0 & homewealth!=.)
		cap gen has`compo' = (`compo'wealth!=0 & `compo'wealth!=.)

* Create matrices with frequency of `compo' and average `compo' values  by income decile x old x married
		if "`compo'" == "home" {
			crosstab income has`compo' [w=wgint] if item==0, by(oldmar) matname(frq`compo'`year')
		}
		if "`compo'" == "mort" {
			crosstab income has`compo' [w=wgint] if item==0 & hashome==1, by(oldmar) matname(frq`compo'`year')
		}
		if "`compo'" == "home" | "`compo'" == "mort" {
		crosstab income `compo'wealth [w=wgint] if item==0 & has`compo'==1, by(oldmar) matname(avg`compo'`year')
		}
		if "`compo'" == "curr" | "`compo'" == "othd" {
			crosstab income has`compo' [w=wgint], by(oldmar) matname(frq`compo'`year')
			crosstab income `compo'wealth [w=wgint] if has`compo'==1, by(oldmar) matname(avg`compo'`year')
		}

* Replace missing values in small cells
		xtile rank_inc = income [w=wgint], nq(10)
			quietly: tab rank_inc
			local I=r(r)
		quietly: tab oldmar
			local J=r(r)
		foreach mat in frq`compo' avg`compo'  {
			forval j = 1/`J' { 
				forval i = 1/`I' { 
					if `mat'`year'[`i', `j'] == . {
		 			matrix `mat'`year'[`i', `j']= 0
		 			}
		 		}
		 	}
		 }		
		* foreach mat in frq`compo' avg`compo'  {
		* 	forval j = 1/`J' { 
		* 		if `mat'`year'[`I', `j'] == . {
		* 			matrix `mat'`year'[`I', `j']= 0
		* 		}
		* 		if `mat'`year'[1, `j'] == . {
		* 			matrix `mat'`year'[1, `j']= 0
		* 		}
		* 	}			
		* 	local I = `I' - 1
		* 	forval i = 2/`I' { 	
		* 		forval j = 1/`J' { 								
		* 			if  `mat'`year'[`i', `j'] == . {
		* 			matrix `mat'`year'[`i', `j']= 0.5 * (`mat'`year'[`i'-1, `j'] + `mat'`year'[`i'+1, `j'])
		* 			}
		* 		}
		* 	}
		* 	local I = `I' + 1
		* }

* Create matrice with sum of `compo' by income decile x old x married	
		matrix sum`compo'`year' = J(`I', `J', 1) 
		levelsof rank_inc  
		mat rownames sum`compo'`year' = `r(levels)'
		levelsof oldmar
		mat colnames sum`compo'`year' = `r(levels)'
		forval i = 1/`I' { 
			forval j = 1/`J' {
				if "`compo'" == "home" {
					quietly: su wgint if item==0 & rank_inc==`i' & oldmar==`j', meanonly 
					matrix sum`compo'`year'[`i', `j'] = avg`compo'`year'[`i', `j'] * frq`compo'`year'[`i',`j'] * r(sum) * 1e-10
					}
				if "`compo'" == "mort" {
					quietly: su wgint if item==0 & rank_inc==`i' & oldmar==`j' & hashome==1, meanonly 
					matrix sum`compo'`year'[`i', `j'] = avg`compo'`year'[`i', `j'] * frq`compo'`year'[`i',`j'] * r(sum) * 1e-10 					
				}
				if "`compo'" == "curr" | "`compo'" == "othd" {
					quietly: su wgint if rank_inc==`i' & oldmar==`j', meanonly 
					matrix sum`compo'`year'[`i', `j'] = avg`compo'`year'[`i', `j'] * frq`compo'`year'[`i',`j'] * r(sum) * 1e-10 					
				}				 
			}
		} 

* Show matrices
		* di "YEAR = `year'"
		* quietly: su wgt
		* 	di "TOTAL NUMBER OF SCF UNITS IN `year' = `r(sum)'"
		* mat list frq`compo'`year'
		* 	di "FRACTION OF NON-ITEMIZERS WITH `compo' IN `year' BY INCOME DECILE X MARRIED X 65+"
		* mat list avg`compo'`year'
		* 	di "AVERGAGE `compo' WEALTH OF NON-ITEMIZERS WITH `compo' IN `year' BY INCOME DECILE X MARRIED X 65+"
		* mat list sum`compo'`year'
		* 	di "TOTAL `compo' WEALTH OF NON-ITEMIZERS IN `year' BY INCOME DECILE X MARRIED X 65+"
	}

* Interpolation for missing SCF years
	local ii=1
	foreach year of local between {
		di "YEAR = `year'"
		if mod(`ii',2)==1 {
			local prev=`year'-1
		}
		else {
			local prev=`year'-2	
		}
			di "PREVIOUS SURVEY YEAR: `prev'"
		local next = `prev' + 3
			di "NEXT SURVEY YEAR: `next'"
		foreach mat in frq`compo' avg`compo' sum`compo' {
			matrix `mat'`year'= `mat'`prev' + (`mat'`next' - `mat'`prev')*(`year' - `prev')/(`next' - `prev')
		} 
		mat list frq`compo'`year'
		*	di "FRACTION OF NON-ITEMIZERS WITH `compo' IN `year' BY INCOME DECILE X MARRIED X 65+"
		mat list avg`compo'`year'
		*	di "AVERGAGE `compo' WEALTH OF NON-ITEMIZERS WITH `compo' IN `year' BY INCOME DECILE X MARRIED X 65+"
		mat list sum`compo'`year'
		*	di "TOTAL `compo' WEALTH OF NON-ITEMIZERS IN `year' BY INCOME DECILE X MARRIED X 65+"
	local ii = `ii' +1	
	}

* Pre-SCF matrices
	local tt`compo'scf`first' = 0
	forval i = 1/`I' { 
		forval j = 1/`J' {
			local tt`compo'scf`first' =  `tt`compo'scf`first''  + sum`compo'`first'[`i',`j']
		}
	}
	local pre = `first'-1			
	foreach year of numlist 1962/`pre' {
		insheet using "$parameters", clear names
		keep if yr==`year'
		if "`compo'" == "mort" {
			keep ttmortw
			local sharemortdeditemizers=0.80
			local adjust`year' = ttmortw*(1-`sharemortdeditemizers')/`tt`compo'scf`first''
		}
		if "`compo'" == "home" {
			keep ttrestw
			local shareproptaxitemizers=0.75
			local adjust`year' = ttrestw*(1-`shareproptaxitemizers')/`tt`compo'scf`first''
		}
		if "`compo'" == "curr" | "`compo'" == "othd" {
			rename ttcurrency ttcurr 
			rename ttothdebt ttothd
			keep tt`compo'
			local adjust`year' = tt`compo'/`tt`compo'scf`first''
		}

		di "YEAR = `year'"
		di "ADJUSTMENT FACTOR FOR TOTAL `compo' WEALTH OF NON-ITEMIZERS in `year': `adjust`year''"
		mat frq`compo'`year' = frq`compo'`first'
		mat avg`compo'`year' = avg`compo'`first' * `adjust`year''
		mat sum`compo'`year' = sum`compo'`first' * `adjust`year''
		mat list frq`compo'`year'
			* di "FRACTION OF NON-ITEMIZERS WITH `compo' IN `year' BY INCOME DECILE X MARRIED X 65+"
		mat list avg`compo'`year'
			* di "AVERGAGE `compo' WEALTH OF NON-ITEMIZERS WITH `compo' IN `year' BY INCOME DECILE X MARRIED X 65+"
		mat list sum`compo'`year'
			* di "TOTAL `compo' WEALTH OF NON-ITEMIZERS IN `year' BY INCOME DECILE X MARRIED X 65+"

	}


*Save matrices 
	foreach year of numlist 1962/2013  {
			foreach m in frq avg sum {
				putexcel A1=matrix(`m'`compo'`year', names) using "$dirmatrix/`m'`compo'`year'.xlsx", replace
			}
		}
}

