clear
cd "$replication_root"
set more off

use 1_data/1_constructed_data/network_and_voting_stats.dta, replace
drop if VILLAGE=="8785"



* Info summary stats

    #delimit ;

    foreach s in 10 20 {;
        foreach p in 35 60 {;
            foreach network in union {;

                if "`network'" == "union" {;
                    local long_network_name "Union";
                };
                label var dm_shr_`network'_p0`p'_s`s' "p 0.`p', `s' steps, `long_network_name'";
            };
        };
    };

    corrtex dm_shr_union_p060_s10
            dm_shr_union_p060_s20
              dm_shr_union_p035_s10
              dm_shr_union_p035_s20,
        file(3_results/corr_diffusion) replace digits(2)
        key(diffusion_corr)
        title("Diffusion Correlations across Parameter Values");;

foreach network in union {;
    pca
        dm_shr_`network'_p060_s10
        dm_shr_`network'_p060_s20
        dm_shr_`network'_p035_s10
        dm_shr_`network'_p035_s20;
    predict info_index_`network';
};




#delimit cr

corr info_index_union context_index_union
local cleaned_correlation: display %9.2f `r(rho)'
file open myfile using 3_results/socialcontext_diffusion_corr.tex, write text replace
file write myfile "`cleaned_correlation'"
file close myfile

*********
* Ubridge Awareness
*********

    * Get significance
    reg LC5chair_turnout_adultpop info_ubridgeawareness
    local pre_beta_lc5 = _b[info_ubridgeawareness]
    local t = _b[info_ubridgeawareness]/_se[info_ubridgeawareness]
    local p = 2*ttail(e(df_r),abs(`t'))
    local p_lc5: display %9.2f `p'
    local beta_lc5: display %9.2f `pre_beta_lc5'

    reg pres_turnout_adultpop info_ubridgeawareness
    local pre_beta_pres = _b[info_ubridgeawareness]
    local t = _b[info_ubridgeawareness]/_se[info_ubridgeawareness]
    local p = 2*ttail(e(df_r),abs(`t'))
    local p_pres: display %9.2f `p'
    local beta_pres: display %9.2f `pre_beta_pres'

    reg context_index_union info_ubridgeawareness
    local pre_beta_context = _b[info_ubridgeawareness]
    local t = _b[info_ubridgeawareness]/_se[info_ubridgeawareness]
    local p = 2*ttail(e(df_r),abs(`t'))
    local p_context: display %9.2f `p'
    local beta_context: display %9.2f `pre_beta_context'

    #delimit ;

    twoway (lfitci pres_turnout_adultpop info_ubridgeawareness)
           (scatter pres_turnout_adultpop info_ubridgeawareness) ,
          ytitle("Presidential Turnout")
          legend(off)
          xtitle("UBridge Awareness")
          name(presidential_ubridge, replace)
          plotregion(color(white))
         graphregion(color(white))
          note("Beta:`beta_pres', P-Value:`p_pres'");

    twoway (lfitci LC5chair_turnout_adultpop info_ubridgeawareness)
           (scatter LC5chair_turnout_adultpop info_ubridgeawareness) ,
          ytitle("LC5 Turnout")
          legend(off)
          plotregion(color(white))
            graphregion(color(white))
          xtitle("UBridge Awareness")
          name(LC5_ubridge, replace)
          note("Beta:`beta_lc5', P-Value:`p_lc5'");


      twoway (lfitci context_index_union info_ubridgeawareness)
             (scatter context_index_union info_ubridgeawareness) ,
            ytitle("TPP")
            legend(off)
            plotregion(color(white))
          graphregion(color(white))
            xtitle("UBridge Awareness")
            name(context, replace)
            note("Beta:`beta_context', P-Value:`p_context'");

    graph combine  LC5_ubridge presidential_ubridge context,
            title("UBridge Awareness, Turnout and TPP")
            plotregion(color(white))
            graphregion(color(white))
            note("Awareness is share of village residents aware of UBridge, turnout in shares.");

    graph export 3_results/ubridge_awareness_and_tpp.pdf, replace;

    * Just LC5, no presidential;
    twoway (lfitci LC5chair_turnout_adultpop info_ubridgeawareness)
           (scatter LC5chair_turnout_adultpop info_ubridgeawareness) ,
          ytitle("LC5 Turnout")
          legend(off)
          plotregion(color(white))
            graphregion(color(white))
          xtitle("UBridge Awareness")
          name(LC5_ubridge, replace)
          note("Beta:`beta_lc5', P-Value:`p_lc5'"
         "Awareness is share of village residents aware of UBridge, turnout in shares.");

     graph export 3_results/ubridge_awareness_lc5only.pdf, replace;

     twoway (lfitci context_index_union info_ubridgeawareness)
            (scatter context_index_union info_ubridgeawareness) ,
           ytitle("TPP (Union)")
           legend(off)
           plotregion(color(white))
             graphregion(color(white))
           xtitle("UBridge Awareness")
           name(LC5_ubridge, replace)
           note("Beta:`beta_context', P-Value:`p_context'"
          "Awareness is share of village residents aware of UBridge, TPP.");

      graph export 3_results/ubridge_awareness_tpp.pdf, replace;

    #delimit cr


*************
* Index and Turnout
*************

foreach network in union {
    if "`network'" == "union" {
        local long_network_name "Union"
    }

    * Get significance
    reg LC5chair_turnout_adultpop info_index_`network'
    local t = _b[info_index_`network']/_se[info_index_`network']
    local pre_beta_lc5 = _b[info_index_`network']
    local p = 2*ttail(e(df_r),abs(`t'))
    local p_lc5: display %9.2f `p'
    local beta_lc5: display %9.2f `pre_beta_lc5'


    reg pres_turnout_adultpop info_index_`network'
    local t = _b[info_index_`network']/_se[info_index_`network']
    local pre_beta_pres = _b[info_index_`network']
    local p = 2*ttail(e(df_r),abs(`t'))
    local p_pres: display %9.2f `p'
    local beta_pres: display %9.2f `pre_beta_pres'

    reg context_index_`network' info_index_`network'
    local t = _b[info_index_`network']/_se[info_index_`network']
    local pre_beta_context = _b[info_index_`network']
    local p = 2*ttail(e(df_r),abs(`t'))
    local p_context: display %9.2f `p'
    local beta_context: display %9.2f `pre_beta_context'

    #delimit ;

    twoway (lfitci pres_turnout_adultpop info_index_`network')
           (scatter pres_turnout_adultpop info_index_`network') ,
          ytitle("Presidential Turnout")
          legend(off)
          xtitle("Info Diffusion, `long_network_name'")
          plotregion(color(white))
          graphregion(color(white))
          name(presidential_`network', replace)
          note("Beta:`beta_pres', P-Value:`p_pres'");

    twoway (lfitci LC5chair_turnout_adultpop info_index_`network')
           (scatter LC5chair_turnout_adultpop info_index_`network') ,
          ytitle("LC5 Turnout")
          legend(off)
          plotregion(color(white))
          graphregion(color(white))
          xtitle("Info Diffusion, `long_network_name'")
          name(LC5_`network', replace)
          note("Beta:`beta_lc5', P-Value:`p_lc5'");


      twoway (lfitci context_index_`network' info_index_`network')
             (scatter context_index_`network' info_index_`network') ,
            ytitle("TPP, `long_network_name'")
            legend(off)
            plotregion(color(white))
            graphregion(color(white))
            xtitle("Info Diffusion, `long_network_name'")
            name(context_`network', replace)
            note("Beta:`beta_context', P-Value:`p_context'");
          graph export 3_results/info_and_tpp_scatter.pdf, replace;


};

    graph combine  LC5_union presidential_union,
        graphregion(color(white))
        plotregion(color(white))
        note("Info Diffusion in standard deviations of PCA index across parameter values, turnout in shares.");
    graph export 3_results/info_and_turnout_scatter.pdf, replace;

#delimit cr


* Additional regressions with info as controls
_eststo clear
eststo: reg LC5chair_turnout_adultpop context_index_union info_ubridgeawareness
eststo: reg LC5chair_turnout_adultpop context_index_union info_index_union
eststo: reg pres_turnout_adultpop context_index_union info_ubridgeawareness
eststo: reg pres_turnout_adultpop context_index_union info_index_union

label var info_ubridgeawareness "Share of Village Aware of UBridge"
label var info_index_union "Info Diffusion Simulation 1st Component"

esttab  using "3_results/turnout_context_and_information.tex", ///
            b(a2) label replace nogaps compress se(a2) bookt ///
            noconstant nodepvars star(* 0.1 ** 0.05 *** 0.01) ///
            mtitles("LC5 Chair" "LC5 Chair" "Presidential" "Presidential")
