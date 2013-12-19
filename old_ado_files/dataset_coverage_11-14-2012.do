program define dataset_coverage

	// This program generates a dataset of the coverage rates, so that they can be plotted. 
	syntax , Cutoffs(numlist) Q(integer) Path(string) [Category(string)]
	
	foreach cutoff of numlist `cutoffs' {
	
		// loop over number of quintiles
		forv quantile = 1/`q' {	
			local q`quantile' = r(coverage_cutoff_quantile`quantile')
		}
		
		preserve
		drop *
		gen quantile = .
		gen coverage = .
		
		/*
		if ("`variablename'"=="") {
			local variablename = "coverage"
			local variablelabel = "Coverage"
		} 
		else {
			local variablelabel = "Coverage (`variablename')"
		}
		gen `variablename' = .
		*/
		
		label var quantile "Quantile"
		// label var `variablename' "`variablelabel'"
		if ("`category'"~="") {
			label var coverage "Coverage: `category'"
			gen category = "`category'"
		}
		else {
			label var coverage "Coverage"
		}
		
		forv quantile = 1/`q' {	
			set obs `quantile'
			replace quantile = `quantile' in `quantile'
			// replace coverage = `q`quantile'' in `quantile'
			replace `variablename' = `q`quantile'' in `quantile'
		}
		
		sort quantile
		save "`path'", replace
		restore
	}
	
end
