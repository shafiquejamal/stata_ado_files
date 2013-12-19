program define adultequivhhsize, rclass
	syntax , Age(varname numeric) Male(varname numeric) Generate(name) Scale(string) Over(varname numeric) Reltohead(varname numeric)
	version 9.1

	tempvar hhmemberweight
	
	// different scales. Have not implemented McClemments' yet
	if ("`scale'"=="shafique") {
	
		qui gen `hhmemberweight' = .
		qui replace `hhmemberweight' = 1 if `age' > 14 & `age' ~= .
		qui replace `hhmemberweight' = 0.5 if `age' <= 14
	
	}
	else if ("`scale'"=="oecdm") {
	
		// Use the OECD modified scale (http://www.oecd.org/LongAbstract/0,3425,en_2649_33933_35411112_1_1_1_1,00.html)
		// sort `over' `age'
		qui gen 	`hhmemberweight' = 1 	if `reltohead' == 1
		qui replace `hhmemberweight' = 0.5	if `reltohead' != 1 & `age' >= 	15
		qui replace `hhmemberweight' = 0.3	if `reltohead' != 1 & `age' < 	15
	
	}
	
	// Now we calculate the adjusted household size, which will be stored in the variable named "generate"
	qui cap drop `generate'
	qui egen `generate' = total(`hhmemberweight'), by(`over')
	
end program

