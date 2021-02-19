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

home = '/users/nick/dropbox/QJPS_ReplicationPackage_EGPR/'


sys.path.append(home + '2_code/libraries/import_edgelists')
import import_edgelists

sys.path.append(home + '2_code/libraries/coordination_model_folder')
import coordination_model as cm

sys.path.append(home + '2_code/libraries/network_integration')
import network_integration_measure as ni

sys.path.append(home + '2_code/libraries/diffusion_model_cythonized')
import pyximport; pyximport.install()
import diffusion_model_cython as dm
dm.test_suite()

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


import pandas as pd
stats = pd.DataFrame(columns=['support'], index=town_names,
                     dtype='float')




#############
# Information diffusion
#############

# Quick test:
dm.test_suite()

steps = range(2, 62, 2)

num_runs = 1000

df_035 = pd.DataFrame(index=steps)
df_060 = pd.DataFrame(index=steps)


total_iterations = len(networks) * len(town_names) * 3
counter = 0

# Note no way to set seed because random draws done using C in Cython code
# for speed, not using numpy / python. :/

for network in networks:
    for p in np.arange(0.35, 0.85, 0.25):

        diffusion_plot_df = pd.DataFrame(index=steps)

        for town in town_names:
            print('Diffusion: town {}, network {}. Step {} of {}'.format(town, network, counter, total_iterations))
            counter +=1

            g = graphs[town][network]

            results = dm.diffusion_run_steps(g, p, number_of_runs=num_runs,
                                             num_starting_infections=1,
                                             steps_at_which_to_evaluate=steps,
                                             normalize_p = True)

            # Results for diffusion curve plot
            diffusion_plot_df[town] = results * g.vcount()


            # Results for stata
            for step in steps:
              varname = 'dm_{}_p{:.2f}_s{}'.format(network,
                                                   p, step, num_runs)

              stats.loc[town, varname] = results.loc[step]


        diffusion_plot_df = diffusion_plot_df.drop(["8785"], axis='columns')
        ax = diffusion_plot_df.plot(legend=False)
        ax.set_ylabel("Vertices Informed")
        ax.set_xlabel(f"Simulation Steps, p={p:.2f}")

        pct_as_string = re.sub('^0\.', '0', '{:.2f}'.format(p))
        plt.savefig("3_results/diffusion_curves_{}_p{}_n{}.pdf".format(network,
                                                                       pct_as_string, num_runs))


##############
# Some basic stats
#############
for town in town_names:
    for network in networks:
        g = graphs[town][network]

        stats.loc[town, 'ecount_{}'.format(network)] = g.ecount()
        stats.loc[town, 'vcount_{}'.format(network)] = g.vcount()
        stats.loc[town, 'avg_degree_{}'.format(network)] = (g.ecount() / g.vcount()) * 2
        stats.loc[town, 'avg_shortest_{}'.format(network)] = g.average_path_length()

        # Quick and dirty community fragmentations.
        # don't love optimization criterion, but ok as start?
        groups = g.community_infomap(trials=20).membership
        shares = pd.Series(groups).value_counts() / len(groups)
        frac = 1 - (shares * shares).sum()
        stats.loc[town, 'infomap_frac_{}'.format(network)] = frac

        groups = g.community_multilevel().membership
        shares = pd.Series(groups).value_counts() / len(groups)
        frac = 1 - (shares * shares).sum()
        stats.loc[town, 'blondel_frac_{}'.format(network)] = frac

        # Eigenvector centrality dists
        centralities = pd.Series( g.evcent(directed=False, scale=True) )
        stats.loc[town, 'evcent_skew_{}'.format(network)] = centralities.skew()
        stats.loc[town, 'evcent_mean_{}'.format(network)] = centralities.mean()
        stats.loc[town, 'evcent_median_{}'.format(network)] = centralities.median()

        threex = len(centralities.loc[centralities > (3 * centralities.median())])
        stats.loc[town, 'evcent_grt3xmedian_{}'.format(network)] = threex

        fivex = len(centralities.loc[centralities > (5 * centralities.median())])
        stats.loc[town, 'evcent_grt5xmedian_{}'.format(network)] = fivex

        stats.head()

############
# Summary stat table
############
from tabulate import tabulate


df = stats.loc[stats.index != '8785']

table_values = list([
        ['Average Size',            df['vcount_union'].mean(), df['vcount_friend'].mean(),
                                    df['vcount_family'].mean(), df['vcount_lender'].mean(),
                                    df['vcount_solver'].mean()],
        ['Average Num Connections', df['ecount_union'].mean(), df['ecount_friend'].mean(),
                                    df['ecount_family'].mean(), df['ecount_lender'].mean(),
                                    df['ecount_solver'].mean()],
        ['Average Degree',          df['avg_degree_union'].mean(), df['avg_degree_friend'].mean(),
                                    df['avg_degree_family'].mean(), df['avg_degree_lender'].mean(),
                                    df['avg_degree_solver'].mean()],
        ['Min Size',                df['vcount_union'].min(), df['vcount_friend'].min(),
                                    df['vcount_family'].min(), df['vcount_lender'].min(),
                                    df['vcount_solver'].min()],
        ['Max Size',                df['vcount_union'].max(), df['vcount_friend'].max(),
                                    df['vcount_family'].max(), df['vcount_lender'].max(),
                                    df['vcount_solver'].max()]
        ])


headers = ['Union', 'Friends', 'Family', 'Lender', 'Solver']
table = tabulate(table_values, headers, tablefmt="latex_booktabs", floatfmt=",.1f")
print(table)

with open("3_results/graph_summary_stats.tex", "w") as outfile:
    outfile.writelines(table)


# With reciprocated only
df = stats.loc[stats.index != '8785']


table_values = list([
        ['Average Size',            df['vcount_unionRE'].mean(), df['vcount_friendRE'].mean(),
                                    df['vcount_familyRE'].mean(), df['vcount_lenderRE'].mean(),
                                    df['vcount_solverRE'].mean()],
        ['Average Num Connections', df['ecount_unionRE'].mean(), df['ecount_friendRE'].mean(),
                                    df['ecount_familyRE'].mean(), df['ecount_lenderRE'].mean(),
                                    df['ecount_solverRE'].mean()],
        ['Average Degree',          df['avg_degree_unionRE'].mean(), df['avg_degree_friendRE'].mean(),
                                    df['avg_degree_familyRE'].mean(), df['avg_degree_lenderRE'].mean(),
                                    df['avg_degree_solverRE'].mean()],
        ['Min Size',                df['vcount_unionRE'].min(), df['vcount_friendRE'].min(),
                                    df['vcount_familyRE'].min(), df['vcount_lenderRE'].min(),
                                    df['vcount_solverRE'].min()],
        ['Max Size',                df['vcount_unionRE'].max(), df['vcount_friendRE'].max(),
                                    df['vcount_familyRE'].max(), df['vcount_lenderRE'].max(),
                                    df['vcount_solverRE'].max()]
        ])


headers = ['Union', 'Friends', 'Family', 'Lender', 'Solver']
table = tabulate(table_values, headers, tablefmt="latex_booktabs", floatfmt=",.1f")
print(table)

with open("3_results/graph_summary_stats_reciponly.tex", "w") as outfile:
    outfile.writelines(table)





###################
# Save
###################

import re
import glob
stats.columns = map(lambda x: re.sub('\.', '', x), stats.columns)

date_suffix = time.strftime("%Y_%m_%d_%H_%M")

stats.to_stata(fname='1_data/1_constructed_data/info_diffusion_and_network_statistics_n{}.dta'.format(num_runs))
