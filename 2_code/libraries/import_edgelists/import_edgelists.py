################
#
# Read in edgelists exported
# from R into python igraph
# objects
#
# Set path to 18_voting_and_networks folder.
################

def run_import(home):
    import os
    import igraph as ig
    import re

    os.chdir(home)


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

    graph_types = ['family',
                   'friend',
                   'lender',
                   'solver',
                   'union']

    graph_types = graph_types + ['{}_nonrecip'.format(g) for g in graph_types]



    graph_renames =  {'family': 'familyRE',
                      'friend': 'friendRE',
                      'lender': 'lenderRE',
                      'solver': 'solverRE',
                      'union': 'unionRE',
                      'family_nonrecip': 'family',
                      'friend_nonrecip': 'friend',
                      'lender_nonrecip': 'lender',
                      'solver_nonrecip': 'solver',
                      'union_nonrecip': 'union'}


    graphs = dict()

    for town in town_names:
        graphs[town] = dict()

        for gtype in graph_types:
            path = '1_data/0_source_data/network_edgelists/{}_{}.graphml'.format(town, gtype)
            graphs[town][graph_renames[gtype]] = ig.Graph.Read_GraphML(f=path)

            if re.match('(solver|lender)', gtype):
                graphs[town][graph_renames[gtype]].to_undirected()

            assert not graphs[town][graph_renames[gtype]].is_directed()

    return graphs
