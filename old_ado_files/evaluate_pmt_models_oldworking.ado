program define evaluate_pmt_models

	syntax varname [using/], model_urban(string) model_rural(string) CABsolute(integer) Target_coverage(real) Poorest20(varname) Quantilec(varname) logpline(real) urban(varname) rural(varname) [TOLerance(real 0.001) step(integer 5) append]
	version 10.1
	tempname equation_rural equation_urban logcutoff cabsolute2 explogcutoff exit_loop
	tempvar logpccd_hat_rural logpccd_hat_urban logpccd_hat
	local step = abs(`step')
	
	tempname cabsolute_loop
	local `cabsolute_loop' = `cabsolute' 	// this is for looping over values of the cutoff to optimize the target coverage rate. But I will loop only over the section "combined" below, in order 
    										//	to speed things up

	/*
	di `"model_urban=`model_urban'"'
	di `"model_rural=`model_rural'"'	
	*/
	
	// ------------------Urban Model-------------------------------
	
	qui xi: svy, subpop(`urban'): reg `varlist' `model_urban'
	varsformyrelabel // This program relabels vars that are created by xi. The default label is something like "roof_material=3", and this code would change that to "roof_material=slate" for example
	variables_and_coeffs using "`using'_urban_variables_and_coeffs.csv", r(0.0000001) o // This outputs a csv file of variables and their coefficients, useful for making tables to put in a doc
	construct_reg_eqn , f("`using'_urban_equation.txt") r(0.0000001) // constructs a regrestion equation with the esitmated coefficients and saves it as one line in a text file. Useful if I want to run the regression on a different set of data (with the same variable names)
	local `equation_urban' `"`r(equation)'"'
	// di "equation_urban is: `equation_urban'"

	// Want to create a "dataset" of coefficients and their names so that one can plot these in stata. The bar height is the coefficient, and the x-axis are the variables. Useful for looking at relative strengths of the coefficients.
	qui dataset_coefficients , f("plotme_urban.dta")
	qui cap drop `logpccd_hat_urban'
	qui predict `logpccd_hat_urban' if e(sample)
	// The program "pmt2" simulates the performance of the PMT model. In the r values are inclusion, exclusion, overall coverage, coverage per quintile, etc.
	qui xi: pmt2 `varlist' `model_urban' [`svyweight'`svyexp'] if `urban'==1, cab(``cabsolute_loop'')  p(`poorest20') quantilec(`quantilec') logpline(`logpline') // graphme(``cabsolute_loop'')
	varsformyrelabel // again, relabel the categorical variables so that humans can understand them without having to look anything up.
	dataout_pmt2 , l("(Brute Force) Urban") c(``cabsolute_loop'') f("$tjdir12_reports/`using'.csv") q(5) `append' // This just outputs the results from the r values
	
	// ------------------Rural Model-------------------------------
	
	qui xi: svy, subpop(`rural'): reg `varlist' `model_rural'
	varsformyrelabel
	// ssc install MATNAMES
	variables_and_coeffs using "`using'_rural_variables_and_coeffs.csv", r(0.0000001) o
	construct_reg_eqn , f("`using'_rural_equation.txt") r(0.0000001)
	local `equation_rural' `"`r(equation)'"'

	// Want to create a "dataset" of coefficients and their names so that one can plot these in stata
	qui dataset_coefficients , f("`using'_plotme_rural.dta")
	qui cap drop `logpccd_hat_rural'
	qui predict `logpccd_hat_rural' if e(sample)
	qui xi: pmt2 `varlist' `model_rural' [`svyweight'`svyexp'] if `rural'==1, cab(``cabsolute_loop'')  p(`poorest20') quantilec(`quantilec') logpline(`logpline') // graphme(``cabsolute_loop'')
	// return list
	varsformyrelabel
	dataout_pmt2 , l("(Brute Force) Rural") c(``cabsolute_loop'') f("$tjdir12_reports/`using'.csv") q(5) a

	// ------------------------------------------- Performance of models combinded ------------------------------------------- 

	// di "equation_rural: ``equation_rural''"
	// di "equation_urban: ``equation_urban''"	gen `logpccd_hat' = .	replace `logpccd_hat' = `logpccd_hat_urban' if urban == 1	replace `logpccd_hat' = `logpccd_hat_rural' if rural == 1
	
	tempname fraction_covered_loop fraction_covered cabsolute_tried count y1 y2 x1 x2 last_word
	local `count' = 0
	local `exit_loop' = 0
	while (``exit_loop'' == 0) {
	
		local `count' = ``count'' + 1
	
		local `logcutoff' = ln(``cabsolute_loop'')
		// di "cutoff: ``logcutoff''"
		local `explogcutoff' = exp(``logcutoff'')
		// di "explogcutoff = ``explogcutoff''"
		
		// get rid of decimal in the name of variable
		local `cabsolute2' = round(``cabsolute_loop'')
		// di "cutoff rounded = ``cabsolute2''"
		
		tempvar eligible_`cabsolute2'		qui cap drop `eligible_`cabsolute2''		qui gen `eligible_`cabsolute2'' = .		qui replace `eligible_`cabsolute2'' = 1 if `logpccd_hat' <  ``logcutoff'' & `logpccd_hat' ~= .		qui replace `eligible_`cabsolute2'' = 0 if `logpccd_hat' >= ``logcutoff'' & `logpccd_hat' ~= .
			
		qui pmt_eligible `eligible_`cabsolute2'' [`svyweight'`svyexp'], p(`poorest20') qu(`quantilec')		dataout_pmt_eligible, l("(Brute Force) All (before bonuses)") f("$tjdir12_reports/`using'.csv") q(5) c(``cabsolute_loop'') a		dataset_coverage , c(``cabsolute_loop'') q(5) p("$tjdir12_reports/dataset_coverage_all_beforebonuses_``cabsolute_loop''_`using'.dta") 
		local `fraction_covered' = r(fraction_covered)
		
		// For the next iteration of the loop
		// Keep track of what's already been tried, don't want to duplicate. If duplicate, then exit
		
		// calculate next cutoff
		if (``count'' ~= 1) {
			local `last_word' = ``count'' - 1
			local `y2' = ``cabsolute_loop''								// This is the current cutoff being tried
			local `y1' : word ``last_word'' of ``cabsolute_tried'' 		// This is the previous cutoff tried
			local `x2' = ``fraction_covered''							// The current fraction covered
			local `x1' : word ``last_word'' of ``fraction_covered_loop''				// The current previous covered
			local step = ((``y2''-``y1'')/(``x2''-``x1''))*(`target_coverage'-``x2'')
			// di `"count=``count'' step=`step'"'
		}
		else {
			if (`r(fraction_covered)' > `target_coverage' + `tolerance') {
				// di `"count=``step'' step=`step'"'
				local step = -1*`step'
				// di `"count=``count'' step=`step'"'
			}
		}
		
		/*
		di `"count=``count''"'
		di `"y2=``y2''"'
		di `"y1=``y1''"'
		di `"x2=``x2''"'
		di `"x1=``x1''"'
		di `"step=`step'"'
		di `"fraction_covered=``fraction_covered''"'
		*/
		
		if (`step'==.) {
			exit
		}
		
		// Exit if this loop is a repeat of a previous cutoff
		if (`: list `cabsolute_loop' in local `cabsolute_tried'') {
			exit
		}
		
		local `cabsolute_tried' ``cabsolute_tried'' ``cabsolute_loop''
		local `fraction_covered_loop' ``fraction_covered_loop'' ``fraction_covered''
		
		if ((`r(fraction_covered)' < `target_coverage' - `tolerance') | (`r(fraction_covered)' > `target_coverage' + `tolerance')) {
			local `cabsolute_loop' = ``cabsolute_loop'' + `step'
		}
		else {
			local `exit_loop' = 1
		}
		
		// Lets not do too many loops
		if (``count'' > 10) {
			local `exit_loop' = 1
		}
		
		
	}
	 
end
