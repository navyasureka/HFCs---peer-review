
	ieboilstart, versionnumber(14.1)
    `r(version)'
	
* ========================		
* Set Dropbox directory
* ========================
	
	
	global roshni		0
	global guillaume    0
    global anais        0
	global janvier      0
    global navya        1

	if $roshni			{
	global dropbox				"C:/Users/wb528092/Dropbox"
	}
	if $guillaume		{
	global dropbox				"C:/Users/wb524189/Dropbox"
	}
	if $anais		{
	global dropbox				"C:/Users/atoun/Dropbox"
	}
	if $janvier         {       
	global dropbox              "C:/Users/wb576587/Dropbox (Janvier Rurangwa)"
	}
	if $navya      {       
	global dropbox              "C:/Users/hp/Dropbox"
	}

	
	
* ===============
* Set filepaths
* ===============

	global project 				"$dropbox/Rwanda Land Markets" 	
	global raw_data             "$project/8_fup3/raw/Survey"
 	global data					"$project/8_fup3/data/Training"
	global dofile				"$project/8_fup3/dofiles"
	global checksdo				"$dofile/data checks/Muyanza_fup2/Survey"
	global import				"$dofile/import and append/Survey"
	global logfile				"$dofile/log files/Training"				
	global output               "$project/8_fup3/outputs/Survey"
	global excel				"$output/excel"
	global consistency			"$output/consistency checks"
	global sample				"$data/sampling/final"
	global backchecks			"$excel/backchecks"
	
	
*****************************
*	 Consistency Checks 	*
*****************************

	
***********************************************
*	Technical Checks 	
*	Each case caught by these checks should be 
*	reported and understood as it might be a 
*	sign of us not recodring all data correctly
***********************************************
	
	do "$checksdo/1_muyanza_fup2_consistencychecksTech.do"
	
***********************************************
*	Response Quality Checks
*	
***********************************************	

	do "$checksdo/2_muyanza_fup2_consistencychecks.do"

***********************************************
*	Survey Time Checks
*	
***********************************************	

	/*do "$checksdo/3_muyanza_fup2_surveytime.do"
	do "$checksdo/4_muyanza_fup2_moduletime.do"*/
	
