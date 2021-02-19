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


networks = ['union']

import pandas as pd



###################
# Coordination Simulations (Siegel)
###################

betas = [(0.6, 0.5), (0.6, 0.25), (0.7, 0.5), (0.7, 0.25), (0.5, 0.5), (0.5, 0.25)]
    # Also looked at  (0.75, 0.1), but basically convergences at start point.

# Run test suite once
cm.test_suite()


threshold = 0.01
num_runs = 2500
drops = [5, 10, 15]
# drops = [15]
def simulate(town, seed, threshold, num_runs, drop):
    stats = pd.DataFrame(index=[town],
                 dtype='float')


    # A little clumsy, but need novel seed for each beta / network type,
    # of which there are 24, so inflate by 100 and increment ones-place
    # each pass

    j = 1
    seed = seed * 10000 + (drop * 100)

    for network in networks:
        print(town)
        print(network)


        # Copy since drops are destructive
        g = graphs[town][network].copy()

        # Degree centrality scores. Don't need scale for ordinal,
        # and can do testing if don't use.
        high_centrality = pd.Series( g.eigenvector_centrality(scale=False) )

        # drop n most central
        high_centrality = high_centrality.sort_values(ascending=False)
        to_drop = list(high_centrality.iloc[0:drop].index)

        # Make sure getting most central
        assert (np.isclose(high_centrality.loc[to_drop], high_centrality.max())).any()

        # drop from network
        g.delete_vertices(to_drop)


        # Now run.
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
            stats.loc[town, 'cr{}_{}_m{}_s{}_mean'.format(drop, network, beta[0], beta[1])] = avg.coordination
            stats.loc[town, 'cr{}_{}_m{}_s{}_med'.format(drop, network, beta[0], beta[1])] = median
            stats.loc[town, 'cr{}_{}_m{}_s{}_conv'.format(drop, network, beta[0], beta[1])] = avg.converged
            stats.loc[town, 'cr{}_{}_m{}_s{}_step'.format(drop, network, beta[0], beta[1])] = avg.steps

    return stats


#########
# Actual run
#########

for drop in drops:

    from joblib import Parallel, delayed
    results = Parallel(n_jobs=7, verbose=100, backend='multiprocessing')(delayed(simulate)(town, i + 238192, threshold, num_runs, drop)
                                                                for i, town in enumerate(town_names))
    stats = pd.concat(results, axis='index')

    ##############
    # Some basic stats to check merges later
    #############
    for town in town_names:
        for network in networks:
            g = graphs[town][network]

            stats.loc[town, 'coord_d{}_ecount_{}'.format(drop, network)] = g.ecount()
            stats.loc[town, 'coord_d{}_vcount_{}'.format(drop, network)] = g.vcount()


    ###################
    # Save
    ###################

    import re
    import glob
    stats.columns = map(lambda x: re.sub('\.', '', x), stats.columns)

    date_suffix = time.strftime("%Y_%m_%d_%H_%M")


    # Double save -- one with basic name always updated to most recent, one
    # with date for archive purposes.
    stats.to_stata(fname='1_data/1_constructed_data/coordination_statistics_drop{}_n{}.dta'.format(drop, num_runs))
