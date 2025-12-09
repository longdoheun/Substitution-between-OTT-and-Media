clear
set more off
capture log close
cd "/Users/doheun/documents/Stata/IODS_2025" // project folder
** 나머지 경로는 전부 상대경로로 작성

* 수면 시간, 장소, OTT[연결] 사용은 jointly 일어날 수 있음.
* 예를 들어 직장에서 OTT를 틀어두고 잠에 들 수 있음. 이러한 모호한 경우에 대한 분류가 필요.


* let z \in {1, 0}, z is binary value and composite leisure is not observable.

* S / H / O / M (8 cases)
*--------------------
* 1 / z / z / z => sleeping dominates whatever status of work, media and OTT are. (8 cases)
*--------------------
* 0 / 1 / z / z => Work Place dominates whatever status of media are. (4 cases)
*--------------------
* 0 / 0 / 1 / z  => OTT
* 0 / 0 / 0 / 0 => composite

* S >> H >> O >> M >> C

// The main focus is whether they are paid or not at joint time consuming.

* sleep vs workplace : we can think of rest time in which it is not paid
* sleep vs media[OTT] : WLOG it is sleep
* media[OTT] vs workplace : for simplicity, assume that they are not slacking and watching OTT is also a working hour.

forvalues num = 21/24 {
	log using "./output/log/dv`num'.log", replace

	use "./raw_data/diary_vertical/d`num'v31_KMP_stata.dta", clear // raw diary dta by year

	drop housenum
	rename d`num'* *

	gen year = `num'

	// First, make unified time slot.

	* T_ij = { S, H, O, M, C } i means individual and j means each time slot

	label define time_allocation 1 "sleeping" 2 "work" 3 "watching OTT" 4 "composite Media" 5 "composite leisure"

	// Second, allocate each time slot exclusively by the rule above

	forvalues j = 1/96 {
		gen t`j' = cond(s`j' == 1, 1, cond(p`j' == 3, 2, cond(CA`j' == 21, 3, cond(AA`j' != 0, 4, 5)))) // S >> O >> W >> C
		
		* value labeling
		label values t`j' time_allocation
		
		local start_h = int((`j'-1)*15 / 60)
		local start_m = mod((`j'-1)*15, 60)
		local end_h = int(`j'*15 / 60)
		local end_m = mod(`j'*15, 60)
		
		local start_h_converted = cond(`start_h' < 10, "0`start_h'", "`start_h'")
		local start_m_converted = cond(`start_m' < 10, "0`start_m'", "`start_m'")
		local end_h_converted = cond(`end_h' < 10, "0`end_h'", "`end_h'")
		local end_m_converted = cond(`end_m' < 10, "0`end_m'", "`end_m'")
		
		* variable labeling
		label variable t`j' "소비 시간 `start_h_converted'`start_m_converted'-`end_h_converted'`end_m_converted'"
	}


	// Third, sum daily hours

	ds t*
	local t_vars `r(varlist)'

	* 1) sleeping hours
	local sleep_vars "" // 변환된 변수 이름을 저장할 새로운 매크로


	foreach time of local t_vars {
		

		local new_var `time'_recode
		
		gen `new_var' = (`time' == 1)
		
		local sleep_vars "`sleep_vars' `new_var'"
	}
	
	egen sleep_counts = rowtotal(`sleep_vars')
	gen sleep_hour = sleep_counts * 15
	drop t*_recode

	label variable sleep_hour "총 수면 시간 (분), 15분마다 기록"

	* 2) working hours
	local work_vars "" // 변환된 변수 이름을 저장할 새로운 매크로


	foreach time of local t_vars {
		

		local new_var `time'_recode
		
		gen `new_var' = (`time' == 2)
		
		local work_vars "`work_vars' `new_var'"
	}

	egen work_counts = rowtotal(`work_vars')
	gen working_hour = work_counts * 15
	drop t*_recode

	label variable working_hour "총 근로 시간 (분), 15분마다 기록"

	* 3) Watching OTT
	local OTT_vars "" // 변환된 변수 이름을 저장할 새로운 매크로


	foreach time of local t_vars {
		

		local new_var `time'_recode
		
		gen `new_var' = (`time' == 3)
		
		local OTT_vars "`OTT_vars' `new_var'"
	}

	egen OTT_counts = rowtotal(`OTT_vars')
	gen OTT_hour = OTT_counts * 15
	drop t*_recode

	label variable OTT_hour "총  OTT 시청 시간 (분), 15분마다 기록"

	* 3) Other Media
	local media_vars "" // 변환된 변수 이름을 저장할 새로운 매크로


	foreach time of local t_vars {
		

		local new_var `time'_recode
		
		gen `new_var' = (`time' == 4)
		
		local media_vars "`media_vars' `new_var'"
	}

	egen media_counts = rowtotal(`media_vars')
	gen media_hour = media_counts * 15
	drop t*_recode

	label variable media_hour "총  OTT 제외 미디어 사용 시간 (분), 15분마다 기록"
	
	* 5) Composite hours
	local composite_vars "" // 변환된 변수 이름을 저장할 새로운 매크로


	foreach time of local t_vars {
		

		local new_var `time'_recode
		
		gen `new_var' = (`time' == 5)
		
		local composite_vars "`composite_vars' `new_var'"
	}

	egen composite_counts = rowtotal(`composite_vars')
	gen composite_hour = composite_counts * 15
	drop t*_recode

	label variable composite_hour "총 복합(잔여) 시간 (분), 15분마다 기록"

	keep pid year m1 mm1st dd1st day1 weekend spday1 OTT_hour composite_hour sleep_hour working_hour media_hour

	rename mm1st D_mm
	rename dd1st D_dd
	rename day1 D_dayOfWeek
	rename weekend D_weekend
	rename spday1 D_spday
	
	reshape wide year D_mm D_dd D_dayOfWeek D_weekend D_spday OTT_hour composite_hour sleep_hour working_hour media_hour, i(pid) j(m1)
	
	drop year2 year3
	
	rename year1 year
	save "./final_data/temp/d`num'v31.dta", replace

	log close
}

// 패널 데이터 병합
use "./final_data/temp/d21v31.dta", clear // 2021년 데이터를 먼저 로드
forvalues num = 22/24 {
	append using "./final_data/temp/d`num'v31.dta"
}

// hid와 year를 기준으로 정렬하고 패널 데이터 세팅
sort pid year
xtset pid year

save "./final_data/mdv31.dta", replace
