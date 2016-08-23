program define pmt2_train_test, rclass
	// July 26 2010
	// July 31 2010 - this routine uses the pmt_eligible_train_test.ado program. I've split this into two, incase one wishes to evaluate the performance of non-regression models
	// August 03 2010 : I want to replace the sum command with one that uses survey settings. This works well. Next one will add option to use betas from
	//					a subsample to predict consumption for the rest of the sample
	// August 04 2010 : Adding option to use betas from a subsample. STILL NEED TO VERIFY THAT IT IS WORKING PROPERLY. Also removing reduncancy for pmt_eligible in having to specifiy the Quantiles variable AND the number of Quantiles.
	// August 06 2010 : For threshold, will use bottom X percent of ACTUAL (not predicted) consumption of the ENTIRE sample
	// August 27: add option to specify whether the the subsamples are a filter - i.e. we toss out observations that are not in the subsample, when calculating leakage, undercoverage, coverage of the difference quantiles, etc.
	// March 23 2012 : The cutoff is specified as a percentile of the predicted distribution. I will add the option to specify the cutoff as an absolute number. User should specify either C or CAB
	
	syntax varlist(min=2 ts) [if],  Poor(varname numeric) quantilec(varname numeric) trainingIndicator(varname numeric) testingIndicator(varname numeric) Cutoffs(numlist asc min=1 max=20 >0) [Graphme(real -1) logpline(real 0) Filter GENerate(name)]
	version 9.1 
	marksample touse
					
	tempvar logpccd_predicted 
	
	qui spearman `varlist' `if'
	return scalar rho = r(rho)  
	
	qui svy : reg `varlist' if `touse' & `trainingIndicator'==1
	return list
	local R2 = e(r2) 
	local N = e(N)
	return scalar r2 = `R2'
	return scalar N = `N'
	predict `logpccd_predicted'
	
	if ( "`generate'"!="") {
		cap drop `generate'
		predict `generate' if `touse'
	}
	
	qui count if `logpccd_predicted' ~= .
	qui local count_predicted = r(N)
	 	 
	foreach cutoff of numlist `cutoffs'	{
	
		di "cutoff=`cutoff'"
		local cutoffWithoutDecimal = subinstr(substr(`"`cutoff'"',1,7), ".", "pp", .)

		tempvar eligible
					
		qui gen `eligible' =.		
		qui replace `eligible' = 1 if `logpccd_predicted' < `cutoff' & `logpccd_predicted' ~= .  & `touse'
		qui replace `eligible' = 0 if `logpccd_predicted' >= `cutoff' & `logpccd_predicted' ~= .  & `touse'
													
		// Here the classification of quantile is done based on the entire sample. This is probably what most people want.
		// need to get the number of quantiles
		svy: tab `quantilec'
		local quantiles = e(r)		
		// 
		// [`weight'`exp'] is not used, but the darn thing doesn't work unless I include it!
		pmt_eligible_train_test `eligible', p(`poor') qu(`quantilec') evaluationSubset(`testingIndicator')
				
		return scalar leakage_`cutoffWithoutDecimal' = r(leakage)
		return scalar undercoverage_`cutoffWithoutDecimal' = r(undercoverage)
		return scalar targeting_accuracy_`cutoffWithoutDecimal' = r(targeting_accuracy)
		return scalar coverage_targetgroup_`cutoffWithoutDecimal' = r(coverage_rate_targetgroup)
		return scalar fractionis_targetgroup_`cutoffWithoutDecimal' = r(fractionoftotal_in_targetgroup)
		return scalar fraction_covered_`cutoffWithoutDecimal' = r(fraction_covered)
		
		return scalar inclusion_error_rate_`cutoffWithoutDecimal' = r(inclusion_error_rate)
		return scalar exclusion_error_rate_`cutoffWithoutDecimal' = r(exclusion_error_rate)
		
		forv q = 1/`quantiles' {
			return scalar coverage_cutoff`cutoffWithoutDecimal'_q`q' = r(coverage_cutoff_quantile`q')
			local temp = r(coverage_cutoff_q`q')
		}
				
		if (`graphme'~= -1)  {
		
			tempname xlimlower xlimupper ylimlower ylimupper
			local `xlimlower' = 9
			local `xlimupper' = 11
			local `ylimlower' = 10.5
			local `ylimupper' = 13
		
			tempvar  nonpoor_ineligible poor_ineligible nonpoor_eligible poor_eligible
			
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
		
			twoway (scatter `logpccd_predicted' `1' if `poor_ineligible'==1 & `testingIndicator', xline(`logpline', lcolor(0)) yline(`cutoff') mc(red) m(x) ) /* 
			*/	(scatter `logpccd_predicted' `1' if `nonpoor_ineligible' == 1 & `testingIndicator', mc(green) m(x)) /*
			*/	(scatter `logpccd_predicted' `1' if `nonpoor_eligible'==1 & `testingIndicator', mc(black) m(x)) /* (scatter `logpccd_predicted' `1' if `Quantilec'==10 & logpccd_predicted < `cutoff' & `1' ~= . & `logpccd_predicted' ~= ., mc(blue) m(Oh))
			*/	(scatter `logpccd_predicted' `1' if `poor_eligible' == 1 & `testingIndicator', mc(blue) m(x) xlabel(``xlimlower''(1)``xlimupper'') ylabel(``ylimlower''(1)``ylimupper'') ysc(r(``ylimlower'' ``ylimupper'')) xsc(r(``xlimlower'' ``xlimupper'')) ) /*
			*/ , title("Cutoff `cutoff'") legend(lab(1 "Errors of Exclusion") lab(3 "Errors of Inclusion") lab(2 "Nonpoor, Ineligible") lab(4 "Poor Eligible") )
			
		}
				
	}	
end program

