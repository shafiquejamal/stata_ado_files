program define pmt_eligible, rclass
	// July 26 2010
	// July 31 2010: Modified pmt.ado so that it does not need a regression model - the eligible variable is passed as a parameter
	
	syntax varlist(min=1 max=1) [if] [pw aw iw fw], Poor(varname numeric) Quantiles(integer) [, SUBsetcutoff]
	version 9.1 
	marksample touse
	
	// subsetcutoff = use this if you want Quantilec and logcutoff calculated on the subset of the sample described by the [if]. If absent, then 
	//	the whole dataset (and not just the subsample described by the [if] condition will be used.
	
	
	tempvar eligible eligible_notpoorest20 ineligible_poorest20 errors_incl errors_excl poor_eligible nonpoor_ineligible Quantilec nonpoor_eligible poor_ineligible
				
	qui gen `eligible' = `1'
	qui gen `nonpoor_eligible' = .
	qui gen `poor_ineligible' = .
	
	qui replace `nonpoor_eligible' = 1 if `eligible' == 1 & `poor' ~= 1 & `poor' ~= . & `touse' 
	qui replace `nonpoor_eligible' = 0 if (`eligible' ~= 1 | `poor' == 1) & `touse'
	
	qui replace `poor_ineligible' = 1 if `eligible' == 0 & `poor' == 1 & `poor' ~= . & `touse' 
	qui replace `poor_ineligible' = 0 if (`eligible' == 1 | `poor' == 0) & `poor' ~= . & `touse' 
	
	qui gen `nonpoor_ineligible' =.
	replace `nonpoor_ineligible' = 1 if `poor'==0 & `eligible'==0 & `touse'
	replace `nonpoor_ineligible' = 0 if (`poor'==1 | `eligible'==1) & `touse'
	qui gen `poor_eligible'  =.
	replace `poor_eligible' = 1 if `poor'==1 & `eligible'==1 & `touse'
	replace `poor_eligible' = 0 if (`poor'==0 | `eligible'==0) & `touse'
	
	// calculate leakage, undercoverage
	qui sum `nonpoor_eligible' [`weight'`exp'] if `eligible' == 1 & `touse'
	local leakage = r(mean)
	qui sum `poor_ineligible' [`weight'`exp'] if `poor' == 1 & `touse'
	local undercoverage = r(mean)
				
	// di "leakage: `leakage'"
	// di "undercoverage: `undercoverage'"
				
	// Here is where we calculate the coverage for each decile
	// First generate quantile indicators
	
	if ("`subsetcutoff'"=="subsetcutoff") {  // In this case, the quantile classification is done based on the subsample ONLY. Generally, one would not wish to do this
		qui xtile `Quantilec' = `1' [`weight'`exp'] if `touse', n(`quantiles') 
		// xtile Quantilec2 = `1' [`weight'`exp'] if `touse', n(`quantiles')
	}
	else { // Here the classification of quantile is done based on the entire sample. This is probably what most people want.
		qui xtile `Quantilec' = `1' [`weight'`exp'], n(`quantiles') 
		// xtile Quantilec2 = `1' [`weight'`exp'], n(`quantiles')
	}
	
	forv q = 1/`quantiles' {
		
		// While the quintile is classified according to the entire sample, "coverage" is defined based on the subsample only. This is what makes most sense.
		//		For e.g., if there is only 1 observation in the first quantile in this subsample, and 10,000 in the rest, and this one is covered, then the 
		//		coverage will be 100% for quantile1 for this subsample. 
		
		qui sum `eligible' [`weight'`exp'] if `Quantilec' == `q' & `touse'
		return scalar coverage_cutoff_quantile`q' = r(mean)
		
	}
	
	// Need to store the results somewhere, somehow
	return scalar leakage = `leakage'
	return scalar undercoverage = `undercoverage'

end program

