clear
set more off

*************
* Summarize voting behavior statistics.
* Plot distributions and look at correlation of measures
* across parameter values.
*************

* Get own path here
cd "$replication_root"

use 1_data/1_constructed_data/network_and_voting_stats.dta, clear

* 8785 Stats
sum vcount_friend if VILLAGE == "8785"
local clean_corr: display %9.0f `r(mean)'
display "`clean_corr'"
file open myfile using 3_results/outlier_size.tex, write text replace
file write myfile "`clean_corr'"
file close myfile


drop if VILLAGE =="8785"



* Turnout correlations across types
twoway (lfitci pres_turnout_adultpop LC5chair_turnout_adultpop) ///
       (scatter pres_turnout_adultpop LC5chair_turnout_adultpop), ///
   ytitle("Presidential Turnout") ///
   xtitle("LC5 Turnout")

graph export 3_results/summary_turnout.pdf, replace

************
* Turnout summary statistics
************

hist pres_turnout_adultpop, title("Presidential Turnout") xtitle("Estimated Share of Adult Population Voting in Presidential Election") width(0.05) freq ytitle("Num Villages")
graph export 3_results/presidential_turnout_hist.pdf, replace

hist LC5chair_turnout_adultpop, title("LC5 Chair Turnout") xtitle("Estimated Share of Adult Population Voting in LC5 Chair Election") width(0.05) freq ytitle("Num Villages")
graph export 3_results/LC5chair_turnout_hist.pdf, replace

************
* Block voting summary stats
************


foreach i in pres_turnout_adultpop pres_blockvoting pres_viable ///
             LC5chair_turnout_adultpop LC5chair_blockvoting LC5chair_viable ///
             LC5coun_turnout_adultpop LC5coun_blockvoting {
                 count if `i' != .
                 local num = r(N)
                 sum `i'
                 twoway(hist `i', bin(4)), note("N: `num', mean: `r(mean)'")
                 tempfile `i'
                 graph save ``i''.gph, replace
                 graph export 3_results/summary_`i'.pdf, replace

             }

graph combine `pres_turnout_adultpop'.gph `pres_blockvoting'.gph `pres_viable'.gph ///
            `LC5chair_turnout_adultpop'.gph `LC5chair_blockvoting'.gph `LC5chair_viable'.gph ///
            `LC5coun_turnout_adultpop'.gph `LC5coun_blockvoting'.gph, ///
            title("Voting Summary Stats")

graph export 3_results/voting_summary_graphs.pdf, replace

* Correlations across race types:
corrtex pres_turnout_adultpop LC5chair_turnout_adultpop LC5coun_turnout_adultpop, ///
        file(3_results/corr_turnout) replace digits(2) title("Turnout") key("turnout_corr")

    * Save
    corr pres_turnout_adultpop LC5chair_turnout_adultpop
    local clean_corr: display %9.2f `r(rho)'
    display "`clean_corr'"
    file open myfile using 3_results/turnout_corr_coefficient.tex, write text replace
    file write myfile "`clean_corr'"
    file close myfile



corrtex pres_blockvoting LC5chair_blockvoting LC5coun_blockvoting, ///
        file(3_results/corr_blockvoting) replace digits(2) title("Block Voting")

corrtex pres_viable LC5chair_viable, ///
        file(3_results/corr_efficientvoting) replace digits(2) title("Efficient Voting")


hist avg_vil_concentration_pres, title("Village Voter Concentration") xtitle("Avg Village Votes as Share of Total Precinct Votes" "(Weighted Avg Across Precincts)")
graph export 3_results/concentration_hist.pdf, replace

************
* Plot precinct alignment against tpp
************

label var avg_vil_concentration_pres "Concentration (Pres)"
label var avg_vil_concentration_LC5chair "Concentration (LC5 Chair)"


corr avg_vil_concentration_pres avg_vil_concentration_LC5chair
local clean_corr: display %9.4f `r(rho)'
display "`clean_corr'"
file open myfile using 3_results/alignment_correlation.tex, write text replace
file write myfile "`clean_corr'"
file close myfile

_eststo clear

foreach race in pres LC5chair {
    reg avg_vil_concentration_`race' context_index_union

      local temp = _b[context_index_union]
      local beta: display %9.2f `temp'

       local t = _b[context_index_union]/_se[context_index_union]
       local p = 2 * ttail(e(df_r), abs(`t'))
       local p: display %9.2f `p'


    eststo turnout_`race': reg `race'_turnout_adultpop context_index_union avg_vil_concentration_`race'

    #delimit ;
    twoway (lfitci avg_vil_concentration_`race' context_index_union)
          (scatter avg_vil_concentration_`race' context_index_union) ,
         ytitle("Village Precinct Alignment")
         legend(off)
         xtitle("TPP, Union Network")
         plotregion(color(white))
         graphregion(color(white))
         name(`race', replace)
         note("Beta:`beta', P-Value:`p'");

    #delimit cr
    graph export 3_results/precinct_alignment_`race'.pdf, replace


}
#delimit ;

esttab turnout_pres turnout_LC5chair using "3_results/turnout_alignment_tpp.tex",
       b(a2) label replace nogaps compress se(a2) bookt
       noconstant nodepvars star(* 0.1 ** 0.05 *** 0.01)
       mtitles("Pres" "LC5Chair");

 #delimit cr


* Export max and min presidential turnout for text

sum pres_turnout_adultpop, d
local clean_max: display %9.0f `r(max)' * 100
display "`clean_max'"
file open myfile using 3_results/pres_turnout_max.tex, write text replace
file write myfile "`clean_max'"
file close myfile

sum pres_turnout_adultpop, d
local clean_min: display %9.0f `r(min)' * 100
display "`clean_min'"
file open myfile using 3_results/pres_turnout_min.tex, write text replace
file write myfile "`clean_min'"
file close myfile

sum pres_turnout_registered, d
local clean_max: display %9.0f `r(max)' * 100
display "`clean_max'"
file open myfile using 3_results/pres_turnout_max_reg.tex, write text replace
file write myfile "`clean_max'"
file close myfile

sum pres_turnout_registered, d
local clean_min: display %9.0f `r(min)' * 100
display "`clean_min'"
file open myfile using 3_results/pres_turnout_min_reg.tex, write text replace
file write myfile "`clean_min'"
file close myfile
