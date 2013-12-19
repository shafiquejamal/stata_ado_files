program define renamevaluelabel

	// syntax anything(id="variable and values" name=arguments)
	syntax anything(id="original and new label name" name=labelnames)
	version 9.1
	
	// steps:
	//	1. drop the label with the new label name, if it exists
	//  2. create the new label from the old label
	//  3. apply this new label to variables with the old label
	
	di "labelnames = `labelnames'"
	
	foreach item of local labelnames {
		di `"item = `item'"'
	}
	
	tempname originallabelname 
	local `originallabelname' : word 1 of `labelnames'
	tempname newlabelname 
	local `newlabelname' : word 2 of `labelnames'

	di `"``originallabelname'', ``newlabelname''"'
	
	cap label drop ``newlabelname''
	label copy ``originallabelname'' ``newlabelname''

end
