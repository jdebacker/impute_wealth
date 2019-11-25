foreach year of numlist 1962 1964 1966/2010 {
use "$root/output/dinafiles/usdina`year'.dta"
compress
saveold "$root/output/dinafiles/usdina`year'.dta", version(12) replace
}
