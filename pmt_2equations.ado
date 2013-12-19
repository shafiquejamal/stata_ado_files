program define pmt_2equations, rclass
	
	syntax varname [if] [pw aw iw fw], eq1(varlist) eq2(varlist) Cutoffs(numlist asc min=1 max=20 >0 <=50 integer) Poor(varname numeric) Quantiles(integer) Filename(string)  [Graphme(integer -1) logpline(real 0) Usesubsamplebetas(varname numeric) Filter appendorcreate] // separateby(varname numeric) 
	version 9.1 
	marksample touse
	
	// separateby is the name of the variable which is equal to 1 for eq1 and 0 for eq2, and . Eg. eq1 is for urban, so use if urban == 1 for eq1 and if urban == 0 for eq2, because eq2 applies to rural 
	
	qui svyset
	local svyweight = r(wtype)
	local svyexp    = r(wexp) 
	// di "[`svyweight'`svyexp']"
	
	tempvar gen1 gen2 eligible Quantilec logpccd_hat
	
	pmt2 `varlist' `eq1'  [`weight'`exp'] if rural == 1, c(`cutoffs') g(`graphme') p(`poor') q(`quantiles') logpline(`logpline') gen(`gen1')
	// return list
	
	pmt2 `varlist' `eq2'  [`weight'`exp'] if rural == 0, c(`cutoffs') g(`graphme') p(`poor') q(`quantiles') logpline(`logpline') gen(`gen2')
	// return list
		
	// Combined coverage rate
	// First get predicted log consumption
	gen 		`logpccd_hat' = `gen1' if rural == 1
	replace 	`logpccd_hat' = `gen2' if rural == 0
	
	// find out the value of logpccd that corresponds to the cutoff
	_pctile `varlist' [`svyweight'`svyexp'], n(100)
	// return list
	
	local logcutoff = r(r`cutoffs')
	// di "logcutoff = `logcutoff'" 
	
	gen `eligible' = .
	// di "replace 1"
	replace `eligible' = 1 if `logpccd_hat' <  `logcutoff'  
	// di "replace 0"
	replace `eligible' = 0 if `logpccd_hat' >= `logcutoff'
	
	qui xtile `Quantilec' = `varlist' [`svyweight'`svyexp'], n(`quantiles') 
	// sum `Quantilec', d
	
	// This will generate the performance, given actual consumption, quintiles of consumption, and eligibility
	pmt_eligible `eligible' [`svyweight'`svyexp'], p(`poor') qu(Quintilec)
	return list
	return scalar fraction_covered = r(fraction_covered)
	dataout_pmt_eligible, l("All") f("$tjdir09_reports/`filename'") q(5) c(`cutoffs') `appendorcreate'
	

	// return scalar fraction_covered = 1 // r(fraction_covered)
	
end program

