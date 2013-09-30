program define taboutgraph

	// Written by Shafique Jamal (shafique.jamal@gmail.com)
	// This program requires that the second variable in varlist have a value label attached to it
	// It plots the column output of the tabout command

	syntax varlist(min=2 max=2) using/ [aweight], GCmd(string) GOptions(string asis) TAboutoptions(string asis) [replace overcategorysuboptions(string asis) overxsuboptions(string asis)]
	version 9.1
	// di `"`0'"'
	cap drop _v*
	cap ssc install lstrfun
	
	// first generate the table
	tabout `varlist' [`weight'`exp'] using `using', `replace' `taboutoptions'
	di `"tabout [`weight'`exp'] `varlist' using `using', `replace'"'
	local number_of_rows 	= r(r)
	local number_of_columns = r(c)
	return list
	
	// get the filename
	di `"regexm:"'
	di regexm(`"`using'"',`"((.*)\.(.+))$"')
	if (regexm(`"`using'"',`"((.*)\.(.+))$"')) {
		local pathtofile_original 			= regexs(1)
		local pathtofile_withoutextension 	= regexs(2)
		local pathtofile_extension 			= regexs(3)
	}
	di `"pathtofile_original:`pathtofile_original'"'
	di `"pathtofile_withoutextension:`pathtofile_withoutextension'"'
	di `"pathtofile_extension:`pathtofile_extension'"'
	// open the file and process it. 
	
	local count = 0
	tempname fhr
	tempname fhw
	tempfile tf
	file open `fhr' using `"`pathtofile_original'"', r 
	
	// ---------------------------
	// file open `fhw' using `"$WHO_KG_reports/tempfile.csv"', t write all replace
	file open `fhw' using `"`tf'"', t write all replace
	
	local count = `count' + 1

	// First line is variable label. 
	file read `fhr' line
	return list
	local count = 1
	while r(eof)==0 {
		local count = `count' + 1
		// di `"count = `count'"'
		file read `fhr' line
		
		if (`count'~=3) { // This line is units - we can throw this away
			file write `fhw' `"`line'"' _n
			// di `"`line'"'
		}
    }
		
	file close `fhr'
	file close `fhw'
	
	// We should save the value labels. Check to make sure that the label exists
	tempfile tfvaluelabels
	tempname nameofvaluelabel
	tempname variablenamewithlabel
	local `variablenamewithlabel' : word 2 of `varlist'
	local `nameofvaluelabel' : value label ``variablenamewithlabel''
	label save ``nameofvaluelabel'' using `"`tfvaluelabels'"', replace
	
	preserve
	qui insheet using `"`tf'"', t clear names
	
	// I want to restore the value levels and value labels
	do `"`tfvaluelabels'"'
	// ssc install labellist
	// levelsof ``nameofvaluelabel'', local(levels)
	labellist ``nameofvaluelabel''
	local levels = r(``nameofvaluelabel''_values)
	local labels = r(``nameofvaluelabel''_labels)
	
	save `"`pathtofile_withoutextension'_short.dta"', replace

	drop total
	drop if _n == _N
	
	local count = 0
	local count_levels = 0
	foreach var of varlist * {
		local count = `count' + 1
		
		if (`count'==1) {
			qui rename `var' x
		}
		else {
			local count_levels = `count_levels' + 1
			local level : word `count_levels' of `levels'
			qui rename `var' _v`level'
			// qui rename `var' _v`count'
			local v`level'_labelforfilename = `"`var'"'        	// used for the filename for saving graphs of individual variables
			local v`level'_varlabel : variable label _v`level' 	// used for the subtitle in the plot of individual variables.
		}
	}
	
	// COME BACK TO THIS
	// graph each y var, then all y vars
	
	foreach level of local levels {
		`gcmd' (asis) _v`level', over(x, ) `goptions' subtitle(`"`v`level'_varlabel'"')
		graph export "`pathtofile_withoutextension'_`v`level'_labelforfilename'.pdf", replace
	}
	/*
	forv x = 2/`count' {
		`gcmd' (asis) _v`x', over(x) `goptions' subtitle(`"`v`x'_varlabel'"')
		// di `"subtitle: subtitle(`"`v`x'_varlabel'"'), `v`x'_varlabel', v`x'_varlabel"'
		graph export "`pathtofile_withoutextension'_`v`x'_labelforfilename'.pdf", replace
	}
	*/
	
	// graph all yvars
	qui reshape long _v, i(x) j(category)
	// cap tostring category, replace
	label values category ``nameofvaluelabel''

	/*
	forv x = 2/`count' {
	qui replace category = `"`v`x'_varlabel'"' if category == `"`x'"'
	}
	*/
	`gcmd' (asis) _v, over(category, `overcategorysuboptions') over(x, `overxsuboptions') asyvars `goptions'
	graph export "`pathtofile_withoutextension'_allvars.pdf", replace
	save `"`pathtofile_withoutextension'_long.dta"', replace
	restore
end program
