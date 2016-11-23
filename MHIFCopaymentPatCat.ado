program define MHIFCopaymentPatCat

	syntax varname, GENerate(name) maxCopaySurgeryRepublican2(real) iPSurgeryVisits(varname numeric) iPNonSurgeryVisits(varname numeric) treatedGovtHospitalRepublican(varname numeric) treatedGovtHospitalSubNational(varname numeric) maxCopaySurgerySubNational2(real) maxCopayNonSurgRepublican2(real) maxCopayNonSurgSubNational2(real) avgCopayNonSurgRepublican2(real) avgCopayNonSurgSubNational2(real) avgCopaySurgeryRepublican2(real) avgCopaySurgerySubNational2(real)
	tempvar surg nonsurg remainingFreeVisits

	gen `surg' = 0
	
	// No contribution for Uninsured
	replace `surg' = 0 if `varlist' == 4 & `treatedGovtHospitalRepublican' == 1 // Surgery, Uninsured, Republican
	replace `surg' = 0 if `varlist' == 4 & `treatedGovtHospitalSubNational' == 1 // Surgery, Uninsured, SubNational
	// Insured
	replace `surg' = `iPSurgeryVisits'*(`maxCopaySurgeryRepublican2'-`avgCopaySurgeryRepublican2') if `varlist' == 3 &  `treatedGovtHospitalRepublican' == 1 // Surgery, Insured, Republican
	replace `surg' = `iPSurgeryVisits'*(`maxCopaySurgerySubNational2'-`avgCopaySurgerySubNational2') if `varlist' == 3 & `treatedGovtHospitalSubNational' == 1 // Surgery, Insured, SubNational
	// Medical
	replace `surg' = `iPSurgeryVisits'*`maxCopaySurgeryRepublican2' if `varlist' == 2 & `treatedGovtHospitalRepublican' == 1 // Surgery, medical group, Republican
	replace `surg' = `iPSurgeryVisits'*`maxCopaySurgerySubNational2' if `varlist' == 2 & `treatedGovtHospitalSubNational' == 1 // Surgery, medical group, SubNational
	
	// Social - First 2 IP visits are free - assume first two are surgey visits. So MHIF pays max copay for first two visits, then max-avg for the rest
	replace `surg' = (`iPSurgeryVisits')*(`maxCopaySurgeryRepublican2') if `varlist' == 1 & `treatedGovtHospitalRepublican' == 1 & `iPSurgeryVisits' <= 2 // Surgery, social group, Republican
	replace `surg' = (`iPSurgeryVisits')*(`maxCopaySurgerySubNational2') if `varlist' == 1 & `treatedGovtHospitalSubNational' == 1 & `iPSurgeryVisits' <= 2 // Surgery, social group, SubNational
	
	replace `surg' = 2*(`maxCopaySurgeryRepublican2') + (`iPSurgeryVisits'-2)*(`maxCopaySurgeryRepublican2'-`avgCopaySurgeryRepublican2') if `varlist' == 1 & `treatedGovtHospitalRepublican' == 1 & `iPSurgeryVisits' > 2 // Surgery, social group, Republican
	replace `surg' = 2*(`maxCopaySurgerySubNational2') + (`iPSurgeryVisits'-2)*(`maxCopaySurgerySubNational2'-`avgCopaySurgerySubNational2') if `varlist' == 1 & `treatedGovtHospitalSubNational' == 1 & `iPSurgeryVisits' > 2 // Surgery, social group, SubNational
	qui sum `surg'
	assert(r(mean) >= 0)
	
	gen `remainingFreeVisits' = 2-`iPSurgeryVisits'
	replace `remainingFreeVisits' = 0 if `remainingFreeVisits' < 0 
	label var `remainingFreeVisits' "Free visits remaining after IP surgery visits"
	// u5 is free, so MHIF pays max copayment amount for these folks
	replace `surg' = (`iPSurgeryVisits'-2)*`maxCopaySurgeryRepublican2' if `varlist' == 1 & u5 == 1 & `treatedGovtHospitalRepublican' // u5, Republican
	replace `surg' = (`iPSurgeryVisits'-2)*`maxCopaySurgerySubNational2' if `varlist' == 1 & u5 == 1 & `treatedGovtHospitalSubNational' // u5, SubNational
	replace `surg' = 0 if `surg' < 0
	// According to SGBP, part 4 "Inpatient Care", para 19, subpart 1), "the following categories of citizens are subject to a minimum level of co-payment: 
	//	- pensioners under the age of 70 years - no indicator; ***
	//	- Persons awarded the medal "Veteran of Labor"; - no indicator
	// 	- Persons receiving social benefits;" - no indicator
	
	gen `nonsurg' = 0
	
	// No contribution for Uninsured
	replace `nonsurg' = 0 if `varlist' == 4 & `treatedGovtHospitalRepublican' == 1 // NonSurgery, Uninsured, Republican
	replace `nonsurg' = 0 if `varlist' == 4 & `treatedGovtHospitalSubNational' == 1 // NonSurgery, Uninsured, SubNational
	// Insured
	replace `nonsurg' = `iPNonSurgeryVisits'*(`maxCopayNonSurgRepublican2'-`avgCopayNonSurgRepublican2') if `varlist' == 3 &  `treatedGovtHospitalRepublican' == 1 // NonSurgery, Insured, Republican
	replace `nonsurg' = `iPNonSurgeryVisits'*(`maxCopayNonSurgSubNational2'-`avgCopayNonSurgSubNational2') if `varlist' == 3 & `treatedGovtHospitalSubNational' == 1 // NonSurgery, Insured, SubNational
	// Medical
	replace `nonsurg' = `iPNonSurgeryVisits'*`maxCopayNonSurgRepublican2' if `varlist' == 2 & `treatedGovtHospitalRepublican' == 1 // NonSurgery, medical group, Republican
	replace `nonsurg' = `iPNonSurgeryVisits'*`maxCopayNonSurgSubNational2' if `varlist' == 2 & `treatedGovtHospitalSubNational' == 1 // NonSurgery, medical group, SubNational
	
	// Social - First 2 IP visits are free - assume first two are surgey visits. Remaining visits were calculated above
	tempvar nVisitsNoCopay nVisitsCopay
	egen `nVisitsNoCopay' = rmin(`remainingFreeVisits' `iPNonSurgeryVisits')
	qui sum `nVisitsNoCopay'
	assert(r(mean) >= 0)
	gen `nVisitsCopay' = `iPNonSurgeryVisits'-`nVisitsNoCopay'
	replace `nVisitsCopay' = 0 if `nVisitsCopay' < 0
	qui sum `nVisitsCopay'
	assert(r(mean) >= 0)
	
	replace `nonsurg' = (`nVisitsNoCopay')*(`maxCopayNonSurgRepublican2') + (`nVisitsCopay')*(`maxCopayNonSurgRepublican2'-`avgCopayNonSurgRepublican2') if `varlist' == 1 & `treatedGovtHospitalRepublican' == 1 // NonSurgery, social group, Republican
	replace `nonsurg' = (`nVisitsNoCopay')*(`maxCopayNonSurgSubNational2') + (`nVisitsCopay')*(`maxCopayNonSurgSubNational2'-`avgCopayNonSurgSubNational2') if `varlist' == 1 & `treatedGovtHospitalSubNational' == 1 // NonSurgery, social group, SubNational
	qui sum `nonsurg'
	assert(r(mean) >= 0)

	// u5 is free, so MHIF pays max copayment amount for these folks
	replace `nonsurg' = `iPSurgeryVisits'*`maxCopayNonSurgRepublican2' if `varlist' == 1 & u5 == 1 & `treatedGovtHospitalRepublican' // u5, Republican
	replace `nonsurg' = `iPSurgeryVisits'*`maxCopayNonSurgSubNational2' if `varlist' == 1 & u5 == 1 & `treatedGovtHospitalSubNational' // u5, SubNational
	// According to SGBP, part 4 "Inpatient Care", para 19, subpart 1), "the following categories of citizens are subject to a minimum level of co-payment: 
	//	- pensioners under the age of 70 years - no indicator; ***
	//	- Persons awarded the medal "Veteran of Labor"; - no indicator
	// 	- Persons receiving social benefits;" - no indicator
	
	gen `generate' = `surg' + `nonsurg'
	cap drop surgTemp
	gen surgTemp = `surg'
	cap drop nonSurgTemp
	gen nonSurgTemp = `nonsurg'
	
end
