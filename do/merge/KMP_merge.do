clear
set more off
capture log close
cd "/Users/doheun/documents/Stata/IODS_2025"
** 나머지 경로는 전부 상대경로로 작성

log using "./output/log/merge.log", replace

use "./final_data/pv31.dta", clear 

** 1. 키 변수(pid, year)를 기준으로 1:1 merge 실행
merge 1:1 pid year using "./final_data/mdv31.dta"

// 합치기 결과 확인
tabulate _merge

drop _merge

** 2. household data와 personal data를 merge
merge m:1 hid year using "./final_data/hv31.dta"


** personal과 diary는 응답했으나 household survey의 응답하지 않은 경우 
drop if _merge == 1 
drop _merge


** weekend 변수 labeling 변경
label define D_weekend 0 "주중" 1 "주말"

forvalues num = 1/3 {
	replace D_weekend`num' = (D_weekend`num' == 2)
	label values D_weekend`num' D_weekend
}

tab D_weekend1
tab D_weekend2
tab D_weekend3

** 배우자의 유무 
gen spouse = (mar == 2)
label define spouse_label 0 "배우자 없음" 1 "배우자 있음"
label values spouse spouse_label
label variable spouse "배우자의 유무"

** employment type
gen employment_type = job2
replace employment_type = 0 if employment_type ==.
replace employment_type = 0 if employment_type == 4
label define employment_type_label 0 "무직" 1 "임근 근로자" 2 "고용주" 3 "단독 자영업자"

label values employment_type employment_type_label
label variable employment_type "고용 형태"

** wage 변수 추가
gen wage = .

forvalues num = 2/18{
	replace wage = (`num'-2)*50 + 25 if income1 == `num' // 설문 항목의 중간값을 선정
}
replace wage = 0 if income1 == 1 // 소득 없음

label variable wage "개인 월평균 소득 (항목별 중간, 만원)"

tab wage

** 미디어 디지털 컨텐츠 비용 변수 
ds *_payment
local payment_vars "`r(varlist)'"
di "`payment_vars'"

foreach var of varlist `payment_vars' {
    forvalues num = 1/8{
		replace `var' = 0.5 * ( (2*`num') -1 ) * 0.5 if `var' == `num' // 설문 항목의 중간값을 선정 단위 만원
	}
	replace `var' = 0 if `var' == .
	tab `var'
}

** 인당 미디어 지출 변수 생성
gen OTT_payment = svod_payment + tvod_payment
label variable OTT_payment "OTT 전체 월평균 지출 (항목별 중간, 만원)"
gen other_media_payment = evod_payment + contents_payment + music_payment + game_payment + etc_payment
label variable other_media_payment "OTT 제외 미디어 월평균 지출 (항목별 중간, 만원)"

** 비율 변수 생성
forvalues num = 1/3{
	
	// 비수면 시간
	gen non_sleep_hour`num' = OTT_hour`num' + composite_hour`num' + working_hour`num' + media_hour`num'
	label variable non_sleep_hour`num' "[`num'일차] 비수면 시간 (15분 단위 측정 결과)"
	
	// 전체 미디어 사용 시간
	gen total_media_hour`num' = OTT_hour`num' + media_hour`num'
	label variable total_media_hour`num' "[`num'일차] 전체 미디어 사용 시간 (15분 단위 측정 결과)"
	
	// 비수면 시간 중 OTT 시청 시간의 비중
	gen L_OTT`num' = OTT_hour`num' / non_sleep_hour`num'
	label variable L_OTT`num' "[`num'일차] 비수면 시간 중 OTT 시청 시간의 비중"
	
	// 비수면 시간 중 일하는 시간의 비중
	gen H`num' = working_hour`num' / non_sleep_hour`num'
	label variable H`num' "[`num'일차] 비수면 시간 중 일하는 시간의 비중"
	
	// 비수면 시간 중 나머지 복합 시간의 비중
	gen L_composite`num' = composite_hour`num' / non_sleep_hour`num'
	label variable L_composite`num' "[`num'일차] 비수면 시간 중 나머지 복합 시간의 비중"
	
	// 비수면 시간 중 OTT를 제외한 미디어 사용 시간의 비중
	gen L_media`num' = media_hour`num' / non_sleep_hour`num'
	label variable L_media`num' "[`num'일차] 비수면 시간 중 OTT를 제외한 미디어 사용 시간의 비중"
	
	// 전체 미디어 사용시간 중 OTT 시청시간의 비중
	gen m_OTT`num' = OTT_hour`num' / total_media_hour`num'
	label variable m_OTT`num' "[`num'일차] 전체 미디어 사용시간 중 OTT 시청시간의 비중"
	
	// 전체 미디어 사용시간 중 OTT를 제외한 미디어 사용시간의 비중
	gen m_media`num' = media_hour`num' / total_media_hour`num'
	label variable m_media`num' "[`num'일차] 전체 미디어 사용시간 중 OTT를 제외한 미디어 사용시간의 비중"
}


gen log_total_media_hour1 = ln(total_media_hour1)
gen log_total_media_hour2 = ln(total_media_hour2)
gen log_total_media_hour3 = ln(total_media_hour3)


** log wage로 변경 
gen lnWage = ln(wage)
drop if lnWage == . // 소득이 없는 사람들은 배제, 분석은 소득이 기회비용인 사람들로 한함.

** Money intensity 계산을 위한 변수
forvalues num = 1/3{
	// [0,1] 사이에 정의되기 위해서 소비시간이 있거나 유료구독을 하는 경우만을 포함하여 평균
	gen alpha_O`num' = OTT_payment / ( OTT_payment + wage*L_OTT`num') if L_OTT`num' > 0 | OTT_payment > 0
	
	// [0,1] 사이에 정의되기 위해서 소비시간이 있거나 유료결제를 하는 경우만을 포함하여 평균
	gen alpha_I`num' = other_media_payment / (other_media_payment + wage*L_media`num') if L_media`num' > 0 | other_media_payment > 0
}

** 다이어리 데이터 기록달과 연도를 엮어서 시간변수 생성 
egen year_month1 = group(year D_mm1)
egen year_month2 = group(year D_mm2)
egen year_month3 = group(year D_mm3)

** 변수 순서 조정 및 정렬
order d26*, last

order pid hid year

sort pid year

xtset pid year

xtdescribe

save "./final_data/OTT_media_panel.dta", replace

log close
