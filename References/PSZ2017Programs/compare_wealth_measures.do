* June 2018: compare different measures of wealth (tax units vs. equal split; KG capitalized vs. not)

cap mkdir $diroutsheet/wealth


	
* Tax units, hweal for both ranking and shares
clear matrix 
foreach yr of numlist $years { 
use hweal* dweght* id using "$dirusdina/usdina`yr'.dta", clear
collapse (sum) hweal (mean) dweght dweghttaxu, by(id)
replace dweght = dweghttaxu
shcomp   hweal [w=dweght], matname(sh`yr'taxukg)
mat sh`yr'taxukg  = (`yr', sh`yr'taxukg)
mat shtaxukg   = (nullmat(shtaxukg)  \ sh`yr'taxukg)
mat list shtaxukg
}
clear
svmat shtaxukg, names(col)
qui compress
export excel using "$diroutsheet/wealth/shtaxukg.xlsx", first(var) replace 


* Tax units, mixed method
	clear matrix 
	foreach yr of numlist $years { 
		use hweal* dweght* id using "$dirusdina/usdina`yr'.dta", clear
			collapse (sum) hweal hwealnokg (mean) dweght dweghttaxu, by(id)
			replace dweght = dweghttaxu
		shcomp    hwealnokg hweal [w=dweght], matname(sh`yr'taxumix)
		mat sh`yr'taxumix  = (`yr', sh`yr'taxumix)
		mat shtaxumix   = (nullmat(shtaxumix)  \ sh`yr'taxumix)
		mat list shtaxumix
	}
	clear
	svmat shtaxumix, names(col)
	qui compress
	export excel using "$diroutsheet/wealth/shtaxumix.xlsx", first(var) replace	


* Equal-split, mixed method
	clear matrix 
	foreach yr of numlist $years { 
		use hweal* dweght* married id using "$dirusdina/usdina`yr'.dta", clear
			collapse (first) married (mean) hweal* dweght, by(id)
			qui gen second=1
			qui replace second=2 if married==1
			expand second
		shcomp    hwealnokg hweal [w=dweght], matname(sh`yr'equalmix)
		mat sh`yr'equalmix  = (`yr', sh`yr'equalmix)
		mat shequalmix   = (nullmat(shequalmix)  \ sh`yr'equalmix)
		mat list shequalmix
	}
	clear
	svmat shequalmix, names(col)
	qui compress
	export excel using "$diroutsheet/wealth/shequalmix.xlsx", first(var) replace	


* Equal-split, hweal for both ranking and shares
	clear matrix 
	foreach yr of numlist $years { 
		use hweal* dweght* married id using "$dirusdina/usdina`yr'.dta", clear
			collapse (first) married (mean) hweal* dweght, by(id)
			qui gen second=1
			qui replace second=2 if married==1
			expand second
		shcomp  hweal [w=dweght], matname(sh`yr'equal)
		mat sh`yr'equal  = (`yr', sh`yr'equal)
		mat shequal   = (nullmat(shequal)  \ sh`yr'equal)
		mat list shequal
	}
	clear
	svmat shequal, names(col)
	qui compress
	export excel using "$diroutsheet/wealth/shequalkg.xlsx", first(var) replace	


* Equal-split, hwealnokg for both ranking and shares
	clear matrix 
	foreach yr of numlist $years { 
		use hweal* dweght* married id using "$dirusdina/usdina`yr'.dta", clear
			collapse (first) married (mean) hweal* dweght, by(id)
			qui gen second=1
			qui replace second=2 if married==1
			expand second
		shcomp  hwealnokg [w=dweght], matname(sh`yr'equalnokg)
		mat sh`yr'equalnokg  = (`yr', sh`yr'equalnokg)
		mat shequalnokg   = (nullmat(shequalnokg)  \ sh`yr'equalnokg)
		mat list shequalnokg
	}
	clear
	svmat shequalnokg, names(col)
	qui compress
	export excel using "$diroutsheet/wealth/shequalnokg.xlsx", first(var) replace	


	
	
	
/*
* Top 1% shares equal-split available on WID.world
wid, indicators(shweal) areas(US) perc(p99p100) ages(992) pop(j) clear
export excel using "$diroutsheet/wealth/shequalwid.xlsx", first(var) replace	
