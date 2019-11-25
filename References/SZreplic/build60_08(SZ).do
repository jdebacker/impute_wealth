* FIRST STEP: constructing files smallX.dta containing the income variables of interest and the marginal 
* tax rates from TAXISM
* originally used for TPE 2004 paper
* revised for JEP and JEL paper on 6/2005
* revised 11/2009 for Atkinson copula project
* revised 9/2013 for Saez-Zucman wealth capitalization project
* revised 1/2014 for Piketty-Saez-Zucman DINA project (adding demographic variables and tax/benefits variables)

* Input for build60_08.dta are the PUF files available at NBER in STATA format from 1960-2009, x60, x62, x64, x66,...,x99, x2000,..., x2008
* available on NBER server at homes/data/soi/dta
* see http://users.nber.org/~taxsim/gdb/ for complete documentation of the files

clear all

set type double
set memory 400m
set matsize 600
set more off

* I) Build small micro-data with key variables to be used

* standard ded for singles 1970-2014 from tax policy center historical standard deduction (checked that 1970 is $1000) needed to create 65+ old dummy
* 1000	1050	1300	1300	1300	1600	1700	2200	2200	2300	2300	2300	2300	2300	2300	2400	2480	2540	3000	3100	3250	3400	3600	3700	3800	3900	4000	4150	4250	4300	4400	4550	4700	4750	4850	5000	5150	5350	5450	5700	5700	5800	5950	6100	6200
* standard ded for married 1970-2014
* 1000	1050	1300	1300	1300	1900	2100	3200	3200	3400	3400	3400	3400	3400	3400	3550	3670	3760	5000	5200	5450	5700	6000	6200	6350	6550	6700	6900	7100	7200	7350	7600	7850	9500	9700	10000	10300	10700	10900	11400	11400	11600	11900	12200	12400
* standard ded for heads 1970-2014
* 1000	1050	1300	1300	1300	1600	1700	2200	2200	2300	2300	2300	2300	2300	2300	2400	2480	2540	4400	4550	4750	5000	5250    5450	5600	5750	5900	6050	6250	6350	6450	6650	6900	7000	7150	7300	7550	7850	8000	8350	8400	8500	8700	8950	9100
* Piketty-Saez total taxunits 1960-2012 in 000s 68681	69997	71254	72464	73660	74772	75831	76856	77826	78793	79924	81849	83670	85442	87228	89127	91048	93076	95213	97457	99625	101432	103250	105067	106871	108736	110684	112640	114656	116759	119055	120453	121944	123378	124716	126023	127625	129301	130945	132267	134473	137088	139703	141843	143982	145881	148361	149875	152462	153543	156167	158367	160681
* Piketty-Saez adults 20+ in 000s 1960-2013 	111314	112450	113754	115096	116796	118275	119724	121143	123507	125543	127674	130774	133502	136006	138444	141055	143609	146305	149142	152105	155268	158033	160665	163135	165650	168205	170556	172552	174344	176060	178365	180978	183443	185685	187757	189911	192043	194426	196795	199255	201588	204062	206452	208682	211051	213511	216055	218482	220976	223491	226114	228746	231409	233882
* Total adults 65+ in 000s 1960-2012 			16675	17089	17457	17778	18127	18451	18755	19071	19365	19680	20107	20561	21020	21525	22061	22696	23278	23892	24502	25134	25707	26221	26787	27361	27878	28416	29008	29626	30124	30682	31247	31812	32356	32902	33331	33769	34143	34402	34619	34798	35071	35290	35522	35864	36203	36650	37164	37826	38778	39623	40477	41394	43145


global year_build="60 62 64 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 2000 2001 2002 2003 2004 2005 2006 2007 2008"
global std_s="600 600 600 600 600 600 600 1000	1050	1300	1300	1300	1600	1700	2200	2200	2300	2300	2300	2300	2300	2300	2400	2480	2540	3000	3100	3250	3400	3600	3700	3800	3900	4000	4150	4250	4300	4400	4550	4700	4750	4850	5000	5150	5350	5450"
global std_m="600 600 600 600 600 600 600 1000	1050	1300	1300	1300	1900	2100	3200	3200	3400	3400	3400	3400	3400	3400	3550	3670	3760	5000	5200	5450	5700	6000	6200	6350	6550	6700	6900	7100	7200	7350	7600	7850	9500	9700	10000	10300	10700	10900"
global std_h="600 600 600 600 600 600 600 1000	1050	1300	1300	1300	1600	1700	2200	2200	2300	2300	2300	2300	2300	2300	2400	2480	2540	4400	4550	4750	5000	5250    5450	5600	5750	5900	6050	6250	6350	6450	6650	6900	7000	7150	7300	7550	7850	8000"
global taxun="68681				71254			73660			75831	76856	77826	78793	79924	81849	83670	85442	87228	89127	91048	93076	95213	97457	99625	101432	103250	105067	106871	108736	110684	112640	114656	116759	119055	120453	121944	123378	124716	126023	127625	129301	130945	132267	134473	137088	139703	141843	143982	145881	148361	149875	152462"
global adults="111314			113754			116796			119724	121143	123507	125543	127674	130774	133502	136006	138444	141055	143609	146305	149142	152105	155268	158033	160665	163135	165650	168205	170556	172552	174344	176060	178365	180978	183443	185685	187757	189911	192043	194426	196795	199255	201588	204062	206452	208682	211051	213511	216055	218482	220976"
global old65="16675				17457			18127			18755	19071	19365	19680	20107	20561	21020	21525	22061	22696	23278	23892	24502	25134	25707	26221	26787	27361	27878	28416	29008	29626	30124	30682	31247	31812	32356	32902	33331	33769	34143	34402	34619	34798	35071	35290	35522	35864	36203	36650	37164	37826	38778"

* for choosing specific years, change numlist 1/46 below (1960 only = numlist 1, 2008 only = numlist 46, etc.)
foreach ii of numlist 1/46 {
local X : word `ii' of $year_build
local stdyr_s : word `ii' of $std_s
local stdyr_m : word `ii' of $std_m
local stdyr_h : word `ii' of $std_h
local taxunyr : word `ii' of $taxun
local adultsyr : word `ii' of $adults
local yr=`X'
if `X'<2000 {
local yr=`X'+1900
}
display "year = " `yr' " counter = " `ii' " std ded married "  `stdyr_m'

use "$dirirs/x`X'" 
cd .. 
cd .. 
cap replace wght=1 if wages>50000 & wght>500 & `X'==60 
cap replace wght=1 if agi>50000 & wght>500 & `X'==60 
cap replace agi=agi-agidef if `X'==66 | `X'==67 | `X'==68 | `X'==69 | `X'==70 | `X'==71  
* WEIGHTS: variable DWEGHT is weight (pop weight*100000 for integer rounding reasons) 
cap gen dweght=wght  
cap gen dweght=dwght 
replace dweght=100*dweght if `X'==60 | `X'==64 | (`X'>=68 & `X'<=75)  
* this one fixes a bug in 1986, an obs with agi=1.1m and div 425K with weight 7919, way too high, error in SOI tabs
replace dweght=100 if agi>1000000 & dweght>50000 
replace dweght=int(1000*dweght) 

* TOTAL NUMBER OF TAX UNITS AND ADULTS 20+ FROM PIKETTY-SAEZ 
gen taxunits=`taxunyr'
gen adults20=`adultsyr'

* MARRIED DUMMY (married joint filers, includes qualifying widowers since 2000, those who've lost spouse in last 2 years, a minuscule group .06% in 1999) 
gen married=0 
replace married=1 if mars==1 & `X'<=62 
replace married=1 if mars==2 & `X'>=64 

* MARRIED SEPARATE DUMMY (married separate filers) 
gen marriedsep=0 
replace marriedsep=1 if mars==2 & `X'<=62 
replace marriedsep=1 if (mars==3 | mars==6) & `X'>=64 

* SINGLE DUMMY (includes singles) 
gen single=0 
replace single=1 if mars==5 & `X'<=62 
replace single=1 if mars==1 & `X'>=64 

* HEAD OF HOUSEHOLD DUMMY (include heads and surviving spouses with children) 
gen head=0 
replace head=1 if (mars==3 | mars==4) & `X'<=62 
replace head=1 if (mars==4 | mars==5| mars==7) & `X'>=64 

* NUMBER OF DEPENDENTS 
gen xded=0 
cap replace xded=xocah+xocawh+xoodep+xopar if `X'>=81 
cap replace xded=xocah+xocawh+xoodep+xopah if `X'==80 
cap replace xded=xocah+xocawh+xoodep+xopah+xopawh if `X'==79 
cap replace xded=xocah+xocawh+xopah+xopawh if `X'==78 
cap replace xded=dpndx if `X'==77 | `X'==76 | (`X'>=71 & `X'<=74) | (`X'>=68 & `X'<=69) | `X'==66 
cap replace xded=xocah+xocawh+xoodep if `X'==75 
cap replace xded=xocah+xocawh+xoodep+xopar if `X'==70 
cap replace xded=totex-ageex-blndex-txpyex if `X'==67 
cap replace xded=xoodep if `X'==64 
cap replace xded=xoodep+dpndx if `X'==62 

* CLAIMED AS DEPENDENT ON OTHER RETURN (typically parent), can only be done after TRA 86
gen dependent=0
cap replace dependent=1 if xtot==0 & `X'>=87

* NUMBER OF CHILDREN AT HOME (no specific info pre-78 except 62, 70 and 75 so I use total deps pre-78 including 62, 70 and 75 to avoid discontinuities, 5%-10% over-statement) 
gen xkids=xded 
cap replace xkids=xocah if `X'>=78 

* ITEMIZER DUMMY (no fded in 1977 so need to use totitm>0 instead) 
gen item=0 
cap gen fded=(totitm>0) if `X'==77 
replace item=1 if fded==1 

* WAGES  * wages do not include 401(k) contributions 
gen waginc=wages 
* blurring for wages in 1996+, could be fixed using the eitc_main.do code from AEJ 2010 bunching paper as wagescalc=agi+agiadj-(sum of all other income components)

* IRAs, PENSIONS AND ANNUITIES  * always taxable pensions including taxable IRAs because non-taxable pensions emanate in general from after-tax wage contributions 
gen peninc=0 
cap replace peninc=txpen  if `X'<=73 | `X'==76 
cap replace peninc=txpen+ftpen  if `X'==74 | `X'==75 
cap replace peninc=pentax if `X'==67 
cap replace peninc=ftpen+txpen if `X'>=77 & `X'<=81 
cap replace peninc=iragi+taxoth if `X'>=82 & `X'<=86 
cap replace peninc=penagi if `X'==87 
cap replace peninc=txpen+taxira  if `X'>=88 & `X'<=95 
cap replace peninc=txpen+ftpen  if `X'>=96 | `X'==91 
replace peninc=0 if peninc==. 
* non-taxable pensions, no info before 1968 and 71-73 (for Saez-zucman wealth capitalization) 
gen penincnt=0 
cap replace penincnt=totpen-txpen if `X'>=68 & `X'<=81 
cap replace penincnt=other-taxoth if `X'>=82 & `X'<=86 
cap replace penincnt=piar-penagi if `X'==87 
cap replace penincnt=totpen-txpen if `X'>=88 
cap replace penincnt=e01500-txpen if `X'==2006 
* bug in 1969 and 1984 corrected 
cap replace penincnt=0 if penincnt>=700000 & dweght>1e+8 & `X'==84  
cap replace penincnt=0 if penincnt>=1000000 & `X'==69  

replace penincnt=0 if penincnt==. 
* IRA pensions (not available separately before 1987), only taxable IRA pensions 
gen penira=0 
* cap replace penira=ftpen if `X'>=74 & `X'<=81  
* cap replace penira=iragi if `X'>=82 & `X'<=86 
cap replace penira=taxira  if `X'>=88 & `X'<=95 
cap replace penira=ftpen  if `X'>=96 | `X'==91 
replace penira=0 if penira==. 

* DIVIDENDS  * includes the small div exclusion before 1987 
gen divinc=0 
cap replace divinc=divrec if `X'==60 
cap replace divinc=divrec+grdiv if `X'==62 | `X'==64 
cap replace divinc=divrec if `X'>=66 & `X'<=86 
cap replace divinc=divagi if `X'>=87 
cap replace divinc=divrec+divexc if `X'==68 

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
cap gen rentinc=0 
cap replace rentinc=(3933-1063)*othinc/(3933-1063+584-75+692-30+2343) if `X'==62  
* othinc includes other, rents, estates, royalties 
cap replace rentinc=rentny-rentnl if `X'<=72 | `X'==74 
cap replace rentinc=rentyl if `X'==73 | `X'>=75 | `X'==64 
cap replace rentinc=ttlrnt-rrmort if `X'>=2007 
cap replace rentinc=-rntlss if `X'>=2007 & rntlss>0 
cap replace rentinc=0 if retinc==. 
gen rentincp=max(0,rentinc) 
gen rentincl=-min(0,rentinc) 
cap replace rentincp=(3933)*othinc/(3933-1063+584-75+692-30+2343) if `X'==62 
cap replace rentincl=(1063)*othinc/(3933-1063+584-75+692-30+2343) if `X'==62 

* ESTATES AND TRUSTS no estate income in 62, 64, I impute for 62 but not for 64 bc no SOI tab estate in 64 
gen estinc=0 
cap replace estinc=(692-30)*othinc/(3933-1063+584-75+692-30+2343) if `X'==62 
* othinc includes other, rents, estates, royalties 
cap replace estinc=estny-estnl if `X'<=72 | `X'==74
cap replace estinc=estpl if `X'==73 | (`X'<=80 & `X'>=76) 
cap replace estinc=esty-estlss if `X'>=81 | `X'==75 
replace estinc=0 if estinc==. 
* ROYALTIES no royalties income in 62, no royalty separate in 2007+ so imputed imperfectly, total is too high 
gen rylinc=0 
cap replace rylinc=(584-75)*othinc/(3933-1063+584-75+692-30+2343) if `X'==62  
* othinc includes other, rents, estates, royalties 
cap replace rylinc=ryltny-ryltnl if `X'<=72 | `X'==74 
cap replace rylinc=ryltyl if `X'==73 | `X'>=75 | `X'==64 
cap replace rylinc=rry-rrlos if `X'>=2007 & ttlrnt==0 
cap replace rylinc=max(0,rry-rrlos-rentinc) if `X'>=2007 & ttlrnt>0 
cap replace rylinc=0 if rylinc==. 
* EXTRA VARIABLE: othinc_imp = other income + rents + royalties + estates to input 62 from 64 and 66 
cap gen othinc_imp=0 
cap gen miscy =0  
cap gen miscl=0 
cap gen othery=0 
replace othinc_imp=miscy-miscl+rentinc+rylinc+estinc if `X'==66 
replace othinc_imp=othery+rentinc+rylinc if `X'==64 
replace othinc_imp=othinc if `X'==62 
cap gen othinc=0  
* need to avoid removing othinc_imp 
drop miscy miscl othery othinc 

* correcting 2007+ to match SOI totals, need to do by hand by sum rentincp rentincl rylinc in small data 
cap replace rentincp=rentincp*(56510/(762.2963*143.05)) if `X'==2007 
cap replace rentincl=rentincl*(74090/(399.7153*143.05)) if `X'==2007 
cap replace rylinc=rylinc*((17875-235)/(156.6823*143.05)) if `X'==2007 
cap replace rentincp=rentincp*(60072/(859.4697*142.58)) if `X'==2008 
cap replace rentincl=rentincl*(75494/(408.3931*142.58)) if `X'==2008 
cap replace rylinc=rylinc*((26574-209)/(186.6574*142.58)) if `X'==2008 
cap replace rentinc=rentincp-rentincl if `X'>=2007 

* BUSINESS OF PROFESSION (SCHED C INCOME) + FARM 
* LOSS AND GAINS AGGREGATED RETURN BY RETURN 
cap gen schcinc=0  
cap replace schcinc=busny if `X'==62 
cap replace schcinc=schedc+farm if `X'==64 | `X'==73 | `X'>=75 

cap replace schcinc=busny-busnl+farmy-farml if `X'<=72 | `X'==74 
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
cap replace partpinc=partny if (`X'==62) & partny>0  
cap replace partpinc=partpl if (`X'==64 | `X'==76 | `X'==77 | `X'==78) & partpl>0 
cap replace partpinc=partny if (`X'>=66 & `X'<=72) | `X'==74 
cap replace partpinc=party if  (`X'>=79 & `X'<=86) | `X'==73 | `X'==75   
cap replace partpinc=passy+npassy if `X'>=87 & `X'<=2003 
cap replace partpinc=partpy+partnpy if `X'>=2004    
replace partpinc=0 if partpinc==. 
* NEGATIVE INCOME 
cap gen partlinc=0  
cap replace partlinc=-partny if `X'==62 & partny<0  
cap replace partlinc=-partpl if (`X'==64 | `X'==76 | `X'==77 | `X'==78) & partpl<0 
cap replace partlinc=partnl if (`X'>=66 & `X'<=72) | `X'==74 
cap replace partlinc=partl if (`X'>=79 & `X'<=86) | `X'==73 | `X'==75  
cap replace partlinc=passl+npassl if `X'>=87 
cap replace partlinc=partlinc+p179xd if `X'>=93 
cap replace partlinc=partpl+partnpl if `X'>=2004 

replace partlinc=0 if partlinc==. 

* S-CORP INCOME (S-CORP 1962, 1964, AND 1968 REPORTED ON PARTNERSHIPS) 
* LOSS AND GAIN ON SAME RETURN POSSIBLE EXCEPT FOR YEARS 1974, 1976 and 1978 WHERE LOSS AND GAINS AGGREGATED RETURN BY RETURN 
* POSITIVE INCOME 
cap gen scorpinc=0  
cap replace scorpinc=smbny if (`X'>=66 & `X'<=72) | `X'==74 
cap replace scorpinc=netpl if (`X'==76 | `X'==78) & netpl>0 
cap replace scorpinc=sbtly if (`X'>=79 & `X'<=86) | `X'==73 | `X'==75 | `X'==77  
cap replace scorpinc=smbpy+smbnpy if `X'>=87 
replace scorpinc=0 if scorpinc==. 
* NEGATIVE INCOME 
cap gen scorlinc=0 
cap replace scorlinc=smbnl if (`X'>=66 & `X'<=72) | `X'==74  
cap replace scorlinc=sbtlss if (`X'>=79 & `X'<=86) | `X'==73 | `X'==75  
cap replace scorlinc=-netpl if (`X'==76 | `X'==78) & netpl<0 
cap replace scorlinc=-(netpl-sbtly) if `X'==77  
cap replace scorlinc=smblos+sbnpls if `X'>=87 
cap replace scorlinc=scorlinc+s179xd if `X'>=93 
cap replace scorlinc=smbnpl+s179xd+smblos if `X'>=2000 
cap replace scorlinc=smbnpl+s179xd+smbpl if `X'>=2004 
replace scorlinc=0 if scorlinc==. 

* POST TRA86, DECOMPOSITION PASSIVE VS NON-PASSIVE 
* PARTNERSHIP INCOME  
* POSITIVE INCOME NON-PASSIVE 
cap gen partpnp=0  
cap replace partpnp=npassy if `X'>=87 
cap replace partpnp=partnpy if `X'>=2004  
replace partpnp=0 if partpnp==. 
* POSITIVE INCOME PASSIVE 
cap gen partpp=0  
cap replace partpp=passy if `X'>=87 
cap replace partpp=partpy if `X'>=2004 
replace partpp=0 if partpp==. 
* NEGATIVE INCOME NON-PASSIVE 
cap gen partlnp=0  
cap replace partlnp=npassl if `X'>=87 
cap replace partlnp=partlnp+p179xd if `X'>=93 
cap replace partlnp=partnpl if `X'>=2004 
replace partlnp=0 if partlnp==. 
* NEGATIVE INCOME PASSIVE 
cap gen partlp=0  
cap replace partlp=passl if `X'>=87 
cap replace partlp=partpl if `X'>=2004 
replace partlp=0 if partlp==. 

* S-CORP INCOME  
* POSITIVE INCOME NON-PASSIVE 
cap gen scorpnp=0  
cap replace scorpnp=smbnpy if `X'>=87 
replace scorpnp=0 if scorpnp==. 
* POSITIVE INCOME PASSIVE 
cap gen scorpp=0  
cap replace scorpp=smbpy if `X'>=87 
replace scorpp=0 if scorpp==. 
* NEGATIVE INCOME NON-PASSIVE 
cap gen scorlnp=0  
cap replace scorlnp=smblos if `X'>=87 
cap replace scorlnp=scorlnp+s179xd if `X'>=93 
cap replace scorlnp=smbnpl+s179xd if `X'>=2004 
replace scorlnp=0 if scorlnp==. 
* NEGATIVE INCOME PASSIVE 
cap gen scorlp=0  
cap replace scorlp=sbnpls if `X'>=87 & `X'<=99 
cap replace scorlp=smbnpl if `X'<=2003 & `X'>=2000 
cap replace scorlp=smbpl if `X'>=2004 
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
cap replace kgagi=cgagi if `X'==60 
cap replace kgagi=max(0.5*(nltclac+nstgc),-1000)+salepr if `X'==62 
cap replace kgagi=cgagi if `X'==64 
cap replace kgagi=cgagi if `X'==66 
cap replace kgagi=ncapgn-ncapls+totorg+othpng-othpnl if `X'>=67 & `X'<=70 
cap replace kgagi=ncapgn-ncapls+totorg if `X'==71 
cap replace kgagi=ncapgn-ncapls+salegn-salels if `X'==72 | `X'==74 
cap replace kgagi=cgagi if `X'==75 | `X'==73
cap replace kgagi=cgagi+cgdist if `X'>=76 & `X'<=78 
cap replace kgagi=cgagi+cgdist+supgn if (`X'<=96 & `X'>=79) | (`X'>=98) 
cap replace kgagi=cgagi+supgn if `X'==97 
replace kgagi=0 if kgagi==. 
* BLOWED UP CAPITAL GAINS, 50% of KG in AGI up to 1978, 40% of KG in AGI from 1979 to 1986 
gen kgincfull=kgagi 
replace kgincfull=2.5*kgagi if `X'>=79 & `X'<=86 
replace kgincfull=2*kgagi if `X'>=60 & `X'<=78

* NET CAPITAL GAINS in AGI from SCHEDULE D (excludes capital distributions cgdist and sales of other property from form 4797 supgn)
cap gen kgagid=0 
cap replace kgagid=cgagi if `X'==60 
cap replace kgagid=0.5*(nltclac+nstgc) if `X'==62 
cap replace kgagid=cgagi if `X'==64 
cap replace kgagid=cgagi if `X'==66 | `X'==70
cap replace kgagid=ncapgn-ncapls+totorg if `X'>=67 & `X'<=69 
cap replace kgagid=ncapgn-ncapls+totorg if `X'==71 
cap replace kgagid=ncapgn-ncapls if `X'==72 | `X'==74 
cap replace kgagid=cgagi if `X'==75 | `X'==73
cap replace kgagid=cgagi if `X'>=76 & `X'<=78 
cap replace kgagid=cgagi if (`X'<=96 & `X'>=79) | (`X'>=98) 
cap replace kgagid=cgagi if `X'==97 
replace kgagid=0 if kgagid==.
*  BLOWED UP CAPITAL GAINS, 50% of KG in AGI up to 1978, 40% of KG in AGI from 1979 to 1986 
gen kginc=kgagid
replace kginc=max(-1000,2*kgagid) if `X'>=60 & `X'<=76
replace kginc=max(-2000,2*kgagid) if `X'==77 
replace kginc=max(-3000,2*kgagid) if `X'==78 
replace kginc=max(-3000,2.5*kgagid) if `X'>=79 & `X'<=86 

/*
quietly sum kgincfull [w=dweght]
local kgps=r(sum_w)*r(mean)*1e-11
quietly sum kginc [w=dweght]
local kgzuc=r(sum_w)*r(mean)*1e-11
display "YEAR =" `X' " TOT KGINC PIK " `kgps' " TOT KGINC ZUCMAN " `kgzuc'
*/




* OLD-AGE EXEMPTIONS, no direct info from 1996 on so imputed based on SSA benefits and standard ded, I checked that the aggregate level is good in 1995 computing it both ways (the overlap is high about 80%, much higher for non-itemizers), careful jump up in gssb in 2006 as new rules require reporting gssb even if ssagi=0, # of cases with gssb>0 & ssagi=0 jumps up from 2.9m in 2005 to 6.9m in 2006
* In 1979-1981, use xfpt and xfst (as agex not available)
* For marrieds, I assume primary taxpayer is always the husband and secondary the wife (confirmed internally that this 90%+ accurate)
gen oldexm=0 
cap replace oldexm=1 if agex!=. & agex>0 & (`X'==64 | (`X'>=71 & `X'<=74)) 
* in 1982 to 1995, agex=1 if primary only 65+, =2 if secondary only 65+, =3 if both 65+
cap replace oldexm=1 if agex!=. & (agex==1 | agex==3) & (`X'>=82 & `X'<=95) 
cap replace oldexm=1 if ageex!=. & ageex>0 & (`X'==62 | (`X'>=66 & `X'<=70 ) | `X'==75)
cap replace oldexm=1 if (xfpt==2 | xfpt==3) & (`X'>=76 & `X'<=81) 

* imputations post-1996 done as in TPC, oldexm=1 if higher std ded or gssb>0 for itemizers 
* in 2008-9, retdstd (real estate taxes up to $500 ($1000 if MFJ) in totald standard ded)
cap replace totald=totald-retdstd if (`X'==2008 | `X'==2009) & fded==2 & retdstd>0
cap replace oldexm=1 if `X'>=96 & fded!=2 & (ssagi>0 | (gssb>0 & peninc+penincnt>0)) 
cap replace oldexm=1 if `X'>=96 & fded==2 & totald>`stdyr_m'+150 & married==1 
cap replace oldexm=1 if `X'>=96 & fded==2 & totald>.5*`stdyr_m'+150 & marriedsep==1 
cap replace oldexm=1 if `X'>=96 & fded==2 & totald>`stdyr_s'+150 & single==1 
cap replace oldexm=1 if `X'>=96 & fded==2 & totald>`stdyr_h'+150 & head==1

* COMPUTING MARRIED SPOUSE AGE 65+>0, always assuming that the female spouse is younger than the male spouse (as no direct info is available except 1969, 1974, 1979-1995)
gen oldexf=0
cap replace oldexf=1 if agex!=. & agex>1 & (`X'==64 | (`X'>=71 & `X'<=74)) & married==1 
cap replace oldexf=1 if agex!=. & (agex==2 | agex==3) & (`X'>=82 & `X'<=95) & married==1 
cap replace oldexf=1 if ageex!=. & ageex>1 & (`X'==62 | (`X'>=66 & `X'<=70 ) | `X'==75) & married==1 
cap replace oldexf=1 if (xfst==2 | xfst==3) & (`X'>=76 & `X'<=81)  & married==1 
* after 1996, itemizers, assume 2 spouse above 65 if SSA benefits are above 90th percentile of gssb for non-married (suggesting both spouses on SSA)
cap gen gssb=0
quietly sum gssb [w=dweght] if married!=1 & gssb>0, det
local maxssa=r(p90)
* display `maxssa'
cap replace oldexf=1 if `X'>=96 & fded!=2 & (gssb>=`maxssa') & married==1
* you get higher std ded for each spouse 65+ (or blind), increment of +$800 in 1996, +$1050 in 2008
cap replace oldexf=1 if `X'>=96 & fded==2 & totald>`stdyr_m'+150+800+(1050-800)*(`yr'-1996)/(2008-1996) & married==1 

* In 1969 and 1974, we have gender information for age 65+ and gender of singles as well
gen female=0
cap replace female=1 if sex==2 & (`X'==74 | `X'==69) & married!=1


* ADJUSTMENTS 
gen agiadj=0 
cap replace agiadj=disabx if `X'<=62 
cap replace agiadj=disabx+moving+empexp+setax if `X'==64 
cap replace agiadj=disabx+moving+empexp+seadj if `X'==66 
cap replace agiadj=disabx+moving+empexp+iraded if `X'==67 | `X'==71 | `X'==72 | `X'==73
cap replace agiadj=ttladj if (`X'>=68 & `X'<=70) | (`X'>=74 & `X'<=83) 
cap replace agiadj=moving+empexp+iraded+keogh+penlty+almpd+secern if `X'==84 | `X'==85 | `X'==86 
cap replace agiadj=empexp+iraded+irasec+keogh+penlty+almpd if `X'==87 
cap replace agiadj=empexp+iraded+irasec+keogh+penlty+almpd+health if `X'==88 | `X'==89 
cap replace agiadj=hsetax+iraded+irasec+keogh+penlty+almpd+health if `X'>=90 & `X'<=91 
cap replace agiadj=hsetax+moving+iraded+irasec+keogh+penlty+almpd+health  if `X'>=92 & `X'<=96 
cap replace agiadj=hsetax+moving+iraded+keogh+penlty+almpd+health if `X'>=97 & `X'<=99 
cap replace agiadj=hsetax+iraded+keogh+penlty+almpd+health if `X'>=2000 | `X'<=2002 
cap replace agiadj=eduexp+stloan+tuided+hsetax+iraded+keogh+penlty+almpd+health if `X'==2003 
cap replace agiadj=eduexp+stloan+tuided+hsetax+iraded+keogh+penlty+almpd+health+hsave if `X'>=2004 

* NEED TO CHECK WHETHER MOVING IS IN AGI AFTER 2001 

* TOTAL GROSS INCOME EXCL. K GAINS, UI and SS 
gen income=0  
gen agicrr=0 
cap replace income=agi-kgagi+agiadj+divexc if (`X'>=60 & `X'<=71)  
cap replace income=agi-kgagi+agiadj+divrec-divagi if (`X'>=72 & `X'<=78)  
cap replace income=agi-kgagi+agiadj+divrec-divagi-uiagi if `X'==79 | `X'==80 | `X'==82 | `X'==83
cap replace income=agi-kgagi+agiadj+divrec+inty-divint-uiagi if `X'==81 
cap replace income=agi-kgagi+agiadj+divrec-divagi-uiagi-ssagi if `X'==84 | `X'==85 | `X'==86 
cap replace income=agi-kgagi+agiadj-uiagi-ssagi if `X'>=87 
cap replace agicrr=divexc if (`X'>=62 & `X'<=71)  
cap replace agicrr=divrec-divagi if (`X'>=72 & `X'<=78)  
cap replace agicrr=divrec-divagi-uiagi if `X'==79 | `X'==80 | `X'==82 | `X'==83
cap replace agicrr=divrec+inty-divint-uiagi if `X'==81 
cap replace agicrr=divrec-divagi-uiagi-ssagi if `X'==84 | `X'==85 | `X'==86 
cap replace agicrr=-uiagi-ssagi if `X'>=87 
* GROSS INCOME = AGI + AGICRR + AGIADJ

* DEDUCTIONS COMPONENTS (note that today 30% of item ded are mortage interest, 30% are taxes paid, 15% charit ded, the other are very small (med ded, misc expenses, etc.). Exemptions are about same size as item ded and stand ded a bit smaller 

* CHARITABLE CONTRIBUTIONS  * no info on charitable giving in 67, 69, 71 
gen charit=0 
cap replace charit=contrd 
cap replace charit=0 if charit==. 

* TOTAL ITEMIZED DEDS (used for imputation), missing only for 1 year, totald is the name, totitm in 77-79 
cap gen totald=totitm 
cap gen itemded=item*totald 
* sum itemded [w=dweght] 

* INTEREST DEDUCTIONS  * no info on interest deductions in 67, 69, 71 
gen intded=0 
cap replace intded=tintpd 
cap replace intded=0 if intded==. 
cap replace intded=(.16/.575)*itemded if `X'==67 | `X'==69 | `X'==71 

* MORTGAGE INTEREST DEDUCTIONS  * no info on specific mortgage component in 60 and 62, 67, 69, 71 and 74 
* CAREFUL, mortgage also includes investment interest paid for borrowing for active business venture (which dominates at the top)
gen mortded=0 
cap replace mortded=tintpd 
cap replace mortded=mortpd  
* before TRA 86, not only mortgage but also other interest paid deductible 
cap replace mortded=0 if mortded==. 
cap replace mortded=0.6*tintpd if `X'==74  
* use average of 73 and 75 and tintpd to impute mortded for 74 
cap replace mortded=0.55*tintpd if `X'==62  
cap replace mortded=.16*itemded if `X'==67 
cap replace mortded=.16*itemded if `X'==69 
cap replace mortded=.16*itemded if `X'==71 

* INTEREST DED NON MORTGAGE  * valid on before TRA 86 
gen intdedoth=0 
cap replace intdedoth=intded-mortded if `X'<=86   
cap replace intdedoth=-intdedoth if `X'==64|`X'==67|`X'==69|`X'==71 

* MORTGAGE INTEREST DEDUCTION FROM RENTAL  * info only from 1990 on 
cap gen mortrental=rrmort 

* STUDENT LOANS  * info only from 1999+ (1998 variable is wrong) 
gen studentded=0 
cap replace studentded=stloan if `X'>=99 

* cap drop itemded 

* CALCULATING TAXES PAID AND REFUNDABLE CREDITS
* fedtax will be Fed tax after credits (taxaft), can't be less than zero, so refundable credits are not included, in 1960 only taxbc is available
gen fedtax=0
cap replace fedtax=taxaft 
cap replace fedtax=taxbc if `X'==60

* EITC credit, eictot is the total EITC, eicrefn is the part of the EITC that does not offset Fed income tax after credits (refundable portion+portion offsetting other taxes such as self-employed tax, IRA+401k early withdrawal tax)
gen eictot=0
cap rename eiccoff eicoff
cap replace eictot=eicoff+eicrd+eicref if `X'>=79 | `X'==75
cap replace eictot=eic if `X'>=76 & `X'<=78
gen eicrefn=0
cap replace eicrefn=eicoff+eicref if `X'>=79 | `X'==76 | `X'==75
cap replace eicrefn=eicoth+eicref if `X'==78
cap replace eicrefn=eicref if `X'==77
label variable eictot "Total EITC received"
label variable eicrefn "Refundable EITC = Total EITC - EITC offsetting Fed Inc Tax net of tax credits"

* Child tax credit (starts in 1998), ctctot is total CTC, ctcrefn is the part refundable (additional child tax credit)
gen ctctot=0
cap rename addcrd accrd
cap replace ctctot=chtcr+accrd if `X'>=98
gen ctcrefn=0
cap replace ctcrefn=accrd if `X'>=98
label variable ctctot "Total Child Tax Credit (CTC) received"
label variable ctcrefn "Refundable CTC = Additional CTC = Total CTC - CTC offsetting Fed Inc Tax"

* STATE INCOME TAXES, available for itemizers but not for non-itemizers, would need to use TAXSIM to estimate state taxes, starting in 2008, state income taxes not on Schedule A if sales taxes are higher, no info in 67, 69, 71, 74, 76, 78 imputed by matching below
gen statetax=0
label variable statetax "State+local income taxes = from schedule A - state tax refund (prior year)"
cap gen stxref=0
cap replace statetax=stytax-stxref if item==1 & `X'<2004
cap replace statetax=stytax-stxref if item==1 & saletx==0 & `X'>=2004
* for 74 use ttltxp 75, for 76 use ttltxp 77, for 78 use ttltxp 79 (micro-matching done below), totals from small files
cap replace statetax=(187/534)*ttltxp if `X'==74 
cap replace statetax=(229/600)*ttltxp if `X'==76  
cap replace statetax=(283/655)*ttltxp if `X'==78 
* for 67 use itemded 68, for 69 use itemded 70, for 71 use itemded 72 (micro-matching done below), totals from SOI tables
cap replace statetax=(6.5/69.2)*itemded if `X'==67 
cap replace statetax=(9.1/87.7)*itemded if `X'==69 
cap replace statetax=(12.4/96.2)*itemded if `X'==71

* XX need to impute missing stytax for non-itemizers and for itemizers using sales tax ded for 2004+

* REAL ESTATE PROPERTY TAXES (needed for capitalization of real estate), no info in 67, 69, 71, 74, 76, 78 imputed by matching below
cap gen ttltxp=0  
* variable used for imputation later on 
gen realestatetax=0 
label variable realestatetax "Real Estate Taxes Paid, Schedule A"
cap replace realestatetax=rprptx 
cap replace realestatetax=.35*ttltxp if `X'==74 
* use average of 73 and 75 and ttltxp to impute realestatetax for 74 
cap replace realestatetax=.345*ttltxp if `X'==76  
cap replace realestatetax=.327*ttltxp if `X'==78 

cap replace realestatetax=.136*itemded if `X'==67 
cap replace realestatetax=.136*itemded if `X'==69 
cap replace realestatetax=.136*itemded if `X'==71

* SELF EMPLOYMENT FED PAYROLL TAX 
cap gen setax=0 
cap gen sey=0 
replace setax=.079*min(sey,15300) if `X'==76 
* in 1964, 1968, setax does not exist, seems miscoded as seadj
cap replace setax=seadj if `X'==68 | `X'==64

* TRANSFERS
* MEDICARE is a capitation: total Medicare spending/(pop wide numberabove 65+DI beneficiaries) from outside sources to be done in build_usdina
* MEANS-TESTED TRANSFERS: MEDICAID, TANF, SSI, PUBLIC HOUSING, SNAP, FREE LUNCHES assume it all goes to bottom 50% and to be matched to CPS

* UNEMPLOYMENT INSURANCE (UI) INCOME not available before 1979 because fully non-taxable
* 1979-1986, UI partly taxable (only if AGI above some threshold lowered in 1982-6), comparison with NIPA shows that 75% to 85% of UI benefits were reported on returns for 1979-1986 with no discontinuity in 1986-7 suggesting that all filers reported their full UI regardless of UIAGI>0 or not
* 1987+, UI fully taxable and hence fully reported (except 2009 when $2400 of UI was exempt for primary and 2nd filer separately)
* in 2008, 83% of UI NIPAs are reported
gen uiinc=0
label variable uiinc "UI benefits (1979+ only)"
cap replace uiinc=ui if `X'<87
cap replace uiinc=uiagi if `X'>=87
cap replace uiinc=uiagi+2400 if `X'==2009 & uiagi>0
* need to impute in CPS matching pre-1979

* SOCIAL SECURITY INCOME not available before 1984 because fully non-taxable
* in 1984, ssinc becomes partly taxable, taxation increases in 1993, up to 
* for 1984-2005, SSinc not always reported when taxable SSinc=0, fully reported in 2006+ (use only 2006+ for matching)
* fraction NIPA ssinc reported is 35% in 84-93 increases slowly to 50% in 05 jumps to 62% in 06 and is 67% in 2008 
* need to impute in CPS matching pre-2006
gen ssinc=0
label variable ssinc "Social security retirement+DI benefits (absent pre-1984, 1984-2005 incomplete, 2006+ complete)"
cap replace ssinc=gssb if `X'>=84

* SUM OF COMPONENTS 
gen suminc=waginc+peninc+divinc+intinc+rentinc+estinc+rylinc+schcinc+scorinc+partinc 

* OTHER INCOME NOT INCLUDED IN SUMINC HAS TO BE LAST TO INCLUDE ALL VARIABLES 
gen othinc=income-suminc 

* REMOVING CORP S-INCOME and PARTNERSHIP LOSSES 
* replace suminc=suminc-scorinc+partlinc 
* replace income=income-scorinc+partlinc 

cap gen year=`X' 
replace year=`X'+1900 if `X'<100 
cap gen flpdyr=year 
* cap gen agex=0
cap drop agex
keep agi wages dweght setax ttltxp taxunits-othinc flpdyr 
gen id=_n  
sort id 



save "$dirsmall/small`yr'.dta", replace
}



/*
* testing code
* 1960 1962 1964 1966/2008
foreach yr of numlist 1960 1962 1964 1966/1980 {
display "YEAR = " `yr' 
use "$dirsmall/small`yr'.dta", clear
* sum single married head item oldexm oldexf xded xkids setax waginc  [w=dweght] 
* sum setax waginc  [w=dweght] 
*sum oldexm oldexf  [w=dweght] if married==1
*sum oldexm oldexf  [w=dweght] if married==0
* bys item: sum oldexm oldexf  [w=dweght] if married==1
* sum eictot eicrefn ctctot ctcrefn fedtax agi [w=dweght]
sum statetax realestatetax [w=dweght] if item==1
}
*/


#delimit;
* adding missing extreme observations for 1996-present;
* We use discrepancy between $10m+ SOI tab bracket and $10m+ computed from micro-data ($1m+ for 1996-99 as $1m+ is highest SOI bracket);
* # of extreme returns excluded is reported in PUF file documentation page 3;
* synthetic observation is added using id=0 record;
* careful that the $10m+ from the PUF samples have noise because sampling rate is only 33% in 1996-2004 and 10% in 2005+;
* as a result, the id=0 observations sometimes bigger than top 400 tabs done with internal SOI data;

* matrix input from income.xls sheet fixingmicro 1996-2011;
* variable list: count agi divinc intinc waginc kginc agiadj peninc penincnt intexm rylinc estinc rentincp rentincl schcincp schcincl partscorp partscorl charit realestatetax statetax fedtax;


matrix input table=
(113 83 83 191 123 100 90 98 80 45 53 58 13 10 10 10 \
314402063	423507211	533469193	653184370	300128133	174988989	129421398	159126112	256932933	376274843	452475087	561612712	399968769	240133885	345715738	321636083 \
16637097	20272005	21734952	25372478	9673414	7142669	6093870	10049091	18740821	22318777	28715176	37219720	32943902	22523842	33542051	26758647 \
18642177	22028614	24697007	27257505	11874396	9847466	7082065	7974713	10694625	19129732	27879563	36453697	22712435	14670540	18053545	15155518 \
91744720	123768259	159016757	207162755	75177400	44157630	29114831	32559413	51565771	65904223	71895407	90264836	75020367	45897921	56479162	55180596 \
110683589	163422829	222780814	270661887	174713405	88305400	57755764	74235385	125696910	191289216	243123059	314075163	181505077	81121848	153365554	143890344 \
918252	1146387	1389135	1740608	220521	169267	130747	159479	252457	1016894	1245577	1968094	2083932	1500367	2324465	2366569 \
1549094	2751237	2977621	3960892	345677	262672	157366	225285	400469	708638	645073	779123	581040	397117	1208635	1611168 \
2169492	3550367	4967734	8122300	715896	442184	425647	342275	701674	778115	1096141	1276011	1042302	599669	1265802	716092 \
7984926	9511566	10786907	12387076	3804670	2900685	2500696	2637448	3515258	5218381	7585202	9165251	5658711	3869855	4446554	4212465 \
1243697	1654535	1271260	1608391	514725	596090	381153	544645	731137	1140239	1484892	1385928	2221817	1349164	1389799	1749255 \
2362147	3063697	3600007	3586571	1443064	579320	1729723	1734273	2472640	3884051	3189115	3701553	4210884	3993148	4280335	3764220 \
3129275	3622081	4275715	4889450	546701	557152	492325	562795	827092	1089174	1038011	1166028	964688	877115	1343734	782279 \
374368	432433	544150	547438	72729	75174	62279	123469	161219	266398	313266	382555	311934	243594	247615	263879 \
6007954	7033045	7808643	9964964	2323036	2285893	1480011	1226471	2044209	3231782	3452208	3260950	4016456	3186775	2814942	3287292 \
882180	1005498	999748	1250383	475931	240639	281826	465878	562406	793783	1189468	1071181	1110342	564039	905200	1085123 \
66570734	81146457	92731993	107240229	29328718	25458069	27237810	32318656	47847343	74058943	80527915 	85691923	87420912	70384494	78622396	75741227 \
6612064	8719095	12032037	14546182	8990950	6183027	3970572	4579631	6867334	9204985	13093433	18991492	15379452	9074374	13078700	11835040 \ 
13648238	18618418	21141556	27245122	16919373	11156433	8670099	10762507	16898662	22980856	26180998	31038050	20286500	13896715	18732755	18787873 \
1478460	1844825	2165342	2620509	382207	323807	297052	360634	565042	797657	948067	1117388	851312	661672	835377	863807 \
16344849	20854795	25787947	31961568	14418408	9449979	6401626	7586758	12409862	18206444	21434774	26432597	22664746	15402081	17920794	19809557 \
96260153	121001713	145442075	180559429	76081256	45327935	33737749	35416375	54202159	78268656	91012054	110843279	83558216	53790072	71433949	65644001);



* divinc intinc waginc kginc agiadj peninc penincnt intexm rylinc estinc rentincp rentincl schcincp schcincl;



local ii=0;
foreach X of numlist 1996/2008 {;
local ii=`ii'+1;
use "$dirsmall/small`X'.dta", clear;
drop if id==0;
sort id;expand 2 in 1 if id==1;replace id=0 if id==1 & _n>1;
replace dweght=table[1,`ii']*100000 if id==0;sort id;
local jj=1;
replace schcincl=-schcincl if schcincl<0;
foreach var in agi divinc intinc waginc kginc agiadj peninc penincnt intexm rylinc estinc rentincp rentincl schcincp schcincl partscorp partscorl charit realestatetax statetax fedtax {;
	local jj=`jj'+1;
	egen aux=sum(dweght*`var'/(1000*100000)) if agi>=10000000 & `X'>=2000 & id!=0;
	replace aux=sum(dweght*`var'/(1000*100000)) if agi>=1000000 & `X'<2000  & id!=0;
	egen `var'sum=max(aux) ; drop aux ;
	replace `var'=1000*(table[`jj',`ii']-`var'sum)/table[1,`ii'] if id==0 ;
	drop `var'sum;
};
* separating S-corp from partnership income;
egen aux=sum(dweght*scorpinc2/(1000*100000)) if agi>=10000000 & id!=0;
egen scorpincsum=max(aux);drop aux;
egen aux=sum(dweght*partpinc2/(1000*100000)) if agi>=10000000 & id!=0;
egen partpincsum=max(aux);drop aux;
replace partpinc2=partscorp*partpincsum/(partpincsum+scorpincsum) if id==0;
replace scorpinc2=partscorp*scorpincsum/(partpincsum+scorpincsum) if id==0;
drop scorpincsum partpincsum;
egen aux=sum(dweght*scorlinc2/(1000*100000)) if agi>=10000000 & id!=0;
egen scorlincsum=max(aux);drop aux;
egen aux=sum(dweght*partlinc2/(1000*100000)) if agi>=10000000 & id!=0;
egen partlincsum=max(aux);drop aux;
replace partlinc2=partscorl*partlincsum/(partlincsum+scorlincsum) if id==0;
replace scorlinc2=partscorl*scorlincsum/(partlincsum+scorlincsum) if id==0;
drop scorlincsum partlincsum;
replace scorpinc=scorpinc2 if id==0;
replace scorlinc=scorlinc2 if id==0;
replace partpinc=partpinc2 if id==0;
replace partlinc=partlinc2 if id==0;

* fixing the rent and royalty for 2007+;
replace rentincp=0 if `X'>=2007 & id==0;replace rentincl=0 if `X'>=2007 & id==0;replace rylinc=0 if `X'>=2007 & id==0;
* cleaning up all the other variables;
replace wages=waginc if id==0;
replace kgagi=kginc if id==0;
replace kgincfull=kginc if id==0;
replace kgagid=kginc if id==0;
replace rentinc=rentincp-rentincl if id==0;
replace schcinc=schcincp-schcincl if id==0;
replace partscor=partscorp-partscorl if id==0;
replace partinc=partpinc2-partlinc2 if id==0;
replace scorinc=scorpinc2-scorlinc2 if id==0;
replace partpp=partpinc if id==0;replace partlp=partlinc if id==0;
replace scorpp=scorpinc if id==0;replace scorlp=scorlinc if id==0;
foreach var in single head marriedsep xded xkids oldexm setax intded mortded scorpnp scorlnp partpnp partlnp  othinc_imp {;
replace `var'=0 if id==0;};
replace married=1 if id==0;
replace item=1 if id==0;
replace flpdyr=`X' if id==0 & `X'>100;
replace flpdyr=1900+`X' if id==0 & `X'<100;
replace suminc=waginc+peninc+divinc+intinc+rentinc+estinc+rylinc+schcinc+scorinc+partinc if id==0;
replace income=agi-kgagi+agiadj if id==0;
replace othinc=income-suminc if id==0;

list if id==0;
sort id;
save "$dirsmall/small`X'.dta", replace; 
keep if id==0;
gen year=`X';
save "$dirsmall/test`X'.dta", replace; 
};


* testing the resulting dataset to compare top 400 to official SOI published top 400 statistics
use "$dirsmall/test1996.dta", clear;
foreach X of numlist 1997/2008 {;
	append using "$dirsmall/test`X'.dta";
};
order year id dweght agi;
foreach var of varlist wages-partscorl {;
	replace `var'=`var'/agi;
};
order year dweght agi kginc divinc intinc intexm waginc partscorp partscorl schcinc estinc rylinc rentincp rentincl;
save "$dirsmall/test.dta", replace;

* checking how close small files comes from top 400 in IRS;
foreach X of numlist 1992/2008 {;
    use "$dirsmall/small`X'.dta", clear;
    gen aux=-agi;cumul aux [w=dweght], gen(cumw) freq;drop aux;
	keep if cumw<=402*100000;
	gen year=`X';
	save "$dirsmall/top400_`X'.dta", replace; 
};
use "$dirsmall/top400_1992.dta";
foreach X of numlist 1992/2008 {;
	append using "$dirsmall/top400_`X'.dta";
};
save "$dirsmall/top400.dta", replace; 
gen one=1/100000;
table year [w=dweght], c(sum one min agi mean agi mean kginc);
table year [w=dweght], c(mean waginc mean intinc mean divinc mean kginc);
table year [w=dweght], c(mean schcincp mean schcincl mean partscorp mean partscorl);



* bottom line: works reasonably well but not perfect, id=0 is not in top 400 for 96-99;
* small files tend to underestimate top 400 relative to SOI except for year 2007;
* overall, I think it is better to benchmark relative to $10m+ top bracket rather than top 400;
* I suspect that a number of the extreme value returns removed from PUF micro files are large negatives as well;
* for components, partnership and S-corp income seems undervalued by 50%, agi, kginc, intinc, divinc seem OK;

#delimit cr
******************************************************************************************
* III adding imputations using matching.do subroutine nnmatch for missing variables 
* this smoothes out about 2/3 of the jagged series in gross housing and mortgages for 1962-1978 due to missing variables
* CAREFUL: takes 30 mins to run because matching procedure is slow 
* SAVING TIME: to avoid repeating the imputation set the global impute=0 (set impute=1 to repeat the imputation) 
******************************************************************************************
global directmatch $dirsmall

cd "$dirbuild/Programs"

global dirprog "$dirbuild/Programs"

* do we need to redo imputations? if yes set global impute=1
global impute=1

* fixing 62 rentinc, rylinc, estinc using 64, 64, 66 (as no estinc in 64) using othinc_imp=other+rentinc+rylinc+estinc
global varmiss "rentinc"
global varmatch "othinc_imp" 
global varmatch0 "agi"
global year1=1962
global year0=1964
do $dirprog/matching.do
global varmiss "rylinc"
global year1=1962
global year0=1964
do $dirprog/matching.do
global varmiss "estinc"
global year1=1962
global year0=1966
do $dirprog/matching.do
* computing positive and negative rental income for imputed rentinc in 62
use "$directmatch/small$year1.dta", clear
replace rentincp=max(0,rentinc)
replace rentincl=-min(0,rentinc)
save "$directmatch/small$year1.dta", replace


* fixing mortgage interest deduction "mortded" for 62, 67, 69, 71, 74
* use itemded (total itemized deductions) for 67, 69, 71 (using 68, 70, 72 resp)
global varmiss "mortded"
global varmatch "itemded" 
global varmatch0 "agi"
global year1=1967
global year0=1966
do $dirprog/matching.do
global year1=1969
global year0=1968
do $dirprog/matching.do
global year1=1971
global year0=1970
do $dirprog/matching.do

* use intded (total interest in item deds) for 62 and 74 (use 66 (closest with info) and 75 resp)
global varmiss "mortded"
global varmatch "intded" 
global varmatch0 "agi"
global year1=1962
global year0=1966
do $dirprog/matching.do
global year1=1974
global year0=1975
do $dirprog/matching.do


* fixing real estate taxes paid "realestatetax" for 67, 69, 71, 74, 76, 78
* use itemded (total itemized deductions) for 67, 69, 71 (using 68, 70, 72 resp)
global varmiss "realestatetax"
global varmatch "itemded" 
global varmatch0 "agi"
global year1=1967
global year0=1968
do $dirprog/matching.do
global year1=1969
global year0=1970
do $dirprog/matching.do
global year1=1971
global year0=1972
do $dirprog/matching.do
* use ttltxp (total taxes paid in item deds) for 74, 76, 78 (using 75, 77, 79 resp)
global varmiss "realestatetax"
global varmatch "ttltxp" 
global varmatch0 "agi"
global year1=1974
global year0=1975
do $dirprog/matching.do
global year1=1976
global year0=1977
do $dirprog/matching.do
global year1=1978
global year0=1979
do $dirprog/matching.do

* fixing state income taxes paid "statetax" for 67, 69, 71, 74, 76, 78
* use itemded (total itemized deductions) for 67, 69, 71 (using 68, 70, 72 resp)
global varmiss "statetax"
global varmatch "itemded" 
global varmatch0 "agi"
global year1=1967
global year0=1968
do $dirprog/matching.do
global year1=1969
global year0=1970
do $dirprog/matching.do
global year1=1971
global year0=1972
do $dirprog/matching.do
* use ttltxp (total taxes paid in item deds) for 74, 76, 78 (using 75, 77, 79 resp)
global varmiss "statetax"
global varmatch "ttltxp" 
global varmatch0 "agi"
global year1=1974
global year0=1975
do $dirprog/matching.do
global year1=1976
global year0=1977
do $dirprog/matching.do
global year1=1978
global year0=1979
do $dirprog/matching.do



cap log close

******************************************************************************************
* aggregate values in tabular format
******************************************************************************************
global sumstats="income agi waginc divinc kginc intinc intexm estinc rylinc scorpinc scorpinc2 scorlinc scorlinc2 scorinc partpinc partpinc2 partlinc partlinc2 partinc"
global sumstats2="schcincp schcincl schcinc rentincp rentincl rentinc peninc penincnt peninctotal penira othinc mortded intdedoth realestatetax  charit oldexm married item itemded"
 
matrix results = J(55,50,.)
foreach year of numlist 1960 1962 1964 1966/2008 {
 local ii=`year'-1960+1
 use "$dirsmall/small`year'.dta", clear
 cap gen kgincfull=kginc
 cap gen peninctotal=peninc+penincnt
 cap gen one=1
 matrix results[`ii',1]=`year'
 sum income [w=dweght]
 local jj=1
 foreach var of varlist one $sumstats $sumstats2 {
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






