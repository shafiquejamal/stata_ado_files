program define makelegendlabelsfromvarlabels

	// Written by Shafique Jamal (shafique.jamal@gmail.com). 25 Nov 2012
	//
	
	// Wrote it to fix an annoyance with graph bar. I want graph bar to use variable labels, not variable names, in the legend, but it won't do this if I am using a "(stat)" rather than "(asis)"
	syntax varlist, local(name local) [c(integer 30)]
	version 9.1
	
	// local charlength = 30
	
	tempname count
	local `count' = 0
	tempname labeloptions
	tempname variablelabel
	foreach var of local varlist {
		local `count' = ``count'' + 1
		local `variablelabel' : variable label `var'
		
		// It would be great to break this up at a word boundary if the length is > 34 characters
		if (length(`"``variablelabel''"') > `c') {
			tempname variablelabel_part1
			tempname variablelabel_part2
			local `variablelabel_part1' = substr(`"``variablelabel''"', 1, `c')
			local `variablelabel_part2' = substr(`"``variablelabel''"', `c' + 1, . )
			local `labeloptions' `"``labeloptions'' label(``count'' `"``variablelabel_part1''"' `"``variablelabel_part2''"') "'
		}
		else {
			local `labeloptions' `"``labeloptions'' label(``count'' `"``variablelabel''"') "'
		}
	}
	
	// di `"labeloptions: ``labeloptions''"'
	// need to return this in a local macro
	c_local `local' `"``labeloptions''"'
	

end program
