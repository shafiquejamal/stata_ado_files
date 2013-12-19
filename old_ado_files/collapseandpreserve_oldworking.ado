program define collapseandpreserve

	// Written by Shafique Jamal (shafique.jamal@gmail.com).
	// This will collapse the dataset and preserve the variable and value labels
	
	syntax anything(id="variable and values" name=arguments equalok), by(string asis)
	version 9.1
	
	// save all the value labels
	tempfile tf
	label save using `"`tf'"', replace
	
	// get the list of variables to be collapse, and keep track of the value label - variable correspondence 
	tempname listofvars
	tempname listofvaluelabels
	tempname valuelabelname
	tempname stat
	local `stat' "(mean)"
	foreach a of local arguments {
		di `"word: `a'"'
		if (regexm(`"`a'"',"^\(.*\)$")) { // if there is something like (first), (mean), etc.
			local `stat' = `"`a'"'	
		} 
		else { // This is a variable. Store the associated variable label and value label name
			local `listofvars'   `"``listofvars'' `a'"'
			local `valuelabelname' : value label `a'
			tempname vl_`a'
			local `vl_`a'' : variable label `a'
			local `vl_`a'' `"``stat'' ``vl_`a'''"'
			if (`"``vl_`a'''"' == `""') {
				local `vl_`a'' `"``stat'' `a'"'
			}
			if (`"``valuelabelname''"' == `""') { // variable has no value label
				local `listofvaluelabels' `"``listofvaluelabels'' ."'
			}
			else {
				local `listofvaluelabels' `"``listofvaluelabels'' ``valuelabelname''"'
			}
		}
	}
	
	collapse `arguments', by(`by')
	// macro list
	
	// retrieve the valuelabels
	qui do `"`tf'"'
	
	// reapply the variable labels and the value labels
	tempname count
	local `count' = 0
	foreach var of local `listofvars' {
	
		// reapply the variable labels
		local `count' = ``count'' + 1
		label var `var' `"``vl_`var'''"'
		
		// reapply the value labels
		local `valuelabelname' : word ``count'' of ``listofvaluelabels''
		if (`"``valuelabelname''"' != `"."') {
			label values `var' ``valuelabelname''
		}
	}
end program
