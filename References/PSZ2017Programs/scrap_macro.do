* Do-file that scrapes NIPA and FRB data and puts them into raw data sheets of DINA.xlsx with all variables in column and years in row. 
* Parts 1, 2 (NIPA): code from Gabe Chodorow Reich's Data programs: http://scholar.harvard.edu/chodorow-reich/data-programs
* Parts 3,4 (Z1, Fixed assets): GZ code updated Sept-Oct 2016

clear matrix
cd $direxcel


/*************************************************************************************************************
1. Download historical NIPA data, 1929-1969
Code from Gabe Chodorow Reich's website (https://dl.dropboxusercontent.com/s/581812b4qsswvnm/NIPA_1929-1969.do) downloaded Oct. 2015
*************************************************************************************************************/
/*
#delimit;
clear;
tempfile data;
qui gen line=.;
qui save `data', replace;

forvalues s = 1/7 {;
	qui insheet using "http://bea.gov/national/nipaweb/ss_data/section`s'all_hist.csv", comma nonames clear double;
	qui describe, short;
	local no_vars = r(k); *Number of variables in dataset;

	**Table descriptive variables;
	qui gen table = v1 if substr(v1,1,5)=="Table"; *Table number variable;
	qui gen units = v1 if substr(v1[_n-1],1,5)=="Table"; *Units variable;
	qui replace units = "n.a." if substr(v1[_n-1],1,5)=="Table" & units==""; *E.g. contributions to percent change in GDP;
	qui egen periodicity = ends(v1) if substr(v1[_n-2],1,5)=="Table", punct(" ") head; *Periodicity variable;
	qui egen vintage = ends(v1) if substr(v1[_n-4],1,5)=="Table", punct("published") last trim; *Data vintage;
	foreach var of varlist table units periodicity vintage {;
		qui replace `var' = `var'[_n-1] if `var'=="";
	 };

	**Line descriptive variables;
	qui replace v1 = "0" if v1=="Line"; *This is the line with the year;
	qui replace v1 = "0.5" if v1=="" & v1[_n-1]=="0"; *This is the variable with the quarter/month if applicable;
	qui destring v1, force replace;
	rename v1 line;
	qui keep if v4!="";
	rename v2 description;
	rename v3 code;
	qui compress;

	**Reshape into panel, table-by-table;
 	qui egen tableid = group(table periodicity v4) if line==0; *Numeric identifier for each NIPA table or table component in the section. The monthly tables "wrap." v4 picks up the first year;
	qui replace tableid = tableid[_n-1] if missing(tableid);
	qui sum tableid;
	local no_tables = r(max);
	forvalues i = 1/`no_tables' {;
		preserve;
		qui keep if tableid==`i';
		disp(table[1]);
		forvalues t = 4/`no_vars' {; *Rename variables to valueyyyy[_Q/M];
			qui tostring v`t', force replace; *Some empty columns are read in as numeric;
			if v`t'[1]=="" | v`t'[1]=="." {; *Variable has less than the maximum number of observations in the section;
				qui drop v`t';
				continue;
			};
			local yyyy = v`t'[1];
			rename v`t' value`yyyy';
			if line[2]==0.5 {; *Table is quarterly or monthly;
				local qm = value`yyyy'[2];
				rename value`yyyy' value`yyyy'_`qm';
			};
		};
		qui drop in 1;
		qui reshape long value, i(table units periodicity vintage description code line) j(datestring) string;
		qui append using `data';
		qui save `data', replace;
		restore;
	};
};

qui use `data', replace;	
qui destring value, force replace ignore(",");
qui drop if line==0.5;

qui split table, limit(2);
qui egen table_number = concat(table1 table2), punct(" ");
qui gen table_name = subinstr(table,table_number,"",.);
qui drop table table1 table2;

qui gen date = date(datestring,"Y") if periodicity=="Annual";
qui replace date = dofq(quarterly(datestring,"YQ")) if periodicity=="Quarterly";
qui replace date = dofm(monthly(datestring,"YM")) if periodicity=="Monthly";
qui format date %td;

foreach var of varlist table_name periodicity units desc {;
	qui replace `var' = subinstr(`var',"  ","",.);
};
qui compress;

qui sort table_number periodicity line date;	
	
order table_number table_name units vintage code description line date value;

qui save "$direxcel/NIPA 1929-1969", replace;



/*************************************************************************************************************
2. Download NIPA data post 1969 and merge with pre-1969 series
Unmodified code from Gabe Chodorow Reich's website (https://dl.dropboxusercontent.com/s/hopdkudl40n9ezm/NIPA_1969-.do) downloaded Oct. 2015
*************************************************************************************************************/

#delimit;
clear;
tempfile data;
qui gen line=.;
qui save `data', replace;



forvalues s = 1/7 {;
qui insheet using "https://www.bea.gov//national/nipaweb/SS_Data/Section`s'All_csv.csv", comma nonames clear double;
	*qui insheet using "http://bea.gov/national/nipaweb/ss_data/section`s'all_csv.csv", comma nonames clear double;
	qui describe, short;
	local no_vars = r(k); *Number of variables in dataset;


	**Table descriptive variables;
	qui gen table = v1 if substr(v1,1,5)=="Table"; *Table number variable;
	qui gen units = v1 if substr(v1[_n-1],1,5)=="Table"; *Units variable;
	qui replace units = "n.a." if substr(v1[_n-1],1,5)=="Table" & units==""; *E.g. contributions to percent change in GDP;
	qui egen periodicity = ends(v1) if substr(v1[_n-2],1,5)=="Table", punct(" ") head; *Periodicity variable;
	qui egen vintage = ends(v1) if substr(v1[_n-4],1,5)=="Table", punct("published") last trim; *Data vintage;
	foreach var of varlist table units periodicity vintage {;
		qui replace `var' = `var'[_n-1] if `var'=="";
	 };

	**Line descriptive variables;
	qui replace v1 = "0" if v1=="Line"; *This is the line with the year;
	qui replace v1 = "0.5" if v1=="" & v1[_n-1]=="0"; *This is the variable with the quarter/month if applicable;
	qui destring v1, force replace;
	rename v1 line;
	qui keep if v4!="";
	rename v2 description;
	rename v3 code;
	qui compress;

	**Reshape into panel, table-by-table;
 	qui egen tableid = group(table periodicity v4) if line==0; *Numeric identifier for each NIPA table or table component in the section. The monthly tables "wrap." v4 picks up the first year;
	qui replace tableid = tableid[_n-1] if missing(tableid);
	qui sum tableid;
	local no_tables = r(max);
	forvalues i = 1/`no_tables' {;
		preserve;
		qui keep if tableid==`i';
		disp(table[1]);
		forvalues t = 4/`no_vars' {; *Rename variables to valueyyyy[_Q/M];
			qui tostring v`t', force replace; *Some empty columns are read in as numeric;
			if v`t'[1]=="" | v`t'[1]=="." {; *Variable has less than the maximum number of observations in the section;
				qui drop v`t';
				continue;
			};
			local yyyy = v`t'[1];
			rename v`t' value`yyyy';
			if line[2]==0.5 {; *Table is quarterly or monthly;
				local qm = value`yyyy'[2];
				rename value`yyyy' value`yyyy'_`qm';
			};
		};
		qui drop in 1;
		qui reshape long value, i(table units periodicity vintage description code line) j(datestring) string;
		qui append using `data';
		qui save `data', replace;
		restore;
	};
};

qui use `data', replace;	
qui destring value, force replace ignore(",");
qui drop if line==0.5;

qui split table, limit(2);
qui egen table_number = concat(table1 table2), punct(" ");
qui gen table_name = subinstr(table,table_number,"",.);
qui drop table table1 table2;

qui gen date = date(datestring,"Y") if periodicity=="Annual";
qui replace date = dofq(quarterly(datestring,"YQ")) if periodicity=="Quarterly";
qui replace date = dofm(monthly(datestring,"YM")) if periodicity=="Monthly";
qui format date %td;

foreach var of varlist table_name periodicity units desc {;
	qui replace `var' = subinstr(`var',"  ","",.);
};
qui compress;

qui sort table_number periodicity line date;	
	
order table_number table_name units vintage code description line date value;

qui append using "$direxcel/NIPA 1929-1969";

qui sort table_number periodicity line date;	
duplicates drop table_number code-datestring, force;
qui drop tableid;
#delimit cr

* Send NIPA series to DINA Excel file
	keep if periodicity=="Annual"
	destring datestring, replace
	rename datestring year
	#delimit;
	keep if 
	units=="[Billions of dollars]" |
	table_number=="Table 1.1.4." | table_number=="Table 1.7.4." | /* deflators */
	table_number=="Table 7.1." /* Population */
	;
	#delimit cr
	duplicates drop code year, force
	keep year code value
	reshape wide value, i(year) j(code) s
	rename value* *
	mkmat _all, mat(bulk)
	putexcel A1=matrix(bulk, colnames)  using "$root/DINA(Aggreg).xlsx", sh(nipa_raw) modify keepcellf
	qui erase "$direxcel/NIPA 1929-1969.dta"




/*************************************************************************************************************
Download all annual NIPA data (new flat file, 2018)
*************************************************************************************************************/
*/	

clear
qui insheet using "https://apps.bea.gov/national/Release/TXT/NipaDataA.txt"
	replace value=subinstr(value,",","",.)
	destring value, replace
save "$direxcel/annual_nipa_full.dta", replace

use "$direxcel/annual_nipa_full.dta", clear
	#delimit;
	keep if 
		substr(seriescode,-2,2)=="RG" | 
		substr(seriescode,-1,1)=="C" | 
		substr(seriescode,1,3)=="L30" | 
		substr(seriescode,1,5)=="LA000" | 
		substr(seriescode,1,3)=="S12" | 
		substr(seriescode,1,3)=="TRP" | 
		seriescode =="CON520" |
		seriescode =="DPCERC" |
		seriescode =="G17009" |
		seriescode =="DPCERG";

	drop if substr(seriescode,1,1)=="N" | substr(seriescode,1,1)=="J" | substr(seriescode,1,1)=="Q" | substr(seriescode,1,1)=="H";
	drop if substr(seriescode,1,1)=="D" & seriescode !="DPCERG" & seriescode !="DPCERC";
	drop if substr(seriescode,-1,1)=="C" & substr(seriescode,1,1) == "C";
	drop if substr(seriescode,1,2)=="B5" | substr(seriescode,1,2)=="B6" | substr(seriescode,1,2)=="B8";
	drop if substr(seriescode,1,2)=="W6";
	#delimit cr


	replace value = value / 1000 if substr(seriescode,-2,2)!="RG" 
	replace seriescode = seriescode + "1" // add 1 suffix (meaning annual data, as used in Excel)
	reshape wide value, i(period) j(seriescode) string 
	rename period year
	rename value* *
	order year 
	save "$direxcel/nipa.dta", replace
	mkmat _all, mat(bulk)
	putexcel set "$root/DINA(Aggreg).xlsx",  sh(nipa_raw) modify 
putexcel A1=matrix(bulk), colnames

/*************************************************************************************************************
3. Download Flow of Funds csv files and send to DINA Excel file
*************************************************************************************************************/
/*

* Series structure: https://www.federalreserve.gov/apps/fof/SeriesStructure.aspx

	clear all

* Downloded latest Z1
	cap mkdir "$direxcel/fof"	
	cd "$direxcel/fof"	
	copy "https://www.federalreserve.gov/releases/z1/20180920/z1_csv_files.zip" "fof.zip", replace
		qui unzipfile "fof.zip", replace
		qui erase fof.zip

* Import and merge all csv files
	local csvfiles : dir "$direxcel/fof/csv" files "*.csv"
	local ii = 1
	foreach file of local csvfiles {
		qui import delimited using  "$direxcel/fof/csv/`file'", varnames(1) clear case(preserve)
		di "Importing file `file'"
		cap qui drop v*
		local type : type date			
		if `ii' == 1 {
			if "`type'" == "int" {
				keep date
				qui rename date year
				expand 4
				qui bys year: gen quarter=_n 
			}
			if "`type'" == "str7"  {
				keep date
				qui gen year = substr(date, 1, 4)
				qui gen quarter = substr(date, -1, 1)
				destring year, replace
				destring quarter, replace
			}
			qui saveold   "$direxcel/fof/fofseries.dta", replace
		}

		if `ii' > 1 {
			if "`type'" == "int" {
				qui gen year = date
				qui gen quarter = 4
			}
			if "`type'" == "str7" {
				qui gen year = substr(date, 1, 4)
				qui gen quarter = substr(date, -1, 1)
				foreach var of varlist _all {
					qui destring `var', force replace
				}
			}
			qui cap drop date
			qui merge 1:1 year quarter using "$direxcel/fof/fofseries.dta", nogenerate noreport force
			qui saveold "$direxcel/fof/fofseries.dta", replace
		}
		local ii = `ii' + 1	
	}
	qui sort year quarter
	qui order year quarter
	compress
	saveold "$direxcel/fof/fofseries.dta", replace

* Keep subset of variables, year-end values, and export
	use "$direxcel/fof/fofseries.dta", clear
	keep year quarter FA* FL* LA* LM* FU*A
	keep if quarter == 4
	
	foreach var of varlist _all {
		destring `var', force replace
	}
	mkmat _all, mat(ima_raw)
	putexcel set "$root/DINA(Aggreg).xlsx", sh(ima_raw) modify 
	putexcel A1=matrix(ima_raw), colnames 


/*************************************************************************************************************
4. Download BEA Fixed Assets 
*************************************************************************************************************/

* Downloded latest Fixed Assets
	cap mkdir "$direxcel/FixedAssets"	
	cd "$direxcel/FixedAssets"	
	copy "http://www.bea.gov//national/FA2004/ss_data/sectionall_csv.zip" "fixedassets.zip", replace
		qui unzipfile "fixedassets.zip", replace
		qui erase fixedassets.zip

// They're not in a convenient format so manually import for now.
