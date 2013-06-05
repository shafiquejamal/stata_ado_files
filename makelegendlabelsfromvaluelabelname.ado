program define makelegendlabelsfromvallabn

	// Written by Shafique Jamal (shafique.jamal@gmail.com). 25 Nov 2012
	//
	
	// Wrote it to fix an annoyance with graph bar. I want graph bar to use variable labels, not variable names, in the legend, but it won't do this if I am using a "(stat)" rather than "(asis)"
	syntax , local(name local) valuelabelname(string asis) [c(integer 30)]
	version 9.1
	
	// local charlength = 30
	
	tempname count
	local `count' = 0
	tempname labeloptions
	tempname valuelabels
	
	labellist _all, labels
	local `valuelabels' = r(catn_labels) 
	
	foreach valuelabel of local `valuelabels' {
		local `count' = ``count'' + 1
		
		// It would be great to break this up at a word boundary if the length is > 34 characters
		if (length(`"``valuelabel''"') > `c') {
			tempname valuelabel_part1
			tempname valuelabel_part2
			tempname valuelabel_tochange
			tempname positionofspace
			tempname positionofspace_prev
			tempname exitwhileloop
			local `exitwhileloop'   = 0
			local `positionofspace' = 0
			local `variablelabel_tochange' `"``variablelabel''"'
			while (``exitwhileloop'' == 0) {
			
				local `positionofspace' = strpos(`"``valuelabel_tochange''"', " ")
				if (``positionofspace'' >= `c' | ``positionofspace''==0) {
					local `exitwhileloop'   = 1
				} 
				else {
					local `positionofspace_prev' = ``positionofspace''
					local `valuelabel_tochange' = subinstr(`"``valuelabel_tochange''"'," ",".",1)
				}
			
			} 
			
			local `valuelabel_part1' = substr(`"``valuelabel''"', 1, ``positionofspace_prev'')
			local `valuelabel_part2' = substr(`"``valuelabel''"',    ``positionofspace_prev'' + 1, . )
			local `labeloptions' `"``labeloptions'' label(``count'' `"``valuelabel_part1''"' `"``valuelabel_part2''"') "'
		}
		else {
			local `labeloptions' `"``labeloptions'' label(``count'' `"``valuelabel''"') "'
		}
	}
	
	// di `"labeloptions: ``labeloptions''"'
	// need to return this in a local macro
	c_local `local' `"``labeloptions''"'
	

end program
