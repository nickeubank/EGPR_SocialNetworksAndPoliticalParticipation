clear
set more off
*************
* Import network statistics output by Python script
* and merge with voting statistics at village level.
*************

* Get own path here
cd "$replication_root"

global networks_list "union friend family lender solver unionRE  "
global diffusion_sample_size = 1000
global coord_sim_size = 2500

foreach i in  info_diffusion_and_network_statistics coordination_statistics_drop5 ///
              coordination_statistics_drop10  coordination_statistics_drop15 {

    if "`i'" == "info_diffusion_and_network_statistics" {
        local sim_size = $diffusion_sample_size
    }
    if regexm("`i'", "(coordination_statistics_drop)(.*)")   {
        local dropcount = regexs(2)
        local sim_size = $coord_sim_size
    }


    use "1_data/1_constructed_data/`i'_n`sim_size'.dta", clear
    rename index town_name
    gen DataSetID = .
    capture renvars coord_d`dropcount'_vcount_* , predrop(9)
    capture renvars _vcount_* , predrop(1)

    * Put DataSetIDs into network stats.
    * Taken from 14_network_mapping/2_do/6_SMSArua_NetworkMapping_analysis.do, confirmed by direct comparison of names
    * with 15_Previously_Restricted/Final DataSets/Village and Cluster/Village_Data_2016_Census_Analysis_Clean_withLegacyDataSetIDs_20170129.dta
    * and by cross-testing names with merged census data below.

    replace DataSetID = 1341 if town_name=="3221"
    replace DataSetID = 140  if town_name=="3168"
    replace DataSetID = 299  if town_name=="9849"
    replace DataSetID = 163  if town_name=="7296"
    replace DataSetID = 840  if town_name=="6360"
    replace DataSetID = 391  if town_name=="8640"
    replace DataSetID = 302  if town_name=="3936"
    replace DataSetID = 905  if town_name=="7350"
    replace DataSetID = 1171 if town_name=="2718"
    replace DataSetID = 180  if town_name=="8785"
    replace DataSetID = 947  if town_name=="3713"
    replace DataSetID = 756  if town_name=="7764"
    replace DataSetID = 843  if town_name=="6040"
    replace DataSetID = 101  if town_name=="7018"
    replace DataSetID = 1372 if town_name=="6358"
    replace DataSetID = 750  if town_name=="9716"

    duplicates report town_name
    assert r(N) == r(unique_value)

    * Spot check to make sure my summary states match to summary states from Romain
    * both for calculations and network-to-village-name matching.
    * Checked from 14_network_mapping/5_output/final_report_v3
    if "`i'" == "info_diffusion_and_network_statistics" {

        sum vcount_friend if town_name == "8785"
        assert r(mean) == 30

        sum vcount_friend if town_name == "3221"
        assert r(mean) == 237

        sum vcount_friend if town_name == "7764"
        assert r(mean) == 254
    }
    if regexm("`i'", "(coordination_statistics_drop)(.*)")   {
        renvars vcount_* town_name, postfix("_dropmeasures`dropcount'")
    }

    if "`i'" == "info_diffusion_and_network_statistics" {
      local i = "info_diffusion"
    }

    sort town_name
    tempfile `i'
    save ``i'', replace

}

*************
* Merge up
*************

use "1_data/0_source_data/anonymized_villages_with_voting_effectiveness.dta", clear

***
* Main Network Stats
***

sort DataSetID
merge 1:1 DataSetID using `info_diffusion'
keep if _m==3
drop _m
assert _N==16

assert village==town_name
* Little network best come from little village!
assert adult_pop < 50 if vcount_union < 50

***
* Coordination minus central agents
***
foreach dropcount in 5 10 15 {
  sort DataSetID
  merge 1:1 DataSetID using `coordination_statistics_drop`dropcount''
  assert _m==3
  assert _N==16
  drop _m
}


foreach i in town_name  vcount_union {
  foreach dropcount in 5 10 15 {
    assert `i' == `i'_dropmeasures`dropcount'
  }
}
drop *_dropmeasures*

****
* Cleaning and organization
****



* Gather
local max_steps = 30
local plist = "035 060"
foreach network in $networks_list {

    renvars dm_*, presub("dm_`network'" "dm_shr_`network'")

    * Create normalizations of diffusion
    foreach p of local plist {
        forvalues s = 1/`max_steps' {
            local s2 = `s' * 2
            gen dm_num_`network'_p`p'_s`s2' = dm_shr_`network'_p`p'_s`s2' * vcount_`network'
        }
    }

    * Regulars
    foreach p of local plist {
        forvalues s = 1/`max_steps' {
            local s2 = `s' * 2

            label var dm_num_`network'_p`p'_s`s2' "Num people,p`p',s`s2',`network'"
            label var dm_shr_`network'_p`p'_s`s2' "Share of network,p`p',s`s2',`network'"

        }
    }

    label var evcent_skew_`network' "Centrality Skewness, 'network'"
    label var infomap_frac_`network' "Fragmentation (Infomap)"
    label var blondel_frac_`network' "Fragmentation (Blondel)"

    capture drop avg_degree_`network'
    gen avg_degree_`network' = ecount_`network' / vcount_`network'
    label var avg_degree_`network' "Average Degree"


}



* Add political indices
rename village VILLAGE
sort VILLAGE
merge 1:1 VILLAGE using 1_data/1_constructed_data/political_participation_vars.dta
assert _m == 3
drop _m

* add political games
sort VILLAGE
merge 1:1 VILLAGE using 1_data/1_constructed_data/behavioral_game_vars.dta
assert _m == 3
drop _m

* Add social context measure
rename VILLAGE index
merge 1:1 index using 1_data/1_constructed_data/coordination_statistics_n${coord_sim_size}.dta
assert _m == 3
drop _m

rename index VILLAGE



* Check social context results
foreach x in cr_friend_m06_s05_conv cr_friend_m06_s025_conv ///
             cr_friend_m07_s05_conv cr_friend_m07_s025_conv ///
             cr_friend_m05_s05_conv  ///
             cr_union_m06_s05_conv cr_union_m06_s025_conv ///
             cr_union_m07_s05_conv cr_union_m07_s025_conv ///
             cr_union_m05_s05_conv {

    assert `x' == 1
}

assert coord_ecount_friend == ecount_friend
assert coord_vcount_friend == vcount_friend
assert coord_vcount_union == vcount_union
drop coord_*count_*


foreach drops in "" "5" "10" "15" {
    foreach x in $networks_list {
        if "`x'" == "union" | "`drops'" == "" {
            pca cr`drops'_`x'_m06_s05_mean  ///
                cr`drops'_`x'_m06_s025_mean   ///
                cr`drops'_`x'_m07_s05_mean  ///
                cr`drops'_`x'_m07_s025_mean   ///
                cr`drops'_`x'_m05_s05_mean
            predict context`drops'_index_`x'

            foreach m in 5 6 7 {
                foreach s in 5 25 {
                    label var cr_`x'_m0`m'_s0`s'_mea "Mean 0.`m', SD 0.`s'"
                }
            }
        }
    }
}


* Get better naming conventions for reciprocated networks
label var context_index_union "Eqm Participation Index (Union)"
label var context_index_family "Eqm Participation Index (Family)"
label var context_index_friend "Eqm Participation Index (Friends)"
label var context_index_lender "Eqm Participation Index (Lender)"
label var context_index_solver "Eqm Participation Index (Solver)"

label var context_index_unionRE "Eqm Participation Index (UnionRE)"

drop *friendRE*
drop *familyRE*
drop *lenderRE*
drop *solverRE*

* Save
saveold 1_data/1_constructed_data/network_and_voting_stats.dta, replace version(12)
