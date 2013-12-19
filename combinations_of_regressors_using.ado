program define combinations_of_regressors_using, rclass

	syntax anything(id="all regressors" name=all_regressors) [using/] [, MIN_number_of_vars(integer 1) MAX_number_of_vars(integer 20) Prohibited_combinations(string)]
	version 10.1 
	marksample touse
	
	tempname total_number_of_vars combination_loop_upper_limit vars_to_include include_var_or_not_pos regressor_combination include_var_or_not count actual_combs max_number_of_vars2 skip number_prohibited_present
	
	if (`"`using'"' ~= "") {
		tempname fh
		file open `fh' using `"`using'"', w replace all
	}
	// Figure out how many combinations of variables are possible: this is the number of loops for the outter for loop. 
	local `total_number_of_vars' : word count `all_regressors'
	local `combination_loop_upper_limit' = 2^``total_number_of_vars''-1
	
	di `"total_number_of_vars=``total_number_of_vars''"'
	// di `"combination_loop_upper_limit=``combination_loop_upper_limit''"'
	di `"min number of vars=`min_number_of_vars'"'
	di `"max number of vars=`max_number_of_vars'"'
		
	local `actual_combs' = 0
	if (`max_number_of_vars' > ``total_number_of_vars'') {
		local `max_number_of_vars2' = ``total_number_of_vars''
	}
	else {
		local `max_number_of_vars2' = `max_number_of_vars'
	}
	
	forv r = `min_number_of_vars'/``max_number_of_vars2'' {
		// di `"r=`r'"'
		local `actual_combs' = ``actual_combs'' + (exp(lnfactorial(``total_number_of_vars''))/(exp(lnfactorial(``total_number_of_vars''-`r'))*exp(lnfactorial(`r'))))
	}
	di `"number of combinations to be calculated is=``actual_combs''"'
	
	// Loop over all possible combinations
	local `count' = 0
	local `number_prohibited_present' = 0
	forv combination_number = 0/``combination_loop_upper_limit'' {
		// stop
		local `skip' = 0
		// di `"combination_number=`combination_number'"'
		dec2bin_3, b(2) d(`combination_number') n(``total_number_of_vars'')	
		// di `"r(number_of_ones)=`r(number_of_ones)'"'
		
		local `regressor_combination'
		// Include regressor combination only if the combination has the specified minimum number of regressors 
		if (`r(number_of_ones)' >= `min_number_of_vars' &  `r(number_of_ones)' <= `max_number_of_vars') {
			
			local `vars_to_include' = r(contcatenated_startright)
			// di `"vars_to_include=``vars_to_include''"'

			local `include_var_or_not_pos' = 1
			local `regressor_combination'
			foreach regressor of local all_regressors {
				local `include_var_or_not' = substr(`"``vars_to_include''"',``include_var_or_not_pos'',1)
				if (``include_var_or_not''==1) {
					local `regressor_combination' ``regressor_combination'' `regressor'
				}
				local `include_var_or_not_pos' = ``include_var_or_not_pos'' + 1
			}
			/*
			di `"---------------------"'
			di `"combination_number=`combination_number'"'
			di `"count=``count''"'
			di `"regressor_combination=``regressor_combination''"'
			*/
			// di `"regressor_combination : ``regressor_combination''"'
			// skip if this combination is a prohibited combination
			local `skip' = 0
			if (`"`prohibited_combinations'"'~="") {
				foreach prohibited_combination of local prohibited_combinations {
				local `number_prohibited_present' = 0
					// di `"--------------- prohibited_combination :`prohibited_combination' ($`prohibited_combination')----------------"'
					// di `"regressor_combination : ``regressor_combination''"'
					
					foreach var of global `prohibited_combination' {
						// di `"var: `var'"'
						if (`: list var in local `regressor_combination'') {
							// di `"`var' is present in ``regressor_combination''"'
							local `number_prohibited_present' = ``number_prohibited_present'' + 1
						}
						if (``number_prohibited_present'' > 1) {
							// di `"prohibited combination found ------1--------"'
							local `skip' = 1
							continue, break
						}
						
					}
					if (``number_prohibited_present'' > 1) {
						// di `"prohibited combination found ------2--------"'
						local `skip' = 1
						continue, break
					}
					// di `"------------------------------------------------------ This line should not get printed if skip happened"'				
				}
			}
			if (``skip''==0) {
				local `count' = ``count'' + 1
				if (`"`using'"' ~= "") {
					file write `fh' `"``regressor_combination''"' _n
				}
				else {
					return local regressor_combination_``count'' = `"``regressor_combination''"'
				}
				// di `"accepted:   ``regressor_combination''  "'
			}
		}
	
	}
	return scalar number_of_returned_combinations = ``count''
	if (`"`using'"' ~= "") {
		file close `fh'
	}
	
end
