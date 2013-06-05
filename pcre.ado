program define pcre

 	// 30101990
	// Written by Shafique Jamal (shafique.jamal@gmail.com), 01 Dec 2012. Use at own risk :-p
	//
	// This program allows the user to use perl compatible regular expressions on a (single) string VARIABLE (not a scalar string) for matching, obtaining captures from memory parenthesis, and
	//	subsitutions. Its not perfect... I think it supports quantifiers, it does support options/option modifiers, but it does not support named captures/groups. 
	//
	// Usage:
	//
	//	Match only:
	//		pcre SOME_STRING_VARIABLE, re("/^(\d)(\w)/i") gen(NEW_VARIABLE_TO_BE_GENERATED) pa("/usr/local/ActivePerl-5.16/bin/")
	//  Substitution:
	//		pcre SOME_STRING_VARIABLE, re("/^(\d)(\w)/gi") gen(NEW_VARIABLE_TO_BE_GENERATED) pa("/usr/local/ActivePerl-5.16/bin/") repl("firstone_$1_secondone_$2")
	//
	// Note:
	//
	//	1. The arguement for re() should be a regular expression enclosed in double quotes. You can use only the forward slash for a delimiter. Named captures/groups don't work yet (I can't 
	//		figure out why. Any ideas?)
	//  2. The arguement for repl() should be the replacement part of s//THIS_PART/. It should be enclosed in double quotes. Do NOT include the forward slashes or any delimiters. 
	//		Option modifiers do NOT go here. You can use backreferences $1, $2, etc. but NOT named groups/named captures (i.e. you can't use \g{1}, \g{name}, etc. The \g{} notation doesn't work at all).  
	//  3. You can specify the path to your perl installation in pa() (Be sure to include the trailing forward slash). If you don't, it will use whatever version of perl is accessible from the command line in a terminal in whatever path this
	//		is run from.
	//  4. You should specify the path of the perl script that this program calls: stataregex.pl. You can download this from my blog: shafiquejamal.blogspot.com 
	//		The default is the /Applications/STATA12/ directory. Be sure to include the trailing forward slash.  
	//	5. This will generate a binary/dummy variable the match was a success, and variables prefixed by this same variable name with _1, _2, _3 ... , _16 appended to store the named captures/groups. 
	//		It will also store (NEW_VAR_NAME)_s to store the new string with the substitution
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
	//
	//
	//
	// 1. generate a merge variable based on _n. This is to make sure that the newly generated variable matches up by observations with the argument variable
	
	syntax varname(string) [if], GENerate(name) REgularexpression(string asis) [Perlprogramdirwithfinalslash(string asis) PAthroperlwithfinalslash(string asis) REPLacement(string asis)]
	version 9.1
	marksample touse, strok
	// di `"`0'"'
	
	// 2. outsheet the merge variable and the argument variable into a csv file
	tempvar mergevar
	tempname _m
	// tempname touse2
	tempfile tfoutsheet
	tempfile tfinsheet
	tempfile tfinsheed_dta
	gen `mergevar' = _n
	// for some reason, marksample is not working
	// gen `touse2' = 0
	// qui replace `touse2' = 1 `if'
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
			qui replace `var' = . if `touse' == 0
		}
		else {
			qui replace `var' = "" if `touse' == 0
		}
	}	

end program
