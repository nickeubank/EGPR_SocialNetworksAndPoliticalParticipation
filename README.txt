#######
# Nov 22, 2019
# Nick Eubank
# nickeubank@gmail.com
#######

This folder conducts network analysis for the purpose of examining the relationship
between network structure and voting behavior for the paper "Viral Voting: Social
Networks and Political Participation" by Eubank, Grossman, Platas, and Rodden.

All code to execute these analyses can be found in 2_code, and code should be
run in the ordinal sequence implied by file numberings (note: the numbers are
ordinal but they are not sequential -- leaving gaps between file numbers
makes it easier to add new files between old ones without requiring massive
re-numberings).


To make replication easier, however, you can do the full replication with three calls:

1. 2_code/master_simulations.sh (run as bash script)
      - (Running time: ~18 hours on 8 core computer)
2. 2_code/master_dofiles.do (run from Stata)
      - (Running time: Minutes)
3. 2_code/20_analyze/90_plot_networks_w_eqmparticipation.py (run from command line with Python)
      - (Running time: Trivial)

Setting Paths
--------------

- To run dofiles, simply update the global var `replication_root` with the location
of the replication folder.
- Python files have a variable `home` at the top of each files that must be updated.

Randomness
----------

The social context simulations in this analysis have all been seeded with
what we BELIEVE to be seeds that will generate consistent results across
platforms (though of course this is always hard to guarantee).

Those seeds are set around line 131 of 22_social_context_simulations.py,
and line 155 of 25_social_context_simulations_drophighcentrality.py.

Note that we were NOT able to find a way to create a stable seed for the
information diffusion simulations in 20_info_diffusion_and_summary_stats,
and so those results will vary slightly run-to-run.

Content Notes
-------------

For anonymity, village names have been replaced with random integers.

If you are JUST interested in the social context simulation code, you can find it in
the 2_code/libraries/coordination_model_folder. Again, note that for performance
there's a bit of code written in Cython (not regular Python) which appears in them
coordination_helpers.pyx file. You can read more about Cython here:
https://cython.readthedocs.io/en/latest/src/quickstart/overview.html


Python Software Dependencies:
-----------------------------

The code for this project requires use of Python (last run with 3.7 -- there are
a couple f-strings, so you'll need Python 3.7 to run without any issues,
but earlier 3.x should be find if you don't mind a few small patches) and Stata
(last run with StataMP 16).

All packages can be installed by creating a clean conda environment
and running:

```
conda config --add channels conda-forge
conda config --set channel_priority strict
conda install python=3.7.3 pandas=0.25.3 python-igraph=0.7.1.post7 cython=0.29.14 joblib=0.14.0 matplotlib=3.1.2 igraph=0.7.1 pip
pip install tabulate==0.8.6
```

(Though I'd also suggst ipython for ease of use)


Stata Software Dependencies:
----------------------------

Stata code makes use of a number of community packages. To replicate,
install (using `search`):

- renvars (dm88_1)
- esttab (st0085_2)
- corrtex
- blindschemes

Last run on Stata 16 in macOS 10.14.6 (Mojave) in November 2019.
