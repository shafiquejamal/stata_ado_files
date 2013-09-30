program define pmt2, rclass
	// July 26 2010
	// July 31 2010 - this routine uses the pmt_eligible.ado program. I've split this into two, incase one wishes to evaluate the performance of non-regression models
	// August 03 2010 : I want to replace the sum command with one that uses survey settings. This works well. Next one will add option to use betas from
	//					a subsample to predict consumption for the rest of the sample
	// August 04 2010 : Adding option to use betas from a subsample. STILL NEED TO VERIFY THAT IT IS WORKING PROPERLY. Also removing reduncancy for pmt_eligible in having to specifiy the Quantiles variable AND the number of Quantiles.
	// August 06 2010 : For threshold, will use bottom X percent of ACTUAL (not predicted) consumption of the ENTIRE sample
	// August 27: add option to specify whether the the subsamples are a filter - i.e. we toss out observations that are not in the subsample, when calculating leakage, undercoverage, coverage of the difference quantiles, etc.
	// March 23 2012 : The cutoff is specified as a percentile of the predicted distribution. I will add the option to specify the cutoff as an absolute number. User should specify either C or CAB
	
	syntax varlist(min=2 ts) [if] [pw aw iw fw],  Poor(varname numeric) Quantiles(integer) [Cutoffs(numlist asc min=1 max=20 >0 <=70 integer) CABsolute(numlist asc min=0 max=20 >=0) Graphme(integer -1) logpline(real 0) Usesubsamplebetas(varname numeric) Filter GENerate(name)]
	version 9.1 
	marksample touse
	
	// Need to get the weights, so that I can use this with the _pctile command below.
	qui svyset
	local svyweight = r(wtype)
	local svyexp    = r(wexp) 
	di "[`svyweight'`svyexp']"
	
	// Was the option to use betas from a subsample specified?
	if ( "`usesubsamplebetas'"=="") {
		// di "usesubsamplebetas NOT specified"
		tempvar usesubsamplebetas
		qui gen `usesubsamplebetas' = 1
		qui sum `usesubsamplebetas'
	} 
	
	tempvar logpccd_predicted logpccd_predicted_threshold 
	
	qui spearman `varlist' `if'
	return scalar rho = r(rho) 
	
	qui svy : reg `varlist' if `touse' & `usesubsamplebetas'==1	
	local R2 = e(r2) 
	local N = e(N)
	return scalar r2 = `R2'
	return scalar N = `N'
	// predict for the entire sample... may as well
	predict `logpccd_predicted'
	
	if ( "`generate'"!="") {
		cap drop `generate'
		predict `generate' if `touse'
	}
	
	qui count if `logpccd_predicted' ~= .
	qui local count_predicted = r(N)
	 	 
	// should we loop over percentile or absoulute cutoff?
	// check which option user chose
	di "cutoffs = `cutoffs'"
	if ("`cutoffs'"=="") {
		di "log cutoffs not specified - assume absolute cutoff specified"
		local cutoffs_to_loopover `cabsolute'
	}
	di "cabsolute = `cabsolute'"
	if ("`cabsolute'"=="") {
		di "cabsolute not specified - assume log cutoff specified"
		local cutoffs_to_loopover `cutoffs'
	}
	if ("`cutoffs'"=="" & "`cabsolute'"=="") {
		stop
	} 
	 	 
	// set trace on
	// set traced 2
	
	// foreach x of numlist `cutoffs' { // loop over all the cutoffs to be used
	foreach x of numlist `cutoffs_to_loopover'	{
	
		if ("`cutoffs'"~="") {
			// Getting percentiles of the ENTIRE population. This part is only for setting the cutoff. 
			_pctile `1' [`svyweight'`svyexp'], n(100)
			// return list
			local logcutoff = r(r`x')
			di "cutoff: `logcutoff'"
		}
		else {
			local logcutoff = ln(`x')
			di "cutoff: `logcutoff'"
		}

		// for return values, need to fix `x'
		// local x2 = substr("`x'",1,5)
		local x2 = round(`x')

		tempvar eligible nonpoor_ineligible poor_ineligible nonpoor_eligible poor_eligible Quantilec
					
		qui gen `eligible' =.
		qui gen `nonpoor_eligible' = .
		qui gen `poor_ineligible' = .
		
		qui replace `eligible' = 1 if `logpccd_predicted' < `logcutoff' & `logpccd_predicted' ~= .  & `touse'
		qui replace `eligible' = 0 if `logpccd_predicted' >= `logcutoff' & `logpccd_predicted' ~= .  & `touse'
		
		// Make ineligible those who are filtered out, if the filter option has been selected 
		if ("`filter'"=="filter") {
			replace `eligible' = 0 if `usesubsamplebetas'==0
		}
		
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
		
		// what percent of the population is covered?
		qui svy : mean `eligible' if `touse' 
		local percentofpop_covered = _coef[`eligible']
		return scalar percentofpop_covered_`x2' = `percentofpop_covered'
		
		// First generate quantile indicators
		
		// Here the classification of quantile is done based on the entire sample. This is probably what most people want.
		qui xtile `Quantilec' = `1' [`svyweight'`svyexp'], n(`quantiles') 
				
		// 
		// [`weight'`exp'] is not used, but the darn thing doesn't work unless I include it!
		pmt_eligible `eligible' [`svyweight'`svyexp'], p(`poor') qu(`Quantilec')
		
		// No need to make adjustments for filters here
		// Need to store the results somewhere, somehow
		
		return scalar leakage_`x2' = r(leakage)
		return scalar undercoverage_`x2' = r(undercoverage)
		return scalar targeting_accuracy_`x2' = r(targeting_accuracy)
		return scalar targeting_accuracy2_`x2' = r(targeting_accuracy2)
		return scalar coverage_rate_targetgroup_`x2' = r(coverage_rate_targetgroup)
		return scalar fractiontotal_targetgroup_`x2' = r(fractionoftotal_in_targetgroup)
		return scalar fraction_covered_`x2' = r(fraction_covered)
		
		return scalar inclusion_error_rate_`x2' = r(inclusion_error_rate)
		return scalar exclusion_error_rate_`x2' = r(exclusion_error_rate)
		
		forv q = 1/`quantiles' {
			return scalar coverage_cutoff`x2'_quantile`q' = r(coverage_cutoff_quantile`q')
			local temp = r(coverage_cutoff_quantile`q')
			// di "scalar coverage_cutoff`x'_quantile`q' = `temp'"
		}
		
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
				*/	(scatter `logpccd_predicted' `1' if `poor_eligible' == 1, mc(blue) m(x) xlabel(8(1)12) ylabel(8(1)12) ysc(r(8 12)) xsc(r(8 12)) ) /*
				*/ , title("Cutoff `x'") legend(lab(1 "Errors of Exclusion") lab(3 "Errors of Inclusion") lab(2 "Nonpoor, Ineligible") lab(4 "Poor Eligible") )
			}
		}
	}	
end program

