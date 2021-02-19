############
# Calculate network statistics
#
# Starts by importing graphs using function in `import_edgeslists`
# into a dictionary where first key is village name and
# second key is network type.
############


###
# Get graphs,
# set working directory
# make dataframe in which to store
# village level statistics.
##

# Imports

import os
import re
import time
import numpy as np
import igraph as ig
import matplotlib.pyplot as plt
import pandas as pd
import sys

home = '/users/replicationaccount/desktop/QJPS_ReplicationPackage_EGPR/'

sys.path.append(home + '/2_code/libraries/import_edgelists')
import import_edgelists

sys.path.append(home + '/2_code/libraries/coordination_model_folder')
import coordination_model as cm

os.chdir(home)


# Get graphs
graphs = import_edgelists.run_import(home)

town_names = ["3221",
              "7018",
              "3168",
              "7296",
              "8785",
              "9849",
              "7350",
              "3936",
              "9716",
              "8640",
              "7764",
              "2718",
              "6360",
              "6040",
              "3713",
              "6358"]

# Make sure got recip and nonrecip correct.

for v in graphs.items():
    random_village = v[1]
    for i in ['family', 'friend', 'union']:
        assert random_village[i].ecount() >  random_village['{}RE'.format(i)].ecount()


networks = list(graphs.items())[4][1].keys()




###################
# Coordination Simulations (Siegel)
###################

betas = [(0.6, 0.5), (0.6, 0.25), (0.7, 0.5), (0.7, 0.25), (0.5, 0.5), (0.5, 0.25)]
    # Also looked at  (0.75, 0.1), but basically convergences at start point.

# Run test suite once
cm.test_suite()
threshold = 0.01
num_runs = 2500


def simulate(town, seed, threshold, num_runs):
    stats = pd.DataFrame(index=[town],
                 dtype='float')

    # A little clumsy, but need novel seed for each beta / network type,
    # of which there are 24, so inflate by 100 and increment ones-place
    # each pass

    j = 1
    seed = seed * 100


    for network in networks:
        print(town)
        print(network)


        g = graphs[town][network]


        for beta in betas:

            # Get unique seed
            seed2 = seed + j
            j += 1

            convergence = cm.run_coordination_simulation(g, num_runs=num_runs,
                                                         convergence=True,
                                                         convergence_threshold=threshold,
                                                         convergence_period=20,
                                                         convergence_max_steps=1000,
                                                         beta_mean=beta[0],
                                                         beta_std=beta[1],
                                                         np_seed=seed2)

            avg = convergence.mean()
            median = convergence.coordination.median()
            stats.loc[town, 'cr_{}_m{}_s{}_mean'.format(network, beta[0], beta[1])] = avg.coordination
            stats.loc[town, 'cr_{}_m{}_s{}_med'.format(network, beta[0], beta[1])] = median
            stats.loc[town, 'cr_{}_m{}_s{}_conv'.format(network, beta[0], beta[1])] = avg.converged
            stats.loc[town, 'cr_{}_m{}_s{}_step'.format(network, beta[0], beta[1])] = avg.steps

    return stats


from joblib import Parallel, delayed
# 4874382 random number for seed
results = Parallel(n_jobs=7, verbose=100, backend='multiprocessing')(delayed(simulate)(town, i + 487382, threshold, num_runs)
                                          for i, town in enumerate(town_names))
stats = pd.concat(results, axis='index')

##############
# Some basic stats to check merges later
#############
for town in town_names:
    for network in networks:
        g = graphs[town][network]

        stats.loc[town, 'coord_ecount_{}'.format(network)] = g.ecount()
        stats.loc[town, 'coord_vcount_{}'.format(network)] = g.vcount()


###################
# Save
###################

import re
import glob
stats.columns = map(lambda x: re.sub('\.', '', x), stats.columns)

date_suffix = time.strftime("%Y_%m_%d_%H_%M")

# Double save -- one with basic name always updated to most recent, one
# with date for archive purposes.
stats.to_stata(fname='1_data/1_constructed_data/coordination_statistics_n{}.dta'.format(num_runs))




summary_table = pd.DataFrame( {r'$\beta_{mean}$': [0.5, 0.6, 0.6, 0.7, 0.7],
                               r'$\beta_{sd}$': [0.5, 0.5, 0.25, 0.5, 0.25]},
                             dtype='float')

names = {'union':'Union', 'family':'Family', 'friend':'Friends'}
for beta in betas:
    for i in ['union', 'family', 'friend']:
        var_name = 'cr_{}_m{}_s{}_mean'.format(i, beta[0], beta[1], threshold)
        var_name = var_name.replace('.', '')
        mean_value = stats[var_name].mean()

        summary_table.loc[(summary_table[r'$\beta_{mean}$'] == beta[0]) &
                          (summary_table[r'$\beta_{sd}$'] == beta[1]),
            'Mean, {}'.format(names[i])] = mean_value

file = '3_results/diff_summary_table.tex'
summary_table.to_latex(file, index=False, float_format=lambda x: '{:.2f}'.format(x), escape=False)
