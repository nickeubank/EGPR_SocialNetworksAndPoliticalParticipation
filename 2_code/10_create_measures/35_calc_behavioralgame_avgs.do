clear

cd "$replication_root"

use "1_data/0_source_data/anonymized_behavioralgames.dta", clear
keep resid DataSetID TREATMENT village village_rec confirmunderstanding qf*
tab TREATMENT

* Make sure understood
keep if confirmunderstanding == 1

gen test1 = qf1 + qf2 + qf6 + qf7
assert test1 == 2000
drop test1

assert village != ""

bysort village: egen game_strangerallocation = mean(qf2)

keep village game_*
duplicates drop
assert _N < 17
rename village VILLAGE

save 1_data/1_constructed_data/behavioral_game_vars.dta, replace
