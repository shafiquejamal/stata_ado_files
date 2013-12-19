program define taboutgraph

	syntax varlist using/ [aweight], GCmd(string) GOptions(string) TAboutoptions(string asis) [replace]
	version 9.1
	// di `"`0'"'
	cap drop _v*
	cap ssc install lstrfun
	
	// first generate the table
	tabout `varlist' [`weight'`exp'] using `using', `replace' `taboutoptions'
	di `"tabout [`weight'`exp'] `varlist' using `using', `replace'"'
	local number_of_rows 	= r(r)
	local number_of_columns = r(c)
	return list
	
	// get the filename
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
	// open the file and process it. 
	
	local count = 0
	tempname fhr
	tempname fhw
	tempfile tf
	file open `fhr' using `"`pathtofile_original'"', r 
	
	// ---------------------------
	// file open `fhw' using `"$WHO_KG_reports/tempfile.csv"', t write all replace
	file open `fhw' using `"`tf'"', t write all replace
	
	local count = `count' + 1

	// First line is variable label. 
	file read `fhr' line
	return list
	local count = 1
	while r(eof)==0 {
		local count = `count' + 1
		// di `"count = `count'"'
		file read `fhr' line
		
		if (`count'~=3) { // This line is units - we can throw this away
			file write `fhw' `"`line'"' _n
			// di `"`line'"'
		}
    }
		
	file close `fhr'
	file close `fhw'
	
	// We should save the value labels
	
	preserve
	qui insheet using `"`tf'"', t clear names
	save `"`pathtofile_withoutextension'.dta"', replace

	drop total
	drop if _n == _N
	
	local count = 0
	foreach var of varlist * {
		local count = `count' + 1
		// di `"var: `var'"'
		
		if (`count'==1) {
			qui rename `var' x
		}
		else {
			/* tempvar v`count'
			rename `var' `v`count''
			di "v_count = v`count'"
			local v`count'_labelforfilename = `"`var'"'
			local v`count'_varlabel : variable label `v`count''
			*/
			qui rename `var' _v`count'
			local v`count'_labelforfilename = `"`var'"'
			local v`count'_varlabel : variable label _v`count'
		}
	}
	
	// graph each y var, then all y vars
	forv x = 2/`count' {
		`gcmd' (asis) _v`x', over(x) `goptions' subtitle(`"`v`x'_varlabel'"')
		// di `"subtitle: subtitle(`"`v`x'_varlabel'"'), `v`x'_varlabel', v`x'_varlabel"'
		graph export "`pathtofile_withoutextension'_`v`x'_labelforfilename'.pdf", replace
		// local over = `"`over' over(`v`x'')"'
	}
	// graph all yvars

	qui reshape long _v, i(x) j(category)
	cap tostring category, replace
	forv x = 2/`count' {
		qui replace category = `"`v`x'_varlabel'"' if category == `"`x'"'
	}
	`gcmd' (asis) _v, over(category) over(x) asyvars `goptions'
	graph export "`pathtofile_withoutextension'_allvars.pdf", replace

	restore
end program
