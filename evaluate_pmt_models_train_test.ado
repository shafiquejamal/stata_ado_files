program define evaluate_pmt_models_train_test

	// 20 July 2013: adding the capability to base the regression coefficients on a reduced set of observations, given by the variable `trainingIndicator'

	syntax varname [using/] [if], model(string) startingCutoff(real) Target_coverage(real) poor(varname numeric) Quantilec(varname numeric) trainingIndicator(varname numeric) testingIndicator(varname numeric) [TOLerance(real 0.001) step(real 5) logpline(real 0) append]
	version 10.1
	tempname cuttoffOptimizeNoDecimal exit_loop
	tempvar logpccd_hat
	
	// 9 May 2016
	// regresses varname on model, and predict varname_hat. Evaluates the performance on the training set. Need to change to evaluate on testing set
			
	tempname cutoffOptimize
	local `cutoffOptimize' = `startingCutoff' 	// this is for looping over values of the cutoff to optimize the target coverage rate. But I will loop only over the section "combined" below, in order 
												//	to speed things up

	// ------------------ Model ------------------------------------------------------------------------------------ 
	
	qui xi: svy: reg `varlist' `model'  if `trainingIndicator'==1	// varlist is varname above
	varsformyrelabel // This program relabels vars that are created by xi. The default label is something like "roof_material=3", and this code would change that to "roof_material=slate" for example
	
	qui cap drop `logpccd_hat'
	qui predict `logpccd_hat' `if'  // predict for all observations, not just those on which the regression coefficients are based (i.e. not just on the training set)
		
	// ------------------------------------------- Performance of Model ------------------------------------------- 

	tempname fraction_covered_loop fraction_covered cutoffsTried n_steps y1 y2 x1 x2 last_word
	local `n_steps' = 0
	local `exit_loop' = 0
	while (``exit_loop'' == 0) {
	
		local `n_steps' = ``n_steps'' + 1
			
		// get rid of decimal in the name of variable
		local `cuttoffOptimizeNoDecimal' = subinstr(`"`cutoffOptimize'"', ".", "pp", .)
		
		tempvar eligible_`cuttoffOptimizeNoDecimal'
		qui cap drop `eligible_`cuttoffOptimizeNoDecimal''
		qui gen `eligible_`cuttoffOptimizeNoDecimal'' = .
		qui replace `eligible_`cuttoffOptimizeNoDecimal'' = 1 if `logpccd_hat' <  ``cutoffOptimize'' & `logpccd_hat' ~= .
		qui replace `eligible_`cuttoffOptimizeNoDecimal'' = 0 if `logpccd_hat' >= ``cutoffOptimize'' & `logpccd_hat' ~= .
			
		qui pmt_eligible_train_test `eligible_`cuttoffOptimizeNoDecimal'', p(`poor') qu(`quantilec') evaluationSubset(`testingIndicator')
		local `fraction_covered' = r(fraction_covered)
		
		// calculate next cutoff
		if (``n_steps'' ~= 1) {
			local `last_word' = ``n_steps'' - 1
			local `x2' = ``cutoffOptimize''										// This is the current cutoff being tried
			local `x1' : word ``last_word'' of ``cutoffsTried'' 				// This is the previous cutoff tried
			local `y2' = ``fraction_covered''									// The current fraction covered
			local `y1' : word ``last_word'' of ``fraction_covered_loop''		// The previous fraction covered
			
			// if the coverage did not change... then do what?
			if (``y1''==``y2'') {
				if (``y1''==1 | ``y1'' >= `target_coverage') {
					local step = -1	
				}
				else {
					local step = 1	
				}
			} 
			else {
				local step = ((``x2''-``x1'')/(``y2''-``y1''))*(`target_coverage'-``y2'')
				// lets make sure that the step size doesn't get ridiculously large
				if (abs(`step') > 30) {
					local step = (`step'/abs(`step'))*30
				}
			}
			di `"n_steps=``n_steps'' step=`step' cutoffOptimize=``cutoffOptimize'' fraction_covered=``fraction_covered''"'
		}
		else {
			if (`r(fraction_covered)' > `target_coverage' + `tolerance') {
				// di `"n_steps=``step'' step=`step'"'
				local step = -1*`step'
				// di `"n_steps=``n_steps'' step=`step'"'
			}
		}
		
		// Conditions under which to write the data to file and exit the loop: coverage hasn't changed; same threshold is being tried; more than 30 iterations; coverage is within tolerance of target
		if ((`step'==.) | (`: list `cutoffOptimize' in local `cutoffsTried'') | (``n_steps'' > 30) | ((`r(fraction_covered)' > (`target_coverage' - `tolerance')) & (`r(fraction_covered)' < (`target_coverage' + `tolerance'))) ) {

			qui xi: pmt2_train_test `varlist' `model', cutoffs(``cutoffOptimize'')  p(`poor') quantilec(`quantilec') logpline(`logpline') graphme(``cutoffOptimize'') trainingIndicator(`trainingIndicator') testingIndicator(`testingIndicator') 
			varsformyrelabel // again, relabel the categorical variables so that humans can understand them without having to look anything up.
			dataout_pmt2_train_test , l("Model (`: word count `model''):`model'") c(``cutoffOptimize'') f("`using'.csv") q(5) `append' // This just outputs the results from the r values
			
			local `exit_loop' = 1
			exit
		}
		
		local `cutoffsTried' ``cutoffsTried'' ``cutoffOptimize''
		local `fraction_covered_loop' ``fraction_covered_loop'' ``fraction_covered''
		
		if ((`r(fraction_covered)' < `target_coverage' - `tolerance') | (`r(fraction_covered)' > `target_coverage' + `tolerance')) {
			local `cutoffOptimize' = ``cutoffOptimize'' + `step'
		}
		else {
			stop
			local `exit_loop' = 1
		}
		
		// di "n_steps = ``n_steps''"
		// Lets not do too many loops
		if (``n_steps'' > 30) {
			stop
			local `exit_loop' = 1
		}
		

	}
	 
end
