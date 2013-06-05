program define pcre_varname

 	// 30101990
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
	//
	// 02-12-2012: go ahead and pass the full regular expression with delimiters and options in the option REgularexpression(string asis)
	// Next step: detect whether a variable or string is the first arguement
	
	// 1. generate a merge variable based on _n. This is to make sure that the newly generated variable matches up by observations with the argument variable
	
	syntax varname(string) [if] [in], GENerate(name) REgularexpression(string asis) [Perlprogramdirwithfinalslash(string asis) PAthroperlwithfinalslash(string asis) REPLacement(string asis)]
	version 9.1
	marksample touse
	// di `"`0'"'
	
	// 2. outsheet the merge variable and the argument variable into a csv file
	tempvar mergevar
	tempname _m
	tempname touse2
	tempfile tfoutsheet
	tempfile tfinsheet
	tempfile tfinsheed_dta
	gen `mergevar' = _n
	// for some reason, marksample is not working
	gen `touse2' = 0
	qui replace `touse2' = 1 `if'
	cap drop `generate'
	// this is the variable that will hold the string with subsitutions
	cap drop `generate'_*
	
	
	// count if `touse'
	// count if `touse2'
	// di `"`if'"'
	// list hhid `mergevar' `touse'
	
	// qui outsheet `mergevar' `varlist' `touse' using "tfoutsheet.csv", c replace
	qui outsheet `mergevar' `varlist' `touse' using "`tfoutsheet.csv'", c replace
	
	// check options passed
	if (`"`optionmodifiers'"'==`""') {
		local optionmodifiers `""'
	}
	
	// check for perl program directory
	if (`"`perlprogramdirwithfinalslash'"'==`""') {
		local perlprogramdirwithfinalslash "/Applications/STATA12/"
	}
	
	// 3. Perl operations. Need to supply arguments in this order: inputfilename outputfilename nameofnewvariablegenerated regularexpressionpattern regularexpressionoptions
 	// shell `pathroperlwithfinalslash'perl -v
 	// di `"shell `pathroperlwithfinalslash'perl "`perlprogramdirwithfinalslash'stataregex.pl" "`tfoutsheet.csv'" "`tfinsheet.csv'" "`generate'" `regularexpression'"'
 	qui shell `pathroperlwithfinalslash'perl "`perlprogramdirwithfinalslash'stataregex.pl" "`tfoutsheet.csv'" "`tfinsheet.csv'" "`generate'" `regularexpression' '`replacement''
	
	preserve
	qui insheet using "`tfinsheet.csv'", c clear
	sort `mergevar'
	qui save `"`tfinsheed_dta'"', replace
	restore
	
	sort `mergevar'
	qui merge 1:1 `mergevar' using `"`tfinsheed_dta'"', gen(`_m')
	qui drop `_m'
	
	foreach var of varlist `generate'* {
		cap confirm numeric var `var'
		if (_rc == 0) {
			qui replace `var' = . if `touse2' == 0
		}
		else {
			qui replace `var' = "" if `touse2' == 0
		}
	}	

end program
