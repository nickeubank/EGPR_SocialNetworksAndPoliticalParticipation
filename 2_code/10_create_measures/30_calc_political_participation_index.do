clear

cd "$replication_root"

use 1_data/0_source_data/anonymized_village_survey, clear

* Small number of people say their village isn't village
* where working.
count if self_village != village & self_village !=""
assert r(N) < 12
drop if self_village != village & self_village !=""
drop self_village

* Count share that know about ubridge
recode qd1 (3=.) (2=0) (1=1)
rename qd1 info_ubridgeawareness
label drop qd1
sum info_ubridgeawareness

* qe2b_None is a refused to answer. Doesn't appear to apply
* to all -- people have some responses fielded -- but
* since I can't really tell what they refused to
* answer, prefer to drop.

* Recode / rename.
gen pol_generaleffectiveness = qe2a if qe2b_None != 1

gen pol_attendmeeting = (qe2b_Attended == 1) if qe2b_None != 1
gen pol_contribute_member = (qe2b_Contributedmember == 1) if qe2b_None != 1
gen pol_contribute_project_cash = (qe2b_Contributesproject == 1) if qe2b_None != 1
gen pol_contribute_project_labour = (qe2b_Contributedlabour == 1) if qe2b_None != 1
gen pol_reported_leader = (qe2b_Reportedlead == 1) if qe2b_None != 1
gen pol_reported_gov = (qe2b_Reportedgov == 1) if qe2b_None != 1
gen pol_contribute_project_any = ((pol_contribute_project_labour == 1) | (pol_contribute_project_cash == 1)) & qe2b_None != 1

alpha pol_contribute_member pol_contribute_project_cash pol_contribute_project_labour pol_attendmeeting
collapse (mean) pol_* (mean) info_, by(village)

sort village
duplicates report village
assert r(N) == r(unique_value)
rename village VILLAGE

save 1_data/1_constructed_data/political_participation_vars.dta, replace
