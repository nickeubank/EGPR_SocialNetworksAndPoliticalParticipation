



program diff_figure

	syntax [varlist (default=none)] [if],  stub(string) p(string) steps(string) save(string) [drop(string)]
	marksample restriction

	* temporary file
	*---------------
	tempname memhold
	tempfile results
	postfile `memhold' beta se steps category using `results'  

	* preserve
	*-----------
	preserve




	* regression
	*-----------	

	local category_counter = 1
	label define categories 1"", modify

	local race_groups = "LC5chair pres"

	foreach race in `race_groups' {
		foreach network in faf u  {
			foreach s in  `steps' {

				* make network dependent if controlling for avg degree
				if "`varlist'" == "avg_degree" {
					local varlist = "avg_degree_`network'"				
				}

				* Run regression
				*-----------------
				reg `race'_turnout_adultpop  dm_`stub'_`network'`drop'_p`p'_s`s'_ `varlist' if `restriction'
				post `memhold' (_b[dm_`stub'_`network'`drop'_p`p'_s`s'_] / _se[dm_`stub'_`network'`drop'_p`p'_s`s'_]) (_se[dm_`stub'_`network'`drop'_p`p'_s`s'_] ) (`s') (`category_counter')


				* Create relevant labels
				*-----------------
				if "`network'" == "u" {
					local label_network = "Union"
				}
				if "`network'" == "faf" {
					local label_network = "Friends & Fam"
				}

				label define categories `category_counter'"`label_network',`s' Steps", modify
				local category_counter = `category_counter' + 1
			}
			label define categories `category_counter'" ", modify
			local category_counter = `category_counter' + 1

		}	
		label define categories `category_counter'" ", modify
		local category_counter = `category_counter' + 1
		label define categories `category_counter'" ", modify
		local category_counter = `category_counter' + 1

	}

	
	local freedom = e(df_r)
	tempfile cat_labels
	label save categories using "`cat_labels'", replace

	* post the data
	*--------------

	postclose `memhold'
	use `results', clear

	* confidence intervals
	*---------------------
	local interval_radius = 1.75
	gen cihi = beta + `interval_radius'
	gen cilo = beta - `interval_radius'

	* Add labels
	*-----

	do "`cat_labels'"
	label values category categories


	* Y title
	*-----
	if("`stub'" == "num") {
		local ytitle_part2 = "& Std. Dev. in Num People Reached"
	}

	if("`stub'" == "shr") {
		local ytitle_part2 = "&  Std. Dev. in Share of Network Reached"
	}

	* plot
	*-----

	local xtitle = "LC5 Election                                 Presidential Election"
	assert "`race_groups'" == "LC5chair pres"
	sum category, d
	local min = r(min)
	local max = r(max)




	#delimit;

	twoway 
		( rcap cihi cilo category if cilo>0 | cihi <0, color(red) lwidth(medthick)
			yline(0, noextend lpattern(dash) lcolor(gs8) ) ) 
		( scatter beta category if cilo>0 | cihi <0, color(red) msymbol(diamond) msize(small))
		( rcap cihi cilo category if cilo<0 & cihi>0,  color(black) lwidth(medthick)) 
		( scatter beta category if cilo <0 & cihi>0,   color(black) msymbol(diamond) msize(small))
		,
			graphregion(fcolor(white) lcolor(white) margin(l+5)) 
			plotregion(fcolor(white) lstyle(none) lcolor(white) ilstyle(none) )
			legend( off ) xlabel(`min'(1)`max',valuelabel angle(45) labsize(vsmall))
			xtitle("`xtitle'")
			ytitle("Turnout (Share Adult Pop)" "`ytitle_part2'")

		;;

	graph export `save', replace;

	#delimit cr

	* restore
	*-----
	restore

end

