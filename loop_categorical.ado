program define loop_categorical, rclass	
	syntax varname, Generate(string) [Separator(string)]
	version 9.1

	// step 1 : generate indicators for each of the categories
	// step 2 : generate one variable  di*oblast_i for each i
	// step 3 : generate one the eligibility variable for this. It will equal 1 if any of the di*oblast_i variables =1 and 0 otherwise
	// 
	// Repat 2 and 3 to generate and eligibilty variable (e.g. elig0001, elig0010, elig0011, etc) for each combination of 1's and 0's (excluding the
	//			combination of all zeros).
	
	if ("`separator'" == "") { 
		local separator  ","
	}
	
	// step 1 : generate indicators for each of the categories
	tempvar cat_indicators
	cap drop `cat_indicators'_*
	tab `1', g(`cat_indicators'_)
	
	return list
	local r_r = r(r)
	local x_max = (2^`r_r')-1
	
	forv x = 1/`x_max' { // loop over all possible combinations of the indicators for the categorical variable (except for all 0s)
	
		// di "-------------------------------------"
		// di "x=`x'"
		
		// to go through all possible combinations of the binary indicators categorical variable, need to get the binary equivalent of each
		//	number for the iteration. Then generate new variables that are the digits * the respective indicator variables
		//  e.g. generate the variables: v1=d1*oblast_1, v2=d2*oblast_2, v3=d3*oblast_3, etc. later will make a variable (using eqany) that
		//	     equals 1 if any of v1, v2, v3, etc. equals 1
		
		// get the digits of the binary equivalent of x (e.g. 1 is 0001, 4 is 0010, 31 is 1111, etc)
		dec2bin_2 , b(2) d(`x') n(`x_max')
		// return list
		
		// step 2 : generate one variable  di*oblast_i for each i
		tempvar varlistforcat
		forv x2 = 1/`r_r' {
			gen `varlistforcat'_`x2' = r(d`x2')*(`cat_indicators'_`x2')
		}
		
		// Now `generate' this is the variable that is the eligibility dummy. It is one when any of the di*oblast_* are one and zero otherwise
		dec2bin_2 , b(2) d(`x') n(`x_max')
		local digitsrtol = r(contcatenated_startright)
		qui egen `generate'`digitsrtol' = eqany(`varlistforcat'_*), v(1)
		
		// should label the variable, so we know which categories (e.g. which oblasts) for which it equals 1
		qui levelsof `1', local(`categorical'_levels)
		local count = 0
		local categoriestogoinlabel = ""
		local firstcat = 1
		foreach val of local `categorical'_levels {       		/* loop over all values in local list `categorical'_levels */
      	 	local count = `count' + 1
      	 	dec2bin_2 , b(2) d(`x') n(`x_max')
      	 	if (r(d`count')==1) {
      	 		local temp1 : label `1' `val'    			/* add the category label if its corresponding digit is 1  */   
      	 		// di "val:`val', temp1:`temp1'"
      	 		if (`firstcat'==1) {
      	 			local categoriestogoinlabel = "`temp1'"
      	 			local firstcat = 0
      	 		} 
      	 		else {
      	 			local categoriestogoinlabel = "`categoriestogoinlabel'`separator'`temp1'"
      	 		}
      	 	}
     	}
		label var `generate'`digitsrtol' "`categoriestogoinlabel'"
	}
end

