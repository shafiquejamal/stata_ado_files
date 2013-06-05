program define renamevaluelabel

	// Written by Shafique Jamal (shafique.jamal@gmail.com). 25 Nov 2012

	// syntax anything(id="variable and values" name=arguments)
	syntax anything(id="original and new label name" name=labelnames)
	version 9.1
	
	// steps:
	//	1. drop the label with the new label name, if it exists
	//  2. create the new label from the old label
	//  3. apply this new label to variables with the old label
	
	// di "labelnames = `labelnames'"
	
	foreach item of local labelnames {
		// di `"item = `item'"'
	}
	
	tempname originallabelname 
	local `originallabelname' : word 1 of `labelnames'
	tempname newlabelname 
	local `newlabelname' : word 2 of `labelnames'

	// di `"``originallabelname'', ``newlabelname''"'
	
	// Step 1. drop the label with the new label name, if it exists
	cap label drop ``newlabelname''
	
	// Step 2. create the new label from the old label
	label copy ``originallabelname'' ``newlabelname''
	
	// Step 3. replace value labels of variables that have the old label, with this new label
	tempname valuelabelofvariabel
	foreach var of varlist * {
		local `valuelabelofvariabel' : value label `var'
		if ("``valuelabelofvariabel''"=="``originallabelname''") {
			// di "---------------------------------"
			// d `var'
			label values `var' ``newlabelname''
			// d `var'
		}
	}
	

end
