# N minus 1: a MILP minimum network flow problem with (n-1) redundancy
# Last updated: 18 Nov 2016
# Author: johannes.dorfner@tum.de
# License: CC0 <http://creativecommons.org/publicdomain/zero/1.0/>
#
# USAGE
# glpsol -m nminusone.mod
#
# OVERVIEW
# This model finds the minimum cost network within a graph to redundantly
# connect a set of source to a set of demand points.
#
# NETWORK GRAPH
# (for input data, see bottom of file)
# vi's denote vertices, lines show edges. Numbers show costs for building
# a pipe on that edge. 
#
#  Source                       Sink
# ,----.           2           ,----.
# | v1 |-----------------------| v3 |
# `----´                       `----´
#    |        ,-----------------´ |
#   1|     ,----.      3          |
#    `-----| v2 |                 |1
#          `----´      ,----.     |
#             `--------| v4 |-----´
#               1      `----´  
#

# SETS

# Vertices and edges:
# The network is represented by a set of vertex labels, and a set of unordered
# pairs of these vertices.
set vertex;                          # {v1, v2, v3, v4}
set edge within vertex cross vertex; # {{v1, v2}, {v1, v3}, {v2, v3}, ...}

# Arcs: 
# Each undirected edge {v1, v2} corresponds to a pair directed arcs (v1, v2) 
# and (v2, v1). 
set arc within vertex cross vertex := setof{  
    v1 in vertex, v2 in vertex: (v1, v2) in edge or (v2, v1) in edge} (v1, v2);

# Timesteps: 
# for each edge in the graph, one contigency timestep 'cont_vi_vj' is created,
# plus one additional timestep 'all', in which all edges are available. In this
# model, this timestep does not change the result, but with an additional
# parameter timestep duration, it could be used to correctly assess operational
# costs over the year.
set time := {'all'} union setof{(v1, v2) in edge} ('cont_' & v1 & '_' & v2);

 
# PARAMS

# Pipe building costs:
# In this simplified model, only pipe construction incures building costs,
# proportional to the pipe capacity. More generally, source vertices could have
# differing operational costs, pipe construction costs could be split into a
# fixed base for earth works (triggered by variable is_used) and a
# capacity-dependent part (proportional to variable pipe_capacity).
param costs{edge} >= 0; # (EUR/MW)

# Capacity limit:
# Maximum allowable thermal pipe capacity that can be constructed in an edge;
# for simple case studies, this parameter corresponds to the maximum allowable
# pipe diameter
param capacity_upper_limit{edge} >= 0; # (MW)

# Sink or source vertices:
# Each vertex in the graph can either have a (positive) source or a (negative)
# sink or demand of energy. As this simple model does not include losses, the 
# sum of source and sink must add up to exactly zero.
param sinksource{vertex}, default 0; # (MW, +=source, -=sink)

# Pipe availability:
# For each contigency timestep, exactly one edge is not available (0), while all
# other pipes are operational. In larger models, this strategy would lead to too
# many contigency cases. In that case, only crucial/central edges might have a
# contigency set. The idea of this parameter can be generalised directly to 
# source vertices to require (n-1) redundancy also for all sources.
param is_available{(v1,v2) in edge, t in time}, binary := 
    if t == ('cont_' & v1 & '_' & v2) then 0 else 1;  # (1=yes, 0=no)

# VARIABLES
var flow{arc, time} >= 0; # actual power flow through pipe (MW) per timestep
var is_used{arc, time} binary; # 1=pipe used in that direction, 0=not used
var pipe_capacity{edge} >= 0; # built pipe capacity

# OBJECTIVE
minimize obj: sum{(v1, v2) in edge} costs[v1, v2] * pipe_capacity[v1, v2];

# CONSTRAINTS

# power flow in and out of vertices is conserved. sinksource is the fixed demand 
# or supply of a vertex.
s.t. vertex_balance{v in vertex, t in time}:
    sinksource[v]
    + sum{(other, v) in arc} flow[other, v, t]
    - sum{(v, other) in arc} flow[v, other, t]
    = 0;

# the flow is limited by the edge's installed capacity, which must be chosen
# high enough so that the flows in all time steps can be covered. Parameter
# is_available reduces the effective capacity to zero, once for each edge's
# contigency moment. Thanks to the last two constraints, only one of the 
# left-hand side terms can be greater than zero at any time.
s.t. flow_limit{(v1, v2) in edge, t in time}:
    flow[v1, v2, t] + flow[v2, v1, t] <= pipe_capacity[v1, v2] * 
                                         is_available[v1, v2, t];


s.t. one_direction_only{(v1, v2) in edge, t in time}:
    is_used[v1, v2, t] + is_used[v2, v1, t] <= 1;
    
s.t. limit_flow_by_direction{(v1, v2) in arc, t in time}:
    flow[v1, v2, t] <= 
    is_used[v1, v2, t] * (
        if (v1, v2) in edge then capacity_upper_limit[v1, v2]
                            else capacity_upper_limit[v2, v1]);

# SOLVE
solve;

# OUTPUT
printf "\nCAPACITIES\n";
printf " %-3s, %-3s:  %8s\n", "v1", "v2", "cap";
printf "---------------------\n";
printf{(i,j) in edge: pipe_capacity[i,j] <> 0}: 
    " %-3s, %-3s:  %8g\n", i, j, pipe_capacity[i,j];
    printf "\n";

printf "\nFLOWS PER TIMESTEP\n";
printf " %-3s, %-3s:  %8s\n", "v1", "v2", "flow";
printf "---------------------\n";
for{t in time} {
    printf "%s:\n", t;
    printf{(i,j) in arc: flow[i,j,t] <> 0}: 
        " %-3s, %-3s:  %8g\n", i, j, flow[i,j,t];
        printf "\n";
}
    
# DATA
data;

param: vertex: sinksource :=
       v1         1
       v2         0
       v3        -1
       v4         0;
       
param: edge: costs capacity_upper_limit :=
       v1 v2     1     10
       v1 v3     2     10
       v2 v3     3     10
       v2 v4     1     10
       v3 v4     1     10;

end;
