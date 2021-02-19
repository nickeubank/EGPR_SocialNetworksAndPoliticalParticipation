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

    * Get significance
    eststo `network'_pres: reg pres_turnout_adultpop context_index_`network'
    local t = _b[context_index_`network']/_se[context_index_`network']
    local pre_beta_pres = _b[context_index_`network']
    local p = 2*ttail(e(df_r),abs(`t'))
    local p_pres: display %9.2f `p'
    local beta_pres: display %9.2f `pre_beta_pres'

    eststo `network'_lc5: reg LC5chair_turnout_adultpop context_index_`network'
    local t = _b[context_index_`network']/_se[context_index_`network']
    local pre_beta_lc5 = _b[context_index_`network']
    local p = 2*ttail(e(df_r),abs(`t'))
    local p_lc5: display %9.2f `p'
    local beta_lc5: display %9.2f `pre_beta_lc5'

    * Put in one regression to get statistical significance of difference
     preserve
        keep LC5chair_turnout_adultpop pres_turnout_adultpop context_index_`network'
        rename LC5chair_turnout_adultpop turnout_2
        rename pres_turnout_adultpop turnout_1
        gen village = _n
        reshape long turnout_, i(village) j(election)
        gen lc5_election = election == 2
        label var lc5_election "LC5 Chair Election"
        gen lc5_context_interaction = lc5_election * context_index_`network'
        label var lc5_context_interaction "LC5 Election * Eqm Participation"

        eststo `network'_paired: reg turnout context_index_`network' lc5_context_interaction lc5_election, cluster(village)
        local t = _b[lc5_context_interaction]/_se[lc5_context_interaction]
        local p = 2 * ttail(e(df_r), abs(`t'))
        local p_diff_`network': display %9.2f `p'
    restore

    #delimit ;
    twoway (lfitci pres_turnout_adultpop context_index_`network')
           (scatter pres_turnout_adultpop context_index_`network') ,
          ytitle("Presidential Turnout")
          legend(off)
          xtitle("TPP, `long_network_name'")
          plotregion(color(white))
          graphregion(color(white))
          name(presidential_`network', replace)
          note("Beta:`beta_pres', P-Value:`p_pres'");

    twoway (lfitci LC5chair_turnout_adultpop context_index_`network')
           (scatter LC5chair_turnout_adultpop context_index_`network') ,
          ytitle("LC5 Turnout")
          legend(off)
          plotregion(color(white))
          graphregion(color(white))
          xtitle("TPP, `long_network_name'")
          name(LC5_`network', replace)
          note("Beta:`beta_lc5', P-Value:`p_lc5'");

    * Dumb hack to get label to work;
    gen lc5_election = .;
    label var lc5_election "LC5 Chair Election";
    gen lc5_context_interaction = .;
    label var lc5_context_interaction "LC5 Election * Eqm Participation";

    esttab  `network'_pres `network'_lc5 `network'_paired using "3_results/context_voting_regressions_`network'.tex",
                b(a2) label replace nogaps compress se(a2) bookt
                noconstant nodepvars star(* 0.1 ** 0.05 *** 0.01)
                mtitles("Presidential" "LC5 Chair" "Pooled");
    drop lc5_election lc5_context_interaction;
};

    graph combine  LC5_union presidential_union ,
        title("Theoretically Predicted Participation & Turnout")
        graphregion(color(white))
        plotregion(color(white))
        note("Difference between elections significant at p =`p_diff_union'");
    graph export 3_results/context_voting_scatter.pdf, replace;

    foreach race in "LC5" "presidential" {;

        if "`race'" == "presidential" {;
            local title_race = "Presidential";
        };
        if "`race'" == "LC5" {;
            local title_race = "Local Council";
        };

        graph combine  `race'_family `race'_friend `race'_solver `race'_lender ,
            title("Theoretically Predicted Participation & `title_race' Turnout")
            graphregion(color(white))
            plotregion(color(white));
        graph export 3_results/context_voting_scatter_bytype_`race'.pdf, replace;
};
