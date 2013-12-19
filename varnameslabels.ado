program define varnameslabels

	syntax varlist(min=1 ts), [Separator(string) Nolabel]
	version 9.1

	// this program prints out the variable name and its associated label

	
	if ("`separator'"=="") {
		local separator2 = "|"
	}
	else {
		local separator2 = "`separator'"
	}
	
	di "Custom Table"
	
	foreach v of varlist `varlist' {
	 	local varlabel : variable label `v'	
	 	
	 	if ("`nolabel'"=="") {
	 		di "`v'`separator2'`varlabel'"
	 	} 
	 	else {
	 		di "`v'"
	 	}
	 	
	}
	
end

