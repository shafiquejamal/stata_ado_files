program define dataout_eval_pmt_modelscat
	
	// August 03, 2010
	syntax , Label(string) Filename(string) q(integer) [Separator(string) Append]
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
		tempname quantileHeadings
		local `quantileHeadings' ""
		forv quantile = 1/`q' {
			local `quantileHeadings' "``quantileHeadings''`separator'Q`quantile'"
		}
		file write `fh' `"Geography Covered`separator'N`separator'R2`separator'Fraction of Pop Covered`separator'Cutoff`separator'Leakage`separator'Undercoverage`separator'Targeting Accuracy`separator'Inclusion Error Rate`separator'Exclusion Error Rate``quantileHeadings''"' _n
	}
	
	local N = r(N)
	local r2 = r(r2)

	local lineout1 `""`label'"`separator'`N'`separator'`r2'"'

	// go through the return values and make the output string
	// loop over all cutoffs
	
		local cutoff = r(cutoff)
	
		local leakage = r(leakage)
		local undercoverage = r(undercoverage)
		local fractionofpop_covered = r(fraction_covered)
		local targeting_accuracy = r(targeting_accuracy)
		local inclusion_error_rate = r(inclusion_error_rate)
		local exclusion_error_rate = r(exclusion_error_rate)

		local lineout `"`lineout1'`separator'`fractionofpop_covered'`separator'`cutoff'`separator'`leakage'`separator'`undercoverage'`separator'`targeting_accuracy'`separator'`inclusion_error_rate'`separator'`exclusion_error_rate'"'
	
		// loop over number of quintiles
		forv quantile = 1/`q' {
		
			local nextelement = r(coverage_cutoff_quantile`quantile')

			local lineout `"`lineout'`separator'`nextelement'"'
	
		}
		
		file write `fh' `"`lineout'"' _n
	
		
	
	file close `fh'
	
end program

