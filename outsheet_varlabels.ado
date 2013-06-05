// This ado file is a wrapper for the outsheet stata command that allows one to put the variable labels instead of the variable names on the first line of the file.

program define outsheet_varlabels 

	syntax [varlist] using/ [,Comma DELIMiter(string) NONames NOLabel NOQuote replace VARLabels]  
	
	// if no varlist, that means outsheet all variables
	if ("`varlist'"=="") {
		local varlist "*"
	} 
	// Lets make sure that the delimiter is passed on to the outsheet command correctly. At the same time, I need the delimiter without quotes for the first line that I will write for the heading. 
	if (`"`delimiter'"'~="") {
		local delimiterchar = `"`delimiter'"'
		local delimiter `"delimiter("`delimiter'")"'
	} 
	else {
		local delimiterchar = `","'
	}
	// di `"new delimiter macro: `delimiter'"'
	// di `"delimiterchar = `delimiterchar'"'
	// Did the user say "noquote"? If not, then make sure the variable labels line below is double quoted
	if (`"`noquote'"'~="noquote") {
		local quote = `"""'
		// di `"use quotes: `quote'"'
	}
	if ("`varlabels'" == "") { // If user did not specify the variable labels option, then just call outsheet as is
		outsheet `varlist' using `"`using'"', `comma' `delimiter' `nonames' `nolabel' `noquote' `replace'
	} 
	else { // Otherwise, write the variable lables instead of the variable names. Chose line1 to be variable labels
		
		tempfile tempoutsheetfile
		qui outsheet `varlist' using `"`tempoutsheetfile'"', `comma' `delimiter' `nonames' `nolabel' `noquotes' `replace'
		
		// Here, construct the first line
		local count = 0
		foreach var of varlist `varlist' {
			local varlabel : variable label `var'
			if (`"`varlabel'"'=="") {  // What if there no variable label for the label? Then use the variable name instead
				local varlabel `"`var'"'
			}
			// di "var: `var'"
			local count = `count' + 1
			if (`count'==1) { // Don't want a comma before the first item.
				local line1heading `"`quote'`varlabel'`quote'"'
				// di `"`quote'`varlabel'`quote'"'
			}
			else {
				local line1heading `"`line1heading'`delimiterchar'`quote'`varlabel'`quote'"'
				// di `"`line1heading'`delimiterchar'`quote'`varlabel'`quote'"'
			}
		}
		// di `"`line1heading'"'
		// di ""
		
		/* // This method does not work. It overwrites, rather than inserts
		tempname fht
		file open  `fht' using `"`using'"', read write t all
		file seek  `fht' tof
		file write `fht' _n `"`line1heading'"' _n
		file close `fht'
		*/
		
		// Try open tempoutsheetfile as read, the final file as write with the line1heading as the first line
		// This is the final file
		tempname fh_write
		file open `fh_write' using `"`using'"', t write all replace
		file write `fh_write' `"`line1heading'"' _n
		
		// Read from this and put in the final file
		tempname fh_read
		file open `fh_read' using `"`tempoutsheetfile'"', t read 		
		
		file read `fh_read' readfileline
		local count = 0
		while r(eof)==0 {
			local count = `count' + 1
			if (`count'~=1) {
				file write `fh_write' `"`readfileline'"' _n
			}
			file read `fh_read' readfileline
        }
		
		file close `fh_write'
		file close `fh_read'		
		
	}
	
	// di `"sytnax: `varlist' `using', `comma' `delimiter' `nonames' `nolabel' `noquotes' `replace'"'
end
