
clear
cd "$replication_root"
set more off

use 1_data/1_constructed_data/network_and_voting_stats.dta
drop if VILLAGE == "8785"
label var context_index_union "TPP (Union)"
label var pol_attendmeeting "Share attended meeting"
label var pol_contribute_project_any "Contribute to village project"



gen turnout = LC5chair_turnout_adultpop
gen diffusion = dm_num_union_p035_s40

rename pol_contribute_project_any pol_contrib
rename pol_contribute_member pol_contrib_person


#delimit ;
foreach i in   pol_attendmeeting pol_contrib {;
    if ("`i'" == "pol_attendmeeting") {;
        local ytitle "Share Attended Village Meeting";
    };
    if ("`i'" == "pol_contrib") {;
        local ytitle "Share Contributed to Village Project";
    };

    foreach network in union {;
        reg `i'  context_index_`network'  ;
        assert e(N) == 15;
        local beta = _b[context_index_`network'];
        local t = _b[context_index_`network']/_se[context_index_`network'];
        local p = 2*ttail(e(df_r),abs(`t'));
        local p_clean: display %9.2f `p';
        local beta_clean: display %9.2f `beta';

        twoway
            (lfitci `i' context_index_`network' )
            (scatter `i'  context_index_`network' ),
            name(`i'_`network', replace)
            note("Beta:`beta_clean', P-value:`p_clean'")
            legend(off)
            plotregion(color(white))
            graphregion(color(white))
            ytitle("`ytitle'");
        };
};
graph combine
    pol_attendmeeting_union
    pol_contrib_union
    ,
    title("Other Forms of Community Participation")
    plotregion(color(white))
    graphregion(color(white))
    cols(2) rows(2);
graph export 3_results/network_and_other_participation.pdf, replace;;
