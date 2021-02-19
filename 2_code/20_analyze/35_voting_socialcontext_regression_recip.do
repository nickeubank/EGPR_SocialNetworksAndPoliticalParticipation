clear
cd "$replication_root"
set more off

use 1_data/1_constructed_data/network_and_voting_stats.dta, replace

drop if VILLAGE=="8785"


global network_lists "unionRE "

foreach network in  $network_lists {
    if "`network'" == "unionRE" {
        local long_network_name "Union (Friend and Family Reciprical Ties Only)"
    }



    * Get significance
    reg LC5chair_turnout_adultpop context_index_`network'
    local t = _b[context_index_`network']/_se[context_index_`network']
    local pre_beta_lc5 = _b[context_index_`network']
    local p = 2*ttail(e(df_r),abs(`t'))
    local p_lc5: display %9.2f `p'
    local beta_lc5: display %9.2f `pre_beta_lc5'


    reg pres_turnout_adultpop context_index_`network'
    local t = _b[context_index_`network']/_se[context_index_`network']
    local pre_beta_pres = _b[context_index_`network']
    local p = 2*ttail(e(df_r),abs(`t'))
    local p_pres: display %9.2f `p'
    local beta_pres: display %9.2f `pre_beta_pres'



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



};

    graph combine LC5_unionRE presidential_unionRE,
        title("Theoretically Predicted Participation & Turnout" "Union Network Where Friends & Family Ties Must Be Reciprocated")
        graphregion(color(white))
        plotregion(color(white));
    graph export 3_results/context_voting_scatter_reciponly.pdf, replace;
