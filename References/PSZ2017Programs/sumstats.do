******************************************************************************************
* aggregate values in tabular format for small files (to test their quality), stand alone program 
******************************************************************************************
global sumstats "married marriedsep head xded dependent xkids item oldexm oldexf female femalesec"
global sumstats1 "agi setax sey seysec wages waginc peninc penincnt penira divinc intinc intexm rentinc rentincp rentincl rylinc estinc othinc_imp schcinc schcincp schcincl partpinc"
global sumstats2 "partlinc scorpinc scorlinc partpnp partpp partlnp partlp scorpnp scorpp scorlnp scorlp scorinc partinc partscor scorpinc2 scorlinc2 partpinc2 partlinc2 partscorp partscorl kgagi kgincfull kgagid kginc agiadj income agicrr charit itemded intded"
global sumstats3 "mortded intdedoth mortrental studentded fedtax eictot eicrefn ctctot ctcrefn statetax ttltxp realestatetax uiinc ssinc suminc othinc"
global sumstats4 "age agesec agedeath agedeathsec w2wages w2wagesprim w2wagessec w2pensionprim w2pensionsec uiincprim uiincsec ssincprim ssincsec w2healthprim w2healthsec"
if $data==0 global sumstats4 ""

matrix results = J(55,120,.)
foreach year of numlist 1962 1964 1966/$endyear {
*foreach year of numlist 2013/2014 {	
 local ii=`year'-1962+1
 use "$dirsmall/small`year'.dta", clear
 cap gen one=1
 cap gen filer=1
 keep if filer==1
 matrix results[`ii',1]=`year'
 local jj=1
 foreach var of varlist one $sumstats {
 local jj=`jj'+1
 cap gen `var'=.
 quietly sum `var' [w=dweght]
 matrix results[`ii',`jj']=r(sum_w)*r(mean)*1e-8
 }
 foreach var of varlist $sumstats1 $sumstats2 $sumstats3 $sumstats4 {
 local jj=`jj'+1
 cap gen `var'=.
 quietly sum `var' [w=dweght]
 matrix results[`ii',`jj']=r(sum_w)*r(mean)*1e-14
 }
}
 
xsvmat double results, fast names(col)
local jj=1
foreach var of newlist year taxfilers $sumstats $sumstats1 $sumstats2 $sumstats3 $sumstats4 {
 rename c`jj' `var'
 local jj=`jj'+1
 }

mkmat _all, mat(results)

*XX outsheet using $dirsmall/sumstats.xls, replace
outsheet using $dirsmall/sumstats14.xls, replace
*
