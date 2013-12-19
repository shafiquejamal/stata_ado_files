program define overlappingcatgraphmean

	// Written by Shafique Jamal (shafique.jamal@gmail.com). 27 Nov 2012
	// I want to plot the mean of a variable over categorical values on the same plot. Of course, these categorical variables will not be mutually exclusive between them (though the are within them)
	// "using" should specify a .dta file - this program will save a dataset
	// doesn't take weights - uses svy mean to calculate the mean
	//
	// You call it like this:
	//
	// overlappingcatgraphmean varname using "filename.dta", gc(graph bar (asis)) go(over(catvariablelabel, [over_subopts]) over(catvariablelevel, [over_subopts]) asc title("My Title") ...) catvarlist(categoricalvar1 categoricalvar2) replace
	// 	
	// Note that: 
	// 1. 'catvariablelabel', 'catvariablelevel_n' 'catvariablelevel' must be entered exactly as is (without the quotes) - these are names of variables that the program creates
	// 2. the order in which you enter the over() options is up to you.

	syntax varname using/ , GCmd(string) GOptions(string asis) CATvarlist(varlist) [replace]
	// di `"goptions: `goptions '"'
	// exit
	version 9.1
	marksample touse
	tempname tempmat
	tempname variablelabel
	local `variablelabel' : variable label `varlist'	
	di "variablelabel: ``variablelabel''"
			
	// foreach category, find the mean
	foreach catvar of local catvarlist {
		tempfile tf_`catvar'
		
		/*
		// this is a pain: get the name of the variable's value label
		tempname tn_`catvarvaluelabel' 
		local `tn_`catvarvaluelabel'' : value label `catvar'
		label save ``tn_`catvarvaluelabel''' using `"`tf_`catvar''"', replace
		*/
		
		di "cat = `catvar'"
		tempname catvarlabel_`catvar'
		local `catvarlabel_`catvar'': variable label `catvar'
		tempname levels_`catvar'
		levelsof `catvar', local(`levels_`catvar'')
		foreach level of local `levels_`catvar'' {
			svy: mean `varlist' if `catvar' == `level' & `touse'
			matrix `tempmat' = r(table)
			tempname mean_`catvar'_`level'
			local `mean_`catvar'_`level'' = `tempmat'[1,1]
			tempname vl`catvar'_`level'
			local `vl`catvar'_`level'' : label (`catvar') `level' 
			// di "Mean of var: ``mean_`catvar'_`level'''"
		}
	}
	
	// I'll now make a dataset out of this with the following variables: mean of the variable; category name; category level
	// 	The latter two will be numeric, categorical variables with variable labels attached.
	// preserve
	clear
	gen meanofvariable = .
	label var meanofvariable `"``variablelabel''"'
	gen catvariablelabel = ""
	gen catvariablelevel = ""
	gen catvariablelevel_n = .
	tempname count
	local `count' = 0
	foreach catvar of local catvarlist {
		// do `"`tf_`catvar''"'
		di "cat = `catvar'"
		foreach level of local `levels_`catvar'' {
			local `count' = ``count'' + 1
			set obs ``count''
			replace meanofvariable = ``mean_`catvar'_`level''' in ``count''
			replace catvariablelabel = `"``catvarlabel_`catvar'''"' in ``count''
			replace catvariablelevel_n = `level' in ``count''
			replace catvariablelevel = `"``vl`catvar'_`level'''"' in ``count''
			// di "Mean of var: ``mean_`catvar'_`level'''"
		}
	}
	save `"`using'"', `replace'
	`gcmd' meanofvariable,  `goptions' 
	stop
	restore
	
	
	
end program
