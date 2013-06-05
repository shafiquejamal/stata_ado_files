program define megaif

	// By Shafique Jamal
	// e.g. 
	// sysuse auto, clear
	// megaif 0 1, v(foreign) c(drop) e(~=) // this will drop all the observations. Just for illustrative purposes to show how the command could be used
	// another e.g.
	// The command:
	//	megaif 14 15 16 17 18 19 20 21 22, c(gen priv1 = 1) var(income_type2)
	// would execute the following command:
	// 	gen priv1 = 1 if (income_type2 == "14" | income_type2 == "15" | income_type2 == "16" | income_type2 == "17" | income_type2 == "18" | income_type2 == "19" | income_type2 == "20" | income_type2 == "21" | income_type2 == "22") 


	syntax anything(id="variable and values" name=arguments), Var(varname) Cmd(string) [Equality(string) Separator(string)]
	
	// The default is equality
	if ("`equality'" == "") {
		local equality "=="
	}
	
	if ("`separator'" == "") {
		local separator " | "
	}
	else {
		local separator " `separator' "
	}
	
	cap confirm numeric variable `var'
	if (_rc == 0) { // variable is numeric
		local numericvar = 1
	} 
	else {
		local numericvar = 0
	}
	// di "numericvar = `numericvar'"
	
	local count = 0
	local orcondition ""
	foreach w of local arguments {
		local count = `count' + 1

		// di `"w = `w'"'
		if (`numericvar' == 0) {
			local orcondition `"`orcondition'`orseparator'`var' `equality' "`w'""'
		}
		else {
			local orcondition `"`orcondition'`orseparator'`var' `equality' `w'"'
		}
		local orseparator "`separator'"
	}
	
	// di `"orcondition = `orcondition'"'
	di `"cmd to execute: `cmd' if (`orcondition') "'
	// set trace on
	// set traced 1
	`cmd' if (`orcondition')
	set trace off

end


