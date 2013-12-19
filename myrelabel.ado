program def myrelabel
*! NJC 1.0.0 15 July 2003
	version 7
	syntax varlist(numeric)

	tokenize `varlist'
	local nvars : word count `varlist'
	local last ``nvars''
	local vallabel : value label `last'
	if "`vallabel'" == "" {
		// di as err "`last' not labelled"
		// exit 498
	}

	local `nvars'
	local varlist "`*'"

	foreach v of local varlist {
		local varlabel : variable label `v'
		local eqs = index(`"`varlabel'"', "==")
		if `eqs' {
			local value = real(substr(`"`varlabel'"', `eqs' + 2, .))
			if `value' < . {
				if "`vallabel'" == "" {
					label var `v' `"`last'=(no label)"'
				}
				else {
					local label : label `vallabel' `value'
					label var `v' `"`last'=`label'"'
				}
			}
		}
	}

end

