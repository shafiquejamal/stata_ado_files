program define varsformyrelabel 

	// Get list of variables that were xi'd
	local xivars "`_dta[__xi__Vars__To__Drop__]:'"
	di `"xivars:`xivars'"'
	
	// Now just need to get list of un-xi'd variables from this list
	// Here is the first one
	local currentdummyvar : word 1 of `xivars'
	di `"currentdummyvar:`currentdummyvar'"'
	local currentunxidvar = regexr("`currentdummyvar'","_[0-9]+$","")
	di `"currentunxidvar:`currentunxidvar'"'
	local currentunxidvar = regexr("`currentunxidvar'","^_I","")
	di `"currentunxidvar:`currentunxidvar'"'
	
	local allunxidvars "`currentunxidvar'"
	di `"allunxidvars:`allunxidvars'"'
	
	// Now loop through the rest
	local count = 0
	foreach var of local xivars { 
		local count = `count' + 1
		if (`count' != 1) {
			local w : word `count' of `xivars'
			// di "w: `w'"
			
			// check whether the next xi'd var is related to the current one
			if (regexm("`w'","^_I`currentunxidvar'_[0-9]+$")) { // yes, this is part of the same family as the current _I.... variable under consideration
				// di "skip"
			}
			else { // no, it is different. add to the list
				local currentunxidvar = regexr("`w'","_[0-9]+$","")
				di `"currentdummyvar:`currentdummyvar'"'
				local currentunxidvar = regexr("`currentunxidvar'","^_I","")
				di `"currentdummyvar:`currentdummyvar'"'
				local allunxidvars "`allunxidvars' `currentunxidvar'"
				di `"allunxidvars:`allunxidvars'"'
			}		
		}
	}

	unab allunxidvars : `allunxidvars'
	di "allunixidvars: `allunxidvars'"	
	foreach var of local allunxidvars {
		myrelabel _I`var'_* `var'
	}
	
end
