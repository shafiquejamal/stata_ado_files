program define test1, rclass properties(namelis1)
	
	// August 03, 2010
	syntax varlist(min=1 ts) [if] [pw aw iw fw] //, Cutoffs(numlist asc min=1 max=20 >0 <=50 integer) Poor(varname numeric) Quantiles(integer) [Graphme(integer -1) logpline(real 0), SUBsetcutoff]
	version 9.1 
	marksample touse
	
	local k: properties xi
	di "k=`k'"
	
end program

