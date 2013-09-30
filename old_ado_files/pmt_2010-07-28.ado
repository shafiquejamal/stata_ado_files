program pmt, rclass
	// July 26 2010
	syntax varlist(min=2 ts) [if] [pw aw iw fw], Cutoffs(numlist asc min=1 max=20 >0 <=50 integer) Poor(varname numeric) Quantiles(integer) [Graphme(integer -1) logpline(real 0), SUBsetcutoff]
	version 9.1 
	marksample touse
	
	// subsetcutoff = use this if you want Quantilec and logcutoff calculated on the subset of the sample described by the [if]. If absent, then 
	//	the whole dataset (and not just the subsample described by the [if] condition will be used.
	
	tempvar logpccd_predicted logpccd_predicted_threshold
	
	qui reg `varlist' [`weight'`exp'] `if', r 
	local R2 = e(r2) 
	local N = e(N)
	return scalar r2 = `R2'
	return scalar N = `N'
	
	qui spearman `varlist' `if'
	return scalar rho = r(rho) 
	
	// we are predicting here on the subsample (indicated by e(sample) ). This predicted consumption will be compared with a threshold (determined based
	// 	on the entire sample, or only on the subsample, depending on the option specified) to determine eligibility.
	predict `logpccd_predicted' if e(sample)
	
	count if `logpccd_predicted' ~= .
	local count_predicted = r(N)
	
	foreach x of numlist `cutoffs' { // loop over all the cutoffs to be used
						
		// Use the subset to calculate xth perentile cutoff? or use all data?
		// use ONLY subset of the data
		if ("`subsetcutoff'"=="subsetcutoff") { 
			qui reg `varlist' [`weight'`exp'] if `touse', r
			predict `logpccd_predicted_threshold' if e(sample)
			_pctile `logpccd_predicted_threshold' [`weight'`exp'] if `touse', n(100)
			di "subset cutoff"
			
		} 
		else { // use the ENTIRE sample, not just a subset
			
			qui reg `varlist' [`weight'`exp'], r
			predict `logpccd_predicted_threshold' if e(sample)			
			_pctile `logpccd_predicted_threshold' [`weight'`exp'], n(100)
			di "non-subset cutoff"
			
		}
		// return list
		local logcutoff = r(r`x')
		di "cutoff: `logcutoff'"
		
		tempvar eligible eligible_notpoorest20 ineligible_poorest20 errors_incl errors_excl poor_eligible nonpoor_ineligible Quantilec nonpoor_eligible poor_ineligible
					
		qui gen `eligible' =.
		qui gen `nonpoor_eligible' = .
		qui gen `poor_ineligible' = .
		
		qui replace `eligible' = 1 if `logpccd_predicted' < `logcutoff' & `logpccd_predicted' ~= .  & `touse'
		qui replace `eligible' = 0 if `logpccd_predicted' >= `logcutoff' & `logpccd_predicted' ~= .  & `touse'
		
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
			return scalar coverage_cutoff`x'_quantile`q' = 	r(mean)
			
		}
		
		if (`x'==`graphme')  {
			twoway (scatter `logpccd_predicted' `1' if `poor_ineligible'==1, xline(`logpline', lcolor(0)) yline(`logcutoff') mc(red) m(x) ) /* 
			*/	(scatter `logpccd_predicted' `1' if `nonpoor_ineligible' == 1, mc(green) m(x)) /*
			*/	(scatter `logpccd_predicted' `1' if `nonpoor_eligible'==1, mc(black) m(x)) /* (scatter `logpccd_predicted' `1' if `Quantilec'==10 & logpccd_predicted < `logcutoff' & `1' ~= . & `logpccd_predicted' ~= ., mc(blue) m(Oh))
			*/	 /*
			*/	(scatter `logpccd_predicted' `1' if `poor_eligible' == 1, mc(blue) m(x) xlabel(3(1)8) ylabel(3(1)8) ysc(r(3 8)) xsc(r(3 8)) ) /*
			*/ , title("Cutoff `x' pctile (TJK 2009)") legend(lab(1 "Errors of Exclusion") lab(3 "Errors of Inclusion") lab(2 "Nonpoor, Ineligible") lab(4 "Poor Eligible") )
		}
		
		// Need to store the results somewhere, somehow
		return scalar leakage_`x' = `leakage'
		return scalar undercoverage_`x' = `undercoverage'
	}	
end program

