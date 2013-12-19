program define dataout_pmt2
	
	// August 03, 2010
	syntax , Label(string) Filename(string) q(integer) Cutoffs(numlist) [Separator(string) Append]
	version 9.1
	
	tempname fh
	
	// make sure the label has something
	if ("`label'" == "") { 
		local label  " "
	}
	
	if ("`separator'" == "") { 
		local separator  ","
	}
	
	if ("`append'"=="append") {
		file open `fh' using `"`filename'"', w append all
		// di "append to exisiting file"
	}
	else {
		// di "create new file"
		file open `fh' using `"`filename'"', w replace all
		file write `fh' `"Geography Covered`separator'N`separator'R2`separator'Fraction Covered`separator'Cutoff`separator'Leakage`separator'Undercoverage`separator'Targeting Accuracy`separator'Inclusion Error Rate`separator'Exclusion Error Rate`separator'Q1`separator'Q2`separator'Q3`separator'Q4`separator'Q5"' _n
	}
	
	local N = r(N)
	local r2 = r(r2)

	local lineout1 `""`label'"`separator'`N'`separator'`r2'"'

	// go through the return values and make the output string
	// loop over all cutoffs
	foreach cutoff of numlist `cutoffs' {
	
		local cutoff2 = round(`cutoff')
	
		local leakage = r(leakage_`cutoff2')
		local undercoverage = r(undercoverage_`cutoff2')
		local percentofpop_covered = r(percentofpop_covered_`cutoff2')
		local targeting_accuracy = r(targeting_accuracy2_`cutoff2')
		local inclusion_error_rate = r(inclusion_error_rate_`cutoff2')
		local exclusion_error_rate = r(exclusion_error_rate_`cutoff2')

		local lineout `"`lineout1'`separator'`percentofpop_covered'`separator'`cutoff'`separator'`leakage'`separator'`undercoverage'`separator'`targeting_accuracy'`separator'`inclusion_error_rate'`separator'`exclusion_error_rate'"'
	
		// loop over number of quintiles
		forv quantile = 1/`q' {
		
			local nextelement = r(coverage_cutoff`cutoff2'_quantile`quantile')

			local lineout `"`lineout'`separator'`nextelement'"'
	
		}
		
		file write `fh' `"`lineout'"' _n
	
	}
		
	
	file close `fh'
	
end program

