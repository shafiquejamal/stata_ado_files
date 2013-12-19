program define dataset_coverage_per_quintile_pmt_eligible

	syntax , Cutoffs(numlist) Q(integer) Path(string)
	
	foreach cutoff of numlist `cutoffs' {
	
		// loop over number of quintiles
		forv quantile = 1/`q' {	
			local q`q' = r(coverage_cutoff_quantile`quantile')
		}
		
		preserve
		drop *
		gen quantile = .
		gen coverage = .
		
		forv quantile = 1/`q' {	
			set obs `quantile'
			replace quantile = `q' in `quantile'
			replace coverage = `q`q'' in `quantile'
		}
		
		save "`path'/dataset_coverage_per_quintile_pmt_eligible_`cutoff'.dta", replace
		restore
	}
	
end
