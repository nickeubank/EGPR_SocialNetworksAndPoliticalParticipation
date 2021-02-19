clear
cd "$replication_root"
set more off

use 1_data/1_constructed_data/network_and_voting_stats.dta, replace

drop if VILLAGE=="8785"

global network_lists "union"
foreach dropcount in 5 10 15 {

foreach network in  $network_lists {
    if "`network'" == "union" {
        local long_network_name "Union"
    }
    * Get significance
    reg LC5chair_turnout_adultpop context`dropcount'_index_`network'
    local pre_beta_LC5 = _b[context`dropcount'_index_`network']
    local t = _b[context`dropcount'_index_`network']/_se[context`dropcount'_index_`network']
    local p = 2*ttail(e(df_r),abs(`t'))
    local p_LC5: display %9.2f `p'
    local beta_LC5: display %9.2f `pre_beta_LC5'

    reg pres_turnout_adultpop context`dropcount'_index_`network'
    local pre_beta_pres = _b[context`dropcount'_index_`network']
    local t = _b[context`dropcount'_index_`network']/_se[context`dropcount'_index_`network']
    local p = 2*ttail(e(df_r),abs(`t'))
    local p_pres: display %9.2f `p'
    local beta_pres: display %9.2f `pre_beta_pres'


    #delimit ;
    twoway (lfitci pres_turnout_adultpop context`dropcount'_index_`network')
           (scatter pres_turnout_adultpop context`dropcount'_index_`network') ,
          ytitle("Presidential Turnout")
          legend(off)
          xtitle("TPP, `long_network_name'")
          name(presidential_`network', replace)
          plotregion(color(white))
         graphregion(color(white))
          note("Beta:`beta_pres', P-Value:`p_pres'");

    twoway (lfitci LC5chair_turnout_adultpop context`dropcount'_index_`network')
           (scatter LC5chair_turnout_adultpop context`dropcount'_index_`network') ,
          ytitle("LC5 Turnout")
          legend(off)
          plotregion(color(white))
            graphregion(color(white))
          xtitle("TPP, `long_network_name'")
          name(LC5_`network', replace)
          note("Beta:`beta_LC5', P-Value:`p_LC5'");


};

    graph combine  LC5_union presidential_union,
            title("Theoretically Predicted Participation & Turnout")
            subtitle("With `dropcount' Highest Centrality Dropped")
            plotregion(color(white))
            graphregion(color(white));

    graph export 3_results/context_voting_scatter_drop`dropcount'.pdf, replace;
};
