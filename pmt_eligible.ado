program define pmt_eligible, rclass
	// July 26 2010
	// July 31 2010: Modified pmt.ado so that it does not need a regression model - the eligible variable is passed as a parameter.
	//				keep in mind, need to fix quantile - it should now be a vector/variable that is passed as an option
	// August 03 2010 : I want to replace the sum command with one that uses survey settings. I will use svy : mean var1, the ereturn value of which is 
	//					stored in e(b) as _coeff[var1]. This works well. Next one will add option to use betas from
	//					a subsample to predict consumption for the rest of the sample (that change actually applies only to pmt2.ado, not pmt_eligible (this program)
	//					Also removing reduncancy for pmt_eligible in having to specifiy the Quantiles variable AND the number of Quantiles.
	// November 01, 2011 : Modified to calculate eligibility compliance
	// January 30, 2013 : Want to calculate inclusion error rate (% of beneficiaries that are outside the target group) and exclusion error rate (% of target group that are not beneficiaries)
	
	// syntax varlist(min=1 max=1) [if] [pw aw iw fw], Poor(varname numeric) QUantilec(varname numeric) Quantiles(integer) [, SUBsetcutoff]
	// syntax varlist(min=1 max=1) [if] [pw aw iw fw], Poor(varname numeric) QUantilec(varname numeric) Quantiles(integer) [SUBsetcutoff]
	syntax varlist(min=1 max=1) [if] [pw aw iw fw], Poor(varname numeric) QUantilec(varname numeric) 

	version 9.1 
	marksample touse
		
	tempvar eligible eligible_notpoorest20 ineligible_poorest20 errors_incl errors_excl poor_eligible nonpoor_ineligible Quantilec nonpoor_eligible poor_ineligible Quantilec correctly_classified
				
	qui gen `Quantilec' = `quantilec'	// seems pointless I know. I just wanted to change the capitalization of this variable to match code that I had already written.		
	
	// need to get the number of quantiles
	qui svy: tab `quantilec'
	local quantiles = e(r)
	
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
	
	qui gen `correctly_classified' =.
	replace `correctly_classified' = 1 if (`poor_eligible'==1 | `nonpoor_ineligible'==1)
	replace `correctly_classified' = 0 if (`poor_eligible'==0 & `nonpoor_ineligible'==0)
	
	count if `eligible' == 1 & `touse'
	if (r(N) != 0) {
		cap qui svy : mean `nonpoor_eligible' if `eligible' == 1 & `touse'
		if (_rc ~= 0) {
			local leakage = .
		}
		else {
			local leakage 		= _coef[`nonpoor_eligible']
		}
	}
	else {
		local leakage       = .
	}
	count if `poor' == 1 & `touse'
	if (r(N) != 0) {
		cap qui svy : mean `poor_ineligible' if `poor' == 1 & `touse'
		if (_rc ~= 0) {
			local undercoverage = .
		}
		else {
			local undercoverage = _coef[`poor_ineligible']
		}
	}
	else {
		local undercoverage = .
	}
	cap qui svy : mean `correctly_classified' if `touse'
	if (_rc ~= 0) {
		local elig_compliance = .
	}
	else {
		local elig_compliance = _coef[`correctly_classified']
	}
	// di "leakage: `leakage'"
	// di "undercoverage: `undercoverage'"
	
	// Here is where we calculate the coverage for each decile
	// First generate quantile indicators
	
	forv q = 1/`quantiles' {
		
		// While the quintile is classified according to the entire sample, "coverage" is defined based on the subsample only. This is what makes most sense.
		//		For e.g., if there is only 1 observation in the first quantile in this subsample, and 10,000 in the rest, and this one is covered, then the 
		//		coverage will be 100% for quantile1 for this subsample. 
				
		count if `Quantilec' == `q' & `touse' 
		if (r(N) != 0) {
			cap qui svy : mean `eligible' if `Quantilec' == `q' & `touse'
			if (_rc ~= 0) {
				return scalar coverage_cutoff_quantile`q' = .
			}
			else {
				return scalar coverage_cutoff_quantile`q' = _coef[`eligible']	
			}
		}
		else {
			return scalar coverage_cutoff_quantile`q' = .
		}
	}
	
	// the fraction of the total population covered, i.e. overall coverage rate
	count if `touse'
	if (r(N) != 0) {	
		cap qui svy : mean `eligible' if `touse'
		if (_rc ~= 0) {
			local fraction_covered = .
		}
		else {	
			local fraction_covered = _coef[`eligible']
		}
		
		// the fraction of the total population that is in the target group
		cap qui svy : mean `poor' if `touse'
		if (_rc ~= 0) {	
			local fractionoftotal_in_targetgroup = .
		}
		else {	
			local fractionoftotal_in_targetgroup = _coef[`poor']
		}
	}
	else {
		local fraction_covered = 0
		local fractionoftotal_in_targetgroup = .
	}

	// coverage rate of the target group
	count if `poor' == 1 & `touse'
	if (r(N) != 0) {	
		cap qui svy : mean `poor_eligible' if `poor' == 1 & `touse'
		if (_rc ~= 0) {
			local coverage_rate_targetgroup = .
		}
		else {
			local coverage_rate_targetgroup = _coef[`poor_eligible']
		}
	}
	else {
		local coverage_rate_targetgroup = 0
	}
	
	// *****************************************************************
	
	// inclusion error rate: percentage of beneficiaries that are outside of the target group
	count if `poor' == 1 & `touse'
	if (r(N) != 0) {	
		cap qui svy : mean `nonpoor_eligible' if `eligible' == 1 & `touse'
		if (_rc ~= 0) {
			local inclusion_error_rate = .
		}
		else {	
			local inclusion_error_rate = _coef[`nonpoor_eligible']
		}
	}
	else {
		local inclusion_error_rate = 0
	}
	
	// exclusion error rate: percentage of target group that is ineligible
	count if `poor' == 1 & `touse'
	if (r(N) != 0) {	
		cap qui svy : mean `poor_ineligible' if `poor' == 1 & `touse'
		if (_rc ~= 0) {
			local exclusion_error_rate = .
		}
		else {	
			local exclusion_error_rate = _coef[`poor_ineligible']
		}
	}
	else {
		local exclusion_error_rate = 0
	}
	
	// *****************************************************************
	
	// targeting accuracy is: coverage rate of the target group * fraction of the total population that is in the target group / overall coverage rate
	if (`fraction_covered' == 0) {
		local targeting_accuracy = .	
	}
	else {
		local targeting_accuracy = `coverage_rate_targetgroup'*`fractionoftotal_in_targetgroup'/`fraction_covered'	
	}
	
	// alternatively, use the sum of poor_eligible over all eligible, and take the mean
	count if `eligible' == 1 & `touse'
	if (r(N) != 0) {
		cap qui svy : mean `poor_eligible' if `eligible' == 1 & `touse'
		if (_rc ~= 0) {
			local targeting_accuracy2 = .
		}
		else {
			local targeting_accuracy2 = _coef[`poor_eligible'] 
		}
	}
	else {
		local targeting_accuracy2 = .
	}
	
	// Need to store the results 
	return scalar leakage = `leakage'
	return scalar undercoverage = `undercoverage'
	return scalar targeting_accuracy = `targeting_accuracy'
	return scalar targeting_accuracy2 = `targeting_accuracy2'
	return scalar coverage_rate_targetgroup = `coverage_rate_targetgroup'
	return scalar fractionoftotal_in_targetgroup = `fractionoftotal_in_targetgroup'
	return scalar fraction_covered = `fraction_covered'
	return scalar elig_compliance =`elig_compliance'
	
	return scalar inclusion_error_rate = `inclusion_error_rate'
	return scalar exclusion_error_rate = `exclusion_error_rate'
	
end program

