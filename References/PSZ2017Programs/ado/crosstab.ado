*! Program that puts averages of var2 by var1 x by in a matrix (neither table not tab summarize saves results in matrix) 
	cap program drop crosstab
	program crosstab 
		version 12.1 
		syntax varlist(max=2) [if] [in] [fw aw pw iw], by(varname) [matname(name)] 

		quietly { 
			marksample touse 
			markout `touse' `by', strok 
			count if `touse' 
			if r(N) == 0 error 2000 
		
			tab `by'
			local J = r(r) 

			if "`weight'"!="" {
			local wgt "[`weight'`exp']"
			}
			else local wgt ""
			
			tokenize `varlist'
            local income `1'
            local var `2'
			local I = 10
			tempvar decile
			xtile `decile' = `income' `wgt', nq(`I')

			if "`matname'" == "" local matname "crosstab" 
			matrix `matname' = J(`I', `J', 1) 
		
			forval i = 1/`I' { 
				forval j = 1/`J' { 
					su `var' `wgt' if `decile' == `i' & `by' == `j' & `touse', meanonly 
					matrix `matname'[`i', `j'] = r(mean) 
				}
			} 
		
			levelsof `decile' if `touse' 
			matrix rownames `matname' = `r(levels)' 
			levelsof `by' if `touse', local(levels)
			local lbe : value label `by'
			local colnames 
			foreach l of local levels {
			local f`l' : label `lbe' `l'
			local f2`l'  =strtoname("`f`l''")
			local colnames `colnames' `f2`l''
			}
			matrix colnames `matname' = `colnames'
		} 
	end

	