program dec2bin, rclass

	syntax [varlist], Base(integer) Decimal(integer) Ndigits(integer)

	qui inbase `base' `decimal'
	local decimal2 `decimal'

	local i=1
	while (`i' <= `ndigits') {
		// di "START: decimal2=`decimal2'"
		local bit`i' = mod(`decimal2',2^`i')==2^`=`i'-1'
		local decimal2=`decimal2'-`bit`i''*2^`=`i'-1'
		// di "bit`i'=`bit`i''"
		return scalar d`i' =  `bit`i''
		local i=`i'+1
	}
	
end




