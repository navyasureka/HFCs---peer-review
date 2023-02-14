*qui {
******************************
* 	Consistency Checks 		 *
******************************

	set more off
    
*** 1. Load Data	
use "$raw_data\Muyanza_FUP3_Final_V1.dta", clear
    
*** 2. Tag dups
	duplicates tag id_05, gen(tag)
	
	drop if tag  == 1 & responsestatus != 1 | consent != 1

	 /*
    forvalues x = 1/4 {
    tab ag_23_`x' ag_43_season_`x'
    tab ag_23_`x' ag_43_formal_`x'
    tab ag_23_`x' ag_43_registered_`x' 
    tab ag_23_`x' ag_43_swap_`x'
    tab ag_23_`x' ag_43_season_`x'
    
    }*/
	* below code is examples of consistency checks. 
	* need to modify based on our dataset, if we want to run similar checks, and add checks specific to this data	

	* Flag 1 -- HH Head is not the first person listed
	gen flag_1 = 0 
	replace flag_1 = 1 if (hh_15 != 1)
	la var flag_1 "Flag 1: HH Head is not the First Person Listed"
	
	
	* Flag 2 -- Appropriate Age of Main Respondent
	gen flag_2 = 0
	la var flag_2 "Flag 2: Main Respondent is 16 or younger"
	forvalues r = 1/16	{
			cap replace flag_2 = 1 if (hh_18b == `r' & hh_07_`r'<16)
		}

	
	*Flag 3 -- Check that HHH is the same person of the baseline
	gen flag_3 = 0
	replace flag_3 = 1 if hh_15b == 0
	la var flag_3 "Flag 3: HHH not confirmed from BL" 						

	
	* Flag 4 -- Appropriate Age of FS Respondent
	gen 	flag_4 = 0
	la var 	flag_4 "Flag 4: FS Respondent is 16 or younger"
	forvalues r = 1/10	{
			 replace flag_4 = 1 if (new_resp == `r' & hh_07_`r'<10) 
		}

	
	* Flag 5 -- Proportion of all crops grown on plot
	* Flag 6 -- Proportion of all crops grown on plot relative to reported total proportion

	forvalues s = 1/3	{
		forvalues p = 1/2	{
			
			*Variable was categorical variable 0-20 representing 0-100% where
			*each category represent an increment increase of 5%.  Dividing the
			*categories by 20 results in a continious variable with the 
			*corresponding decimal value. The categorial value label is afterwards removed
			 replace  pc1_01_`s'_`p' =  pc1_01_`s'_`p' / 20
			 lab val pc1_01_`s'_`p'
			
			forvalues c = 1/3	{
				
				*Variable was categorical variable 0-20 representing 0-100% where
				*each category represent an increment increase of 5%.  Dividing the
				*categories by 20 results in a continious variable with the 
				*corresponding decimal value. The categorial value label is afterwards removed
				 replace pc1_04_`s'_`p'_`c' = pc1_04_`s'_`p'_`c' / 20
				 lab val pc1_04_`s'_`p'_`c' 

			}
			
			tempvar  	cropTotal
			 egen 	`cropTotal' = rowtotal(pc1_04_`s'_`p'_*)
			
			cap gen plotarea_`p' = pl_plot_area_`p'
			local 	plotarea_`p'	pc1_01_`s'_`p'
			
			 gen 	omitt_sub_flag_5_s`s'_p`p' = (`cropTotal' > 1 & `cropTotal' < .)
			 la var  omitt_sub_flag_5_s`s'_p`p' "Flag 5 Detailed: Proportion of Crops>1 on Plot `p' Season `s'"
			
			gen 	omitt_sub_flag_6_s`s'_p`p' = (`cropTotal' > `plotarea_`p'' | `cropTotal' < 0.5 * `plotarea_`p'') & `cropTotal' != . & `plotarea_`p'' != .
			 la var 	omitt_sub_flag_6_s`s'_p`p' "Flag 6 Detailed: (prop Plot < Prop of Crops < .5 * prop Plot) Plot `p' Season `s'"
		}
	}
	
	egen omitt_flag_5 = anymatch(omitt_sub_flag_5_s?_p? ) , v(1)
	egen omitt_flag_6 = anymatch(omitt_sub_flag_6_s?_p? ) , v(1)
	
	
	*Flag 7 -- Rates of parcels matching per enumerator.							
	
	* Parcels
	forvalues i = 1/5 {
		  gen parc_not_recogn_`i' = 1 if ag_15_`i'==0 & ag_15_lost_`i'==5 
	}
	
	egen parc_not_recogn_tot = rsum(parc_not_recogn_1 - parc_not_recogn_5)
	destring old_parcels_count, replace
	gen rate_parc_not_recogn = parc_not_recogn_tot / old_parcels_count
	
	gen flag_7 = 0
	replace flag_7 = 1 if rate_parc_not_recogn >= .2 & old_parcels_count!=.
	la var flag_7 "Flag 7: more than 20% of the old parcels are not recognized by the respondent"

		

	
	* Flag 8 -- Rates of plots matching per enumerator 
	
	forvalues i = 1/4 {
		gen plot_not_recogn_`i' = 1 if (ag_23_`i'==0 ) 
	}
	
	egen plot_not_recogn_tot = rsum(plot_not_recogn_1 - plot_not_recogn_4)
	destring nplots_old, replace
	gen rate_plot_not_recogn = plot_not_recogn_tot / nplots_old
	
	gen flag_8 = 0
	replace flag_8 = 1 if rate_plot_not_recogn >= .2 & nplots_old!=.
	la var flag_8 "Flag 8: more than 20% of the old plots are not recognized by the respondent"

	

	
	*Flag 11 - Make sure that each plot asked about in labor section (meaning 
	*cultivated or rented out but know production, plus in CA/CAC or most 
	*important plot outside) has at least some labor applied during either growth 
	*or harvest
	
	destring pl1_06_*, replace
	destring pl1_07_*, replace
	destring pl1_10_*, replace
	destring pl1_11_*, replace
	
	forvalues s = 1/3 {
	
		forvalues p = 1/2 {
			
			*Consider missing codes like -88 as some labor was applied, we just don't know how much.
			 replace pl1_06_`s'_`p' = 1 if pl1_06_`s'_`p' < 0 //HH labor growing
			 replace pl1_07_`s'_`p' = 1 if pl1_07_`s'_`p' < 0 //paid labor growing
			 replace pl1_10_`s'_`p' = 1 if pl1_10_`s'_`p' < 0 //HH labor harvest
			 replace pl1_11_`s'_`p' = 1 if pl1_11_`s'_`p' < 0 //paid labor harvest
			
			
			 egen any_labor_season`s'_plot`p' = rowtotal(pl1_06_`s'_`p' pl1_07_`s'_`p' pl1_10_`s'_`p' pl1_11_`s'_`p')
			
			 replace any_labor_season`s'_plot`p' = 1 if any_labor_season`s'_plot`p' > 0 & any_labor_season`s'_plot`p' != .
			
			  gen sub_flag_10_season`s'_plot`p' = (any_labor_season`s'_plot`p' == 0 & relevance_do_`p'== 1)
			
		}
	}

	
	egen flag_10 = anymatch(sub_flag_10_*) , v(1)
	
	la var flag_10 "Plot cultivated at least one season, but no type of labor reported"
	
	
	* Flag 11 -- Reported Labor for Inputs or Irrigation if 2_muyanza_fup2_consistencychecksd either
	
	forvalues s = 1/3	{

		egen input_applied_`s' = anycount(pn1_01_`s'*), v(1)
		egen irrigation_used_`s' = anycount(pi1_01_`s'*), v(1)

		egen pl`s'_06 = rowtotal(pl1_06_`s'*)
		egen pl`s'_07 = anymatch(pl1_07_`s'*), v(1)
	}
	
	gen flag_11 = 0
	forvalues s = 1/3 {
		replace flag_11 = 1 if flag_10 != 1 & ((input_applied_`s' == 1 | irrigation_used_`s' == 1) & pl`s'_06 == 0 & pl`s'_07 == 0)
	}
	
	la var flag_11 "Flag 11: Applied Inputs or Used Irrigation but Reported no labor"
	

	* Flag 12 -- Reported labor for harvest if harvested

	* Dummy for a Harvest >0
	forvalues s = 1/3	{
		gen harvested_`s' = 0
		forvalues p = 1/2	{
			forvalues c = 1/3	{
				 replace harvested_`s' = 1 if pc1_09_`s'_`p'_`c' > 0 & pc1_09_`s'_`p'_`c' != .
			}
		}

		egen pl`s'_10 = rowtotal(pl1_10_`s'*)
		egen pl`s'_11 = anymatch(pl1_11_`s'*), v(1)
	}
	
	
	gen flag_12 = 0

	forvalues s = 1/3 {
		replace flag_12 = 1 if flag_10 != 1 & (harvested_`s' == 1 & pl`s'_10 == 0 & pl`s'_11 == 0)
	}
	la var flag_12 "Flag 12: Harvested Something but Reported no labor"
		
	
**TO UPDATE
	** The following few flags relates to harvest amount and usage of 
	*  harvested amount. In order to do this we first standardize the 
	*  amounts:

	* First, Standardize Crop Measurements
	* First, Standardize Crop Measurements
	forvalues s = 1/3 {
		forvalues p = 1/2	{
			forvalues c = 1/3	{
				forvalues v = 1/12	{
					local var: word `v' of 09 09B 09C 10 10B 10C 11 11B 11C 12 12B 12C
					local b: word `v' of "Harvested" "Green Maize Harvested" "Dry Maize Harvested" "Sold" "Green Maize Sold" "Dry Maize Sold" "HH Consumed" "Green Maize HH Consumed" "Dry Maize HH Consumed" "Lost to Spoilage/Post-Harvest Loss" "Green Maize Lost to Spoilage/Post-Harvest Loss" "Dry Maize Lost to Spoilage/Post-Harvest Loss"
					
					local amountVar 		pc1_`var'_`s'_`p'_`c'
					local unitVar			pc1_`var'x_`s'_`p'_`c'
					local standardizedVar 	pc1_`var'_`s'_`p'_`c'_kg
					
					qui gen 	`standardizedVar' = .
					la var 		`standardizedVar' "Amount `b' (KG) [Crop `c'] [Plot `p']"
					cap qui replace `standardizedVar' = 0 if `amountVar' == 0
					cap qui replace `standardizedVar' = (`amountVar'			) 	if `unitVar' == 1
					cap qui replace `standardizedVar' = (`amountVar' * 25	) 	if `unitVar' == 2
					cap qui replace `standardizedVar' = (`amountVar' * 50	) 	if `unitVar' == 3
					cap qui replace `standardizedVar' = (`amountVar' * 100	) 	if `unitVar' == 4
					cap qui replace `standardizedVar' = (`amountVar' * 907	) 	if `unitVar' == 5
					cap qui replace `standardizedVar' = (`amountVar' * 1.5	) 	if `unitVar' == 7
					cap qui replace `standardizedVar' = (`amountVar' * 15	) 	if `unitVar' == 8
					cap qui replace `standardizedVar' = (`amountVar' * 15	) 	if `unitVar' == 9
					*order 		`standardizedVar', after(`unitVar')
					*drop 		`amountVar' `unitVar'

				}
			}
		}
	}
	
	/** Flag Dry/Green Maize. If the quantiaty sold, consumed etc is refers to both 
	*  green and dry maize, then these questions are asked how much for dry and 
	*  green mazie seperately. This flag checks that the sum of those two quantities
	*  are less that the total maize sold, consumed etc.
	foreach QNum in 09 10 11 12 {
		
		gen flag_Maize_Q`QNum' = 0
		
		forvalues season = 1/3 {
			forvalues plot = 1/2 {
				forvalues crop = 1/3 {
				
					if `season' == 1 local seasonName 20c
					if `season' == 2 local seasonName 21a
					if `season' == 3 local seasonName 21b 

					*Generates some locals to make the code below more readable 
					local prefix pc1_`QNum'_`season'
					local suffix `plot'_`crop'
					
					** If the total amount (`prefix'_`suffix') is equal or more than
					*  green maize (`prefix'b_`suffix') and dry maize (`prefix'c_`suffix') combined
					 gen bothDiff_`QNum'_`season'_`suffix' = `prefix'_`suffix' - ( `prefix'B_`suffix' + `prefix'C_`suffix' ) if ///
						crp_`seasonName'`crop'_s`plot' == 1 & `prefix'A`suffix' == 3
					
					** Ignore if either of total maize (`prefix'_`suffix'), green maize
					*  (`prefix'b_`suffix') or dry maize (`prefix'c_`suffix') as a negative
					*  value as error code like -88
					 replace bothDiff_`QNum'_`season'_`suffix' = . if `prefix'_`suffix' < 0 | `prefix'B_`suffix' < 0 |`prefix'C_`suffix' < 0
					
					*Set flag to 1 if total is less than sum
					 replace flag_Maize_Q`QNum' = 1 if  bothDiff_`QNum'_`season'_`suffix' < 0
				}
			}
		}
	}
*/
	
	* Flag 13: Harvest and what was done w/it - Standardized
	
	forvalues s = 1/3 {
		forvalues p = 1/2 {
			forvalues c = 1/3 {
				
					if `s' == 1 local seasonName 21a
					if `s' == 2 local seasonName 20b
					if `s' == 3 local seasonName 20c
				
				local suffix `s'_`p'_`c'
				
				gen 	sub_flag_13_`suffix' = 0
				la var 	sub_flag_13_`suffix' "Flag 13 Det.: Harvest<Done with it Season `s' Plot `p' crop `c'"
				
				local harvVar  pc1_09_`s'_`p'_`c'_kg
				local soldVar  pc1_10_`s'_`p'_`c'_kg
				local consVar  pc1_11_`s'_`p'_`c'_kg
				local spoilVar pc1_12_`s'_`p'_`c'_kg
				
				* Calculate total usage of harvest
				egen done_w_harv_`suffix' = rowtotal(`soldVar' `consVar' `spoilVar')

				* Compare usage of harvest to harvest
				replace sub_flag_13_`suffix' = 1 if (`harvVar' < done_w_harv_`suffix') & `harvVar' != .
			
			}
		}
	}

	forvalues s = 1/3 {
		egen flag_13_`s' = anymatch(sub_flag_13_`s'_*), v(1)
		la var flag_13_`s' "Flag 13 `s': Harvest is LESS than what was done with it in season `s'"
		
	}

	
	
	sum flag*
	
	* Total
	egen tot_flags 			= rowtotal(flag*)
	egen tot_sub_flags 		= rowtotal(sub_flag*)
	egen tot_all_flags 		= rowtotal(flag* sub_flag*)
	
	egen count_flags 		= anycount(flag*) 			,v(0 1)
	egen count_sub_flags 	= anycount(sub_flag*) 		,v(0 1)
	egen count_all_flags 	= anycount(flag* sub_flag*) ,v(0 1)
	
	preserve
	putexcel set "$excel\flags_per_survey.xlsx", replace
		sum tot_flags, detail
		return list
        putexcel A1 ="Sum", nformat(text) bold
		putexcel B1 ="Value", nformat(text) bold
		putexcel A2 ="Number obs", nformat(text) bold
		sleep 1000 //Makes Stata stop for 1000 milliseconds. This makes putexcel not have file access conflict with dropbox
		putexcel B2 = `r(N)'
		sleep 1000
		putexcel A3 ="Mean flags", nformat(text)
		sleep 1000
		putexcel B3 = `r(mean)', nformat(number_d2)
		sleep 1000
		putexcel A4 ="SD flags"
		sleep 1000
		putexcel B4 = `r(sd)', nformat(number_d2)
		sleep 1000
		putexcel A5 ="Median", nformat(text)
		sleep 1000
		putexcel B5 =`r(p50)', nformat(number_d2)
		sleep 1000
		putexcel A6 ="Min", nformat(text)
		sleep 1000
		putexcel B6 =`r(min)', nformat(number_d2)
		sleep 1000
		putexcel A7 ="Max", nformat(text)
		sleep 1000
		putexcel B7 =`r(max)', nformat(number_d2)
		
		
		// graph with ints per day, since table won't appear properly in the dashboard
		histogram tot_flags,  freq
		graph export "$consistency\Total number of flags.png",replace
	restore
	
	gen 	output = 0
	replace output = 1 if tot_flags >= 3 
	replace output = 1 if tot_flags == 2 & tot_all_flags >= 6
	replace output = 1 if tot_flags == 1 & tot_all_flags >= 4 

	tab tot_all_flags tot_flags, m
	tab tot_all_flags tot_flags if output == 1
	
	
	
		keep if output == 1
		
		*Deleting variables with no flags and testing if that was all variables

	

		cap assert _N == 0
		
		if _rc {
		
			sort tot_flags
		
			ds flag* sub_flag_*
			foreach var in `r(varlist)'	{
				qui sum `var'
				if r(mean)== 0	{
					drop `var'
				}
			}
			
			local orderkeep id_05 id_03 tot_flags tot_all_flags flag_* sub_flag_* 
			
			order 	`orderkeep'
			keep 	`orderkeep'
		
			local date = subinstr(c(current_date), " ", "", .)
			
			 export excel using "$excel\ResponseQuality_`date'.xlsx", firstrow(varlabels) sheetreplace
			
			 export excel using "$excel\ResponseQuality.xlsx", firstrow(varlabels) sheetreplace


			noi di ""
			noi di ""
			count
			
			noi di as error "There are `r(N)' observation(s) with too many response quality flags. Excel file ResponseQuality_`date'.xlsx saved."
			
			noi di as error "There are `r(N)' observation(s) with too many response quality flags. Excel file ResponseQuality.xlsx saved."

			noi list id_05 id_03 tot_flags tot_all_flags 
			
			gen numberSurveys =1 
			
			collapse (sum) numberSurveys tot_flags tot_all_flags flag_*  sub_flag_*, by(id_03)
			
			gen tot_flags_perSurvey = tot_flags / numberSurveys
			
			order id_03 numberSurveys tot_flags_perSurvey tot_flags tot_all_flags flag_* sub_flag_* 

			noi di ""
			noi di ""
			count
			
			noi di as error "There are `r(N)' enumerators(s) with surveys with too many response quality flags. Excel file ResponseQuality_Enum_`date'.xlsx saved."
			noi di as error "There are `r(N)' enumerators(s) with surveys with too many response quality flags. Excel file ResponseQuality_Enum.xlsx saved."
			noi list id_03  numberSurveys tot_flags_perSurvey tot_flags

		}
		else {
		
			noi di ""
			noi di ""
			count
			
			noi di "There are no observations with flags. No excel file generated."
		}
*	}

