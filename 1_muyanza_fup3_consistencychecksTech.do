use "$raw_data\Muyanza_FUP3_Final_V1.dta", clear
	duplicates tag id_05, gen(tag)
	
	keep if tag  == 0

	
	set more off
	
	local m_p	= 4
	local m_c1p = 1
	
	
***********************************************
*	Technical Checks 	
*	Each case caught by these checks should be 
*	reported and understood as it might be a 
*	sign of us not recording all data correctly
**********************************************
	

	* Tech flag 1: Plots all described and questions asked
		* In plots module
		forvalues p = 1/`m_p'{
			gen tech_flag_1_`p' = 0
			* Plot described 
			cap replace tech_flag_1_`p' = 1 if ((ag_22 >= `p' & ag_22 != .) & ///
												ag_p`p' == "") 
												
			* Plot questions asked 
			destring ag_pos_`p', replace
			replace tech_flag_1_`p' = 1 if ((ag_22 >= `p' & ag_22 != .) & ///
											ag_pos_`p' < `p' & ag_29_`p' != .) 	
			la var tech_flag_1_`p' "Tech Flag 1 Detailed: Missing Plot Loop for Plot `p'"
		}
		
		
		egen tech_flag_1 = anymatch(tech_flag_1_*), v(1)
		la var tech_flag_1 "Tech Flag 1: Missing Plot Loops!"
		

		* In transactions module
		forvalues p = 1/`m_c1p'	{
			gen tech_flag_1_c1_`p'  = 0
			* Plot described 
			cap replace tech_flag_1_c1_`p' = 1 if ((c1ag_22 >= `p' & c1ag_22 != .) & ///
												c1ag_p`p' == "") 
			* Plot questions asked 
			destring c1ag_pos_`p', replace
			replace tech_flag_1_c1_`p'  = 1 if ((c1ag_22 >= `p' & c1ag_22 != .) & ///
											c1ag_pos_`p' < `p' & c1ag_29_`p' != .) 	
			la var tech_flag_1_c1_`p' "Tech Flag 1 Detailed: Missing Plot Loop for Plot `plot'"
		}
		
		
		egen tech_flag_1_c1 = anymatch(tech_flag_1_c1*), v(1)
		la var tech_flag_1_c1 "Tech Flag 1: Missing transactions Loops!"
		
	
	
	* Tech flag 2: -- Number of plots cultivated, versus in plot roster


	forvalues p = 1/2 {
		gen tech_flag_2_`p' = 0
		forvalues s = 1/3 {
			replace tech_flag_2_`p' = 1 if !missing(ag_p`p') & `p' <= ag_22 & missing(ag_33_all_`s'_`p') 
			}
		}
		
	forvalues p = 1/`m_p' {
		gen in_roster_`p' = 1 if ag_22 >= `p' & ag_22 != .
		cap replace in_roster_`p' = 0 if ag_22 >= `p' & ag_p`p' == "" & ag_22 != .
	}
	egen tech_flag_2 = anymatch(tech_flag_2_*), v(1)
		la var tech_flag_2 "Tech Flag 2 : Number of plots in seasons module doesn't matches number in plot roster"
	
	

	
	*Tech Flag 3: Correct number of crop loops
	
	forvalues p = 1/2 {
		forvalues s=1/3 {
			gen tech_flag_3_`s'_`p' = 0
			forvalues c = 1/3 {
				replace tech_flag_3_`s'_`p' = 1 if !missing(crp_20a`c'_s_`s'_`p') ///
													& missing(pc1_04_`s'_`p'_`c')
			}
		}
	}

	egen tech_flag_3 = anymatch(tech_flag_3_*), v(1)
	la var tech_flag_3 "Tech Flag 3: Missing Crop Loops!" 
	

	/*
1	Still own and cultivate
2	Still own and continue to rent out
3	Still own and started renting out
4	Still own and stopped renting out
5	Continue to rent in
6	Stopped renting in
7	Sold
8	Lost possession in other way (given for free,...)
9	bought/acquired

1	Bought
2	Aquired for free
3	Sold
4	Given away for free
5	Newly rented out
6	No longer rented out
7	Newly rented in
8	No longer rented in


*/
	
	*Tech flag 4: Testing if transaction details were asked when a plot was rented in or out
	* Plot roster
	gen tech_flag_4  = 0
	
	forvalues p = 1/4 {
		cap replace tech_flag_4  = 1 if inlist(ag_23_`p',2,3,4,5,6) & ///
										missing(ag_31a_1_`p')
	}
	
	la var tech_flag_4 "Tech Flag 4: Missing Questions on transactions in case of rentals (plot roster)"
	
	* Transactions
	gen tech_flag_4_c1  = 0
	
	forvalues p = 1/4 {
		cap replace tech_flag_4_c1  = 1 if inlist(c1ag_23_`p',2,5,6,7,8) & ///
										missing(c1ag_31a_1_`p')
	}
	
	la var tech_flag_4_c1 "Tech Flag 4: Missing Questions on transactions in case of rentals (transactions)"
	
	
	* Tech Flag 5: Correct number of production module loops based on reranking.
		gen tech_flag_5  = 0
		
	
	*forvalues p = 1/2 {
		*cap replace tech_flag_5  = 1 if inlist(ag_mip`p',2,1) & ///
										*missing(AG_33_All_1_`p')
	*}
* Case 1- two main plots remain unchanged- only repeat the production module 2 times.	
	forvalues p = 1/4 {
	cap replace tech_flag_5  = 1 if ag_mip1==2 & ag_mip2==1 & ///
										missing(AG_33_All_`p'_1)
	}
	
		forvalues p = 1/4 {
		cap replace tech_flag_5  = 1 if ag_mip1==2 & ag_mip2==1 & ///
										missing(AG_33_All_`p'_2)
		}
		
			forvalues p = 1/4 {
	cap replace tech_flag_5  = 1 if ag_mip1==1 & ag_mip2==2 & ///
										missing(AG_33_All_`p'_1)
	}
	
		forvalues p = 1/4 {
		cap replace tech_flag_5  = 1 if ag_mip1==1 & ag_mip2==2 & ///
										missing(AG_33_All_`p'_2)
		}
		
*	 Case 2- one of the main plots changes- repeat the production module 3 times- one time for the new imp plot and 2 times for the plots which were imp in the baseline		
	forvalues p = 1/4 {									
	cap replace tech_flag_5  = 1 if ag_mip1==1 & ag_mip2!=2 & ///
										missing(AG_33_All_`p'_3)	
	}
	
		forvalues p = 1/4 {									
	cap replace tech_flag_5  = 1 if ag_mip1==2 & ag_mip2!=1 & ///
										missing(AG_33_All_`p'_3)	
	}
	
*	 Case 3- both the main plots changes- repeat the production module 4 times- two times for the new imp plots and 2 times for the plots which were imp in the baseline		
	
	forvalues p = 1/4 {										
	cap replace tech_flag_5  = 1 if ag_mip1!=1 & ag_mip2!=2 & ///
										missing(AG_33_All_`p'_3)	
	}
		
	forvalues p = 1/4 {	
	cap replace tech_flag_5  = 1 if ag_mip1!=2 & ag_mip1!=1 & ///
										missing(AG_33_All_`p'_4)
	}
	
*	 Case 4- HH had only one plot in baseline and no other plot was transacted, repeat the production module 1 time
gen trans_plots=0
replace trans_plots=total_number_plots if total_number_plots>=0 & !missing(total_number_plots)
	
	forvalues p = 1/4 {	
	cap replace tech_flag_5  = 1 if old_plot_count==1 & trans_plots==0 & ///
										missing(AG_33_All_`p'_1)
	}



*	 Case 5- HH had only one plot in baseline and other transacted plots, repeat the production module 2 times if the plot 1 was important and for the 2nd most important plot
	forvalues p = 1/4 {	
	cap replace tech_flag_5  = 1 if old_plot_count==1 & trans_plots!=0 & ///
										missing(AG_33_All_`p'_2)
	}


*	 Case 6- HH had only one plot in baseline and other transacted plots, repeat the production module 3 times if the plot 1 was not in first 2 important plots
	forvalues p = 1/4 {	
	cap replace tech_flag_5  = 1 if old_plot_count==1 & trans_plots!=0 & agmip1!=1 & ag_mip2!=1 & ///
										missing(AG_33_All_`p'_3)
	}



	la var tech_flag_5 "Tech Flag 5: Missing production module based on reranking"
	
	
	
		
	
	
	
	*Sum total tech flags
	
	sum tech_flag_*

	egen tech_flag 			= anymatch(tech_flag_*), v(1)
	egen tech_flag_count 	= rowtotal(tech_flag_*)

	*Deleting variables with no tech flags and testing if that was all variables
	keep if tech_flag != 0
	
	cap confirm file "$excel\TechnicalChecks_All.xls"
	
	if !_rc {

		tempfile ignoreMergeAll ignoreMergeUnAddressed
	
		preserve 
			clear
			
			import excel "$excel\TechnicalChecks_All.xls", firstrow
			
			keep id_05 id_03 Ignore Date
			
			save 	`ignoreMergeAll'
			
		restore	
		
		merge 1:1 id_05 id_03 using `ignoreMergeAll'		, nogen
		

		cap confirm file "$consistency\TechnicalChecks_unAddressed.xls"
		
		if !_rc {
		
			preserve 
				clear
				
				import excel "$excel\TechnicalChecks_unAddressed.xls", firstrow
				
				keep id_05 id_03 Ignore Date
				
				save 	`ignoreMergeUnAddressed'
				
			restore
		
		
		merge 1:1 id_05 id_03 using `ignoreMergeUnAddressed', nogen update replace
		
		}
		
	}
	else {
	
		gen Ignore 	= "No"
		gen Date	= ""
	
	}
	
	local date = subinstr(c(current_date), " ", "", .)
	
	cap assert _N == 0


	if _rc {
		
		keep id_05 id_03 tech_flag* Ignore Date 
		
		
		ds tech_flag_*
		foreach var in `r(varlist)'	{
			qui sum `var'
			if r(mean)== 0	{
				drop `var'
			}
		}		
		
		decode(id_03), gen(id_03_name)
		
		order tech_flag tech_flag_count tech_flag_* , last
		order id_05 id_03 id_03_name Date Ignore
		
		replace Ignore	= "No" 		if Ignore 	== ""
		replace Date 	= "`date'" 	if Date 	== ""
		}
		
		count if Date == "`date'"
		if r(N)> 0 cap export excel using "$excel\TechnicalChecks_`date'.xlsx" if Date == "`date'", firstrow(variables) replace nolabel
		
		cap export excel using "$excel\TechnicalChecks_All.xlsx" , firstrow(variables) replace nolabel
		
		drop if lower(Ignore) == "yes" | lower(Ignore) == "y"
	
	
	cap assert _N == 0
	
	if _rc {
		ds tech_flag_*
		foreach var in `r(varlist)'	{
			qui sum `var'
			if r(mean)== 0	{
				drop `var'
			}
		}		
		
		cap export excel using "$excel\TechnicalChecks_unAddressed.xlsx", firstrow(variables) replace nolabel
		
		noi di as error "There are `r(N)' observation(s) with at least one technical flag. Excel file TechnicalChecks_`date'.xls saved and both TechnicalChecks_All.xls and TechnicalChecks_unAddressed.xls is updated."
		noi list id_03 id_05 tech_flag_count
	}

	else {
	
		noi di ""
		noi di ""
		count
		
		cap confirm file "$excel\TechnicalChecks_unAddressed.xlsx"

		if !_rc {
			
			erase "$excel\TechnicalChecks_unAddressed.xlsx"
			
			noi di "There are no observations with technical flags. No excel file generated and TechnicalChecks_unAddressed.xls is deleted."
		}
		
		else {
		
			noi di "There are no observations with technical flags. No excel file generated."
		}
		
	}
 


