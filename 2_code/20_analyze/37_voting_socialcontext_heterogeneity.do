clear
cd "$replication_root"

set more off

use 1_data/1_constructed_data/network_and_voting_stats.dta, replace


drop if VILLAGE=="8785"

global network_lists "union family friend solver lender"

foreach network in  $network_lists {
    if "`network'" == "union" {
        local long_network_name "Union"
    }
    if "`network'" == "family" {
        local long_network_name "Family"
    }
    if "`network'" == "friend" {
        local long_network_name "Friends"
    }
    if "`network'" == "lender" {
        local long_network_name "Lender"
    }
    if "`network'" == "solver" {
        local long_network_name "Solver"
    }

    _eststo clear


    * Label Vars
    label var pres_blockvoting "Pres Vote Homogeneity"
    label var LC5chair_blockvoting "LC5Chair Vote Homogeneity"
    label var lc3_competitiveness "LC3 Competitive"
    label var lc5coun_competitiveness "LC5 Council Competitive"


    * Hand-generate interactions
    gen pres_interact_block = context_index_`network' * pres_blockvoting
    label var pres_interact_block "TPP X Vote Homogeneity"

    gen LC5chair_interact_block = context_index_`network' * LC5chair_blockvoting
    label var LC5chair_interact_block "TPP X Vote Homogeneity"

    gen LC5chair_interact_lc5coun = context_index_`network' * lc5coun_competitiveness
    label var LC5chair_interact_lc5coun "TPP X LC5 Competitive"

    gen LC5chair_interact_lc3 = context_index_`network' * lc3_competitiveness
    label var LC5chair_interact_lc3 "TPP X LC3 Competitive"

    label var context_index_`network' "TPP (Union)"

    *********
    * Regs!
    *********

    eststo `network'_pres: reg pres_turnout_adultpop context_index_`network'
    eststo `network'_pres_interact: reg pres_turnout_adultpop context_index_`network' pres_blockvoting pres_interact_block

    sum pres_blockvoting
    estadd scalar stddv_block = `r(sd)': ``network'_pres_interact'

    eststo `network'_lc5: reg LC5chair_turnout_adultpop context_index_`network'
    eststo `network'_lc5_interact: reg LC5chair_turnout_adultpop context_index_`network' LC5chair_blockvoting LC5chair_interact_block

    sum LC5chair_blockvoting
    estadd scalar stddv_block = `r(sd)': ``network'_lc5_interact'

    eststo `network'_lc5_interact_lc5coun: reg LC5chair_turnout_adultpop context_index_`network' lc5coun_competitive LC5chair_interact_lc5coun, cluster(subcounty_group)

    sum lc5coun_competitive
    estadd scalar stddv_competitiveness = `r(sd)': ``network'_lc5_interact_lc5coun'

    eststo `network'_lc5_interact_lc3: reg LC5chair_turnout_adultpop context_index_`network' ///
    lc3_competitiveness LC5chair_interact_lc3 , cluster(parish_group)

    sum lc3_competitive
    estadd scalar stddv_competitiveness = `r(sd)': ``network'_lc5_interact_lc3'

    #delimit ;
    esttab  `network'_pres `network'_pres_interact `network'_lc5 `network'_lc5_interact `network'_lc5_interact_lc5coun `network'_lc5_interact_lc3
                using "3_results/context_voting_regressions_`network'_heterogeneity.tex",
                b(a2) label replace nogaps compress se(a2) bookt
                noconstant nodepvars star(* 0.1 ** 0.05 *** 0.01)
                mtitles("Pres" "Pres" "LC5Chair" "LC5Chair" "LC5Chair" "LC5Chair")
                stats(stddv_block stddv_competitiveness ,
                    labels(	"Std of Block Voting"
                            "Std of Competitiveness"));
//


     #delimit cr
     drop pres_interact LC5chair_interact*

}

*********
* Cluster counts
*********
foreach x in subcounty_group parish_group {
    inspect `x'
    local clean_clusters: display %9.0f `r(N_unique)'
    display "`clean_clusters'"
    file open myfile using 3_results/heterogeneous_num_clusters_`x'.tex, write text replace
    file write myfile "`clean_clusters'"
    file close myfile


}
