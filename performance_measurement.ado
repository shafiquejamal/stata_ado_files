program define performance_measurement, rclass

	syntax varname [if] [pw aw iw fw], [groupOfInterest(varname numeric) dataSubsetIndicator(varname numeric)]
	
	version 9.1 
	marksample touse
	
	if ( "`dataSubsetIndicator'"=="") {
		tempvar dataSubsetIndicator
		qui gen `dataSubsetIndicator' = 1
	} 
	
	if ( "`groupOfInterest'"=="") {
		tempvar groupOfInterest
		qui gen `groupOfInterest' = 1
	}
		
	qui count if `groupOfInterest' == 1 & `touse' & `dataSubsetIndicator'
	return list
	if (r(N) != 0) {
		svy: mean `varlist' if `groupOfInterest' == 1 & `touse' & `dataSubsetIndicator'
		if (_rc ~= 0) {
			local performanceMeasure = .
		}
		else {
			local performanceMeasure = _coef[`varlist']
		}
	}
	else {
		local performanceMeasure       = .
	}
	
	return scalar performanceMeasure = `performanceMeasure'

end program
