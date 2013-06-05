program dec2bin_3, rclass

	syntax [varlist], Base(integer) Decimal(integer) [Ndigits(integer 0)]

	// this part finds out how many digits the number to be converted will require. Return a result with the greater of ndigits and the number of digits required by the number to be converted
	tempname ndigitsfromthisnumber2 ndigits_required ndigits_result contcatenated_startright contcatenated_startleft decimal2 number_of_ones
	local `ndigitsfromthisnumber2' `decimal'
	local i=1
	while (``ndigitsfromthisnumber2'' > 0) {
		local bit`i' = mod(``ndigitsfromthisnumber2'',2^`i')==2^`=`i'-1'
		local `ndigitsfromthisnumber2'=``ndigitsfromthisnumber2''-`bit`i''*2^`=`i'-1'
		// di "bit`i'=`bit`i''"
		return scalar d`i' =  `bit`i''
		local i=`i'+1
	}
	local `ndigits_required' = `i'-1
	if (``ndigits_required'' > `ndigits') {
		local `ndigits_result' = ``ndigits_required''
	}
	else {
		local `ndigits_result' = `ndigits'
	}

	return scalar ndigits_result = ``ndigits_result''
	
	// di "------------"
	
	// this does the actual conversion to binary
	qui inbase `base' `decimal'
	local `decimal2' `decimal'

	local `contcatenated_startright' = ""
	local `contcatenated_startleft' = ""
	local `number_of_ones' = 0
	local i=1
	while (`i' <= ``ndigits_result'') {
		// di "START: decimal2=`decimal2'"
		local bit`i' = mod(``decimal2'',2^`i')==2^`=`i'-1'
		local `decimal2'=``decimal2''-`bit`i''*2^`=`i'-1'
		// di "bit`i'=`bit`i''"
		return scalar d`i' =  `bit`i''
		local `contcatenated_startleft' "``contcatenated_startleft''`bit`i''"
		local `contcatenated_startright' "`bit`i''``contcatenated_startright''"
		
		if (`bit`i''==1) {
			local `number_of_ones' = ``number_of_ones''+1
		}
		
		local i=`i'+1
	}
	
	return local contcatenated_startleft "``contcatenated_startleft''"
	return local contcatenated_startright "``contcatenated_startright''"
	return scalar number_of_ones = ``number_of_ones''
	
end





