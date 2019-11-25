/*
4/2016
Using the $10m+ AGI stats from INSOLE to construct the aggregate synthetic record to correct PUF 1996+
topstat.dta were created at IRS using the INSOLE-PUF data, no need to do after 2010, so I replace $endyear by 2012
*/

if $data==1 {
foreach year of numlist 1992/2012 {


* XX need to create directory in internal data $dirirsint rawdata/irsinternal
use $dirirs/x`year'.dta, clear
keep if agi>=1e+7
cap drop occup occupsec
cap drop gender
cap drop zip
cap drop count-femalesec
cap drop adjgross- w2wages
cap drop retid

gen one=1
collapse (sum) * [iw=dweght]
drop dweght
rename one dweght
save $dirirsint/topstat/top`year'.dta, replace

* added 11/2016, set variable below 10 to zero for confidentiality

use $dirirsint/topstat/top`year'.dta, clear
foreach var of varlist * {
	replace `var'=0 if `var'<10 & `var'>0
	}
save $dirirsint/topstat/top`year'.dta, replace
}
* end of internal data program for $data=1
}

* start of creation of aggregate record for external data
if $data==0 {

foreach yr of numlist 1996/2012 { 
global yr=`yr'

** creating the $10m+ AGI stats
use "$dirirs/x$yr", clear
keep if agi>=1e+7
gen one=1
* removing aggregate record 2009+
if $yr>=2009 {
drop if  dweght>=100*100 & agi>=1e+7 & $yr>=2009
	}
replace dweght=dweght/100
collapse (sum) * [iw=dweght]
drop dweght
rename one dweght
save "$dirirsint/topstat/toppuf`yr'.dta", replace

** creating the aggregate record
use "$dirirsint/topstat/top`yr'.dta", clear

* fixing name discrepancy between my own PUF files and SAS Feenberg (current NBER PUF files), 1998 file updated recently
if $yr>=1987 & $yr<=2003 & $yr!=1998 {
cap drop passy passl
rename partpy passy 
rename partnpy npassy 
rename partpl passl 
rename partnpl npassl 
	}


expand 2

* for 1996-2008, number of tax units in aggregate difference record is based on PUF documentation (# of extreme returns excluded from PUF sampling)
if `yr'==1996 local numunits=113
if `yr'==1997 local numunits=83
if `yr'==1998 local numunits=83
if `yr'==1999 local numunits=191
if `yr'==2000 local numunits=123
if `yr'==2001 local numunits=100
if `yr'==2002 local numunits=90
if `yr'==2003 local numunits=98
if `yr'==2004 local numunits=80
if `yr'==2005 local numunits=45
if `yr'==2006 local numunits=53
if `yr'==2007 local numunits=58
if `yr'==2008 local numunits=13


append using "$dirirsint/topstat/toppuf`yr'.dta"
cap drop id
gen id=_n

* for 2009+, number of tax units in aggregate difference record is based on straight difference in $10m+ AGI bracket # returns between PUF and SOI 
* can't use the actual number of tax units in aggregate PUF records bc only a subset comes from $10m+ AGI bracket
if  $yr>2008 {
replace dweght=100*(dweght[_n+1]-dweght[_n+2]) if _n==1
* defined numunits for 2009+ here using info here
quietly sum dweght if _n==1
local numunits=r(mean)/100
* display "YEAR = " $yr " NUMUNITS = " `numunits'
	}

foreach var of varlist * {
	replace `var'=(`var'[_n+1]-`var'[_n+2])/`numunits' if _n==1 
	}
replace dweght=100*`numunits' if _n==1 

replace id=0 if _n==1

cap list agi passy npassy passl npassl

* fixing the key categorical variables, assuming MFJ with 2 kids, the most common case
keep if _n==1
replace mars=2 
replace xocah=2 
replace xtot=4 
replace flpdyr=$yr 
foreach var of varlist fded xfpt xfst schb sche prep {
	replace `var'=1 
	}
foreach var of varlist retid dsi efi eic elect ie midr tform xocawh xoodep xopar   {
	replace `var'=0 
	}
* set positive income components to zero when negative
foreach var of varlist wages sey seysec cgagi txpen ftpen totpen divagi inty intmb {
	replace `var'=0 if `var'<0
	}

save "$dirirsint/topstat/synthrec`yr'.dta", replace
}

* end of external data program for $data=0
}


* testing relative to old method, it works fine for the key income components
* note this test does not work until small dataset is built

foreach yr of numlist 1996/2012 { 
display " YEAR =  " `yr'
use "$dirirsint/topstat/synthrec`yr'.dta", clear
gen scorpinc=0
cap replace scorpinc=smbpy+smbnpy if `yr'>=1987 
gen scorlinc=0 
*sum sbn* smb* s179* flpdyr

replace scorlinc=smblos+sbnpls+s179xd if `yr'>=1993 & `yr'<=1999 
replace scorlinc=smbnpl+s179xd+smblos if `yr'>=2000 & `yr'<=2003 
replace scorlinc=smbnpl+s179xd+smbpl if `yr'>=2004 
*sum scorlinc scorpinc flpdyr
cap gen partcorp=scorpinc-scorlinc+passy+npassy-passl-npassl
cap gen partcorp=partpy+partnpy-(partpl+partnpl+p179)+scorpinc-scorlinc
sum agi wages dweght cgagi divagi inty schedc partcorp 
*sum partcorp
use "$dirsmall/small`yr'.dta", clear
gen partcorp=partpinc+scorpinc-partlinc-scorlinc
sum agi wages dweght kginc divinc intinc schcinc partcorp if id==0
*sum partcorp if id==0
}

* more elaborate test relative to old method using the old small files, oldagg contains the old one, newagg the new one
foreach yr of numlist 1996/2012 { 
	use $dirsmall/small`yr'.dta, clear
	keep if id==0
	save $dirirsint/topstat/test`yr'.dta, replace
	}
use $dirirsint/topstat/test1996.dta, clear
foreach yr of numlist 1997/2012 { 
	append using $dirirsint/topstat/test`yr'.dta
	}
save $dirirsint/topstat/newagg.dta, replace

* compare $dirirsint/topstat/oldagg.dta and $dirirsint/topstat/newagg.dta to check






