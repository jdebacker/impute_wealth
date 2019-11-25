*! Programs that puts shares and averages of var1 and components (var2, 3...) by g-percentile in a matrix
* revised to have only deciles (instead of percentiles)
cap program drop gpercsmall
	program gpercsmall
		version 12.1 
		syntax varlist [if] [in] [fw aw pw iw], [matname(name)] 

		quietly { 
			marksample touse 
			markout `touse', strok 
			count if `touse' 
			if r(N) == 0 error 2000 
		
			tokenize `varlist'
            local first `1'
            macro shift
            local rest `*'
			local nbcompo : list sizeof local(rest)

			if "`weight'"!="" {
			local wgt "[`weight'`exp']"
			}
			else local wgt ""

			tempvar rank 
			cumul `first' `wgt' if `touse', gen(`rank')
			tempvar gperc 
			
			gen `gperc'=0
			replace `gperc'= 10*trunc(10*`rank') if `rank'<0.9
			replace `gperc'=90 if `rank'>=0.9 & `rank'<0.95
			replace `gperc'=95 if `rank'>=0.95 & `rank'<0.99
			replace `gperc'=99 if `rank'>=0.99 & `rank'<0.999
			replace `gperc'=99.9 if `rank'>=0.999 & `rank'<0.9999
			replace `gperc'=99.99 if `rank'>=0.9999 & top400!=1
			sum `rank' if top400==1
			replace `gperc'=100*r(min)-1e-9 if top400==1
			
			
			
			
			/*
			* added top percentiles for wealth tax simulation
			replace `gperc'=min(trunc(100000*`rank'),99999)/1000 if `rank'>=0.9999 & `rank'<0.99999
			replace `gperc'=min(trunc(1000000*`rank'),999999)/10000 if `rank'>=0.99999 & `rank'<0.999999
			replace `gperc'=min(trunc(10000000*`rank'),9999999)/100000 if `rank'>=0.999999
			* end of added percentiles */
			
			tab `gperc'
			
			/*
			gen gperc=`gperc'
			table gperc [w=dweght], c(mean peinc min peinc max peinc)
			glue2
			*/
						
			local I = r(r)
			levelsof `gperc', local(levels)
			mat input perc = (`levels' 101)

			su `first' `wgt' if `touse'
				local total = r(sum)

			replace `rank'=`rank'*100	
			if "`matname'" == "" local matname "gperc" 
			matrix `matname' = J(`I', 5+`nbcompo', 0)
				forval i = 1/`I' {
					mat `matname'[`i',1]=perc[1,`i']
					su `first' `wgt' if `rank'>=perc[1,`i'] & `rank'<perc[1,`i'+1] & `touse', meanonly
						local nb:	 display %9.0f `r(sum_w)'/10e4
						*local thres: display %9.0f `r(min)'
						if abs(r(min)) < 1e3						local thres = round(r(min),1e1)
						if abs(r(min)) >= 1e3 & abs(r(min)) < 1e4  	local thres = round(r(min),5e1)
						if abs(r(min)) >= 1e4 & abs(r(min)) < 1e5 	local thres = round(r(min),1e2)
						if abs(r(min)) >= 1e5 & abs(r(min)) < 1e6	local thres = round(r(min),1e3)
						if abs(r(min)) >= 1e6 & abs(r(min)) < 1e7	local thres = round(r(min),1e4)	
						if abs(r(min)) >= 1e7 & abs(r(min)) < 1e8	local thres = round(r(min),1e5)		
						if abs(r(min)) >= 1e8  						local thres = round(r(min),1e6)		
						local sh:    display %9.5f `r(sum)'/`total'
						local avg:   display %9.0f `r(mean)'	
						mat `matname'[`i',2]= `nb'
						mat `matname'[`i',3]= `thres'
						mat `matname'[`i',4]= `sh'
						mat `matname'[`i',5]= `avg'	
							
					local j = 6
					foreach c in `rest' {
						su `c' `wgt' if `rank'>=perc[1,`i'] & `rank'<perc[1,`i'+1] & `touse', meanonly
						local avg`c': display %9.0f `r(mean)'
						mat `matname'[`i',`j']= `avg`c''
						local j=`j'+1
					}	
				}
			mat `matname'[`I',1]= 400'	
			matrix colnames `matname' = gperc nb thres sh avg `rest'
			* matrix rownames `matname' = `levels' 
		}
	end


	
	 
