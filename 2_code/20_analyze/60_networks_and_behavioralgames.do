
clear
cd "$replication_root"
set more off

use 1_data/1_constructed_data/network_and_voting_stats.dta, clear
drop if VILLAGE == "8785"
label var context_index_union "TPP (Union)"


gen turnout = LC5chair_turnout_adultpop



label var game_stranger "Avg Allocation to Other"
label var turnout "LC5 Turnout"


#delimit ;
foreach measure in  context_index_union turnout {;

    if "`measure'" == "context_index_union" {;
        local xtitle = "TPP";
    };
    if "`measure'" == "turnout" {;
        local xtitle = "Actual Turnout";
    };

    reg game_strangerallocation `measure';
    assert e(N) == 15;
    local beta = _b[`measure'];
    local t = _b[`measure']/_se[`measure'];
    local p = 2*ttail(e(df_r),abs(`t'));
    local p_clean: display %9.2f `p';
    local beta_clean: display %9.2f `beta';

    twoway
        (lfitci game_strangerallocation `measure')
        (scatter game_strangerallocation `measure' ),
        name(`measure', replace)
        note("Beta:`beta_clean', P-value:`p_clean'")
        legend(off)
        plotregion(color(white))
        graphregion(color(white))
        ytitle("Avg Allocation to Stranger")
        xtitle("`xtitle'");
    };
graph combine
     context_index_union turnout
    ,
    title("Network Structure and Generosity")
    plotregion(color(white))
    graphregion(color(white))
    rows(1);
graph export 3_results/games_and_network.pdf, replace;;
