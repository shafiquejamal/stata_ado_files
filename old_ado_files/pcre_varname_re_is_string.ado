program define pcre_varname_rescalar

	syntax varname(string), REgularexpression(string asis) GENerate(name) [Optionmodifiers(string asis)]
	version 10.1
	
	// Written by Shafique Jamal (shafique.jamal@gmail.com), 01 Dec 2012. Use at own risk :-p
	//
	// This program allows the user to use perl compatible regular expressions on a (single) string VARIABLE (not a scalar string) for matching, obtaining captures from memory parenthesis, and
	//	subsitutions. 
	//
	// Steps:
	// 1. generate a merge variable based on _n. This is to make sure that the newly generated variable matches up by observations with the argument variable
	// 2. outsheet the merge variable and the argument variable into a csv file
	// 3. read the file into memory using perl
	// 4. perform the reg exp mach querry on each observation. Store result (0 or 1) in an array, whose index is the observation number as given in the merge variable
	// 5. save a new datafile, with the orignal merge var, and the match results variable, with the variable names in the headings
	// 6. merge this 
	
	// 1. generate a merge variable based on _n. This is to make sure that the newly generated variable matches up by observations with the argument variable
	// 2. outsheet the merge variable and the argument variable into a csv file
	tempvar mergevar
	tempname _m
	tempfile tfoutsheet
	tempfile tfinsheet
	tempfile tfinsheed_dta
	gen `mergevar' = _n
	cap drop `generate'
	
	// outsheet `mergevar' `varlist' using `tfoutsheet', c replace
	qui outsheet `mergevar' `varlist' using "`tfoutsheet.csv'", c replace
	
	// check options passed
	if (`"`optionmodifiers'"'==`""') {
		local optionmodifiers `""'
	}
	
	// 3. Perl operations. Need to supply arguments in this order: inputfilename outputfilename nameofnewvariablegenerated regularexpressionpattern regularexpressionoptions
	// shell perl "/Applications/STATA12/stataregex_01-12-2012b.pl" "`tfoutsheet'" "`tfinsheet'" "`generate'" `regularexpression' "`options'"
	qui shell perl "/Applications/STATA12/stataregex_01-12-2012b.pl" "`tfoutsheet.csv'" "tfinsheet.csv" "`generate'" `regularexpression' "`optionmodifiers'"

	preserve
	qui insheet using "tfinsheet.csv", c clear
	sort `mergevar'
	qui save `"`tfinsheed_dta'"', replace
	restore
	
	sort `mergevar'
	qui merge 1:1 `mergevar' using `"`tfinsheed_dta'"', gen(`_m')
	qui drop `_m'

end program
