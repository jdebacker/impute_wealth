* new program created 3/2016 to add share_f to small files year $yr
* using tables wagspouse`yr'.xls for each year 
* tables wagspouse`yr'.xls created by program sharefbuild.do combining CPS for bottom 95% and tax data for top 5%


local yr=$yr
	
	* load the split matrix
	insheet using "$dirmatrix/wagmat/wagspouse`yr'.xls", clear
	
	* XX test discontinuity 1998 1999
	* if `yr'==1999 insheet using "$dirmatrix/wagmat/wagspouse`yr'copy.xls", clear
	
	mkmat c1-c9, matrix(split)
    display "YEAR = " `yr'
    matrix list split
    local cols=colsof(split)-2
	local rows=rowsof(split)-2
	* load the micro data
	use "$dirsmall/small`yr'.dta", clear
	* cap drop rand-wage_m 
	cap drop share_f*
    * prepare the x`yr' dta to uniformize weighting (as in build_small)
	set seed 4313
	gen rand=runiform()
	set seed 212
	gen rand2=runiform()
	cap drop share_f
	gen share_f=0 if married==1
	* matrix split=split`yr'
	gen aux=wages
	set seed 43256675
	replace aux=aux+runiform()/2 if wages>0
	cumul aux [w=dweght] if married==1 & wages>0, gen(rankw)
	* define corresponding wage pc bracket from 1 to rows
	gen pcbrac=1 if married==1 & wages>0
	foreach pc of numlist 1/`rows' {
		replace pcbrac=pcbrac+1 if rankw>split[`pc'+2,2] & married==1 & wages>0
		}
	* define share bracket from 1 to cols using rand variable and using correspond pcbrac row
	gen sharebrac=1 if married==1 & wages>0
	gen cumshare=0
	foreach col of numlist 1/`cols' {
		replace cumshare=cumshare+split[pcbrac+2,`col'+2]
	    replace sharebrac=sharebrac+1 if rand>cumshare & married==1 & wages>0
	    }

	* define share_f using pcbrac and sharebrac
	gen shmin=split[1,sharebrac+2] if married==1 & wages>0
	gen shmax=split[2,sharebrac+2] if married==1 & wages>0
	replace shmin=0 if shmin<0 & married==1 & wages>0
	replace shmin=1 if shmin>.999 & married==1 & wages>0
	replace share_f=shmin+(shmax-shmin)*rand2 if married==1 & wages>0
	gen wage_f=wages*share_f
	gen wage_m=wages*(1-share_f)
	*keep id wages wage_f wage_m share_f dweght married
	* sort id
	sum wages wage_f wage_m share_f [w=dweght] if married==1
	drop rand rand2 aux-wage_m
	label variable share_f "Imputed share of wife wages (CPS bot 95%, basic interp tax tab top 5%) 1962-"
	* on the inside and for 1999+, use actual variables split
	gen share_ftrue=0 if married==1
	* adding databank condition below (in 7/2018) for when insole in advance of databank
	if $data==1 & $yr>=1999 & $yr<=$databankyear {
		replace share_ftrue=w2wagessec/wages if wages>0 & married==1 & w2wagessec>=0 
		replace share_ftrue=min(share_ftrue,1) if wages>0 & married==1 
		replace share_ftrue=0 if share_ftrue<0 & share_ftrue!=.
		* OLD PRE 9/2016
		*replace share_ftrue=w2wagessec/w2wages if w2wages>0 & married==1 & w2wagessec>=0
		*replace share_ftrue=min(share_ftrue,1)
	}
	label variable share_ftrue "Share wages to wife: w2wagessec/wages, internal only 1999-"
	saveold  "$dirsmall/small`yr'.dta", replace
	

/*
********************************************************************************
* testing of share_f, do not run in main program, just cut and paste
********************************************************************************
	foreach yr of numlist 1962 1964 1966/2009 {
	use  "$dirsmall/small`yr'.dta", clear
	quietly sum share_f [w=dweght] if married==1 & wages>0 
	local shall=r(mean)
	gen aux=wages
	set seed 5442432
	replace aux=aux+runiform()/2 if wages>0
	cumul aux [w=dweght] if married==1 & wages>0, gen(rankw)
	quietly sum share_f [w=dweght] if married==1 & wages>0 & rankw>=.9
	local shallt10=r(mean)
	gen zero=(share_f==0) if married==1 & wages>0
	quietly sum zero [w=dweght] if married==1 & wages>0 
	local shall0=r(mean)
	gen less5=(share_f<=.05) if married==1 & wages>0
	quietly sum less5 [w=dweght] if married==1 & wages>0 
	local shall5=r(mean)
	display "year = " `yr' "  share female =" `shall' "  share female in top 10% =" `shallt10' "  share female 0% =" `shall0' "  share female less than 5% =" `shall5'
}
*/


*****************************************************************************************************************
*****************************************************************************************************************
*  self-employment split imputation using the internal SOI data 1979+, create share_fse
*  use sey seysec whenever sey close to seydina=partpinc+schcincp+rylinc
*  if not, use the tabulation wagmat/sespint`yr'.xls
*  same code both inside and outside except 1979-1983 when seysec external does not exist
*****************************************************************************************************************
*****************************************************************************************************************




* load the split matrix
	if `yr'>=1979 insheet using "$dirmatrix/wagmat/sespint`yr'.xls", clear
	if `yr'<1979 insheet using "$dirmatrix/wagmat/sespint1979.xls", clear
	mkmat c1-c9, matrix(split)
    display "YEAR = " `yr'
    *matrix list split
    local cols=colsof(split)-2
	local rows=rowsof(split)-2
	* load the micro data
	use "$dirsmall/small`yr'.dta", clear
	* cap drop rand-wage_m 
	cap drop share_fse*
	set seed 65353
	gen rand=runiform()
	set seed 5435
	gen rand2=runiform()
	cap drop share_fse
	gen share_fse=0 if married==1
	* matrix split=split`yr'
	
	* dina self-employment
	gen seydina=max(partpinc+schcincp+rylinc,0)	
	gen aux=seydina
	set seed 126675
	replace aux=aux+runiform()/2 if seydina>0
	cumul aux [w=dweght] if married==1 & seydina>0, gen(rankw)
	* define corresponding wage pc bracket from 1 to rows
	gen pcbrac=1 if married==1 & seydina>0
	foreach pc of numlist 1/`rows' {
		replace pcbrac=pcbrac+1 if rankw>split[`pc'+2,2] & married==1 & seydina>0
		}
	* define share bracket from 1 to cols using rand variable and using correspond pcbrac row
	gen sharebrac=1 if married==1 & seydina>0
	gen cumshare=0
	foreach col of numlist 1/`cols' {
		replace cumshare=cumshare+split[pcbrac+2,`col'+2]
	    replace sharebrac=sharebrac+1 if rand>cumshare & married==1 & seydina>0
	    }

	* define share_fse using pcbrac and sharebrac
	gen shmin=split[1,sharebrac+2] if married==1 & seydina>0
	gen shmax=split[2,sharebrac+2] if married==1 & seydina>0
	replace shmin=0 if shmin<0 & married==1 & seydina>0
	replace shmin=1 if shmin>.999 & married==1 & seydina>0
	replace share_fse=shmin+(shmax-shmin)*rand2 if married==1 & seydina>0
	drop rand rand2 aux-shmax
	label variable share_fse "Imputed share of self-employment income using IRS tabs"
	* use actual split sey and seysec whenever sey is close to seydina within 25% (about 75% of cases)
	
	gen real=0
	if ($data==1 & `yr'>=1979) | ($data==0 & `yr'>=1984) {
	    replace share_fse=seysec/sey if married==1 & sey>0 & seydina>0 & sey/seydina>.75 & sey/seydina<=1.25
		replace real=1 if married==1 & sey>0 & seydina>0 & sey/seydina>.75 & sey/seydina<=1.25
		* added security, use seysec and sey if seydina==0
	    replace share_fse=seysec/sey if married==1 & sey>0 & seydina==0
		replace share_fse=min(share_fse,1) if married==1 
		replace share_fse=0 if share_fse<0 & share_fse!=.
	}
	
	drop seydina real
		
	saveold  "$dirsmall/small`yr'.dta", replace

