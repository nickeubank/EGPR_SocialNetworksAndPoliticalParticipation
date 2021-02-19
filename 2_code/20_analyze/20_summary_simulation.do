clear
cd "$replication_root"
set more off

use 1_data/1_constructed_data/network_and_voting_stats.dta, clear
drop if VILLAGE == "8785"

* Full correlation table & overall average:

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


    #delimit ;
    corr cr_`network'_m05_s05_mean
         cr_`network'_m06_s05_mean
         cr_`network'_m06_s025_mean
         cr_`network'_m07_s05_mean
         cr_`network'_m07_s025_mean
         ;
    mat b = r(C);
    local correlation = b[2,1] + b[3,1] + b[4,1] + b[5,1]
                               + b[3,2] + b[4,2] + b[5,2]
                                          + b[4,3] + b[5,3]
                                                 + b[5,4];
    local correlation = `correlation' / 10;
    local cleaned_correlation: display %9.2f `correlation' ;
    file open myfile using 3_results/socialcontext_correlations_`network'.tex, write text replace ;
    file write myfile "`cleaned_correlation'" ;
    file close myfile;




    corrtex
        cr_`network'_m05_s05_mean
        cr_`network'_m06_s05_mean
        cr_`network'_m06_s025_mean
        cr_`network'_m07_s05_mean
        cr_`network'_m07_s025_mean
        ,
        file(3_results/corr_coord_`network') replace digits(2)
        key(corr_`network')
        title("Correlations across Parameter Values, `long_network_name' Network");;

    #delimit cr


}


local counter = 0
local aggregator = 0
foreach x in m05_s05 m06_s05 m06_s025 m07_s05 m07_s025 {
    corr cr_family_`x'_mean cr_friend_`x'_mean cr_lender_`x'_mean cr_solver_`x'_mean
    mat b = r(C)
    local aggregator = `aggregator' + b[2,1] + b[3,1] + b[4,1] + b[3,2] + b[4,2] + b[4,3]
    local counter = `counter' + 6
}

local avg_corr: display %9.2f `aggregator' / `counter'
display "`avg_corr'"
file open myfile using 3_results/cross_network_corr.tex, write text replace
file write myfile "`avg_corr'"
file close myfile

* Correlation of index with average degree:
foreach x in $network_lists {
    gen degree_`x' = ecount_`x' / vcount_`x'
    corr degree_`x' context_index_`x'
    local avg_corr: display %9.2f r(rho)
    display "`avg_corr'"
    file open myfile using 3_results/degree_index_corr_`x'.tex, write text replace
    file write myfile "`avg_corr'"
    file close myfile
}
