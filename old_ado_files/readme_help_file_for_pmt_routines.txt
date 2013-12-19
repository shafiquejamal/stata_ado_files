1. pmt.ado

description:

	Given a regression model, identification of target (poor) group, cutoff, number of quantiles, etc. generates leakage, undercoverage, and coverage per quintile - performance measures of the model. It uses
		the regression model to determine eligibility. 
 	
	Use this with xi, and with svy, subpop(). Usually you will have different regression models for urban and rural, so you can run this separately for each, specifying the subpop each time, to.
		get the performance for urban and rural separately.

inputs:

varlist: y x1 x2 ... xN. The dependent var followed by the explanatory variables. This is your regression model.

options: 
	
	poor: binary indicator variable indicating which observations are poor (target) 
	quantiles: integer, number of quantiles (5 = quintiles, 10 = deciles). These will be NATIONAL quintiles (it is calculated based on ALL observations, not just the subpop)
	cabsolute : the cutoff NOT in the same unites as y (the welfare measure). So if y is log of consumption, cabsolute is in units of consumption. Could be a numlist, but best to just use an integer
	graphme : set this equal to the value of cabsolute if you want this routine to produce a graph showing inclusion and exclusion errors
	logpline: USED ONLY FOR GRAPHING. This is the log of the poverty line. The poverty line defines who is poor (it defines the 'poor' variable above). Make sure you make it in the same units as the variable y above (log of consumption)
	
output:

	leakage
	undercoverage
	targeting accuracy
	coverage rate of the target group
	fraction of the total covered that are in the target group
	fraction of the population covered
	
	coverage rate for the given cutoff for each quantile
	
2. pmt_eligible.ado

description:

	Similar to pmt2.ado, except that it doesn't require a regression model because it takes as an input a binary (dummy) indicator variable indicating which observations are eligible. 
	
	Once you have predicted log consumption for the urban and rural settlement types, and have determined eligibility (and created a variable for eligibility) you can use this routine. 

inputs: 
	
	a single variable - a binary indicator of whether the observation is eligible for social assistance

options: 

	poor: binary indicator variable indicating which observations are poor (target) 
	quantilec: variable indicating the quantiles of consumption

output:

	leakage
	undercoverage
	coverage rate for the given cutoff for each quantile

3. construct_reg_eqn 

description:

	Run this after running an xi: svy... : reg command. It contructs a regression equation (actually just the RHS of the equation) corresponding to the model specified in the reg command using the betas that result from the reg command.
		So if your reg command is reg y x1 x2 x3 and the betas are b0=5 b1=2 b2=-3 b3=4 then the equation constructed will be 2*x1-3*x2+4*x3+5. This equation will be stored in the first line in the file specified. You can use this equation on a differnet
		dataset if you want to apply the estimated regression formula to a different dataset.
		
	In the third line of the file, the program will write a human-friendly, readable version of the equation for you to include in a report. 

inputs:

	No variables. It operates on the return values. 

options: 

	filename: full path to filename that will hold the regression equation. 
	round: specify the rounding you want for the betas (e.g. 0.1 to the nearest tenths, 0.01 nearest hundredths, etc.)

output:

	It returns the equation in r(equation). Just a file containing the estimated regression equations. Here is how you might load the equation in a different ado file in order to apply it to a different dataset (assuming you used a file called "equation.txt"):
	
	tempname fhu
	file open `fhu' using "equation.txt", r t
	file read `fhu' equation
	file close `fhu'
	di `"equation = `equation'"'
	gen predicted_values = `equation'

4. dataset_coefficients.ado

description:

	Run this right after the xi: svy...: reg command. creates and save a dataset of variables and their betas estimated from regression. This is incase you want to plot a bar graph of the betas, to show thier relative magnitude.

inputs:

	No variables. Operates on return values from the reg command. 

options: 

	filename: full path to filename that will hold the dataset
	
output:

	dataset in filename. 

5. dataout_pmt_eligible.ado and dataout_pmt2.ado

description:

	run these program after pmt_eligible and pmt2 respectively in order to store results in a .csv file. 

inputs:

	no variables - these operate on return values. 

options: 
	
	filename: full path to csv file that you want to store the data in
	q : number of quantiles
	separator: separate with comma or colon or whatever. Default is comma, specify something different if you want.
	append: use this option if you want to append to the file rather that replace the specified file, in which case just ommit this option.
	label: a field that you can put a label in (e.g. "all" or "subgroup - seniors")

output:

	file with leakage, undercoverage, targeting accuracy, coverage per quintile, 

6. varsformyrelabel.ado (make sure you have Nick Cox's myrelabel.ado)

description:

	This is a wrapper for myrelabel.ado written by Nick Cox (which modified slightly). Use after xi: svy... : reg command. It relables the variables that xi expanded (prefixed with i. in the reg command) so that the variable
		labels take on the appropriate value lables (great for when including these in a report).

inputs:

	none

options: 

	none

output:

	none


7. variables_and_coeffs.ado

description:

	Run this after xi: svy... : reg command, but preferably after running varsformyrelabel.ado. This creates a csv file with three columns: variable name, variable label, and the beta for including in reports. 

inputs:

	no variables. 

options: 

	filename: full path to filename. 
	round: specify the rounding you want for the betas (e.g. 0.1 to the nearest tenths, 0.01 nearest hundredths, etc.)
	
output:

	no variables or return values. Just a file.
	

description:
inputs:
options: 
output:

