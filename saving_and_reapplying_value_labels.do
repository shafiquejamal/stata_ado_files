// Save and restore value labels
// Shafique Jamal, shafique.jamal@gmail.com
// Saturday 7 May 2011

// define the path for saving temporary files
global path_for_tempfiles $temppath_2009 // I had defined "temppath_2009" earlier in another program

// This is the list of variables for which we want to save the value labels.
label dir
local list_of_valuelables = r(names)

// save the label values
foreach label_value_name of local list_of_valuelables {
	label save `' using $temppath_2009/label_value_`label_value_name', replace
}

// note the names of the label values for each variable that has a label value attached to it: need the variable name - value label correspodence
local list_of_vars_w_valuelables
foreach var of varlist  * {
	local templocal : value label `var'
	if ("`templocal'" != "") {
		local varlabel_`var' : value label `var'
		di "`var': `varlabel_`var''"
		local list_of_vars_w_valuelables "`list_of_vars_w_valuelables' `var'"
	}
}
di "`list_of_vars_w_valuelables'"

// do the collapse here

// redefine the label values
foreach label_value_name of local list {
	do $temppath_2009/label_value_`label_value_name'
}

// reattach the label values
foreach var of local list_of_vars_w_valuelables {
	label values `var' `varlabel_`var''
}
