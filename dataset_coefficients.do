program define dataset_coefficients
	
	syntax , Filename(string) [Separator(string)]
	version 9.1
	if ("`separator'" == "") { 
		local separator  ","
	}
	// Get the names of the variables to write out. Need to change " o." to " " for making name for the macro to hold the variable labels
	local varnames : coln e(b)
	local coefs ""
	foreach varn of local varnames {
		local coef = _coef[`varn']
		local coefs "`coefs' `coef'"
		local varn1 = regexr("`varn'","o._I","_I")
		if ("`varn'" != "_cons") {
			local varlab_`varn1' : variable label `varn1'
		}
		else {
			local varlab_constant "constant"
		}
	}
	preserve
	drop *
	// Generate the new variable names, and apply the labels
	local variablenamestoplot ""
	foreach varn of local varnames {
		local varn1 = regexr("`varn'","o._I","_I")
		if ("`varn'" != "_cons") {
			gen `varn1' = .
			label var `varn1' `"`varlab_`varn1''"'
			local variablenamestoplot "`variablenamestoplot' `varn1'"
		}
		else {
			gen constant = .
			label var constant "constant"
			local variablenamestoplot "`variablenamestoplot' `constant'"
		}
	}
	// Apply the values to the variables as observations
	set obs 1
	local count = 0
	foreach varn of local varnames {
		local count = `count' + 1
		local coef1 : word `count' of `coefs'
		local varn1 = regexr("`varn'","o._I","_I")
		if ("`varn'" != "_cons") {
			// constant?  
			replace `varn1' = `coef1' in 1
		}
		else {
			replace constant = `coef1' in 1
		}
	}
	cap drop __*
	// global variablenamestoplot "`variablenamestoplot'"
	// char [variablenamestoplot] "`variablenamestoplot'"
	notes : `variablenamestoplot'
	save "`filename'" , replace
	restore
end program
