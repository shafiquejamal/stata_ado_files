program define dataset_coverage

	// This program generates a dataset of the coverage rates, so that they can be plotted. 
	syntax , Cutoffs(numlist) Q(integer) Path(string) [CAT(string)]
	version 9.1
	
	foreach cutoff of numlist `cutoffs' {
	
		// loop over number of quintiles
		forv quantile = 1/`q' {	
			local q`quantile' = r(coverage_cutoff_quantile`quantile')
		}
		
		preserve
		drop *
		qui gen quantile = .
		qui gen coverage = .
		qui gen category = ""
		label var quantile "Quantile"

		label var coverage "Coverage"
		
		forv quantile = 1/`q' {	
			qui set obs `quantile'
			qui replace quantile = `quantile' in `quantile'
			qui replace coverage = `q`quantile'' in `quantile'
			qui replace category = `"`cat'"' in `quantile'
		}
		
		sort quantile
		save "`path'", replace
		restore
	}
	
end
