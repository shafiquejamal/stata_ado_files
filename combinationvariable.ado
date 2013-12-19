program define combinationvariable, rclass

	// This program generates a new categorical variable from two distinct categorical variable that covers all combinations of categories of the two variables
	
	syntax varlist(min=2 max=2) [if] [aw], Gen(string) 
		
	qui gen `gen' = .
	local l1: variable label `1'
	local l2: variable label `2'
	label var `gen' "`l1' and `l2'"

	// label define `gen' 0 ""
	
	// loop over all levels of each categorical variable `1' and `2'
	qui levelsof `1', local(l1)
	qui levelsof `2', local(l2)
	local valuelabelname1 : value label `1'
	// di "`valuelabelname1'"
	local valuelabelname2 : value label `2'
	// di "`valuelabelname2'"
	
	qui tab `2'
	// return list
	local max2 = r(r)
	
	local count1 = 0
	foreach loop1 of local l1 {
		
		local count1 = `count1' + 1
		local valuelabel1 : label `valuelabelname1' `loop1'
		// di "1: `valuelable1'"
		
		local count2 = 0
		foreach loop2 of local l2 {
		
			local count2 = `count2' + 1
			
			// create category numbers for the new variable
			local catnum = `max2'*(`count1'-1)+`count2'
			qui replace `gen' = `catnum' if `1'==`loop1' & `2'==`loop2'
			
			// create a label for this category
			local valuelabel2 : label `valuelabelname2' `loop2'
			// di "2: `valuelable2'"
			label define `gen' `catnum' " `valuelabel1' & `valuelabel2' ", add
			
		}
		
	}
	
	label values `gen' `gen'
end
