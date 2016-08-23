program define evaluate_pmt_modelscattrain_test, rclass

	// 20 July 2013: adding the capability to base the regression coefficients on a reduced set of observations, given by the variable `trainingIndicator'

	syntax varname [using/] [if], models(string) startingCutoff(real) Target_coverage(real) poor(varname numeric) Quantilec(varname numeric) trainingIndicator(varname numeric) testingIndicator(varname numeric) [GENerate(name) generateEligible(name) modelByThisCategory(varname) TOLerance(real 0.001) step(real 5) logpline(real 0) append]
	version 10.1
	tempname cuttoffOptimizeNoDecimal exit_loop
	tempvar logpccd_hat
	
	// store the different models in local macros
	
	tempname ct levels	
	if ("`modelByThisCategory'" == "") {
		tempname modelByThisCategory
		qui gen `modelByThisCategory' = 1
		local `levels' 1
	}
	else {
		qui levelsof `modelByThisCategory', l(`levels')
	}

	tokenize "`models'", p(",")
	local `ct' = 0
	foreach level in ``levels'' {
		local `ct' = (2*`level')-1
		tempname model`level'
		local `model`level'' ```ct''' // access model for categorical value x as: ``modelX''
	}
	
	tempname cutoffOptimize
	local `cutoffOptimize' = `startingCutoff' 	// this is for looping over values of the cutoff to optimize the target coverage rate. But I will loop only over the section "combined" below, in order 
												//	to speed things up

	// ------------------ Models ------------------------------------------------------------------------------------ 
	//
	// Predict consumption for each category
	
	gen `logpccd_hat' = .
	foreach level in ``levels'' {
		tempvar trainingIndicator`level' testingIndicator`level' predicted`level'
		gen `trainingIndicator`level'' = `trainingIndicator' & (`modelByThisCategory' == `level')
		gen `testingIndicator`level''  = `testingIndicator'  & (`modelByThisCategory' == `level')
		qui xi: svy: reg `varlist' ``model`level'''  if `trainingIndicator`level'' == 1
		predict `predicted`level'' if (`modelByThisCategory' == `level')
		replace `logpccd_hat' = `predicted`level'' if `logpccd_hat' == . & `predicted`level'' != .
	}
	count if `logpccd_hat' == .
	if ("`generate'" != "") {
		gen `generate' = `logpccd_hat'
	}
	
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
			
			tempname xlimlower xlimupper ylimlower ylimupper
			local `xlimlower' = 9
			local `xlimupper' = 11
			local `ylimlower' = 10.5
			local `ylimupper' = 13
		
			tempvar  nonpoor_ineligible poor_ineligible nonpoor_eligible poor_eligible
			
			qui gen `nonpoor_eligible' = .
			qui gen `poor_ineligible' = .
			qui replace `nonpoor_eligible' = 1 if `eligible_`cuttoffOptimizeNoDecimal'' == 1 & `poor' ~= 1 & `poor' ~= . 
			qui replace `nonpoor_eligible' = 0 if (`eligible_`cuttoffOptimizeNoDecimal'' ~= 1 | `poor' == 1) 
			qui replace `poor_ineligible' = 1 if `eligible_`cuttoffOptimizeNoDecimal'' == 0 & `poor' == 1 & `poor' ~= . 
			qui replace `poor_ineligible' = 0 if (`eligible_`cuttoffOptimizeNoDecimal'' == 1 | `poor' == 0) & `poor' ~= . 
		
			qui gen `nonpoor_ineligible' =.
			replace `nonpoor_ineligible' = 1 if `poor'==0 & `eligible_`cuttoffOptimizeNoDecimal''==0 
			replace `nonpoor_ineligible' = 0 if (`poor'==1 | `eligible_`cuttoffOptimizeNoDecimal''==1) 
			qui gen `poor_eligible'  =.
			replace `poor_eligible' = 1 if `poor'==1 & `eligible_`cuttoffOptimizeNoDecimal''==1 
			replace `poor_eligible' = 0 if (`poor'==0 | `eligible_`cuttoffOptimizeNoDecimal''==0) 
		
			tempname cutoffRounded
			local `cutoffRounded' = round(``cutoffOptimize'', 0.01)
		
			twoway (scatter `logpccd_hat' `varlist' if `poor_ineligible'==1 & `testingIndicator', xline(`logpline', lcolor(0)) yline(``cutoffOptimize'') mc(red) m(x) ) /* 
			*/	(scatter `logpccd_hat' `varlist' if `nonpoor_ineligible' == 1 & `testingIndicator', mc(green) m(x)) /*
			*/	(scatter `logpccd_hat' `varlist' if `nonpoor_eligible'==1 & `testingIndicator', mc(black) m(x)) /* 
			*/	(scatter `logpccd_hat' `varlist' if `poor_eligible' == 1 & `testingIndicator', mc(blue) m(x) xlabel(``xlimlower''(1)``xlimupper'') ytitle("Predicted") ylabel(``ylimlower''(1)``ylimupper'') ysc(r(``ylimlower'' ``ylimupper'')) xsc(r(``xlimlower'' ``xlimupper'')) ) /*
			*/ , title("Cutoff ``cutoffRounded''") legend(lab(1 "Errors of Exclusion") lab(3 "Errors of Inclusion") lab(2 "Nonpoor, Ineligible") lab(4 "Poor Eligible") )

			qui pmt_eligible_train_test `eligible_`cuttoffOptimizeNoDecimal'', p(`poor') qu(`quantilec') evaluationSubset(`testingIndicator')
			return add
			return scalar cutoff = ``cutoffOptimize''
			
			local `exit_loop' = 1
			if ("`generateEligible'" != "") {
				gen `generateEligible' = `eligible_`cuttoffOptimizeNoDecimal''
			}
	
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
