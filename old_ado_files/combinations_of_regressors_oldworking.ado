program define combinations_of_regressors, rclass

	syntax anything(id="all regressors" name=all_regressors) [, MIN_number_of_vars(integer 1) MAX_number_of_vars(integer 20)]
	version 10.1 
	marksample touse
	
	tempname total_number_of_vars combination_loop_upper_limit vars_to_include include_var_or_not_pos regressor_combination include_var_or_not count
	
	// Figure out how many combinations of variables are possible: this is the number of loops for the outter for loop. 
	local `total_number_of_vars' : word count `all_regressors'
	local `combination_loop_upper_limit' = 2^``total_number_of_vars''-1
	
	di `"total_number_of_vars=``total_number_of_vars''"'
	di `"combination_loop_upper_limit=``combination_loop_upper_limit''"'
	
	// Loop over all possible combinations
	local `count' = 0
	forv combination_number = 0/``combination_loop_upper_limit'' {
	
		// di `"combination_number=`combination_number'"'
		dec2bin_3, b(2) d(`combination_number') n(``total_number_of_vars'')	
		// di `"r(number_of_ones)=`r(number_of_ones)'"'
		
		local `regressor_combination'
		// Include regressor combination only if the combination has the specified minimum number of regressors 
		if (`r(number_of_ones)' >= `min_number_of_vars' &  `r(number_of_ones)' <= `max_number_of_vars') {
			
			local `count' = ``count'' + 1
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
			return local regressor_combination_`combination_number' `"``regressor_combination''"'
			return local regressor_combination_seq_``count'' `"``regressor_combination''"'
			return scalar number_of_returned_combinations = ``count''
		}
	}
end
