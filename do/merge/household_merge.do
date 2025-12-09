clear
set more off
capture log close
cd "/Users/doheun/documents/Stata/IODS_2025" // project folder
** 나머지 경로는 전부 상대경로로 작성

forvalues num = 21/24 {
	log using "./output/log/h`num'.log", replace
	use "./raw_data/household/h`num'v31_KMP_stata.dta", clear
	drop h`num'hid
	rename h`num'* *
	keep hid h_income1 h_income2
	gen year = `num'
	save "./final_data/temp/h`num'v31.dta", replace
	
	log close
}

// 패널 데이터 병합
use "./final_data/temp/h21v31.dta", clear // 2021년 데이터를 먼저 로드
forvalues num = 22/24 {
	append using "./final_data/temp/h`num'v31.dta"
}

// hid와 year를 기준으로 정렬하고 패널 데이터 세팅
sort hid year
xtset hid year

save "./final_data/hv31.dta", replace
