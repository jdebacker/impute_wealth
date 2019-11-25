* FIRST STEP: constructing files smallX.dta containing the income variables of interest 
* originally used for TPE 2004 paper
* revised for JEP and JEL paper on 6/2005
* revised 11/2009 for Atkinson copula project
* revised 9/2013 for Saez-Zucman wealth capitalization project
* revised 1/2014 for Piketty-Saez-Zucman DINA project (adding demographic variables and tax/benefits variables)
* revised 11/2015 for US DINA and incorporated into runusdina.do
* revised 12/2015 to work both on internal and external data
* revised 3/2016 after creating at IRS an aggregate record AGI $10m+ with all the PUF variables means for 1996+ to create a difference record with PUF to match $10m+, more efficient than the block of code based on published SOI tabulations

* global $yr is the year from main program runusdina.do

************************************************************
* I) Build small micro-data with key variables to be used
************************************************************

insheet using "$parameters", clear names
keep if yr==$yr
foreach var of varlist _all {
local `var'=`var'
}

* I defined two globals that will be used elsewhere
global tottaxunits `tottaxunits'
global totadults20 `totadults20'


use "$dirirs/x$yr", clear

if $data==0 {
* for 2010+, I keep the aggregate records as it breaks down between positive and negative AGI (but the positive part includes several hundred records below $10m), just need to set marital status and kids right
cap replace mars=2 if (retid>=999996 & retid<=999999) & $yr>=2010
cap replace xtot=4 if (retid>=999996 & retid<=999999) & $yr>=2010
cap replace xocah=2 if (retid>=999996 & retid<=999999) & $yr>=2010
cap replace xfst=1 if (retid>=999996 & retid<=999999) & $yr>=2010
cap replace almpd=0 if (retid>=999996 & retid<=999999) & $yr>=2010
cap replace almrec=0 if (retid>=999996 & retid<=999999) & $yr>=2010
*list if retid==999999 | retid==999998

* dropping the aggregate record for 2009
cap drop if dweght>=100*1e+2 & agi>=1e+7 & $yr==2009
}

* Adding aggregate synthetic record 1996-2009 computed as difference between insole and PUF for $10m+ AGI bracket (added 4/2016)
if $yr>=1996 & $yr<=2009 & $data==0 {
gen last=0
append using "$diroutput/topstat/synthrec$yr.dta"
gen last2=0
drop last-last2
	}

* fix typos in 1960 file
cap replace wght=1 if wages>50000 & wght>500 & $yr==1960 
cap replace wght=1 if agi>50000 & wght>500 & $yr==1960 
cap replace agi=agi-agidef if $yr==1966 | $yr==1967 | $yr==1968 | $yr==1969 | $yr==1970 | $yr==1971  

* WEIGHTS: variable dweght is weight (pop weight*100000 for integer rounding reasons) 
cap gen dweght=wght  
cap gen dweght=dwght 
replace dweght=100*dweght if $yr==1960 | $yr==1964 | ($yr>=1968 & $yr<=1975)  
* this one fixes a bug in 1986, an obs with agi=1.1m and div 425K with weight 7919 (error also in SOI file and tabs, due to small sampling of specific category)
replace dweght=100 if agi>1000000 & dweght>50000 & $yr==1986
* internal files 1979+ directly use population weights (instead of 100*pop weights) except in 1985 and 1986 so re-normalize here
if $data==1 & $yr!=1985 & $yr!=1986 & $yr>=1979 replace dweght=dweght*100
* use 100,000*pop weight to get a rounded integer weight
replace dweght=int(1000*dweght) 
* bug record with missing weight in 1973, set to weight=10 (small AGI record), 3/2018
replace dweght=100000*10 if dweght==.

display `tottaxunits'
* TOTAL NUMBER OF TAX UNITS AND ADULTS 20+ FROM PIKETTY-SAEZ 
gen taxunits=`tottaxunits'
gen adults20=`totadults20'

* MARRIED DUMMY (married joint filers, includes qualifying widowers since 2000, those who've lost spouse in last 2 years, a minuscule group .06% in 1999) 
gen married=0 
replace married=1 if mars==1 & $yr<=1962 
replace married=1 if mars==2 & $yr>=1964 

* MARRIED SEPARATE DUMMY (married separate filers) 
gen marriedsep=0 
replace marriedsep=1 if mars==2 & $yr<=1962 
replace marriedsep=1 if (mars==3 | mars==6) & $yr>=1964 

* SINGLE DUMMY (includes singles) 
gen single=0 
replace single=1 if mars==5 & $yr<=1962 
replace single=1 if mars==1 & $yr>=1964 

* HEAD OF HOUSEHOLD DUMMY (include heads and surviving spouses witren) 
gen head=0 
replace head=1 if (mars==3 | mars==4) & $yr<=1962 
replace head=1 if (mars==4 | mars==5| mars==7) & $yr>=1964 

* test of marital status 
gen test=single+married+marriedsep+head
replace single=1 if test==0
drop test

* NUMBER OF DEPENDENTS 
gen xded=0 
cap replace xded=xocah+xocawh+xoodep+xopar if $yr>=1981 
cap replace xded=xocah+xocawh+xoodep+xopah if $yr==1980 
cap replace xded=xocah+xocawh+xoodep+xopah+xopawh if $yr==1979 
cap replace xded=xocah+xocawh+xopah+xopawh if $yr==1978 
cap replace xded=dpndx if $yr==1977 | $yr==1976 | ($yr>=1971 & $yr<=1974) | ($yr>=1968 & $yr<=1969) | $yr==1966 
cap replace xded=xocah+xocawh+xoodep if $yr==1975 
cap replace xded=xocah+xocawh+xoodep+xopar if $yr==1970 
cap replace xded=totex-ageex-blndex-txpyex if $yr==1967 
cap replace xded=xoodep if $yr==1964 
cap replace xded=xoodep+dpndx if $yr==1962 

* CLAIMED AS DEPENDENT ON OTHER RETURN (typically parent), can only be done after TRA 86
gen dependent=0
cap replace dependent=1 if xtot==0 & $yr>=1987

* NUMBER OF CHILDREN AT HOME (no specific info pre-78 except 62, 70 and 75 so I use total deps pre-78 including 62, 70 and 75 to avoid discontinuities, 5%-10% over-statement) 
gen xkids=xded 
cap replace xkids=xocah if $yr>=1978 
replace xkids=0 if xkids<0


* ITEMIZER DUMMY (no fded in 1977 so need to use totitm>0 instead) 
gen item=0 
cap gen fded=(totitm>0) if $yr==1977 
replace item=1 if fded==1 


* WAGES  * wages do not include 401(k) contributions 
gen waginc=wages 
* blurring for wages in 1996+, could be fixed using the eitc_main.do code from AEJ 2010 bunching paper as wagescalc=agi+agiadj-(sum of all other income components)

* IRAs, PENSIONS AND ANNUITIES  * always taxable pensions including taxable IRAs because non-taxable pensions emanate in general from after-tax wage contributions 
gen peninc=0 
cap replace peninc=txpen  if $yr<=1973 | $yr==1976 
cap replace peninc=txpen+ftpen  if $yr==1974 | $yr==1975 
cap replace peninc=pentax if $yr==1967 
cap replace peninc=ftpen+txpen if $yr>=1977 & $yr<=1981 
cap replace peninc=iragi+taxoth if $yr>=1982 & $yr<=1986 
if $data==1 { 
cap replace peninc=ftpen+txpen if $yr>=1982 & $yr<=1986 
}


cap replace peninc=penagi if $yr==1987 
cap replace peninc=txpen+taxira  if $yr>=1988 & $yr<=1995 
cap replace peninc=txpen+ftpen  if $yr>=1996 | $yr==1991 
replace peninc=0 if peninc==. 
* non-taxable pensions (excludes non-taxable IRA distributions bc not reported in PUF), no info before 1968 and 71-73 (for Saez-zucman wealth capitalization) 
gen penincnt=0 
cap replace penincnt=totpen-txpen if $yr>=1968 & $yr<=1981 
cap replace penincnt=other-taxoth if $yr>=1982 & $yr<=1986 
if $data==1 { 
cap replace penincnt=totpen-txpen if $yr>=1982 & $yr<=1986 
* not clear where total pensions (var totpen is in INSOLE, use e901, e902)
cap replace penincnt=e901-ftpen-txpen  if $yr==1981
}
cap replace penincnt=piar-penagi if $yr==1987 
cap replace penincnt=totpen-txpen if $yr>=1988 
cap replace penincnt=e01500-txpen if $yr==2006 
* bug in 1969 and 1984 corrected 
cap replace penincnt=0 if penincnt>=700000 & dweght>1e+8 & $yr==1984  
cap replace penincnt=0 if penincnt>=1000000 & $yr==1969  
replace penincnt=0 if penincnt==. 
* IRA pensions (not available separately before 1987), only taxable IRA pensions 
gen penira=0 
* cap replace penira=ftpen if $yr>=1974 & $yr<=1981  
* cap replace penira=iragi if $yr>=1982 & $yr<=1986 
cap replace penira=taxira  if $yr>=1988 & $yr<=1995 
cap replace penira=ftpen  if $yr>=1996 | $yr==1991 
replace penira=0 if penira==. 

* DIVIDENDS  * includes the small div exclusion before 1987 
gen divinc=0 
cap replace divinc=divrec if $yr==1960 
cap replace divinc=divrec+grdiv if $yr==1962 | $yr==1964 
cap replace divinc=divrec if $yr>=1966 & $yr<=1986 
cap replace divinc=divagi if $yr>=1987 
cap replace divinc=divrec+divexc if $yr==1968 
* ERROR IN DATA CODING in 1968 
replace divinc=0 if divinc==. 

* TAXABLE INTEREST INCOME  
cap gen intinc=0 
cap replace intinc=inty 
* EXEMPT INTEREST INCOME (only after 1986) 
cap gen intexm=0 
cap replace intexm=intmb  
cap replace intexm=0 if intexm==. 

* NET RENTAL INCOME no rental income in 1962, from 2007 on royalties and rents no longer separated so rentincp defined as gross rents - mortgage on rent if positive and allowable rent losses if negative
* INSOLE: 2007+, we use separate net rental income (rentyl=e25700) and net royalty income (ryltyl=e25800)

cap gen rentinc=0 
cap replace rentinc=(3933-1063)*othinc/(3933-1063+584-75+692-30+2343) if $yr==1962  
* othinc includes other, rents, estates, royalties 
cap replace rentinc=rentny-rentnl if $yr<=1972 | $yr==1974 
cap replace rentinc=rentyl if $yr==1973 | $yr>=1975 | $yr==1964 
cap replace rentinc=ttlrnt-rrmort if $yr>=2007 & $yr<=2008 & $data==0
* mortgages ded for rental income in 2009+ include royalty expenses 
cap replace rentinc=ttlrnt-rrinex if $yr>=2009  & $data==0
cap replace rentinc=-rntlss if $yr>=2007 & rntlss>0  & $data==0
cap replace rentinc=0 if retinc==. 
gen rentincp=max(0,rentinc) 
gen rentincl=-min(0,rentinc) 
cap replace rentincp=(3933)*othinc/(3933-1063+584-75+692-30+2343) if $yr==1962 
cap replace rentincl=(1063)*othinc/(3933-1063+584-75+692-30+2343) if $yr==1962 

* ROYALTIES no royalties income in 62, no royalty separate in 2007+ so imputed imperfectly, total is too high 
gen rylinc=0 
cap replace rylinc=(584-75)*othinc/(3933-1063+584-75+692-30+2343) if $yr==1962  
* othinc includes other, rents, estates, royalties 
cap replace rylinc=ryltny-ryltnl if $yr<=1972 | $yr==1974 
cap replace rylinc=ryltyl if $yr==1973 | $yr>=1975 | $yr==1964 
cap replace rylinc=rry-rrlos if $yr>=2007 & ttlrnt==0  & $data==0
cap replace rylinc=max(0,rry-rrlos-rentinc) if $yr>=2007 & ttlrnt>0  & $data==0
cap replace rylinc=0 if rylinc==.


* ESTATES AND TRUSTS no estate income in 62, 64, I impute for 62 but not for 64 bc no SOI tab estate in 64 
gen estinc=0 
cap replace estinc=(692-30)*othinc/(3933-1063+584-75+692-30+2343) if $yr==1962 
* othinc includes other, rents, estates, royalties 
cap replace estinc=estny-estnl if $yr<=1972 | $yr==1974
cap replace estinc=estpl if $yr==1973 | ($yr<=1980 & $yr>=1976) 
cap replace estinc=esty-estlss if $yr>=1981 | $yr==1975 
replace estinc=0 if estinc==. 

* EXTRA VARIABLE: othinc_imp = other income + rents + royalties + estates to input 62 from 64 and 66 
cap gen othinc_imp=0 
cap gen miscy =0  
cap gen miscl=0 
cap gen othery=0 
replace othinc_imp=miscy-miscl+rentinc+rylinc+estinc if $yr==1966 
replace othinc_imp=othery+rentinc+rylinc if $yr==1964 
replace othinc_imp=othinc if $yr==1962 
cap gen othinc=0  
* need to avoid removing othinc_imp 
drop miscy miscl othery othinc 


* PUF correcting 2007+ to match SOI totals, need to do by hand by sum rentincp rentincl rylinc in small data 
* both inside and outside XX calculate inside sum rentincp rentincl rylinc for 2010-2015
if $data==0 {
cap replace rentincp=rentincp*(56510/(762.2963*143.05)) if $yr==2007 
cap replace rentincl=rentincl*(74090/(399.7153*143.05)) if $yr==2007 
cap replace rylinc=rylinc*((17875-235)/(156.6823*143.05)) if $yr==2007 
cap replace rentincp=rentincp*(60072/(859.4697*142.58)) if $yr==2008 
cap replace rentincl=rentincl*(75494/(408.3931*142.58)) if $yr==2008 
cap replace rylinc=rylinc*((26574-209)/(186.6574*142.58)) if $yr==2008 
cap replace rentincp=rentincp*(59283/(779.432*140.13)) if $yr==2009 
cap replace rentincl=rentincl*(70772/(398.1257*140.13)) if $yr==2009 
cap replace rylinc=rylinc*((15772-260)/(161.7786*140.13)) if $yr==2009 

quietly sum rentincp [w=dweght]
cap replace rentincp=rentincp*(63041/(r(sum)*1e-11)) if $yr==2010 
quietly sum rentincl [w=dweght]
cap replace rentincl=rentincl*(66716/(r(sum)*1e-11)) if $yr==2010
quietly sum rylinc [w=dweght]
cap replace rylinc=rylinc*((18883-291)/(r(sum)*1e-11)) if $yr==2010


* XX calculate inside sum rentincp rentincl rylinc [w=dweght] for 2011+ and replace here
quietly sum rentincp [w=dweght]
cap replace rentincp=rentincp*(63041/(r(sum)*1e-11)) if $yr==2011 
quietly sum rentincl [w=dweght]
cap replace rentincl=rentincl*(66716/(r(sum)*1e-11)) if $yr==2011
quietly sum rylinc [w=dweght]
cap replace rylinc=rylinc*((18883-291)/(r(sum)*1e-11)) if $yr==2011

quietly sum rentincp [w=dweght]
cap replace rentincp=rentincp*(63041/(r(sum)*1e-11)) if $yr==2012 
quietly sum rentincl [w=dweght]
cap replace rentincl=rentincl*(66716/(r(sum)*1e-11)) if $yr==2012
quietly sum rylinc [w=dweght]
cap replace rylinc=rylinc*((18883-291)/(r(sum)*1e-11)) if $yr==2012

quietly sum rentincp [w=dweght]
cap replace rentincp=rentincp*(63041/(r(sum)*1e-11)) if $yr==2013 
quietly sum rentincl [w=dweght]
cap replace rentincl=rentincl*(66716/(r(sum)*1e-11)) if $yr==2013
quietly sum rylinc [w=dweght]
cap replace rylinc=rylinc*((18883-291)/(r(sum)*1e-11)) if $yr==2013

quietly sum rentincp [w=dweght]
cap replace rentincp=rentincp*(63041/(r(sum)*1e-11)) if $yr==2014
quietly sum rentincl [w=dweght]
cap replace rentincl=rentincl*(66716/(r(sum)*1e-11)) if $yr==2014
quietly sum rylinc [w=dweght]
cap replace rylinc=rylinc*((18883-291)/(r(sum)*1e-11)) if $yr==2014

quietly sum rentincp [w=dweght]
cap replace rentincp=rentincp*(63041/(r(sum)*1e-11)) if $yr==2015 
quietly sum rentincl [w=dweght]
cap replace rentincl=rentincl*(66716/(r(sum)*1e-11)) if $yr==2015
quietly sum rylinc [w=dweght]
cap replace rylinc=rylinc*((18883-291)/(r(sum)*1e-11)) if $yr==2015

cap replace rentinc=rentincp-rentincl if $yr>=2007 

* I store here numbers for 2013-2015 based on SOI data
}

* BUSINESS OF PROFESSION (SCHED C INCOME) + FARM 
* LOSS AND GAINS AGGREGATED RETURN BY RETURN 
cap gen schcinc=0  
cap replace schcinc=busny if $yr==1962 
cap replace schcinc=schedc+farm if $yr==1964 | $yr==1973 | $yr>=1975 

cap replace schcinc=busny-busnl+farmy-farml if $yr<=1972 | $yr==1974 
replace schcinc=0 if schcinc==. 
* POSITIVE SCHEDC 
gen schcincp=0  
replace schcincp=schcinc if schcinc>0 
* NEGATIVE SCHEDC 
gen schcincl=0 
replace schcincl=-schcinc if schcinc<0 

* PARTNERSHIP INCOME  * LOSS AND GAIN ON SAME RETURN POSSIBLE EXCEPT FOR YEARS 62, 64, 76, 77, 78 WHERE LOSS AND GAINS AGGREGATED RETURN BY RETURN 
* POSITIVE INCOME 
cap gen partpinc=0  
cap replace partpinc=partny if ($yr==1962) & partny>0  
cap replace partpinc=partpl if ($yr==1964 | $yr==1976 | $yr==1977 | $yr==1978) & partpl>0 
cap replace partpinc=partny if ($yr>=1966 & $yr<=1972) | $yr==1974 
cap replace partpinc=party if  ($yr>=1979 & $yr<=1986) | $yr==1973 | $yr==1975   
cap replace partpinc=passy+npassy if $yr>=1987 & $yr<=2003 
cap replace partpinc=partpy+partnpy if $yr>=2004    
* different name partnership name in Feenberg SAS program and my copy of x files
if $data==1 | ($data==0 & $yr==1998) {
cap replace partpinc=partpy+partnpy if $yr>=1987 & $yr<=2003  
}


replace partpinc=0 if partpinc==. 
* NEGATIVE INCOME 
cap gen partlinc=0  
cap replace partlinc=-partny if $yr==1962 & partny<0  
cap replace partlinc=-partpl if ($yr==1964 | $yr==1976 | $yr==1977 | $yr==1978) & partpl<0 
cap replace partlinc=partnl if ($yr>=1966 & $yr<=1972) | $yr==1974 
cap replace partlinc=partl if ($yr>=1979 & $yr<=1986) | $yr==1973 | $yr==1975  
cap replace partlinc=passl+npassl if $yr>=1987 & $yr<=1992 
cap replace partlinc=passl+npassl+p179xd if $yr>=1993 & $yr<=2003 
cap replace partlinc=partpl+partnpl+p179xd if $yr>=2004 
* different name partnership name in Feenberg SAS program and my copy of x files (I reloaded 1998)
if $data==1 | ($data==0 & $yr==1998) {
cap replace partlinc=partpl+partnpl if $yr>=1987 & $yr<=1992
cap replace partlinc=partpl+partnpl+p179xd if $yr>=1993 & $yr<=2003 
}


replace partlinc=0 if partlinc==. 

* S-CORP INCOME (S-CORP 1962, 1964, AND 1968 REPORTED ON PARTNERSHIPS) 
* LOSS AND GAIN ON SAME RETURN POSSIBLE EXCEPT FOR YEARS 1974, 1976 and 1978 WHERE LOSS AND GAINS AGGREGATED RETURN BY RETURN 
* POSITIVE INCOME 
cap gen scorpinc=0  
cap replace scorpinc=smbny if ($yr>=1966 & $yr<=1972) | $yr==1974 
cap replace scorpinc=netpl if ($yr==1976 | $yr==1978) & netpl>0 
cap replace scorpinc=sbtly if ($yr>=1979 & $yr<=1986) | $yr==1973 | $yr==1975 | $yr==1977  
cap replace scorpinc=smbpy+smbnpy if $yr>=1987 
replace scorpinc=0 if scorpinc==. 
* NEGATIVE INCOME 
cap gen scorlinc=0 
cap replace scorlinc=smbnl if ($yr>=1966 & $yr<=1972) | $yr==1974  
cap replace scorlinc=sbtlss if ($yr>=1979 & $yr<=1986) | $yr==1973 | $yr==1975  
cap replace scorlinc=-netpl if ($yr==1976 | $yr==1978) & netpl<0 
cap replace scorlinc=-(netpl-sbtly) if $yr==1977  
cap replace scorlinc=smblos+sbnpls if $yr>=1987 & $yr<=1992
cap replace scorlinc=smblos+sbnpls+s179xd if $yr>=1993 & $yr<=1999
cap replace scorlinc=smbnpl+smbpl+s179xd if $yr==1998 & $data==0
cap replace scorlinc=smbnpl+s179xd+smblos if $yr>=2000 & $yr<=2003
cap replace scorlinc=smbnpl+s179xd+smbpl if $yr>=2004 
replace scorlinc=0 if scorlinc==. 

* POST TRA86, DECOMPOSITION PASSIVE VS NON-PASSIVE 
* PARTNERSHIP INCOME  
* POSITIVE INCOME NON-PASSIVE 
cap gen partpnp=0  
cap replace partpnp=npassy if $yr>=1987 
cap replace partpnp=partnpy if $yr>=2004  
replace partpnp=0 if partpnp==. 
* POSITIVE INCOME PASSIVE 
cap gen partpp=0  
cap replace partpp=passy if $yr>=1987 
cap replace partpp=partpy if $yr>=2004 
replace partpp=0 if partpp==. 
* NEGATIVE INCOME NON-PASSIVE 
cap gen partlnp=0  
cap replace partlnp=npassl if $yr>=1987 
cap replace partlnp=partlnp+p179xd if $yr>=1993 
cap replace partlnp=partnpl if $yr>=2004 
replace partlnp=0 if partlnp==. 
* NEGATIVE INCOME PASSIVE 
cap gen partlp=0  
cap replace partlp=passl if $yr>=1987 
cap replace partlp=partpl if $yr>=2004 
replace partlp=0 if partlp==. 
* different name partnership name in Feenberg SAS program and my copy of x files
if $data==1 | ($data==0 & $yr==1998) {
cap replace partpnp=partnpy if $yr>=1987 & $yr<=2003  
cap replace partpp=partpy if $yr>=1987 & $yr<=2003  
cap replace partlnp=partnpl if $yr>=1987 & $yr<=1992
cap replace partlnp=partnpl if $yr>=1993 & $yr<=2003 
cap replace partlp=partpl if $yr>=1987 & $yr<=1992
cap replace partlp=partpl+p179xd if $yr>=1993 & $yr<=2003 
}


* S-CORP INCOME  
* POSITIVE INCOME NON-PASSIVE 
cap gen scorpnp=0  
cap replace scorpnp=smbnpy if $yr>=1987 
replace scorpnp=0 if scorpnp==. 
* POSITIVE INCOME PASSIVE 
cap gen scorpp=0  
cap replace scorpp=smbpy if $yr>=1987 
replace scorpp=0 if scorpp==. 
* NEGATIVE INCOME NON-PASSIVE 
cap gen scorlnp=0  
cap replace scorlnp=sbnpls if $yr>=1987 & $yr<=1992
cap replace scorlnp=sbnpls+s179xd if $yr>=1993 & $yr<=1999
cap replace scorlnp=smbnpl+s179xd if $yr<=2003 & $yr>=2000
cap replace scorlnp=smbnpl+s179xd if ($yr==1998 & $data==0)
cap replace scorlnp=smbnpl if $yr>=2004 
replace scorlnp=0 if scorlnp==. 
* NEGATIVE INCOME PASSIVE 
cap gen scorlp=0  
cap replace scorlp=smblos if $yr>=1987 
cap replace scorlp=smbpl if ($yr==1998 & $data==0)
cap replace scorlp=smbpl if $yr>=2004 
replace scorlp=0 if scorlp==. 

* S-CORP NET 
gen scorinc=scorpinc-scorlinc 
* PARTNERSHIP NET 
gen partinc=partpinc-partlinc
* S-CORP+PARTNERSHIP 
gen partscor=partpinc-partlinc+scorpinc-scorlinc 
* POSITIVE AND NEGATIVE PART OF PARTNERSHIP AND S-CORP BY RETURN TO BE CONSISTENT WITH SOI VARIABLES AND TABS 
gen scorpinc2=max(0,scorinc)
gen scorlinc2=-min(0,scorinc) 
gen partpinc2=max(0,partinc) 
gen partlinc2=-min(0,partinc) 
* positive and negative parts of S-CORP+PARTNERSHIP as in SOI tabulations 
gen partscorp=max(0,partscor) 
gen partscorl=-min(0,partscor) 

* NET CAPITAL GAINS IN AGI (as consistent as possible to Piketty-Saez)
cap gen kgagi=0 
cap replace kgagi=cgagi if $yr==1960 
cap replace kgagi=max(0.5*(nltclac+nstgc),-1000)+salepr if $yr==1962 
cap replace kgagi=cgagi if $yr==1964 
cap replace kgagi=cgagi if $yr==1966 
cap replace kgagi=ncapgn-ncapls+totorg+othpng-othpnl if $yr>=1967 & $yr<=1970 
cap replace kgagi=ncapgn-ncapls+totorg if $yr==1971 
cap replace kgagi=ncapgn-ncapls+salegn-salels if $yr==1972 | $yr==1974 
cap replace kgagi=cgagi if $yr==1975 | $yr==1973
cap replace kgagi=cgagi+cgdist if $yr>=1976 & $yr<=1978 
cap replace kgagi=cgagi+cgdist+supgn if ($yr<=1996 & $yr>=1979) | ($yr>=1999) | ($yr==1998 & $data==1)
cap replace kgagi=cgagi+supgn if $yr==1997 | ($yr==1998 & $data==0)
replace kgagi=0 if kgagi==. 
* BLOWED UP CAPITAL GAINS, 50% of KG in AGI up to 1978, 40% of KG in AGI from 1979 to 1986 
gen kgincfull=kgagi 
replace kgincfull=2.5*kgagi if $yr>=1979 & $yr<=1986 
replace kgincfull=2*kgagi if $yr>=1960 & $yr<=1978

* NET CAPITAL GAINS in AGI from SCHEDULE D (excludes capital distributions cgdist and sales of other property from form 4797 supgn)
cap gen kgagid=0 
cap replace kgagid=cgagi if $yr==1960 
cap replace kgagid=0.5*(nltclac+nstgc) if $yr==1962 
cap replace kgagid=cgagi if $yr==1964 
cap replace kgagid=cgagi if $yr==1966 | $yr==1970
cap replace kgagid=ncapgn-ncapls+totorg if $yr>=1967 & $yr<=1969 
cap replace kgagid=ncapgn-ncapls+totorg if $yr==1971 
cap replace kgagid=ncapgn-ncapls if $yr==1972 | $yr==1974 
cap replace kgagid=cgagi if $yr==1975 | $yr==1973
cap replace kgagid=cgagi if $yr>=1976 & $yr<=1978 
cap replace kgagid=cgagi if ($yr<=1996 & $yr>=1979) | ($yr>=1998) 
cap replace kgagid=cgagi if $yr==1997 
replace kgagid=0 if kgagid==.
*  BLOWED UP CAPITAL GAINS, 50% of KG in AGI up to 1978, 40% of KG in AGI from 1979 to 1986 
gen kginc=kgagid
replace kginc=max(-1000,2*kgagid) if $yr>=1960 & $yr<=1976
replace kginc=max(-2000,2*kgagid) if $yr==1977 
replace kginc=max(-3000,2*kgagid) if $yr==1978 
replace kginc=max(-3000,2.5*kgagid) if $yr>=1979 & $yr<=1986 

/*
quietly sum kgincfull [w=dweght]
local kgps=r(sum_w)*r(mean)*1e-11
quietly sum kginc [w=dweght]
local kgzuc=r(sum_w)*r(mean)*1e-11
display "YEAR =" $yr " TOT KGINC PIK " `kgps' " TOT KGINC ZUCMAN " `kgzuc'
*/

* XX use disabx, eldcr, and  as disability indicator available 1960 to 1979 as AGI adjustment

* OLD-AGE EXEMPTIONS, no direct info from 1996 on so imputed based on SSA benefits and standard ded, I checked that the aggregate level is good in 1995 computing it both ways (the overlap is high about 80%, much higher for non-itemizers), careful jump up in gssb in 2006 as new rules require reporting gssb even if ssagi=0, # of cases with gssb>0 & ssagi=0 jumps up from 2.9m in 2005 to 6.9m in 2006
* In 1979-1981, use xfpt and xfst (as agex not available)
* For marrieds, I assume primary taxpayer is always the husband and secondary the wife (confirmed internally that this 90%+ accurate)
gen oldexm=0 

cap replace oldexm=1 if agex!=. & agex>0 & ($yr==1964 | ($yr>=1971 & $yr<=1974)) 
* in 1982 to 1995, agex=1 if primary only 65+, =2 if secondary only 65+, =3 if both 65+
cap replace oldexm=1 if agex!=. & (agex==1 | agex==3) & ($yr>=1982 & $yr<=1995) 
cap replace oldexm=1 if ageex!=. & ageex>0 & ($yr==1962 | ($yr>=1966 & $yr<=1970 ) | $yr==1975)
cap replace oldexm=1 if (xfpt==2 | xfpt==3) & ($yr>=1976 & $yr<=1981) 


* imputations post-1996 done as in TPC, oldexm=1 if higher std ded or gssb>0 for itemizers 
* in 2008-11, retdstd (real estate taxes up to $500 ($1000 if MFJ) in totald standard ded)
cap replace totald=totald-retdstd if ($yr>=2008 & $yr<=2011) & fded==2 & retdstd>0
* XX for 2012 totald is zero for fded=2 (standard ded users), it seems to be a typo in PUF file
cap replace totald=agi-exempt-newtxy if fded==2 & $yr==2012 & newtxy>0

cap replace oldexm=1 if $yr>=1996 & fded!=2 & (ssagi>0 | (gssb>0 & peninc+penincnt>0)) 
cap replace oldexm=1 if $yr==2012 & fded==2 & (ssagi>0 | (gssb>0 & peninc+penincnt>0)) 
cap replace oldexm=1 if $yr>=1996 & fded==2 & totald>`stdyr_m'+150 & married==1 
cap replace oldexm=1 if $yr>=1996 & fded==2 & totald>.5*`stdyr_m'+150 & marriedsep==1 
cap replace oldexm=1 if $yr>=1996 & fded==2 & totald>`stdyr_s'+150 & single==1 
cap replace oldexm=1 if $yr>=1996 & fded==2 & totald>`stdyr_h'+150 & head==1

* for 2009 and 2012, agerange variable (only for the low sampling rate sample)
cap replace oldexm=0 if $yr==2009 & agerange<6 & agerange>0
cap replace oldexm=1 if $yr==2009 & agerange==6 
cap replace oldexm=1 if $yr==2012 & agerange==6 
* set age below 65 for aggregate record for 2009+
cap replace oldexm=0 if  dweght>=100*1e+5 & agi>=1e+7 & $yr>=2009

display `stdyr_m' "  " `stdyr_s' "  " `stdyr_h'


* COMPUTING MARRIED SPOUSE AGE 65+>0, always assuming that the female spouse is younger than the male spouse (as no direct info is available except 1969, 1974, 1979-1995)
gen oldexf=0
cap replace oldexf=1 if agex!=. & agex>1 & ($yr==1964 | ($yr>=1971 & $yr<=1974)) & married==1 
cap replace oldexf=1 if agex!=. & (agex==2 | agex==3) & ($yr>=1982 & $yr<=1995) & married==1 
cap replace oldexf=1 if ageex!=. & ageex>1 & ($yr==1962 | ($yr>=1966 & $yr<=1970 ) | $yr==1975) & married==1 
cap replace oldexf=1 if (xfst==2 | xfst==3) & ($yr>=1976 & $yr<=1981)  & married==1 
* after 1996, itemizers, assume 2 spouse above 65 if SSA benefits are above 90th percentile of gssb for non-married (suggesting both spouses on SSA), this creates big discontinuity as it picks up the high income/wealthy, so better to assign oldexf randomly with 62% chance based on 1995
/* old code
cap gen gssb=0
quietly sum gssb [w=dweght] if married!=1 & gssb>0, det
local maxssa=r(p90)
* display `maxssa'cap 
replace oldexf=1 if $yr>=1996 & fded!=2 & (gssb>=`maxssa') & married==1
* you get higher std ded for each spouse 65+ (or blind), increment of +$800 in 1996, +$1100 in 2009
*/

* new code 4/2016 to smooth out discontinuity
if $yr>=1996 {
set seed 54243
gen randu=uniform()
cap replace oldexf=1 if $yr>=1996 & fded!=2 & oldexm==1 & married==1 & randu<=.62
cap replace oldexf=1 if $yr==2012 & fded==2 & oldexm==1 & married==1 & randu<=.62
drop randu
}
cap replace oldexf=1 if $yr>=1996 & fded==2 & totald>`stdyr_m'+150+800+(1100-800)*($yr-1996)/(2009-1996) & married==1 
* set age below 65 for aggregate record for 2009+
cap replace oldexf=0 if  dweght>=100*1e+5 & agi>=1e+7 & $yr>=2009


* INSOLE use age and agesec variables
if $data==1 & $yr>=1979 {
* fix missing age using agespouse when possible
replace agesec=max(20,age-2) if agesec==. & age!=. & married==1
replace age=max(20,agesec+2) if agesec!=. & age==. & married==1

replace oldexm=0 if age<65 & age!=.
replace oldexm=1 if age>=65 & age!=.
replace oldexf=0 if agesec<65 & agesec!=.
replace oldexf=1 if agesec>=65 & agesec!=.
}




* In 1969 and 1974 and 2009 and 2012 we have gender information for age 65+ and gender of singles as well
* female, femalesec exists already in INSOLE
cap gen female=0
cap replace female=1 if sex==5 & $yr==1969 & married!=1
cap replace female=1 if sex==2 & $yr==1974 & married!=1
* For 2009 (only), gender information for full sample but we ignore it for continuity, for 2012 gender information for low income sample
*cap replace female=1 if  $yr==2009 & gender==2 & $data==0
* by default set femalesec equal to 1 for married
cap gen femalesec=1 if married==1
*cap replace femalesec=0 if $yr==2009 & gender==2  & $data==0

* ADJUSTMENTS, load agiadj as a variable in INSOLE (see matrix)
gen agiadj=0 
cap replace agiadj=disabx if $yr<=1962 
cap replace agiadj=disabx+moving+empexp+setax if $yr==1964 
cap replace agiadj=disabx+moving+empexp+seadj if $yr==1966 
cap replace agiadj=disabx+moving+empexp+iraded if $yr==1967 | $yr==1971 | $yr==1972 | $yr==1973
cap replace agiadj=ttladj if ($yr>=1968 & $yr<=1970) | ($yr>=1974 & $yr<=1983) 
cap replace agiadj=moving+empexp+iraded+keogh+penlty+almpd+secern if $yr==1984 | $yr==1985 | $yr==1986 
cap replace agiadj=empexp+iraded+irasec+keogh+penlty+almpd if $yr==1987 
cap replace agiadj=empexp+iraded+irasec+keogh+penlty+almpd+health if $yr==1988 | $yr==1989 
cap replace agiadj=hsetax+iraded+irasec+keogh+penlty+almpd+health if $yr>=1990 & $yr<=1991 
cap replace agiadj=hsetax+moving+iraded+irasec+keogh+penlty+almpd+health  if $yr>=1992 & $yr<=1996 
cap replace agiadj=hsetax+moving+iraded+keogh+penlty+almpd+health if $yr==1997
* NB I reloaded x1998.dta from NBER on 3/2016 bc some variables like stloan ctc originally misaligned
cap replace agiadj=hsetax+moving+iraded+keogh+penlty+almpd+health+stloan if $yr>=1998 & $yr<=1999 
cap replace agiadj=hsetax+iraded+keogh+penlty+almpd+health+stloan if $yr>=2000 & $yr<=2002 
cap replace agiadj=eduexp+stloan+tuided+hsetax+iraded+keogh+penlty+almpd+health if $yr==2003 
cap replace agiadj=eduexp+stloan+tuided+hsetax+iraded+keogh+penlty+almpd+health+hsave if $yr==2004 
cap replace dpaded=0 if dpaded==.
cap replace agiadj=eduexp+stloan+tuided+hsetax+iraded+keogh+penlty+almpd+health+hsave+dpaded if $yr>=2005
* double checked on 3/2016 correct up to 2009
 
if $data==1 & $yr>=1979 replace agiadj=agiadjirs


* TOTAL GROSS INCOME EXCL. K GAINS, UI and SS 
gen income=0  
gen agicrr=0 
cap replace income=agi-kgagi+agiadj+divexc if ($yr>=1960 & $yr<=1971)  
cap replace income=agi-kgagi+agiadj+divrec-divagi if ($yr>=1972 & $yr<=1978)  
cap replace income=agi-kgagi+agiadj+divrec-divagi-uiagi if $yr==1979 | $yr==1980 | $yr==1982 | $yr==1983
cap replace income=agi-kgagi+agiadj+divrec+inty-divint-uiagi if $yr==1981 
cap replace income=agi-kgagi+agiadj+divrec-divagi-uiagi-ssagi if $yr==1984 | $yr==1985 | $yr==1986 
cap replace income=agi-kgagi+agiadj-uiagi-ssagi if $yr>=1987 
cap replace agicrr=divexc if ($yr>=1962 & $yr<=1971)  
cap replace agicrr=divrec-divagi if ($yr>=1972 & $yr<=1978)  
cap replace agicrr=divrec-divagi-uiagi if $yr==1979 | $yr==1980 | $yr==1982 | $yr==1983
cap replace agicrr=divrec+inty-divint-uiagi if $yr==1981 
cap replace agicrr=divrec-divagi-uiagi-ssagi if $yr==1984 | $yr==1985 | $yr==1986 
cap replace agicrr=-uiagi-ssagi if $yr>=1987 
* GROSS INCOME = AGI + AGICRR + AGIADJ

* DEDUCTIONS COMPONENTS (note that today 30% of item ded are mortage interest, 30% are taxes paid, 15% charit ded, the other are very small (med ded, misc expenses, etc.). Exemptions are about same size as item ded and stand ded a bit smaller 

* CHARITABLE CONTRIBUTIONS  * no info on charitable giving in 67, 69, 71 
gen charit=0 
cap replace charit=contrd 
cap replace charit=0 if charit==. 

* TOTAL ITEMIZED DEDS (used for imputation), missing only for 1 year, totald is the name, totitm in 77-79 
* INSOLE need special totitm (total itemized deductions) totitm=e146 for 1979-80, e147 for 1981, e1690 for 1982-89, e04470 1990-2013, 
cap gen totald=totitm 
cap gen itemded=item*totald 
* sum itemded [w=dweght] 

* INTEREST DEDUCTIONS  * no info on interest deductions in 67, 69, 71 
gen intded=0 
cap replace intded=tintpd 
cap replace intded=0 if intded==. 
cap replace intded=(.16/.575)*itemded if $yr==1967 | $yr==1969 | $yr==1971 

* MORTGAGE INTEREST DEDUCTIONS  * no info on specific mortgage component in 60 and 62, 67, 69, 71 and 74 
* CAREFUL, mortgage also includes investment interest paid for borrowing for active business venture (which dominates at the top)
gen mortded=0 
cap replace mortded=tintpd 
cap replace mortded=mortpd  
* before TRA 86, not only mortgage but also other interest paid deductible 
cap replace mortded=0 if mortded==. 
cap replace mortded=0.6*tintpd if $yr==1974  
* use average of 73 and 75 and tintpd to impute mortded for 74 
cap replace mortded=0.55*tintpd if $yr==1962  
cap replace mortded=.16*itemded if $yr==1967 
cap replace mortded=.16*itemded if $yr==1969 
cap replace mortded=.16*itemded if $yr==1971 

* INTEREST DED NON MORTGAGE  * valid on before TRA 86 
gen intdedoth=0 
cap replace intdedoth=intded-mortded if $yr<=1986   
cap replace intdedoth=-intdedoth if $yr==1964|$yr==1967|$yr==1969|$yr==1971 

* MORTGAGE INTEREST DEDUCTION FROM RENTAL  * info only from 1990 on, in 2009+ it combined both rent and royalties expenses
* but 2008 shows that rrothi (other expenses) about 10% of rrmort, so I take 90% of rrinex in 2009+.
gen mortrental=0
cap replace mortrental=rrmort 
cap replace mortrental=0.9*rrinex if $yr>=2009

* STUDENT LOANS  * info only from 1998+ 
gen studentded=0 
cap replace studentded=stloan if $yr>=1998 

* cap drop itemded 

* CALCULATING TAXES PAID AND REFUNDABLE CREDITS
* fedtax will be Fed tax after credits (taxaft), can't be less than zero, so refundable credits are not included, in 1960 only taxbc is available
gen fedtax=0
cap replace fedtax=taxaft 
cap replace fedtax=taxbc if $yr==1960

* EITC credit, eictot is the total EITC, eicrefn is the part of the EITC that does not offset Fed income tax after credits (refundable portion+portion offsetting other taxes such as self-employed tax, IRA+401k early withdrawal tax)
gen eictot=0
cap rename eiccoff eicoff
cap replace eictot=eicoff+eicrd+eicref if $yr>=1979 | $yr==1975
cap replace eictot=eic if $yr>=1976 & $yr<=1978
gen eicrefn=0
cap replace eicrefn=eicoff+eicref if $yr>=1979 | $yr==1976 | $yr==1975
cap replace eicrefn=eicoth+eicref if $yr==1978
cap replace eicrefn=eicref if $yr==1977


* Child tax credit (starts in 1998), ctctot is total CTC, ctcrefn is the part refundable (additional child tax credit)
gen ctctot=0
cap rename addcrd accrd
cap replace ctctot=chtcr+accrd if $yr>=1998
gen ctcrefn=0
cap replace ctcrefn=accrd if $yr>=1998


* STATE INCOME TAXES, available for itemizers but not for non-itemizers, would need to use TAXSIM to estimate state taxes, starting in 2004, state income taxes not on Schedule A if sales taxes are higher (both in PUF and INSOLE), for 2009+ stytax includes saletx but only for low AGI returns (but not in INSOLE), no info in 67, 69, 71, 74, 76, 78 imputed by matching below
gen statetax=0
cap gen stxref=0
cap replace statetax=stytax-stxref if item==1 & $yr<2004
* in 2004-2008, stytax is zero if the taxpayers uses saletx (use of saletx might still happen in states with income tax but is probably rare)
cap replace statetax=stytax-stxref if item==1 & $yr>=2004 & $yr<=2008
* in 2009+ stytax includes both income and sales taxes (no breakdown) but saletx removed for high AGI returns so OK
* INSOLE pure state income taxes for 2009+ are e18425 called statetaxirs
cap replace statetax=stytax-stxref if item==1 & $yr>=2009 & $data==0
cap replace statetax=statetaxirs-stxref if item==1 & $yr>=2009 & $data==1
* for 74 use ttltxp 75, for 76 use ttltxp 77, for 78 use ttltxp 79 (micro-matching done below), totals from small files
cap replace statetax=(187/534)*ttltxp if $yr==1974 
cap replace statetax=(229/600)*ttltxp if $yr==1976  
cap replace statetax=(283/655)*ttltxp if $yr==1978 
* for 67 use itemded 68, for 69 use itemded 70, for 71 use itemded 72 (micro-matching done below), totals from SOI tables
cap replace statetax=(6.5/69.2)*itemded if $yr==1967 
cap replace statetax=(9.1/87.7)*itemded if $yr==1969 
cap replace statetax=(12.4/96.2)*itemded if $yr==1971
cap replace statetax=max(0,statetax)


* XX need to impute missing stytax for non-itemizers and for itemizers using sales tax ded for 2004+

* REAL ESTATE PROPERTY TAXES (needed for capitalization of real estate), no info in 67, 69, 71, 74, 76, 78 imputed by matching below
cap gen ttltxp=0  
* variable used for imputation later on 
gen realestatetax=0 
cap replace realestatetax=rprptx 
cap replace realestatetax=.35*ttltxp if $yr==1974 
* use average of 73 and 75 and ttltxp to impute realestatetax for 74 
cap replace realestatetax=.345*ttltxp if $yr==1976  
cap replace realestatetax=.327*ttltxp if $yr==1978 

cap replace realestatetax=.136*itemded if $yr==1967 
cap replace realestatetax=.136*itemded if $yr==1969 
cap replace realestatetax=.136*itemded if $yr==1971

* SELF EMPLOYMENT FED PAYROLL TAX 
cap gen setax=0 
cap gen sey=0 
replace setax=.079*min(sey,15300) if $yr==1976 
* in 1964, 1968, setax does not exist, seems miscoded as seadj
cap replace setax=seadj if $yr==1968 | $yr==1964

* SELF-EMPLOYMENT INCOME AND ITS SPLIT BT SPOUSES (added 1/2016), NOT GREAT IN PUF, WILL BE GOOD IN INSOLE (sey capped as SS max in 1984+ except 1991)
* sey does not exist 1962-1975, 1977, 1982-3 so I need to use setax, pb is that there is cap on earnings (wages+self-employed) for SS tax, sey is also capped for 1984+ (except 1991)
* tax rate for self-employed is from https://www.ssa.gov/oact/progdata/taxRates.html
cap gen sey=0 
replace sey=setax/.047 if $yr==1962
replace sey=setax/.054 if $yr==1964
replace sey=setax/.0615 if $yr==1966
replace sey=setax/.064 if $yr==1967 | $yr==1968
replace sey=setax/.069 if $yr==1969 | $yr==1970
replace sey=setax/.075 if $yr==1971 | $yr==1972
replace sey=setax/.080 if $yr==1973
replace sey=setax/.079 if $yr==1974  | $yr==1975  | $yr==1977
replace sey=setax/.0935 if $yr==1982 | $yr==1983 

* secondary self-employment income seysec, exists for 1984+ and capped at SS max-wages (except 1991) so not really useable
* 11/2016, I realized an incoherence in definition of sey and seysec pre-1991 vs post-1991
* before 1991, sey and seysec are only SE inc subject to se tax and hence are not present when individual wages>SScap hence not reliable
* in 1991, sey=.9235*seinc(primary)+.9235*seinc(secondary) and seyec=.9235*seinc(secondary) regardless of wages where seinc is self-employment income in gross income
* after 1991, sey=min(.9235*seinc(primary),SScap) + min(.9235*seinc(secondary),SScap) and seysec=min(.9235*seinc(secondary),SScap) regardless of wages where seinc is self-employment income in gross income
* bottomline: sey and seysec can't be used in external data pre-1991 (need to use internal tab imputation)
* XX need to check that internally, seyprimirs and seysecirs are correct before 1991

cap gen seysec=0
* INSOLE has perfect info uncapped on sey and seysec stored in raw variables seyprimirs and seysecirs
if $data==1 & $yr>=1979 replace sey=seyprimirs+seysecirs
if $data==1 & $yr>=1979 replace seysec=seysecirs

* TRANSFERS
* MEDICARE is a capitation: total Medicare spending/(pop wide numberabove 65+DI beneficiaries) from outside sources to be done in build_usdina
* MEANS-TESTED TRANSFERS: MEDICAID, TANF, SSI, PUBLIC HOUSING, SNAP, FREE LUNCHES assume it all goes to bottom 50% and to be matched to CPS

* UNEMPLOYMENT INSURANCE (UI) INCOME not available before 1979 because fully non-taxable
* 1979-1986, UI partly taxable (only if AGI above some threshold lowered in 1982-6), comparison with NIPA shows that 75% to 85% of UI benefits were reported on returns for 1979-1986 with no discontinuity in 1986-7 suggesting that all filers reported their full UI regardless of UIAGI>0 or not
* 1987+, UI fully taxable and hence fully reported (except 2009 when $2400 of UI was exempt for primary and 2nd filer separately)
* in 2008, 83% of UI NIPAs are reported
gen uiinc=0
cap replace uiinc=ui if $yr<1987
cap replace uiinc=uiagi if $yr>=1987
cap replace uiinc=uiagi+2400 if $yr==2009 & uiagi>0
* need to impute in CPS matching pre-1979

* SOCIAL SECURITY INCOME not available before 1984 because fully non-taxable
* in 1984, ssinc becomes partly taxable, taxation increases in 1993
* for 1984-2005, ssinc not always reported when taxable ssinc=0, fully reported in 2006+ (use only 2006+ for matching)
* ssinc always present when parly taxable ie when ssagi>0 ie AGI(excluding ssinc)+ssinc/2>=$25K ($32K if MFJ), 25K, 32K are fixed nominal thresholds since 1984
* before 2006, ssinc often absent when ssagi=0 (no SSA benefits are taxable)
* fraction NIPA ssinc reported is 35% in 84-93 increases slowly to 50% in 05 jumps to 62% in 06 and is 67% in 2008 
* need to impute in CPS matching pre-2006
gen ssinc=0
cap replace ssinc=gssb if $yr>=1984

* SUM OF COMPONENTS (excluding realized capital gains and other income, and govt transfers UI and SS)
gen suminc=waginc+peninc+divinc+intinc+rentinc+estinc+rylinc+schcinc+scorinc+partinc 

* OTHER INCOME NOT INCLUDED IN SUMINC HAS TO BE LAST TO INCLUDE ALL VARIABLES (includes alimony received, state tax refunds)
gen othinc=income-suminc 

cap drop year
gen year=$yr
cap gen flpdyr=year 
replace flpdyr=flpdyr+1900 if flpdyr<1900
* cap gen agex=0
cap drop agex

* ADDING STATE VARIABLE (fully present in INSOLE)
cap gen state=0

* defining id and setting aggregate record with id=0 at top (and assuming aggrec is below 65), set id=-1 for aggrec with negative AGI
* in 2011, aggrecord broken in 4, AGI<0, AGI in $1-$10m, AGI in $10m-$100m, and AGI>$100m, I give id=-1 to AGI<0 and id=0, -2, -3 to the other ones (id=0 is the maximum)
* that way id=0 flags the agg records with AGI>0 and id=-1 the agg records with AGI<0
* XX need to check retid of agg record after 2010
cap drop id
gen id=_n

* flagging the aggregate records with id variable and setting them to non-old and itemizer
if $data==0 {

if $yr>=1996 & $yr<=2009 {
	replace id=0 if id==_N  
	}
if $yr==2010 {
	cap replace id=0 if retid==999999
	cap replace id=-1 if retid==999998
	}
if $yr>=2011 {
* id=0 if for AGI>=$100m+, id=-2 for $10m<=AGI<$100m, id=-3 for 0<=AGI<$10m, id=-1 for AGI<0
	cap replace id=0 if retid==999999
	cap replace id=-2 if retid==999998
	cap replace id=-3 if retid==999997
	cap replace id=-1 if retid==999996
	}
	
sort id 
replace oldexm=0 if id==0 | id<=-1
replace oldexf=0 if id==0 | id<=-1
* added 5/2017, agg records with AGI>0 itemize (but the negative AGI aggrecord don't itemize)
replace item=1 if id==0 | id<-1

}

if $data==1 & $yr>=1979 cap gen occup=""
if $data==1 & $yr>=1979 cap gen occupsec=""

* Keeping only the relevant variables
if $data==0 | $yr<1979 keep state agi wages sey seysec dweght setax ttltxp taxunits-othinc year flpdyr id
if $data==1 & $yr>=1999            keep state agi wages sey seysec occup occupsec count-femalesec adjgross-w2wages dweght setax ttltxp taxunits-othinc year flpdyr id
if $data==1 & $yr>=1979 & $yr<1999 keep state agi wages sey seysec occup occupsec count-femalesec dweght setax ttltxp taxunits-othinc year flpdyr id

* adding age agesec placeholder variables externally
cap gen age=.
cap gen agesec=.

cap drop stxref

order year id state dweght flpdyr taxunits adults20 married marriedsep single head xded dependent xkids item oldexm oldexf female femalesec age agesec

* added 3/22/2016
cap label drop old
 	label define old 0 "65less" 1 "65plus"
 	label values oldexm old
 	cap label drop matstatus
 	label define matstatus 0 "sing" 1 "marr"
 	label values married matstatus
 	qui egen oldmar=group(married oldexm), label
 		label variable oldmar "Married x 65+ dummy"
 	compress


* labeling all variables

* structure and demographic variables
label variable year "Year of file (=tax returns processed in year+1)"
label variable id "unique ID, ID=0 for synth. record match $10m+ tabs, ID<=0 for agg records 2010+"
label variable state "state (numerical code), 0 if unassigned, available 1979-2008, capped in PUF"
label variable dweght "Population weight * 100,000"
label variable flpdyr "Filing period year (data organized by processing year)"
label variable taxunits "aggregate number of family tax units (in 000s)"
label variable adults20 "aggregate number of adults 20+ (in 000s)"
label variable married "dummy for married joint return (filing status)"
label variable marriedsep "dummy for married filing separate return (rare filing status)"
label variable single "dummy for single return (filing status)"
label variable head "dummy for head of household return (filing status)"
label variable xded "total number of dependents (spouse does not count)"
label variable dependent "dummy for primary filer being a dependent on somebody else's return"
label variable xkids "total number of children at home among dependents"
label variable item "dummy for itemizing deductions (= schedule A present)"
label variable oldexm "Dummy for primary filer being 65+"
label variable oldexf "Dummy for secondary filer being 65+"
label variable female "Dummy for being female (PUF only year 1969, 1974, internal only 1979+"
label variable femalesec "Dummy for being female secondary earner (internal only 1979+)"
label variable age "Age of primary filer = tax year - year of birth DM1 (internal only)"
label variable agesec "Age of secondary filer = tax year - year of birth DM1 (internal only)"

* income variables
label variable agi "Adjusted Gross Income (or deficit)"
label variable wages "total taxable wages"
label variable waginc "total taxable wage income (same as wages)"
label variable peninc "total taxable pension income (=DB+DC+IRA withdrawals, but not Social Security)"
label variable penincnt "total non-taxable pension income (=Roth IRA+ after tax DC withdrawals)"
label variable penira "total taxable IRA withdrawals 1987+ (part of peninc)"
label variable divinc "dividend income (qualified and non-qualified)"
label variable intinc "taxable interest income"
label variable intexm "tax exempt interest income (from state+local bonds = munis)"
label variable rentinc "net rental income (Schedule E) = rentincp-rentincl"
label variable rentincp "positive part of net rental income from Schedule E"
label variable rentincl "(minus) negative part of net rental income from Schedule E"
label variable estinc "estate and trust net income"
label variable rylinc "royalties net income"
label variable othinc_imp "other income imputed"
label variable schcinc "schedule C (sole prioprietorship) net income"
label variable schcincp "schedule C positive profit"
label variable schcincl "(minus) schedule C loss"
label variable partpinc "partnership positive profit (non aggregated by return)"
label variable partlinc "(minus) partnership loss (non aggregated by return)"
label variable scorpinc "S corp positive profit (non aggregated by return)"
label variable scorlinc "(minus) S corp loss (non aggregated by return)"
label variable partpnp "partnership positive profit nonpassive"
label variable partpp "partnership positive profit passive"
label variable partlnp "(minus) partnership loss nonpassive"
label variable partlp "(minus) partnership loss passive" 
label variable scorpnp "S corp positive profit nonpassive"
label variable scorpp "S corp positive profit passive"
label variable scorlnp "(minus) S corp loss nonpassive"
label variable scorlp "(minus) S corp loss passive"
label variable scorinc "S corporation net income"
label variable partinc "partnership net income"
label variable partscor "partnership+S corp net income"
label variable partpinc2 "partnership positive profit (aggregated by return)"
label variable partlinc2 "(minus) partnership loss (aggregated by return)"
label variable scorpinc2 "S corp positive profit (aggregated by return)"
label variable scorlinc2 "(minus) S corp loss (aggregated by return)"
label variable partscorp "partnership+S corp positive profit"
label variable partscorl "(minus) partnership+S corp loss"
label variable kgagi "capital gains in AGI (50% 1960-78, 40% 79-86, 100% 87+) (schdD+cgdist+supgn)"
label variable kgincfull "full realized capital gains (schedule D+cgdist+supgn)"
label variable kgagid "net realized capital gains from SCHEDULE D  in AGI (excludes cgdist and supgn)" // added "
label variable kginc "Total realized capital gains from SCHEDULE D, negative capped at -$3000"
label variable agiadj "Total AGI adjustments (vary a bit across years in allowed adjustments)"
label variable income "Total gross market income (excluding capital gains) = agi-kgagi+agiadj+agicrr"
label variable agicrr "AGI correction = -uiagi - ssagi + dividend exclusion (pre-1979)"
label variable suminc "sum of total market income components (excluding KG and other income)"
label variable othinc "other income in AGI"

* good in INSOLE, bad in PUF
label variable sey "self-employment income (complete in INSOLE, PUF capped and 1984+ only)"
label variable seysec "self-employment income, secondary earner (in PUF capped and 1984+ only)"

* deduction variables
label variable charit "Total charitable giving (schedule A)" 
label variable itemded "Total itemized deductions (schedule A)"
label variable intded "Total interest deduction in schedule A (=mortgage in 1987+)"
label variable mortded  "Mortgage interest deduction (schedule A)"
label variable intdedoth "Non-mortgage interest deduction in schedule A (pre 1987 only)"
label variable mortrental "Mortgage interest paid for rental properties, Schedule E" 
label variable studentded  "Student loan interest deduction 1999+ (capped at $2500)"

* tax and transfer variables
label variable fedtax "Federal Income Tax After Credits (never negative)"
label variable ttltxp "Total taxes (state+local) on schedule A"
label variable statetax "State+local income taxes = from schedule A - state tax refund (prior year)"
label variable realestatetax "Real Estate Taxes Paid, Schedule A"
label variable setax "Self-employment OASDI payroll tax"

label variable eictot "Total EITC received"
label variable eicrefn "Refundable EITC = Total EITC - EITC offsetting Fed Inc Tax net of tax credits"
label variable ctctot "Total Child Tax Credit (CTC) received, prog starts 1998"
label variable ctcrefn "Refundable CTC = Additional CTC = Total CTC - CTC offsetting Fed Inc Tax"
label variable uiinc "UI benefits (1979+ only)"
label variable ssinc "Social security+DI benefits (absent pre-84, 1984-2005 incomplete, 06+ complete)"

* INSOLE only variables
if $data==1 & $yr>=1979 {
label variable occup "Occupation of primary filer (husband if married) INSOLE"
label variable occupsec "Occupation of secondary (wife) filer INSOLE"
label variable agedeath "Age of death of primary filer = yod-yob (if deceased by end 2015) DM1"
label variable agedeathsec "Age of death of secondary (wife) filer = yod-yob (if deceased by end 2015) DM1"
label variable dob "Year of birth of primary filer (DM1)"
label variable dobsec "Year of birth of secondary (wife) filer (DM1)"
label variable dod "Year of death of primary filer (DM1)"
label variable dodsec "Year of death of secondary (wife) filer (DM1)"
label variable tin "TIN of primary filer"
label variable tinsec "TIN of secondary (wife) filer"
label variable tintyp "TIN type of primary filer"
label variable tintypsec "TIN type of secondary (wife) filer"
label variable count "=_n within tin*flpdyr (used for merging by flpdyr tin count due to dups)"
/*
label variable zip5 "ZIP 5 of residence"
*/
order agedeath agedeathsec dob dobsec dod dodsec occup occupsec tin tinsec tintyp tintypsec count, last
}

* DATABANK MERGED VARIABLES 1999+
if $data==1 & $yr>=1999 {
label variable adjgross "AGI from databank"
label variable w2wages "W2 wages of primary+secondary filer, databank 1999+"
label variable w2wagesprim "W2 wages of primary filer, databank 1999+"
label variable w2wagessec "W2 wages of secondary (wife) filer, databank 1999+"
label variable w2pensionprim  "W2 elective pension (401k/DC types) of primary filer, databank 1999+"
label variable w2pensionsec "W2 elective pension (401k/DC types) of secondary (wife) filer, databank 1999+"
label variable uiincprim "Unemployment insurance information return of primary filer, databank 1999+"
label variable uiincsec "Unemployment insurance information return of secondary (wife) filer,  databank 1999+"
label variable ssincprim "Social Security benefits information return of primary file,  databank 1999+"
label variable ssincsec "Social Security benefits information return of secondary (wife) filer,  databank 1999+"
label variable w2healthprim  "W2 health benefits of primary filer (2012+),  databank 1999+"
label variable w2healthsec "W2 health benefits of secondary(wife)  filer (2012+),  databank 1999+"
order adjgross-w2wages, last
}

cap drop _merge
cap drop totald
cap drop fded 
* defining global $vartot as the variable list of small file (right after build_small, to be used in aging.do and onlinedata.do
global vartot ""
global vartot0 "year-oldmar"


foreach var of varlist $vartot0 {
  global vartot "$vartot `var'"
  }
  
save "$dirsmall/small$yr.dta", replace



#delimit cr
******************************************************************************************
* III adding imputations using sub_matching.do subroutine nnmatch for missing variables 
* this smoothes out about 2/3 of the jagged series in gross housing and mortgages for 1962-1978 due to missing variables
* CAREFUL: takes 30 mins to run because matching procedure is slow 
* SAVING TIME: to avoid repeating the imputation set the global impute=0 (set impute=1 to repeat the imputation) 
******************************************************************************************

* cd "$root/programs"

global dirprog "$root/programs"

* do we need to redo imputations? if yes set global impute=1 (careful works only if small files already exist)
global impute=0

* fixing 62 rentinc, rylinc, estinc using 64, 64, 66 (as no estinc in 64) using othinc_imp=other+rentinc+rylinc+estinc

if $yr==1962 {
global varmiss "rentinc"
global varmatch "othinc_imp" 
global varmatch0 "agi"
global year1=1962
global year0=1964
do $dirprog/sub_matching.do
global varmiss "rylinc"
global year1=1962
global year0=1964
do $dirprog/sub_matching.do
global varmiss "estinc"
global year1=1962
global year0=1966
do $dirprog/sub_matching.do
* computing positive and negative rental income for imputed rentinc in 62
use "$dirsmall/small$year1.dta", clear
replace rentincp=max(0,rentinc)
replace rentincl=-min(0,rentinc)
save "$dirsmall/small$year1.dta", replace
}

* fixing mortgage interest deduction "mortded" for 62, 67, 69, 71, 74
* use itemded (total itemized deductions) for 67, 69, 71 (using 68, 70, 72 resp)
global varmiss "mortded"
global varmatch "itemded" 
global varmatch0 "agi"

if $yr==1967 {
global year1=1967
global year0=1966
do $dirprog/sub_matching.do
}

if $yr==1969 {
global year1=1969
global year0=1968
do $dirprog/sub_matching.do
}

if $yr==1971 {
global year1=1971
global year0=1970
do $dirprog/sub_matching.do
}

* use intded (total interest in item deds) for 62 and 74 (use 66 (closest with info) and 75 resp)
global varmiss "mortded"
global varmatch "intded" 
global varmatch0 "agi"

if $yr==1962 {
global year1=1962
global year0=1966
do $dirprog/sub_matching.do
}

if $yr==1974 {
global year1=1974
global year0=1975
do $dirprog/sub_matching.do
}


* fixing real estate taxes paid "realestatetax" for 67, 69, 71, 74, 76, 78
* use itemded (total itemized deductions) for 67, 69, 71 (using 68, 70, 72 resp)
global varmiss "realestatetax"
global varmatch "itemded" 
global varmatch0 "agi"

if $yr==1967 {
global year1=1967
global year0=1968
do $dirprog/sub_matching.do
}
if $yr==1969 {
global year1=1969
global year0=1970
do $dirprog/sub_matching.do
}
if $yr==1971 {
global year1=1971
global year0=1972
do $dirprog/sub_matching.do
}
* use ttltxp (total taxes paid in item deds) for 74, 76, 78 (using 75, 77, 79 resp)
global varmiss "realestatetax"
global varmatch "ttltxp" 
global varmatch0 "agi"
if $yr==1974 {
global year1=1974
global year0=1975
do $dirprog/sub_matching.do
}
if $yr==1976 {
global year1=1976
global year0=1977
do $dirprog/sub_matching.do
}
if $yr==1978 {
global year1=1978
global year0=1979
do $dirprog/sub_matching.do
}

* fixing state income taxes paid "statetax" for 67, 69, 71, 74, 76, 78
* use itemded (total itemized deductions) for 67, 69, 71 (using 68, 70, 72 resp)
global varmiss "statetax"
global varmatch "itemded" 
global varmatch0 "agi"

if $yr==1967 {
global year1=1967
global year0=1968
do $dirprog/sub_matching.do
}
if $yr==1969 {
global year1=1969
global year0=1970
do $dirprog/sub_matching.do
}
if $yr==1971 {
global year1=1971
global year0=1972
do $dirprog/sub_matching.do
}
* use ttltxp (total taxes paid in item deds) for 74, 76, 78 (using 75, 77, 79 resp)
global varmiss "statetax"
global varmatch "ttltxp" 
global varmatch0 "agi"
if $yr==1974 {
global year1=1974
global year0=1975
do $dirprog/sub_matching.do
}
if $yr==1976 {
global year1=1976
global year0=1977
do $dirprog/sub_matching.do
}
if $yr==1978 {
global year1=1978
global year0=1979
do $dirprog/sub_matching.do
}

* return to runusdina.do directory
* cd $root


****************************************************************************************************
* added 2/2018: tabulation for aging the PUFs using internal data (copied from aging program)
* done internally for $yr>=$pufendyear and also externally for $yr=$pufendyear to prepare aging file
****************************************************************************************************

if ($yr>=$pufendyear & $data==1) | ($yr==$pufendyear & $data==0) {

use $root/output/small/small$yr.dta, clear
cap drop if filer==0
global agelist "married xded xkids oldexm oldexf agi waginc peninc penira penincnt divinc intinc intexm rentinc rylinc estinc schcinc scorinc partinc kgagi kginc othinc income mortrental uiinc ssinc sey seysec agicrr agiadj studentded item itemded charit mortded intded statetax realestatetax setax fedtax eictot eicrefn ctctot ctcrefn"
keep year id dweght $agelist
order year id dweght $agelist

* creating 12 stratas (married vs not)*(itemizer vs not)*(old vs young with kids vs young no kids) 
* grouping will be done within each of these 12 stratas
local n=1
gen strata=0
gen kidsdummy=(xkids!=0)
foreach mar of numlist 0 1 {
foreach itm of numlist 0 1 {
replace strata=`n' if oldexm==1 & married==`mar' & item==`itm'
local n=`n'+1
	foreach kid of numlist 0 1 {
	replace strata=`n' if oldexm==0 & married==`mar' & kidsdummy==`kid' & item==`itm'
	local n=`n'+1
		}
	}
	}

tab strata

* creating the AGI bins
bys strata: cumul agi [w=dweght] if agi>=0, gen(agirank)
replace agirank=-1 if agi<0
gen agibin=0
foreach num of numlist -1 0 .1 .2 .3 .4 .5 .6 .7 .8 .9 .95 .99 .995 .999 .9999 {
*foreach num of numlist -1 0 .5 .9 .99 .999 .9999 {
	replace agibin=`num' if agirank>=`num'
	}
	
table strata agibin
gen wt=round(dweght*1e-5)
table strata agibin [w=wt]
gen one=1
sort strata agibin

*sum agi waginc xkids [w=dweght]
drop wt kidsdummy agirank 
if $data==0 save $root/output/small/smallforaging$yr.dta, replace

gen oldexfcount=oldexf
	
* create collapsed table by agibin strata
collapse (rawsum) one dweght oldexfcount (mean) year $agelist [w=dweght], by(strata agibin)
sort strata agibin
*sum agi waginc xkids [w=dweght]

* remove cells with less than 10 observations in internal data, edited 6/2018 to add variable one to keep track of records
if $data==1 {
	drop if dweght<10*1e+5
	drop if one<3
	}

* zeroing out cells with 1 or 2 records with oldexf=1, and zeroing when non-married or when primary <65
replace oldexf=0 if oldexfcount<3 | married==0 | oldexm==0
replace oldexfcount=0 if oldexfcount<3 | married==0 | oldexm==0
* sum oldexfcount, det
replace xkids=0 if xkids*dweght<3
replace xded=0 if xded*dweght<3
*gen test=((xded-xkids)*dweght<3 & xded>xkids)
*list strata one dweght xded xkids if test==1
replace xded=xkids if (xded-xkids)*dweght<3 & xded>xkids
		
* drop one
cap drop ttltxp
replace dweght=round(dweght*1e-5)

saveold $root/output/small/agetable$yr.dta, replace

}




/*
******************************************************************************************
* aggregate values in tabular format, use this separately as it loops across all years
******************************************************************************************
global sumstats="income agi waginc divinc kginc intinc intexm estinc rylinc scorpinc scorpinc2 scorlinc scorlinc2 scorinc partpinc partpinc2 partlinc partlinc2 partinc"
global sumstats2="schcincp schcincl schcinc 
rentincp rentincl rentinc peninc penincnt peninctotal penira othinc mortded intdedoth realestatetax  charit oldexm married item itemded"
 
matrix results = J(40,100,.)
foreach year of numlist 1979/2013 {
 local ii=`year'-1960+1
 use "$dirsmall/small`year'.dta", clear
 cap gen kgincfull=kginc
 cap gen peninctotal=peninc+penincnt
 cap gen one=1
 cap drop occup*
 order one
 matrix results[`ii',1]=`year'
 sum income [w=dweght]
 local jj=1
 foreach var of varlist * {
 local jj=`jj'+1
 quietly sum `var' [w=dweght]
 matrix results[`ii',`jj']=r(sum_w)*r(mean)*1e-14 
 }
}
 
xsvmat double results, fast names(col)
local jj=1
foreach var of newlist year taxfilers $sumstats $sumstats2 {
 rename c`jj' `var'
 local jj=`jj'+1
 }
mkmat _all, mat(results)
outsheet using $dirsmall/sumstats.xls, replace

*/

