program define byablesvymean, byable(recall)

	// svy mean can not be used with by. This program executes svy over the different categories of the by variable (right now, can use only one variable in the by list)
	syntax varlist [if] [using], [replace] 
	marksample touse
	
	// Prepare the file for saving, if applicable	
	if (`"`using'"'~="") {
		// get the filename
		di `""using" option was specified"'	
		di `"regexm:"'
		di regexm(`"`using'"',`"((.*)\.(.+))$"')
		if (regexm(`"`using'"',`"((.*)\.(.+))$"')) {
			local pathtofile_original 			= regexs(1)
			local pathtofile_withoutextension 	= regexs(2)
			local pathtofile_extension 			= regexs(3)
		}
		di `"pathtofile_original:`pathtofile_original'"'
		di `"pathtofile_withoutextension:`pathtofile_withoutextension'"'
		di `"pathtofile_extension:`pathtofile_extension'"'	
	} 
	else {
		di `"using option NOT specified"'
	}
		
	
		
	if _by() {
		di "_by() is true"
		// count if `touse'
		
		svy: mean `varlist' if `touse'
		tempname M themean
		matrix `M' = r(table)
		local `themean' = `M'[1,1]
		di "themean = ``themean''"

	} 
	else {
		
		di "Use this command with 'by'"
		exit
		
	}

end program
