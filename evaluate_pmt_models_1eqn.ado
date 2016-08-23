program define evaluate_pmt_models_1eqn

	// 20 July 2013: adding the capability to base the regression coefficients on a reduced set of observations, given by the variable `trainingIndicator'

	syntax varname [using/] [if], model(string) CABsolute(integer) Target_coverage(real) Poorest20(varname) Quantilec(varname) logpline(real) [TOLerance(real 0.001) step(integer 5) trainingIndicator(varname numeric) append]
	version 10.1
	tempname equation logcutoff cabsolute2 explogcutoff exit_loop
	tempvar logpccd_hat
	
	// 9 May 2016
	// regresses varname on model, and predict varname_hat. Evaluates the performance on the training set. Need to 
	
	qui svyset	local svyweight = r(wtype)	local svyexp    = r(wexp) 	di "[`svyweight'`svyexp']"
	
	// di `"append=`append'"'
	
	tempname cabsolute_loop
	local `cabsolute_loop' = `cabsolute' 	// this is for looping over values of the cutoff to optimize the target coverage rate. But I will loop only over the section "combined" below, in order 
    										//	to speed things up

	// ------------------ Model ------------------------------------------------------------------------------------ 
	
	// di `"trainingIndicator=`trainingIndicator'"'
	if (`"`trainingIndicator'"' == "") {
		di `"trainingIndicator not specified"'
		tempvar trainingIndicator
		gen `trainingIndicator' = 1
	}
	else {
		di `"trainingIndicator=`trainingIndicator'"'
	}
	// sum `trainingIndicator' [aw`svyexp']
	// di `"if=`if'"'
	
	qui xi: svy: reg `varlist' `model'  if `trainingIndicator'==1	// varlist is varname above
	varsformyrelabel // This program relabels vars that are created by xi. The default label is something like "roof_material=3", and this code would change that to "roof_material=slate" for example
	
	qui cap drop `logpccd_hat'
	qui predict `logpccd_hat' `if' // if e(sample)  // I took out the "if e(sample)" because I want to predict for all observations, not just those on which the regression coefficients are based
	
	// count if `logpccd_hat'==.
	
	// ------------------------------------------- Performance of Model ------------------------------------------- 

	tempname fraction_covered_loop fraction_covered cabsolute_tried count y1 y2 x1 x2 last_word
	local `count' = 0
	local `exit_loop' = 0
	while (``exit_loop'' == 0) {
	
		local `count' = ``count'' + 1
	
		local `logcutoff' = ln(``cabsolute_loop'')
		local `explogcutoff' = exp(``logcutoff'')
		
		// get rid of decimal in the name of variable
		local `cabsolute2' = round(``cabsolute_loop'')
		
		tempvar eligible_`cabsolute2'		qui cap drop `eligible_`cabsolute2''		qui gen `eligible_`cabsolute2'' = .		qui replace `eligible_`cabsolute2'' = 1 if `logpccd_hat' <  ``logcutoff'' & `logpccd_hat' ~= .		qui replace `eligible_`cabsolute2'' = 0 if `logpccd_hat' >= ``logcutoff'' & `logpccd_hat' ~= .
			
		qui pmt_eligible `eligible_`cabsolute2'' [`svyweight'`svyexp'], p(`poorest20') qu(`quantilec')
		local `fraction_covered' = r(fraction_covered)
		// return list
		// di ( r(coverage_cutoff_quantile1)+r(coverage_cutoff_quantile2)+r(coverage_cutoff_quantile3)+r(coverage_cutoff_quantile4)+r(coverage_cutoff_quantile5) )*0.20
		// di r(fraction_covered)
		
		// calculate next cutoff
		if (``count'' ~= 1) {
			local `last_word' = ``count'' - 1
			local `x2' = ``cabsolute_loop''										// This is the current cutoff being tried
			local `x1' : word ``last_word'' of ``cabsolute_tried'' 				// This is the previous cutoff tried
			local `y2' = ``fraction_covered''									// The current fraction covered
			local `y1' : word ``last_word'' of ``fraction_covered_loop''		// The current previous covered
			
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
			// di `"count=``count'' step=`step' cabsolute_loop=``cabsolute_loop'' fraction_covered=``fraction_covered''"'
		}
		else {
			if (`r(fraction_covered)' > `target_coverage' + `tolerance') {
				// di `"count=``step'' step=`step'"'
				local step = -1*`step'
				// di `"count=``count'' step=`step'"'
			}
		}
		
		// Conditions under which to write the data to file and exit the loop: coverage hasn't changed; same threshold is being tried; more than 10 iterations; coverage is within tolerance of target
		if ((`step'==.) | (`: list `cabsolute_loop' in local `cabsolute_tried'') | (``count'' > 30) | ((`r(fraction_covered)' > (`target_coverage' - `tolerance')) & (`r(fraction_covered)' < (`target_coverage' + `tolerance'))) ) {

			qui xi: pmt2 `varlist' `model' [`svyweight'`svyexp'] , cab(``cabsolute_loop'')  p(`poorest20') quantilec(`quantilec') logpline(`logpline') u(`trainingIndicator') graphme(``cabsolute_loop'')  
			varsformyrelabel // again, relabel the categorical variables so that humans can understand them without having to look anything up.
			dataout_pmt2 , l("Model (`: word count `model''):`model'") c(``cabsolute_loop'') f("`using'.csv") q(5) `append' // This just outputs the results from the r values
			
			// combined
			qui pmt_eligible `eligible_`cabsolute2'' [`svyweight'`svyexp'], p(`poorest20') qu(`quantilec')
			dataout_pmt_eligible, l("Combined") f("`using'.csv") q(5) c(``cabsolute_loop'') a
			
			local `exit_loop' = 1
			exit
		}
		
		local `cabsolute_tried' ``cabsolute_tried'' ``cabsolute_loop''
		local `fraction_covered_loop' ``fraction_covered_loop'' ``fraction_covered''
		
		if ((`r(fraction_covered)' < `target_coverage' - `tolerance') | (`r(fraction_covered)' > `target_coverage' + `tolerance')) {
			local `cabsolute_loop' = ``cabsolute_loop'' + `step'
		}
		else {
			stop
			local `exit_loop' = 1
		}
		
		// Lets not do too many loops
		/*
		if (``count'' > 10) {
			stop
			local `exit_loop' = 1
		}
		*/

	}
	 
end
