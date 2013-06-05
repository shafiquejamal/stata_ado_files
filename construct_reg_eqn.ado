program define construct_reg_eqn, rclass

	syntax , Filename(string) [Round(real 1)]
	version 9.1

	local varnames1 : coln e(b)
	local equation ""
	local equation2 ""
	foreach varn of local varnames1 {
	
		cap local varlabel : variable label `varn'
	
		// local coef = _coef[`varn']
		if ("`round'" == "") {
			local coef = round(_coef[`varn'])
		}
		else {
			local coef = round(_coef[`varn'],`round')
		}
		if ("`varn'" != "_cons") {
			if (`coef' < 0) {
				local equation  "`equation' `coef'*`varn'"
				local equation2 "`equation2' `coef'*(`varlabel')"
			}
			else if (`coef' > 0) {
				local equation  "`equation' + `coef'*`varn'"
				local equation2 "`equation2' + `coef'*(`varlabel')"
			}
		}
		else {
			if (`coef' < 0) {
				local equation  "`equation' `coef'"
				local equation2 "`equation2' `coef'"
			}
			else if (`coef' > 0) {
				local equation  "`equation' + `coef'"
				local equation2 "`equation2' + `coef'"
			}
		}
	}

	tempname fh
	file open `fh' using "`filename'", w replace all
	file write `fh' "`equation'"  _n _n
	file write `fh' "`equation2'" _n
	file close `fh'

	return local equation `equation'
	

end
