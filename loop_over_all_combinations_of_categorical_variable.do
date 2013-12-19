program define loop_categorical, rclass	
	
	tab `categorical', g(`cat_indicators'_)
	
	// ************************REMOVE*******************************
	// cap drop cat_indicators_*
	// tab `categorical', g(cat_indicators_)  
	
	return list
	local r_r = r(r)
	local x_max = (2^`r_r')-1
	gen `elcat' =.
	
	forv x = 1/`x_max' { // loop over all possible combinations of the indicators for the categorical variable (except for all 0s)
		// di "-------------------------------------"
		// di "x=`x'"
		
		// to go through all possible combinations of the binary indicators categorical variable, need to get the binary equivalent of each
		//	number for the iteration. Then generate new variables that are the digits * the respective indicator variables
		// get the digits of the binary equivalent
		dec2bin_2 , b(2) d(`x') n(`x_max')
		// return list
		
		forv x2 = 1/`r_r' {
			cap drop `varlistforcat'_`x2'
			gen `varlistforcat'_`x2' = r(d`x2')*(`cat_indicators'_`x2')
			
			// ************************REMOVE*******************************
			// cap drop varlistforcat_`x2'
			// gen varlistforcat_`x2' = r(d`x2')*(cat_indicators_`x2')
		}
		
		/*
		if (`catspecified'==1) {
			di ""
			di "Categories being included:"
			di ""
			qui levelsof `categorical', local(levels)
			dec2bin_2 , b(2) d(`x') n(`x_max')
			local y = 1
			foreach l of local levels {
				if r(d`y') == 1 {
					di "Including: `categorical' = `l' (`:label `categorical' `l'')"
				}
				local y = `y'+1
			}
			di ""
			di "Categories being excluded:"
			di ""
			local y = 1
			foreach l of local levels {
				if r(d`y') == 0 {
					di "Excluding: `categorical' = `l' (`:label `categorical' `l'')"
				}
				local y = `y'+1
			}
			
		}
		*/

		// d `varlistforcat'*
		
		// This variable sets eligibility based on a combination of indicators for categorical variables being true (if i1 == | i3 == ...).
		// 	this is another way of doing this, but shorter and allows for unknown number of indicators
		cap drop `elcat'
		egen `elcat' = eqany(`varlistforcat'*), v(1)
		
		// ************************REMOVE*******************************
		/*
		cap drop elcat
		egen elcat = eqany(`varlistforcat'*), v(1)
		
		if (`x'==1) {
			gen c1 = cat_indicators_`x'
			gen c2 = varlistforcat_`x'
			gen c3 = c1-c2
			sum c3
			
			// stop
		}
		*/
	}
end