program pmt, rclass
	syntax varlist(min=2 ts) [if] [aw], Cutoffs(numlist asc min=1 max=20 >0 <50 integer) Poor(varname numeric) Quantiles(integer) [Graphme(integer -1) logpline(real 0)]
	version 9.1
	marksample touse
	
	tempvar logpccd_predicted pctile_loop
	
	qui reg `varlist' [`weight'`exp'] `if', r 
	local R2 = e(r2) 
	local N = e(N)
	return scalar r2 = `R2'
	return scalar N = `N'
	
	qui spearman `varlist' `if'
	
	return scalar rho = r(rho) 
	// return matrix Rho = r(Rho)
	
	cap drop `logpccd_predicted'
	predict `logpccd_predicted' if e(sample)
	count if `logpccd_predicted' ~= .
	local count_predicted = r(N)
	
	qui sum `poor' if `poor' == 1
	local denom_poorest20 = r(N)
	di "denom_poorest20: `denom_poorest20'"
	stop2
	
	foreach x of numlist `cutoffs' { // loop over all the cutoffs to be used
				
		cap drop `pctile_loop'
		_pctile `logpccd_predicted' [`weight'`exp'], n(100)
		local logcutoff = r(r`x')
		di "cutoff: `logcutoff'"
		
		tempvar eligible eligible_notpoorest20 ineligible_poorest20 errors_incl errors_excl poor_covered nonpoor_noncovered Quantilec
		
		qui gen `eligible' =.
		qui gen `eligible_notpoorest20' =.
		qui gen `ineligible_poorest20' =.
		
		qui gen `errors_incl' = .
		qui gen `errors_excl' = .
		qui gen `poor_covered' = 0
		qui gen `nonpoor_noncovered' = 0
	
		qui replace `poor_covered' = 1 if `poor' == 1 & `logpccd_predicted' < `logcutoff' & `1' ~= . & `logpccd_predicted' ~= .
		qui replace `poor_covered' = 0 if (`poor' == 0 | `logpccd_predicted' > `logcutoff') & `1' ~= . & `logpccd_predicted' ~= . // if they are not poor or they are not covered
		qui replace `nonpoor_noncovered' = 1 if `poor' == 0 & `logpccd_predicted' >= `logcutoff' & `1' ~= . & `logpccd_predicted' ~= .
		qui replace `nonpoor_noncovered' = 0 if (`poor' == 1 | `logpccd_predicted' < `logcutoff') & `1' ~= . & `logpccd_predicted' ~= . // if they are poor or they are covered
		qui replace `errors_incl' = 1 if `poor' == 0 & `logpccd_predicted' <= `logcutoff' & `1' ~= . & `logpccd_predicted' ~= .
		qui replace `errors_incl' = 0 if ( `poor' == 1 | `logpccd_predicted' > `logcutoff' ) & `1' ~= . & `logpccd_predicted' ~= .
		qui replace `errors_excl' = 1 if `poor' == 1 & `logpccd_predicted' > `logcutoff' & `1' ~= . & `logpccd_predicted' ~= .
		qui replace `errors_excl' = 0 if ( `poor' == 0 | `logpccd_predicted' <= `logcutoff' ) &  `1' ~= . & `logpccd_predicted' ~= .
		
		qui replace `eligible' = 1 if `logpccd_predicted' < `logcutoff' & `logpccd_predicted' ~= .
		qui replace `eligible' = 0 if `logpccd_predicted' >= `logcutoff' & `logpccd_predicted' ~= .
		qui replace `eligible_notpoorest20' = 1 if `eligible' == 1 & `poor' == 0
		qui replace `eligible_notpoorest20' = 0 if (`eligible' == 0 | `poor' == 1) & `eligible' ~= . & `poor' ~= .
		qui replace `ineligible_poorest20' = 1 if `eligible' == 0 & `poor' == 1
		qui replace `ineligible_poorest20' = 0 if (`eligible' == 1 | `poor' == 0)  & `eligible' ~= . & `poor' ~= .
		
		qui sum `poor_covered' if `poor_covered' == 1
		scalar tot_poor_covered = r(N)
		qui sum `errors_incl' if `errors_incl==1', d
		local incl = r(N)
		di "incl: `incl'"
		qui sum `errors_excl' if `errors_excl'==1, d
		local excl = r(N)
		di "excl: `excl'"
		local undercoverage = `excl' / (`excl' + tot_poor_covered )
		local leakage = `incl' / (`incl' + tot_poor_covered) 
		local inclexcl = `incl' + `excl'
		qui sum `eligible_notpoorest20' if `eligible_notpoorest20' == 1 & `logpccd_predicted' ~= .
		local eligible_notpoorest20 = r(N)
		qui sum `ineligible_poorest20' if `ineligible_poorest20' == 1 & `logpccd_predicted' ~= .
		local ineligible_poorest20 = r(N)
		local spill = `eligible_notpoorest20'  / `denom_poorest20'
		
		local leftout = `ineligible_poorest20' / `denom_poorest20'
		// di "undercoverage: `undercoverage'"
		// di "leakage: `leakage'"
		
		// Here is where we calculate the coverage for each decile
		// First generate quantile indicators
		qui xtile `Quantilec' = pccd [`weight'`exp'], n(`quantiles')
		
		forv q = 1/`quantiles' {
			qui sum `Quantilec' if `Quantilec' == `q'
			local numpplinqtile = r(N)
				
			// number of people in the quintile and covered
			qui sum `Quantilec' if `Quantilec' == `q' & `logpccd_predicted' < `logcutoff' & `1' ~= . & `logpccd_predicted' ~= .
			local numpplinqtilecovered = r(N)
				
			local coverage_quintile_`q' = `numpplinqtilecovered'/`numpplinqtile'
			local temp = `numpplinqtilecovered'/`numpplinqtile'
			// di "`numpplinqtilecovered'/`numpplinqtile' = `temp'"
				
			return scalar coverage_cutoff`x'_quantile`q' = `coverage_quintile_`q''	
		}
		
		if (`x'==`graphme')  {
			twoway (scatter `logpccd_predicted' `1' if `errors_excl'==1, xline(`logpline', lcolor(0)) yline(`logcutoff') mc(red) m(x) ) /* 
			*/	(scatter `logpccd_predicted' `1' if `nonpoor_noncovered' == 1, mc(green) m(x)) /*
			*/	(scatter `logpccd_predicted' `1' if `errors_incl'==1, mc(black) m(x)) /* (scatter `logpccd_predicted' `1' if `Quantilec'==10 & logpccd_predicted < `logcutoff' & `1' ~= . & `logpccd_predicted' ~= ., mc(blue) m(Oh))
			*/	 /*
			*/	(scatter `logpccd_predicted' `1' if `poor_covered' == 1, mc(blue) m(x) xlabel(3(1)8) ylabel(3(1)8) ysc(r(3 8)) xsc(r(3 8)) ) /*
			*/ , title("Cutoff `x' pctile (TJK 2009)") legend(lab(1 "Errors of Exclusion") lab(3 "Errors of Inclusion") lab(2 "Nonpoor, Ineligible") lab(4 "Poor Eligible") )
		}
		
		// Need to store the results somewhere, somehow
		return scalar leakage_`x' = `leakage'
		return scalar undercoverage_`x' = `undercoverage'
	}	
end program
