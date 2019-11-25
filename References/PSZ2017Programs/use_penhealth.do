* crosstab check for pension and health using INSOLE internal files

foreach yr of numlist 1999/$endyear {
use w2* mars age* wages dweght using "$dirirs/x`yr'", clear

keep if w2wagesprim>0 | w2wagessec>0
drop if w2wagesprim==.
drop if w2wagessec==.
cap drop count
cap drop oldmar
gen married=(mars==2)
gen oldexm=(age>=65 & age!=.)
gen oldexf=(agesec>=65 & agesec!=.)
gen id=_n
replace dweght=round(dweght)

qui gen second=1
		qui replace second=2 if married==1
	expand second
		bys id: gen count=_n
		qui replace second=count-1
	sort id second
	qui gen old = 0
		label variable old "Aged 65+"
		qui replace old = 1 if second == 0 & oldexm == 1
		qui replace old = 1 if second == 1 & oldexf == 1
	
	replace w2wages=0
	replace w2wages=w2wagesprim if second==0
	replace w2wages=w2wagessec if second==1
	gen w2pension=0
	replace w2pension=w2pensionprim if second==0
	replace w2pension=w2pensionsec if second==1
	if `yr'>=2012 {
		gen w2health=0
		replace w2health=w2healthprim if second==0
		replace w2health=w2healthsec if second==1
	}
	
    cap label drop oldage
	label define oldage 0 "65less" 1 "65plus"
 	label values old oldage
 	cap label drop matstatus
 	label define matstatus 0 "sing" 1 "marr"
 	label values married matstatus	
    qui egen oldmar=group(married old), label
    label variable oldmar "Married x 65+ dummy"	
	
keep id count second married* oldmar old w2wages* w2pension* w2health* wages dweght
order id count second married* oldmar old w2wages* w2pension* w2health* wages dweght
keep if w2wages>0 & w2wages!=.	

	
gen hasw2pension=(w2pension>0)
if `yr'>=2012 gen hasw2health=(w2health>0)

cumul w2wages [w=dweght], gen(rank)



* looping over all record vs top 10% records
foreach num of numlist 0 .9 {

keep if rank>=`num'
if `num'==0 local r=""
if `num'==.9 local r="top10"

crosstab w2wages w2wages [w=dweght] if w2wages >0, by(oldmar) matname(avgwage`r'`yr')
crosstab w2wages w2pension [w=dweght] if w2wages >0, by(oldmar) matname(avgpension`r'`yr')
crosstab w2wages hasw2pension [w=dweght] if w2wages >0, by(oldmar) matname(frqpension`r'`yr')
crosstab w2wages w2pension [w=dweght] if hasw2pension == 1 & w2wages >0, by(oldmar) matname(avgcondpension`r'`yr')

if `yr'>=2012 {
crosstab w2wages w2health [w=dweght] if w2wages >0, by(oldmar) matname(avghealth`r'`yr')
crosstab w2wages hasw2health [w=dweght] if w2wages >0, by(oldmar) matname(frqhealth`r'`yr')
crosstab w2wages w2health [w=dweght] if hasw2health == 1 & w2wages >0, by(oldmar) matname(avgcondhealth`r'`yr')
}

local cases "avgwage avgpension frqpension avgcondpension"
if `yr'>=2012 local cases "avgwage avgpension frqpension avgcondpension avghealth frqhealth avgcondhealth"

preserve
foreach case in `cases' {
	clear
	svmat `case'`r'`yr', names(col)
	gen decile = _n
	order decile
	export excel using "$dirmatrix/`case'`r'`yr'.xlsx", first(var) replace
	}
restore

}
* end of all vs. top 10 loop

}
* end of yr grand loop



