program define pmt_eligible_train_test, rclass
	// July 26 2010
	// July 31 2010: Modified pmt.ado so that it does not need a regression model - the eligible variable is passed as a parameter.
	//				keep in mind, need to fix quantile - it should now be a vector/variable that is passed as an option
	// August 03 2010 : I want to replace the sum command with one that uses survey settings. I will use svy : mean var1, the ereturn value of which is 
	//					stored in e(b) as _coeff[var1]. This works well. Next one will add option to use betas from
	//					a subsample to predict consumption for the rest of the sample (that change actually applies only to pmt2.ado, not pmt_eligible (this program)
	//					Also removing reduncancy for pmt_eligible in having to specifiy the Quantiles variable AND the number of Quantiles.
	// November 01, 2011 : Modified to calculate eligibility compliance
	// January 30, 2013 : Want to calculate inclusion error rate (% of beneficiaries that are outside the target group) and exclusion error rate (% of target group that are not beneficiaries)
	// May 9, 2016: Modified to produce measures on training and testing datasets

	syntax varname [if], Poor(varname numeric) QUantilec(varname numeric) evaluationSubset(varname numeric) [Graphme(real -1)]

	version 9.1 
	marksample touse
		
	tempvar eligible eligible_notpoorest20 ineligible_poorest20 errors_incl errors_excl poor_eligible nonpoor_ineligible Quantilec nonpoor_eligible poor_ineligible Quantilec correctly_classified
				
	qui gen `Quantilec' = `quantilec'	// seems pointless I know. I just wanted to change the capitalization of this variable to match code that I had already written.		
	
	// need to get the number of quantiles
	qui svy: tab `quantilec'
	local quantiles = e(r)
	
	qui gen `eligible' = `1' // This is the group that is deemed eligible for the program
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
		
	performance_measurement `nonpoor_eligible', groupOfInterest(`eligible') dataSubsetIndicator(`evaluationSubset')
	local leakage = r(performanceMeasure)
	local inclusion_error_rate = `leakage'
	
	performance_measurement `poor_ineligible', groupOfInterest(`poor') dataSubsetIndicator(`evaluationSubset')
	local undercoverage = r(performanceMeasure)
	local exclusion_error_rate = `undercoverage'
	
	performance_measurement `correctly_classified', dataSubsetIndicator(`evaluationSubset')
	local elig_compliance = r(performanceMeasure)

	// Here is where we calculate the coverage for each decile
	// First generate quantile indicators
	
	forv q = 1/`quantiles' {
		
		// While the quintile is classified according to the entire sample, "coverage" is defined based on the subsample only. This is what makes most sense.
		//		For e.g., if there is only 1 observation in the first quantile in this subsample, and 10,000 in the rest, and this one is covered, then the 
		//		coverage will be 100% for quantile1 for this subsample. 
				
		qui count if `Quantilec' == `q' & `touse' & `evaluationSubset'
		if (r(N) != 0) {
			cap qui svy : mean `eligible' if `Quantilec' == `q' & `touse' & `evaluationSubset'
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
	
	// the fraction of the total population covered of the evaluationSubset (e.g. training set, testing set, validation set), i.e. overall coverage rate	
	performance_measurement `eligible', dataSubsetIndicator(`evaluationSubset')
	local fraction_covered = r(performanceMeasure)
	
	performance_measurement `poor', dataSubsetIndicator(`evaluationSubset')
	local fractionoftotal_in_targetgroup = r(performanceMeasure)
	
	// coverage rate of target group
	performance_measurement `poor_eligible', groupOfInterest(`poor') dataSubsetIndicator(`evaluationSubset')
	local coverage_rate_targetgroup = r(performanceMeasure)
		
	// *****************************************************************
	
	// targeting accuracy is: coverage rate of the target group * fraction of the total population that is in the target group / overall coverage rate
	
	// alternatively, use the sum of poor_eligible over all eligible, and take the mean	
	performance_measurement `poor_eligible', groupOfInterest(`eligible') dataSubsetIndicator(`evaluationSubset')
	local targeting_accuracy = r(performanceMeasure)
	
	if (`graphme'~= -1)  {
		if ("`filter'"=="filter") {
			twoway (scatter `logpccd_predicted' `1' if `poor_ineligible'==1, xline(`logpline', lcolor(0)) yline(`logcutoff') mc(red) m(x) ) /* 
			*/	(scatter `logpccd_predicted' `1' if `nonpoor_ineligible' == 1, mc(green) m(x)) /*
			*/	(scatter `logpccd_predicted' `1' if `nonpoor_eligible'==1, mc(black) m(x)) /* (scatter `logpccd_predicted' `1' if `Quantilec'==10 & logpccd_predicted < `logcutoff' & `1' ~= . & `logpccd_predicted' ~= ., mc(blue) m(Oh))
			*/	(scatter `logpccd_predicted' `1' if `poor_eligible' == 1, mc(blue) m(x) xlabel(8(1)12) ylabel(8(1)12) ysc(r(8 12)) xsc(r(8 12)) ) /*
			*/	(scatter `logpccd_predicted' `1' if `usesubsamplebetas'  == 0, mc(purple) m(oh)) /*
			*/ , title("Cutoff `x' pctile (TJK 2009)") legend(lab(1 "Errors of Exclusion") lab(3 "Errors of Inclusion") lab(2 "Nonpoor, Ineligible") lab(4 "Poor Eligible") lab(5 "Filtered Out") )
		}
		else {
			twoway (scatter `logpccd_predicted' `1' if `poor_ineligible'==1, xline(`logpline', lcolor(0)) yline(`logcutoff') mc(red) m(x) ) /* 
			*/	(scatter `logpccd_predicted' `1' if `nonpoor_ineligible' == 1, mc(green) m(x)) /*
			*/	(scatter `logpccd_predicted' `1' if `nonpoor_eligible'==1, mc(black) m(x)) /* (scatter `logpccd_predicted' `1' if `Quantilec'==10 & logpccd_predicted < `logcutoff' & `1' ~= . & `logpccd_predicted' ~= ., mc(blue) m(Oh))
			*/	 /*
			*/	(scatter `logpccd_predicted' `1' if `poor_eligible' == 1, mc(blue) m(x) xlabel(``xlimlower''(1)``xlimupper'') ylabel(``ylimlower''(1)``ylimupper'') ysc(r(``ylimlower'' ``ylimupper'')) xsc(r(``xlimlower'' ``xlimupper'')) ) /*
			*/ , title("Cutoff `x'") legend(lab(1 "Errors of Exclusion") lab(3 "Errors of Inclusion") lab(2 "Nonpoor, Ineligible") lab(4 "Poor Eligible") )
		}
	}
	
	// Need to store the results 
	return scalar leakage = `leakage'
	return scalar undercoverage = `undercoverage'
	return scalar targeting_accuracy = `targeting_accuracy'
	return scalar coverage_rate_targetgroup = `coverage_rate_targetgroup'
	return scalar fractionoftotal_in_targetgroup = `fractionoftotal_in_targetgroup'
	return scalar fraction_covered = `fraction_covered'
	return scalar elig_compliance =`elig_compliance'
	
	return scalar inclusion_error_rate = `inclusion_error_rate'
	return scalar exclusion_error_rate = `exclusion_error_rate'
	
end program

