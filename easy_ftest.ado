
// this routine does f-tests on all xi expanded variables

program define easy_ftest

	local xivars "`_dta[__xi__Vars__To__Drop__]:'"
	local word1 : word 1 of `xivars'
	local pattern = regexr("`word1'","_[0-9]+$","_")
	// di "word1 = `word1'"
	// di "pattern = `pattern'"
	local ftestvars1 "`word1'"
	local count = 0
	local ftestcount 1
	foreach var of local xivars { 
		local count = `count' + 1
		if (`count' != 1) {
			local w : word `count' of `xivars'
			// di "w: `w'"
			// check to see whether the next variable is to be included in this list of f-test variables
			if (regexm("`w'","^`pattern'[0-9]+$")) { // there is a match - add this to this list of ftest variables
				// di "pattern match!"
				local ftestvars`ftestcount' "`ftestvars`ftestcount'' `w'"
				// di "ftestvars`ftestcount' : `ftestvars`ftestcount''"
			}	
			else { // no match, create a new list of f-test variables, add this variable to it as the first element, and replace the pattern
				local ftestcount = `ftestcount' + 1
				local ftestvars`ftestcount' "`w'"
				local pattern = regexr("`w'","_[0-9]+$","_")
			}
		}
	}
	
	forv k = 1/`ftestcount' { // Do all the ftest
		// di "ftestvars`k' : `ftestvars`k''"
		// return local ftestvars`k' `ftestvars`k''
		test `ftestvars`k''
	}
	// return scalar N = `ftestcount'

end
