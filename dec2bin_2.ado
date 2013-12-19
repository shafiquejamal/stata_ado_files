program dec2bin_2, rclass

	syntax [varlist], Base(integer) Decimal(integer) Ndigitsfromthisnumber(integer)

	// this part finds out how many digits to use: it will be the number of digits in the binary conversion of Ndigitsfromthisnumber
	local ndigitsfromthisnumber2 `ndigitsfromthisnumber'
	local i=1
	while (`ndigitsfromthisnumber2' > 0) {
		local bit`i' = mod(`ndigitsfromthisnumber2',2^`i')==2^`=`i'-1'
		local ndigitsfromthisnumber2=`ndigitsfromthisnumber2'-`bit`i''*2^`=`i'-1'
		// di "bit`i'=`bit`i''"
		return scalar d`i' =  `bit`i''
		local i=`i'+1
	}
	local ndigits = `i'-1
	return scalar ndigits = `ndigits'
	
	// di "------------"
	
	// this does the actual conversion to binary
	qui inbase `base' `decimal'
	local decimal2 `decimal'

	local contcatenated_startright = ""
	local contcatenated_startleft = ""
	local i=1
	while (`i' <= `ndigits') {
		// di "START: decimal2=`decimal2'"
		local bit`i' = mod(`decimal2',2^`i')==2^`=`i'-1'
		local decimal2=`decimal2'-`bit`i''*2^`=`i'-1'
		// di "bit`i'=`bit`i''"
		return scalar d`i' =  `bit`i''
		local contcatenated_startleft "`contcatenated_startleft'`bit`i''"
		local contcatenated_startright "`bit`i''`contcatenated_startright'"
		
		// di "contcatenated_startleft: `contcatenated_startleft'"
		// di "contcatenated_startright: `contcatenated_startright'"
		
		local i=`i'+1
	}
	
	return local contcatenated_startleft "`contcatenated_startleft'"
	return local contcatenated_startright "`contcatenated_startright'"
	
end





