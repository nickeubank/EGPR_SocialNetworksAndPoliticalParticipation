clear
cd "$replication_root"

set more off
use 1_data/1_constructed_data/network_and_voting_stats.dta, replace

global networks_list "union"


eststo clear

label var LC5chair_turnout_adultpop "LC5"
label var pres_turnout_adultpop "Pres"

label var context_index_union "TPP (Union)"
label var context_index_friend "TPP (Friends)"
label var context_index_family "TPP (Family)"
label var context_index_lender "TPP (Lender)"
label var context_index_solver "TPP (Solver)"

gen log_vcount_union = log(vcount_union)
label var log_vcount_union "(Log) Network Size"

label var sc_frac "ELF"
label var primary_comp_sc "Educ"

foreach pol_level in LC5chair pres {
    eststo clear
    if("`pol_level'" == "LC5chair") {
        local long_pol_level = "LC5"
    }
    if("`pol_level'" == "pres") {
        local long_pol_level = "Pres"
    }


    foreach control  in `"if VILLAGE!= "8785""' ///
                        `"sc_frac if VILLAGE != "8785""' ///
                        `"primary_comp_sc if VILLAGE != "8785""' ///
                        `"log_vcount_union if VILLAGE!="8785""' ///
                        `"if VILLAGE!="8785" & avg_vil_concentration_pres > 0.3 & avg_vil_concentration_pres !=."' ///
                        "" ///
                        "log_vcount_union"{
        foreach network in $networks_list{

         eststo: reg `pol_level'_turnout_adultpop context_index_`network' `control'

        }
    }

    foreach x in "Basic" "ELF" "Educ" "Size" "Concentrate" "W/16th Village" "W/16th Village" {
        local titles = "`titles' `x'"
    }
    display `"`titles'"'


    esttab using 3_results/context_robustness_`pol_level'.tex, ///
        b(a2) label title("Robustness for `long_pol_level' Election\label{tablerobustness`pol_level'}") ///
        mtitles(`titles') ///
         star(* 0.1 ** 0.05 *** 0.01) ///
        noconstant replace ///
        nogaps compress se(a2) bookt ///
        nodepvars

}
