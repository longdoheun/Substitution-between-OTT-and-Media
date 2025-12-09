clear
set more off
capture log close

forvalues num = 21/24 {
	log using "output/log/p`num'.log", replace

	use "./raw_data/personal/p`num'v31_KMP_stata.dta", clear // original personal.dta by year

	** about OTT
	rename p*d26039 OTT_week_hour
	rename p*d26043 OTT_weekend_hour
	label variable OTT_week_hour "지난 3개월 일평균 OTT 주중 이용시간 (단위 : 분)"
	label variable OTT_weekend_hour "지난 3개월 일평균 OTT 주말 이용시간 (단위 : 분)"
	
	** OTT 서비스 비용
	rename p*d26058 svod_payment
	label variable svod_payment "OTT 서비스 월평균 지출 금액 - 월정액제 가입형(SVOD)(리코드)"

	rename p*d26056 tvod_payment
	label variable tvod_payment "OTT 서비스 월평균 지출 금액 - 건당 결제형(TVOD)(리코드)"


	** 다른 미디어 비용
	rename p*c05047 evod_payment
	label variable evod_payment "온라인 디지털 콘텐츠 월평균 지출금액 - 교육동영상(리코드)"

	rename p*c05002 contents_payment
	label variable contents_payment "디지털 콘텐츠 월평균 지출금액 - 온라인 뉴스/잡지/E-book(웹툰/웹소설 포함)(리코드)"

	rename p*c05008 music_payment
	label variable music_payment "온라인 디지털 콘텐츠 월평균 지출금액 - 음악(리코드)"

	rename p*c05010 game_payment
	label variable game_payment "온라인 디지털 콘텐츠 월평균 지출금액 - 게임(리코드)"

	rename p*c05016 etc_payment
	label variable etc_payment "온라인 디지털 콘텐츠 월평균 지출금액 - 기타(리코드)"
	
	drop p*pid p*housenum
	rename p`num'* *
	
	// 남길 변수들
	keep pid hid area gender byear age age1 hhldsiz area_siz school mar income1 income job* OTT_week_hour OTT_weekend_hour svod_payment tvod_payment evod_payment contents_payment music_payment game_payment etc_payment d26*

	gen year = `num'
	save "./final_data/temp/p`num'v31.dta", replace

	log close
}

// 패널 데이터 병합
use "./final_data/temp/p21v31.dta", clear // 2021년 데이터를 먼저 로드
forvalues num = 22/24 {
	append using "./final_data/temp/p`num'v31.dta"
}

// hid와 year를 기준으로 정렬하고 패널 데이터 세팅
sort pid year hid
xtset pid year

save "./final_data/pv31.dta", replace
// collapse (median) L_OTT=OTT_weekend_hour, by(wage)
// twoway (connected L_OTT wage, msize(medium) mlabel(L_OTT))
