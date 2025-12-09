clear
set more off
capture log close


log using "./output/log/summary.log", replace

use "./final_data/OTT_media_panel.dta", clear


* 분석에 사용할 공통 샘플
drop if D_spday1 == 1 | D_spday2 == 1 | D_spday3 == 1
gen common_sample = 1
replace common_sample = 0 if missing(m_OTT1)| m_OTT1 == 1 | missing(m_OTT2) | m_OTT2 == 1 | missing(m_OTT3) | m_OTT3 == 1


* 연속변수 기술통계량
su if common_sample == 1


* 범주형 변수 기술통계량
tab gender if common_sample == 1
tab employment_type if common_sample == 1
tab school if common_sample == 1
tab area_siz if common_sample == 1
tab hhldsiz if common_sample == 1

** 종속변수의 분포

forvalues day = 1/3 {
	//1일차
	histogram m_OTT`day', fcolor(blue) lcolor(blue) graphregion(fcolor(white)) ///
		aspectratio(1) ///
		saving("./output/graph/OTT`day'_total.gph", replace)
	histogram m_OTT`day' if m_OTT`day' != 0, fcolor(blue) lcolor(blue) graphregion(fcolor(white)) ///
		aspectratio(1) ///
		saving("./output/graph/OTT`day'_0to1.gph", replace)
		
	graph combine "./output/graph/OTT`day'_total.gph" "./output/graph/OTT`day'_0to1.gph"
	graph export "./output/graph/dist_M_OTT`day'.png", replace
}

** Diary data 기술통게량
forvalues num = 1/3{
	su H`num' L_composite`num' L_OTT`num' L_media`num' if D_weekend`num' == 1 & common_sample == 1
	su H`num' L_composite`num' L_OTT`num' L_media`num' if D_weekend`num' == 0 & common_sample == 1
}


// 단순 선형관계는 보고 싶은 부분을 포착하지 못함.
twoway scatter L_OTT1 L_media1
twoway scatter L_OTT2 L_media2
twoway scatter L_OTT3 L_media3

log close
