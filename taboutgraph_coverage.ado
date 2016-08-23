program define taboutgraph_coverage

	// Written by Shafique Jamal (shafique.jamal@gmail.com)
	// This program requires that the second variable in varlist have a value label attached to it
	// It plots the column output of the tabout command

	syntax varlist(min=2 max=2) [if] [in] using/ [aweight], GCmd(string) GOptions(string asis) TAboutoptions(string asis) [replace OVERCategorysuboptions(string asis) OVERXsuboptions(string asis) SINGLECATegorysubptions(string asis) subtitle]
	version 9.1
				
	taboutgraph `varlist' `if' `in' using `using' [`weight'`exp'], gcmd(`gcmd') goptions(`goptions') /// 
		taboutoptions(cells(row) `taboutoptions') `replace' overcategorysuboptions(`overcategorysuboptions') /// 
		overxsuboptions(`overxsuboptions' ) singlecategorysubptions(`singlecategorysubptions') `subtitle' ///

end program 
