program define reshape_keeplabels, rclass

	// August 06, 2010. Shafique Jamal (sjamal@worldbank.org) Dushanbe, Tajikistan.

	syntax varlist(min=1 max=1), eye(varname numeric) jay(varname numeric) Labels(string)
	version 9.1 
	marksample touse
	
	local list "`labels'"
	foreach var of local list{
		levelsof `var', local(`var'_levels) 			/* create local list of all values of `var' */
	 	// di "`var'"
	 	foreach val of local `var'_levels {       		/* loop over all values in local list `var'_levels */
      	 	local `var'vl`val' : label `var' `val'    	/* create macro that contains label for each value */     	
     	}
	}
	
	reshape8 wide `1', i(`eye') j(`jay')
	 
	local var_target "`1'"
	foreach var of local list{
		foreach val of local `var'_levels {       /* loop over all values in local list `var'_levels */
      		label var `var_target'`val' "``var'vl`val''" /* apply */
     	}
	}
	
end

