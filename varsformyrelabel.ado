program define varsformyrelabel 

	// Written by Shafique Jamal (shafique.jamal@gmail.com), 12-07-2012
	// UPDATE 12-07-2012: Need to change how the variable name for the list of `allunxidvariables' is determined. Need to get it from the variable label, rather than the variable name
	//

	// Get list of variables that were xi'd. Use the command: char li 
	local xivars "`_dta[__xi__Vars__To__Drop__]:'"
	// We can quit if there are no xi'd vars
	if (`"`xivars'"'=="") {
		exit
	}

	// Now just need to get list of un-xi'd variables from this list
	// Here is the first one
	local currentdummyvar : word 1 of `xivars'
	// di `"currentdummyvar:`currentdummyvar'"'
	
	// This will get the full variable name
	local currentunxidvar = regexr("`: variable label `currentdummyvar''","==.*$","")
	// di `"currentunxidvar:`currentunxidvar'"'
	local allunxidvars "`currentunxidvar'"
	// di `"allunxidvars:`allunxidvars'"'
	
	// This will get the _I`var' name, without the _# suffix - I need this for the first argument to the myrelabel routine. Variable name gets shortened
	local currentunxidvarwith_I = regexr("`currentdummyvar'","_[0-9]+$","")
	// di `"currentunxidvar:`currentunxidvarwith_I'"'
	local allunxidvarswith_I "`currentunxidvarwith_I'"
	// di `"allunxidvarswith_I:`allunxidvarswith_I'"'
	
	// Now loop through the rest
	local count = 0
	foreach var of local xivars { 
		local count = `count' + 1
		if (`count' != 1) {
			local w : word `count' of `xivars'
			// di "w: `w'"
			
			// check whether the next xi'd var is related to the current one
			// if (regexm("`w'","^_I`currentunxidvar'_[0-9]+$")) { // yes, this is part of the same family as the current _I.... variable under consideration
			if (regexm("`: variable label `w''","^`currentunxidvar'==.*$")) { // yes, this is part of the same family as the current _I.... variable under consideration
				// di "skip"
			}
			else { // no, it is different. add to the list
				// this gets the full variable name
				local currentunxidvar = regexr("`: variable label `w''","==.*$","")
				// di `"currentunxidvar:`currentunxidvar'"'
				local allunxidvars "`allunxidvars' `currentunxidvar'"
				// di `"allunxidvars:`allunxidvars'"'
				
				// This gets the _Ivar name
				local currentunxidvarwith_I = regexr("`w'","_[0-9]+$","")
				// di `"currentunxidvar:`currentunxidvarwith_I'"'
				local allunxidvarswith_I "`allunxidvarswith_I'  `currentunxidvarwith_I'"
				// di `"allunxidvarswith_I:`allunxidvarswith_I'"'
			}		
		}
	}

	// di "allunixidvars: `allunxidvars'"
	// di `"allunxidvarswith_I:`allunxidvarswith_I'"'
	local count = 0	
	foreach var of local allunxidvars {
		local count = `count' + 1
		local varwith_I : word `count' of `allunxidvarswith_I'
		myrelabel `varwith_I'_* `var'
	}
	
end
