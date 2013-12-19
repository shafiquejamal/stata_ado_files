program define makeonezero

	syntax varlist [if/]
	version 9.1 
	marksample touse
	
	foreach var of varlist `varlist' {
		// di "----------------------"
		// di "var: `var'"
		// tab `var', mi
		qui replace `var' = 1 if `var' ~= .
		qui replace `var' = 0 if `var' == . & `if'
		// tab `var', mi
		// count if `if' & `var' == .
	}

end program
