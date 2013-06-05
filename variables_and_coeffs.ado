program define variables_and_coeffs

	// syntax , Filename(string) [Round(real 1)]
	syntax using, [Round(real 1) Omitstandarderrors]
	version 9.1
	
	local N = e(N)
	if ("`round'" == "") {
		local r2 = e(r2)
	}
	else {
		local r2 = round(e(r2),`round')
	}
	
	local r2 = e(r2)
	local N = e(N)

	tempname fh
	file open `fh' `using', w replace all

	local varnames1 : coln e(b)
	local equation ""
	foreach varn of local varnames1 {
		
		cap local varlabel : variable label `varn'
		
		if (_coef[`varn'] ~= 0) {
		
			if ("`round'" == "") {
				local coef = round(_coef[`varn'])
				local se = round(_se[`varn'])
				local t = round(_coef[`varn']/_se[`varn'])
			}
			else {
				local coef = round(_coef[`varn'],`round')
				local se = round(_se[`varn'],`round')
				local t = round(_coef[`varn']/_se[`varn'],`round')
			}
		
		
			if ("`varn'" != "_cons") {
				file write `fh' `""`varn'","`varlabel'","`coef'","`t'""' _n
				if (`"`omitstandarderrors'"' == `""') {
					file write `fh' `""","","(`se')""' _n	
				}
			}
			else {
				file write `fh' `""Constant","Constant","`coef'","`t'""' _n
				if (`"`omitstandarderrors'"' == `""') {
					file write `fh' `""","","(`se')""' _n
				}
			}
		}
	}
	
	// Lets put the number of observations and the R2 at the bottom
	file write `fh' `""Number of obs","","`N'""'  _n  
	file write `fh' `""R-squared",""    ,"`r2'""' _n
	file close `fh'
	
end
