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
	// 
	// UPDATE 12-07-2012: Best way is to call it with a long dataset like this: graph bar v, over(eligible) over(avg). Also note that I haven't tested whether this works with "if"

	// syntax varname using/ [if] [in], GCmd(string) GOptions(string asis) CATvarlist(varlist) Valuelabelsforlevels(string asis) [replace over1options(string asis) over2options(string asis) ]
	/*
	version 9.1
	marksample touse
	tempname tempmat
	tempname variablelabel
	local `variablelabel' : variable label `varlist'	
	di "variablelabel: ``variablelabel''"
	*/
	/*		
	// foreach category, find the mean
	foreach catvar of local catvarlist {
		tempfile tf_`catvar'
		
		/*
		// this is a pain: get the name of the variable's value label
		tempname tn_`catvarvaluelabel' 
		local `tn_`catvarvaluelabel'' : value label `catvar'
		label save ``tn_`catvarvaluelabel''' using `"`tf_`catvar''"', replace
		
		// UPDATE: None of this is necessary. The user will pass a list of value labels, separated by spaces, and these will be assumed to be the same for all the categorical variables specified
		//	e.g. user can pass v(0 "Qualifies" 1 "Does not Qualify"), where the categorical variables and corresponding value lables are:
		//	exempt 	: 0 "Exempt" 	1 "Non-exempt"
		//	PMT		: 0 "Eligible"	1 "Non-eligible"
		//	MBPF	: 0 "Receives"	1 "Does not receive"
		
		*/
	/*	
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
	
	// Need to get the new value labels from the valuelabels option. Actually, this is not necessary
	/*
	local labelnumber = 0
	local labels_numbers ""
	local labels_text ""
	foreach w of local valuelabelsforlevels {
		local labelnumber = `labelnumber' + 1
		if (`labelnumber'/2 ~= floor(`labelnumber'/2) ) {
			tempvar nextword 
			local `nextword' = `labelnumber' + 1 
			local labels_numbers `"`labels_numbers' `: word `labelnumber' 	of `valuelabelsforlevels''"'
			local labels_text `"`labels_text' `: word ``nextword'' 	of `valuelabelsforlevels''"'
		}
	}
	/*
	di `"v:`valuelabelsforlevels'"'
	di `"n:`labels_numbers'"'
	di `"t:`labels_text'"'
	*/
	
	/*
	tempname valueslabels
	label define `valueslabels' `valuelabelsforlevels'
	
	// I'll now make a dataset out of this with the following variables: mean of the variable; category name; category level
	// 	The latter two will be numeric, categorical variables with variable labels attached.
	preserve
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
	`gcmd' meanofvariable,  over(catvariablelevel_n, `over1options') over(catvariablelabel, `over2options') `goptions' 
	restore
	*/
end program
