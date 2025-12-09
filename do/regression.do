clear
set more off
capture log close
cd "/Users/doheun/documents/Stata/IODS_2025"
** 나머지 경로는 전부 상대경로로 작성

log using "./output/log/regression.log", replace

use "./final_data/OTT_media_panel.dta", clear


* 분석에 사용할 공통 샘플
drop if D_spday1 == 1 | D_spday2 == 1 | D_spday3 == 1 // drop special day
gen common_sample = 1
replace common_sample = 0 if missing(m_OTT1) | m_OTT1 == 1 | missing(m_OTT2) | m_OTT2 == 1 | missing(m_OTT3) | m_OTT3 == 1



*Day1
zoib m_OTT1 lnWage i.D_weekend1  log_total_media_hour1 i.employment_type i.age i.area_siz i.hhldsiz i.gender i.school i.year_month1 if common_sample == 1, zeroinflate(lnWage i.D_weekend1 log_total_media_hour1 i.employment_type i.age i.area_siz i.hhldsiz i.gender i.school i.year_month1)  noone //robust cluster(pid) // suest 실행시 robust cluster(pid)는 주석 처리
estimates store m1

scalar beta1_Day1 = _b[proportion:lnWage]

** Money Intensity 추정

su alpha_O1 if e(sample) == 1 // 대체탄력성 = 1.1702557
scalar alpha_O1_hat = r(mean)
su alpha_I1 if e(sample) == 1
scalar alpha_I1_hat = r(mean)



*Day2
zoib m_OTT2 lnWage i.D_weekend2 log_total_media_hour2 i.employment_type i.age i.area_siz i.hhldsiz i.gender i.school i.year_month2 if common_sample == 1, zeroinflate(lnWage i.D_weekend2 log_total_media_hour2 i.employment_type i.age i.area_siz i.hhldsiz i.gender i.school i.year_month2) noone //robust cluster(pid) // suest 실행시 robust cluster(pid)는 주석 처리
estimates store m2

scalar beta1_Day2 = _b[proportion:lnWage]

** Money Intensity 추정

su alpha_O2 if e(sample) == 1 // 대체탄력성 = 1.2328072
scalar alpha_O2_hat = r(mean)
su alpha_I2 if e(sample) == 1
scalar alpha_I2_hat = r(mean)



*Day3
zoib m_OTT3 lnWage i.D_weekend3 log_total_media_hour3 i.employment_type i.age i.area_siz i.hhldsiz i.gender i.school i.year_month3 if common_sample == 1, zeroinflate(lnWage i.D_weekend3 log_total_media_hour3 i.employment_type i.age i.area_siz i.hhldsiz i.gender i.school i.year_month3) noone //robust cluster(pid) // suest 실행시 robust cluster(pid)는 주석 처리
estimates store m3

scalar beta1_Day3 = _b[proportion:lnWage]

** Money Intensity 추정

su alpha_O3 if e(sample) == 1 // 대체탄력성 = 1.2321418
scalar alpha_O3_hat = r(mean)
su alpha_I3 if e(sample) == 1
scalar alpha_I3_hat = r(mean)




** Elasticity
scalar sigma1 = beta1_Day1 / (alpha_O1_hat - alpha_I1_hat) + 1
scalar sigma2 = beta1_Day2 / (alpha_O2_hat - alpha_I2_hat) + 1
scalar sigma3 = beta1_Day3 / (alpha_O3_hat - alpha_I3_hat) + 1

di sigma1 sigma2 sigma3


** 표 저장
esttab m1 m2 m3 using "./output/table/zib_table.tex", ///
    replace                 /* 기존 파일 덮어쓰기 */  ///
    label                   /* 변수 라벨 사용 */       ///
    b(%9.3f) se(%9.3f)      /* 계수(b)와 표준 오차(se) 소수점 자리 지정 */ ///
    star(* 0.10 ** 0.05 *** 0.01) /* 유의 수준 지정 */ ///
    title("ZIB Results")    /* 표 제목 지정 */      ///
    nonotes                 /* 주석(notes) 제거 */     ///
    drop(_cons)             /* 상수항 제거 (선택 사항) */ ///
    mtitle(Day\_1 Day\_2 Day\_3) /* 각 모델의 제목 지정 */ ///
    nogaps                  /* 열 간격 제거 */         ///
    stats(r2 N, fmt(%9.3f 0)) /* R-squared와 N 출력 형식 지정 */ ///
    booktabs

log close



** Robustness Check
log using "./output/log/robustness.log", replace

* 1. 추정된 베타1들이 통계적으로 같음을 기각하지 못하는가? (suest 동일성 검증)

suest m1 m2 m3, cluster(pid) // 실행 전 오류 방지를 위해 robust 와 cluster() option은 주석처리해야 함
test [m1_proportion]lnWage = [m2_proportion]lnWage = [m3_proportion]lnWage

* 2. OTT 시청 비중과 주말 여부는 관측일동안 일관되는가?
alpha m_OTT1 m_OTT2 m_OTT3, item detail
alpha D_weekend1 D_weekend2 D_weekend3, item detail

log close
