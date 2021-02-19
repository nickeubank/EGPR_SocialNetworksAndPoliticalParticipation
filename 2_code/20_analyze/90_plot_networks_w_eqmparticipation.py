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


# Get participation values
df = pd.read_stata('1_data/1_constructed_data/network_and_voting_stats.dta')
df = df[['VILLAGE', 'context_index_union', 'vcount_union', 'ecount_union']]

for idx, t in enumerate(town_names):
    g = graphs[t]['union']
    layout = g.layout("fr")

    town = df.loc[df.VILLAGE == t,:]
    context_index = town.loc[:,'context_index_union'].iloc[0]
    vcount = town.loc[:,'vcount_union'].iloc[0]
    ecount = town.loc[:,'ecount_union'].iloc[0]

    context_index = f'{vcount:,.0f} Vertices, {ecount:,.0f} Edges. Eqm Participation Index Value: {context_index:.2f}'

    with open(f'3_results/town_{idx}_indexvalue.tex', 'w') as f:
        f.write(context_index)

    gplot = ig.plot(g, layout=layout,
                    vertex_size=5,
                    edge_width=0.2,
                    vertex_color='lightblue',
                    bbox=(300,300))
    gplot.save(f'3_results/town_{idx}.png')
