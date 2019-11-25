*! Program that puts top shares & compo in a vector, units ranked by var1
	cap program drop shcomp
	program shcomp
		version 12.1 
		syntax varlist [if] [in] [fw aw pw iw], [matname(name)] 

		quietly { 
			marksample touse 
			markout `touse', strok 
			count if `touse' 
			if r(N) == 0 error 2000 
		
			matrix input cumul = (0, .5, .9, .95, .99, .995, .999, .9999)
			local nbgroup = colsof(cumul)

			tokenize `varlist'
            local first `1'
            macro shift
            local rest `*'
			local nbcompo : list sizeof local(rest)

			if "`weight'"!="" {
			local wgt "[`weight'`exp']"
			}
			else local wgt ""

			su `first' `wgt' if `touse'
				local total = r(sum)
			tempvar rankprog
			cumul `first' `wgt' if `touse', gen(`rankprog')  

			if "`matname'" == "" local matname "shcomp" 
			matrix `matname' = J(1, (1+`nbcompo')*`nbgroup', 0)
				local jj=1
				forval j = 1/`nbgroup' {
					su `first' `wgt' if `rankprog'>=cumul[1,`j'] & `touse', meanonly
					mat `matname'[1,`jj']=r(sum)/`total'
					local kk=`jj'+1
					foreach c in `rest' {
						su `c' `wgt' if `rankprog'>=cumul[1,`j'] & `touse', meanonly
						mat `matname'[1,`kk']=r(sum)/`total'
						local kk=`kk'+1
					}	
					local jj=`jj'+`nbcompo'+1
				}
			
			local names
				local I=`nbgroup'-1 
				foreach i of numlist 0/`I' {
					local x`i'
					foreach w of local varlist {
					             local x`i' `x`i'' `w'`i'

					}
				local names `names' `x`i''
				}
			matrix colnames `matname' = `names'

		} 
	end

	

	