program define genhhhcharacteristics

	// Written by Shafique Jamal (shafique.jamal@gmail.com).
	// For an individual level dataset (includes multiple household members, not just the household head), generates a variable indicating a characteristic of the household head
	// e.g. suppose you want to generate a new variable (hhh_male) indicating the gender of the household head, and the variable identifying the household head is "reltohead", with 1 being the head,
	// and you want to do it by hhid of course. You would use the following command:
	//	
	// genhhhcharacteristics male, b(hhid) gen(hhh_male) h(reltohead) id(1)
	//
	// The above would be the equivalent of doing the following:
	//	gen hhh_male_interm = 1 male if reltohead == 1
	//  bys hhid: egen hhh_male = max(hhh_male_interm)
	//	drop hhh_male_interm
	// And then copying the value label and a modified variable label over to the new household head variable 
	// 

	syntax varname, Byvariables(varlist) GENerate(name) Headvariable(varname) [IDofhead(integer 1) ] 
	version 9.1

	tempvar intermediaryvariable
	gen `intermediaryvariable' = `varlist' if `headvariable' == `idofhead'
	bys `byvariables': egen `generate' = max(`intermediaryvariable')
	
	// Now copy the value label over, if there is one
	tempname valuelabel
	local `valuelabel' : value label `varlist'
	if ("``valuelabel''"~="" & "``valuelabel''"~=" ") {
	
		// di "There is an existing label"
		label values `generate' ``valuelabel''
	}
	
	// Copy over also the variable label
	tempname variablelabel
	local `variablelabel' : variable label `varlist'
	label var `generate' `"``variablelabel'' (For `headvariable' == `idofhead', by `byvariables')"'
	
end program

