program define renamevarandvaluelabel

	// Written by Shafique Jamal (shafique.jamal@gmail.com). 25 Nov 2012

	// This program renames the variable and the value label. Usage:
	// 	renamevarandvaluelabel originalvarname newvarname
	// What it does:
	//	rename originalvarname newvarname
	// and it changes the name of the value label of originalvarname to newvarname. 
	// Just make sure that if there is already a value label named newvarname, you're ok with loosing it.
	//
	// UPDATE 12-07-2012: the option maxlength is there to limit the length of the value label name. I needed to add this because the labellist command (ssc install labellist) generates
	//	errors when the value label name is longer than 23 characters

	// syntax anything(id="variable and values" name=arguments)
	syntax anything(id="original and new label name" name=labelnames) [, MAXLength(integer 23)] 
	version 9.1
	
	// di "maxlength: `maxlength'"
	
	// steps:
	//	1. drop the label with the new label name, if it exists
	//  2. create the new label from the old label
	//  3. apply this new label to variable 
	
	// di "labelnames = `labelnames'"
	
	foreach item of local labelnames {
		// di `"item = `item'"'
	}
	
	tempname originallabelname
	tempname originalvarname 
	local `originalvarname' : word 1 of `labelnames'
	tempname newvarandlabelname 
	local `newvarandlabelname' : word 2 of `labelnames'
	tempname originalVariableLabel 
	local `originalVariableLabel' : var l ``originalvarname''
	
	// Step 1. drop the label with the new label name, if it exists. Wait, if it exists... what do we do? Quit the program
	cap label list ``newvarandlabelname''
	if (_rc == 0) {
		di `"That label (``newvarandlabelname'') already exists. You can use the command "renamevaluelabel [oldlabelname] [newlabelname] written by Shafique Jamal (shafique.jamal@gmail.com) to change that value label name." Exiting"'
		exit
	}
	
	// Step 2. create the new label from the old label. First need to get the name of the label value of the original variable name. Do this only if there is a value label attached
	local `originallabelname' : value label ``originalvarname''
	if ("``originallabelname''"~="" & "``originallabelname''"~=" ") {
	
		// di "There is an existing label"
		tempname newvarandlabelname_forlabelonly
		local `newvarandlabelname_forlabelonly' = substr(`"``newvarandlabelname''"', 1, `maxlength')
		label copy ``originallabelname'' ``newvarandlabelname_forlabelonly''
	
		// Step 3. rename the variable, then attached the new variable label
		rename ``originalvarname'' ``newvarandlabelname''
		label values ``newvarandlabelname'' ``newvarandlabelname_forlabelonly''
	}
	else { // Just rename the variable, forget about the value label, if there is no original value label 
	
		di "No existing label"
		rename ``originalvarname'' ``newvarandlabelname''
	}
	
	// lets keep the orignial variable with its value label and variable label
	clonevar ``originalvarname'' = ``newvarandlabelname''
	cap la val ``originalvarname'' ``originallabelname''
	
	// for the new variable, lets put original name of the variable in the variable label
	la var ``newvarandlabelname'' `"(``originalvarname'') ``originalVariableLabel''"'
	
end
