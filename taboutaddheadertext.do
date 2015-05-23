program define taboutaddheadertext

	syntax varlist [if] [fweight  aweight  pweight  iweight] using/, [pretabletext(string asis) posttabletext(string asis) *] 
	
	/*
	di `"varlist=`varlist'"'
	di `"options=`options'"'
	di `"pretabletex=`pretabletext'"'
	di `"posttabletext=`posttabletext'"'
	di `"using=`using'"'
	*/
	
	// header text will be specified as pretabletext
	if regexm(`"`options'"', "sumcells([^\)]*)") { // Stata's regular expression engine is total junk!
		local variable_to_summarize = substr(regexs(1), 2, .)
	}
	
	local options_tabout = subinstr(`"`options'"', `"sumcells(`variable_to_summarize')"', "", .)
	local options_tabout = subinstr(`"`options_tabout'"', `"pretabletext(`pretabletext')"', "", .)
	if (`"`variable_to_summarize'"' ~= "") {
		local options_tabout = `"cells(mean `variable_to_summarize' sd `variable_to_summarize' N `variable_to_summarize') `options_tabout' "'
	}
	if (!regexm(`"`options'"', "cells([^\)]*)")) {
		local options_tabout = `"cells(freq col cum) `options_tabout' "'
	}
	
	
	/*
	di `"variable_to_summarize=`variable_to_summarize'"'
	di `"options_tabout=`options_tabout'"'
	*/
	
	tempname fh_write
	if regexm(`"`options_tabout'"', "append") {
		// di `"append specified"'
		file open `fh_write' using `"`using'"', t write append		
	} 
	else {
		// di `"append NOT specified - assuming replace or new file"'
		file open `fh_write' using `"`using'"', t write replace
		
	}
	file write `fh_write' `"`pretabletext'"' _n
	file close `fh_write'
	local options_tabout = subinstr(`"`options_tabout'"', `"replace"', "append", .)
	
	// if replace option is specified, then add the pretabletext to the beginning of the file after tabout. If append is specified add it before calling tabout
	tabout `varlist' `if' [`weight'`exp'] using `using', nnoc `options_tabout'


end
