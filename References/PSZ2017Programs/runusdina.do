* Console for US DINA: defines paths & runs programs that creates databases & generate all results from raw files

clear
clear matrix
clear mata
set type double
cap set maxvar 30000

*******************************************************************************
* CHOOSE DATA SOURCE AND YEARS
*******************************************************************************

quietly {
// data = 0 for external data (PUF), data = 1 for internal data (INSOLE)
	global data = 0
	if $data == 0 set matsize 11000

//  * online=0 for internal or PUF external, online = 1 for data to be posted online
	global online = 0
	* if $data == 1 global online = 0 
//   calibweight=1 for PUF online using calibrated weights to match internal stats (otherwise set to zero), not used anymore
	global calibweight = 0

// Select years  
	* endyear is the last year internally, pufendyear is that last year of PUF external, lastyear is last projected year
	global lastyear = 2020
	global pufendyear = 2012
	* XX if $data == 0 global endyear = 2020
	if $data == 0 global endyear = 2016
	
	if $data == 1 global endyear = 2016
	if $data == 1 global lastyear = $endyear

	* databankyear is the last year of databankyear (for wages earnings splits)
	global databankyear = 2015
	* cpsendyear is the last year of cps income available, survey is nominally the march year cpsendyear+1
	global cpsendyear = 2016
	* global years "1962 1964 1966/$lastyear"
	global years "2000"
	
	
	* global years "1962 1964 1966/$lastyear"
		numlist "$years"
		local fullyears = "`r(numlist)'"
		local nbyears : list sizeof local(fullyears)
}

*******************************************************************************
* DEFINE PATHS
*******************************************************************************

quietly {
// Data paths
		cap cd		 "/Users/gzucman/Dropbox/SaezZucman2014/usdina"
		cap cd		 "/Users/zucman/Dropbox/SaezZucman2014/usdina"
  		cap cd 		 "/Users/manu/Dropbox/SaezZucman2014/usdina"
		cap cd 		 "/Users/Antoine/Dropbox/SaezZucman2014/usdina"
		cap cd 		 "/Users/Antoine Arnoud/Dropbox/SaezZucman2014/usdina"
		cap cd       "c:/saez/usdina"
		cap cd       "home/8rknb/usdina"
		cap cd       "bod/OTA7/8rknb/usdina"
		global root "`c(pwd)'"
		

					global  dirirs 		 "$root/rawdata/puf"
					global  dirirsint 	 "$root/rawdata/irsinternal"
					global  dircps 		 "$root/rawdata/cps"
					global  dirscfraw 	 "$root/rawdata/scf"
					global  direxcel	 "$root/rawdata/rawexcel"
					global  diroutput	 "$root/output"
					global  dirmatrix 	 "$root/output/matrices"
					global  dircollapse  "$root/output/small/collapse"
					global  dirsmall	 "$root/output/small"
    if $online==1   global  dirsmall	 "$root/output/small/online"
					global  dirusdina	 "$root/output/dinafiles"
	if $online==1   global  dirusdina	 "$root/output/dinafiles/online"
					global  dirnonfilers "$root/output/cpstaxunit"
					global  dirscfclean	 "$root/output/scfclean"
					global  dirprograms	 "$root/programs"
					global  parameters 	 "$root/programs/parameters.csv"
					global 	aggregate    "$root/DINA(Aggreg).xlsx"
					global 	distrib 	 "$root/DINA(Distrib).xlsx"
	if $data==0 	global 	diroutsheet  "$root/output/ToExcel"
	if $online==1 	global 	diroutsheet  "$root/output/ToExcelonline"
	if $online==1 & $calibweight==1 	global 	diroutsheet  "$root/output/ToExcelonlinecal"
	if $data==1 	global 	diroutsheet  "$root/output/ToExcelInternal"

// Ado file directory
	global ado_dir "$dirprograms/ado"
	sysdir set PERSONAL "$ado_dir"
}



*******************************************************************************
* LOG FILE
*******************************************************************************
/*
quietly {
	cap log close
	if $data == 0 log using "$diroutput/log/usdinalog(${S_DATE})(${S_TIME}).smcl"
    if $data == 1 log using "$diroutput/log/usdinalog(${S_DATE}).smcl", replace

	noisily display "$S_TIME  $S_DATE"

	if $data == 1	noisily di "USING INTERNAL DATA..."
	if $data == 0	noisily di "USING EXTERNAL DATA..."
	noisily di "FOR YEARS `fullyears'..."
	noisily di "NUMBER OF YEARS: `nbyears'"
}
*/
*******************************************************************************
* EXCECUTE DO FILES
*******************************************************************************

cd "$root"


/*

***************************************
*** Part 1: construction of DINA files
***************************************


// Update aggregate data in DINA.xlsx. Last run: December 11, 2015 [takes about 15 min to run, mostly due to NIPA part]
	* if $data == 0 do "programs/scrap_macro.do"

// Build SCF surveys & constructs SCF matrices used for imputations (currently up to SCF 2013, should update to SCF 2016)
	* if $data == 0 do "programs/use_scf.do"
	
// Build CPS surveys & construct CPS matrices used for imputations
    *	if $data == 0 do "programs/use_cps.do"

// Use INSOLE raw files to create PUF equivalent xYYYY.dta files (redoes only $yearmin to $endyear)   
	global yearmin=1979
	* if $data == 1 do "programs/build_xdata.do"
	
	 * added 4/2019: can now use stata program to grab CDW variables in IRS STATA server, bypassing the need to use SAS
	 if $root == "home/8rknb/usdina" & $data==1 do "programs/build_cdw.do"

// Add demographic and databank variables to xYYYY.dta files (redoes only $yearmin to $endyear)
	* if $data == 1 do "programs/build_xfile.do"
	
// Creates aggregate record $10m+ internally ($data=1) and creates the synthetic record in $dirirsint/topstat/synthrec`yr'.dta to append to xfiles externally ($data=0) for 1996-2010 (no need in 2011+ with aggregate records)
	* do "programs/aggrecord.do"
	
// Split wages by computing variable share_f [stored it in work`yr'.dta for now with id=_n sorting to match small later on]
    * set global firstyear=1979 to redo all years, global firstyear=$endyear to do latest year only (faster)
	global firstyear=$endyear	
	* if $online==0 do "programs/sharefbuild"
	* need to bring back internal files matrices/wagmat/wagspintYYYY.xls sespintYYYY.xls etc. to run externally for addsharef.do

// matrix to store results of various tests for impute.do (monitor) and nonfilerappend.do (weights)
	matrix monitor=J(40,25,.)
	matrix weights = J(60,26,.)


	
// Start data construction, looping over years
	foreach yr of numlist $years {
		global yr=`yr'

		/*
// building small files for all years up to $endyear (last year internal micro data available)
	if $yr<=$endyear { 		 
 
	// Build small files from raw NBER PUF micro-files (externaly, year beyond pufendyear are built by aging small$pufendyear using internal tabs)
		 if $yr<=$pufendyear | $data==1  do "programs/build_small.do"
		 * aging the PUF using internal INSOLE tabulations, need to bring back internal files small/agingtableYYYY.dta
		 if $yr>$pufendyear & $data==0  do "programs/aging.do"
		  
	// Build disclosure proof small files for online disclosure (these files can then be used), ADDED 5/2017
	    * global group5=0 if grouping of 5 has to be redone (very time consuming), group5=1 if we re-use older grouping auxfull$yr.dta files
	    global group5=1
		if $online==1 & $data==0 do "programs/onlinedata.do"

	// Adding share_f (share female) for earnings split in small files
		 do "programs/addsharef.do"
		
	// Impute age, gender, using internal tabulations 1979+, and gender imputation 1962-1978
		* need to bring back internal files small/collapse/xmarriedcoarseYYYY.dta and xsinglecoarseYYYY.dta to run externally
		do "programs/impute.do"
		
	// Append non-filers to small data with correct population weighting
		do "programs/nonfilerappend.do"
	}


	
	
// for years past $endyear (last year internal micro data available) we use a projection method based on small2012.dta file
// global taxsim is set to 1 if need to compute taxes using taxsim, set to 0 if taxes already computed	
// issue is that taxsim not available inside IRS
	global taxsim=0
	if $yr>$endyear & $data==0 do "programs/projection.do"

// Creates and saves DINA micro-files at the individual level
	do "programs/build_usdina"

// Testing calibrated weights from Thomas Blanchet (need to get 2016 weights)
   * if $online==1 & $yr<2016 do "programs/weight_usdina"	
	
// Collapses US DINA results
   * if $data==0 do "programs/collapse_dina"

  }

  
  
// Fix fiscal/pre-tax income ratio for top 400
   	do "programs/top400.do"
	


***************************************
*** Part 2: Statistics
***************************************
*/
*/


// Outsheet DINA results (does not use putexcel), set global calibweight=1 if using calibrated weights in online files
	 do "programs/outsheet_dina"
	 
// compare various wealth measures	
    * do "programs/compare_wealth_measures.do"		
/*
//Pre-62
	 global source = 1 // 0 when external data, 1 when internal data
     do "programs/pre62"

// Graph DINA results, $online=-1 when using internal IRS output (need to manually change here), $online=0 when using external full PUF, $online=1 when using online small PUF
	  global online= -1
	  do "programs/graph_dina"
	
// Outsheet tax rates + compo by pre-tax income group since 1913
	  do "programs/taxrates"

// Statistics in CPS
    * do "programs/stats_cps"

// Exports DINA results in a single .csv
	* if $data==0 do "programs/export_dina"

// Put all Excel outsheet into single Excel file
	* if $data==0 do "programs/export-to-excel"

*/
/*
// Distribution of wealth by AGI
 if $data==0 do "programs/wealth-by-agi"

***************************************
*** Part 3: Tax rates computations and simulations
***************************************

// Wealth tax simulations in SCF (2016)
	* do "programs/scftax.do"



cap log close
