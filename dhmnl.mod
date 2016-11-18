# DHMNL: A minimal (mnl) district heating (DH) network optimization model
# Last updated: 03 August 2016
# Author: johannes.dorfner@tum.de
# License: CC0 <http://creativecommons.org/publicdomain/zero/1.0/>

# USAGE
# glpsol -m dhmnl.mod

# OVERVIEW
# This mixed-integer linear programming (MILP) model finds the maximum revenue
# topology and size of a district heating network for a given set of source
# and demand vertices. The model can decide which demands to connect and 
# consequently decide over the location and size of the built network.
#
# This example comes with the following (ASCII-art sketch ahead)
# network graph pre-coded into the data section at the end of the file. The 
# corners (A, D, H, K) house big heating stations, supported by a smaller 
# station in the center (F). All remaining vertices contain either big (E, G), 
# medium (I) and small (B, C, J) demands, which may (do not have to be) 
# satisfied, if profitable.
#
# Costs occur for a) constructing pipes and b) generating heat in heating
# stations. Revenue is generated through satisfying demands. Pipe
# construction costs consist of a capacity-independent part (earthworks) and
# a capacity-dependent part (additional price of larger diamter, additional
# earthworks for a wider hole), both multiplied with the segment length. Heat 
# generation costs may vary among heating stations. Here, the big heating 
# stations are cheapest, but located furthest away from the demand centers.

# NETWORK GRAPH
# (for input data, see bottom of file)
# Letters denote vertices, lines show edges. Numbers show edge lengths. 
#
#         5        4       3
#   A----------B-------C------D
#              |        \
#             /3         \3
#            |            \
#            E------F------G
#            |  2  /   2
#           2\    /2
#       4  _,-I--´          __,----K
#      _--´    \_____,--J--´ 4
#    H´           4  
#



# SETS
set vertex;
set edge within vertex cross vertex; # undirected {v1, v2} pairs
set cost_type := {'network', 'generation', 'revenue'};



# PARAMETERS
param cost_investment_fix >= 0; # (EUR/m)
param cost_investment_var >= 0; # (EUR/MW/m)
param capacity_upper_limit >= 0; # maximum possible pipe capcity (MW)
param revenue_heat; # (EUR/MW)

param length{edge} >= 0; # edge length (m)

param source{vertex} >= 0, default 0; # generation capacity (MW)
param demand{vertex} >= 0, default 0; # 
param cost_heat{vertex} >= 0, default 0; # (EUR/MW)




# VARIABLES
var is_built{edge} binary; # 1 = pipe is built in edge {v1, v2} , 0 = not 
var capacity{edge} >= 0; # built pipe capacity (MW)
var flow{edge}; # pipe power flow (MW, positive: v1->v2, negative:v1<-v2)

var is_satisfied{vertex} binary; # 1 = demand in vertex is satisfied, 0 = not
var generation{vertex} >= 0; # generation power in source vertex (MW)

var costs{cost_type}; # costs and revenues (EUR)



# OBJECTIVE
# sum of network investment (capacity-independent fix plus capacity-dependent 
# variable) and heat generation costs in heating stations
minimize obj: 
    costs['network']
  + costs['generation']
  - costs['revenue'];

  
s.t. obj_network_costs:
  costs['network'] =
    sum{(v1, v2) in edge} 
        length[v1, v2] * (
          cost_investment_fix * is_built[v1, v2] +
          cost_investment_var * capacity[v1, v2]);
          
s.t. obj_generation_costs:
  costs['generation'] = 
    sum{v in vertex} 
      cost_heat[v] * generation[v];
        
s.t. obj_revenue:
  costs['revenue'] = 
    sum{v in vertex} 
      revenue_heat * demand[v] * is_satisfied[v];

        


# CONSTRAINTS

# power flow conservation in nodes: ingoing power flow and generation count
# positive, outgoing power flow and satisfied demand count negative
s.t. vertex_balance{v in vertex}:
      generation[v]
    - demand[v] * is_satisfied[v]
    + sum{(a,b) in edge: v=b} flow[a, v]
    - sum{(a,b) in edge: v=a} flow[v, b]
    = 0;

# limit forward (v1 -> v2) power flow through pipe by built capacity
s.t. flow_limit_upper{(v1, v2) in edge}:
    flow[v1, v2] <= capacity[v1, v2];

# limit reverse (v1 <- v2) power flow through pipe by negative pipe capacity  
s.t. flow_limit_lower{(v1, v2) in edge}:
    -capacity[v1, v2] <= flow[v1, v2];

# limit built pipe capacity to upper limit. Side effect: binary decision 
# variable is_built is forced to take value 1 to allow non-zero value  
s.t. limit_capacity_by_is_built{(v1, v2) in edge}:
    capacity[v1, v2] <= is_built[v1, v2] * capacity_upper_limit;

# limit generation in vertices to heating station capacity
s.t. generation_cap{v in vertex}:
    generation[v] <= source[v];
    

    

solve;

# OUTPUT
printf "\nRESULT\n\n";

printf "COSTS\n";
printf "Network:    %8.1f EUR (%s m total length in %s edges)\n", 
        costs['network'], 
        sum{(v1, v2) in edge} length[v1,v2] * is_built[v1,v2],
        sum{(v1, v2) in edge} is_built[v1,v2];
printf "Generation: %8.1f EUR\n", costs['generation'];
printf "Revenue:    %8.1f EUR\n", -costs['revenue'];
printf "---------------------\n";
printf "Total:      %8.1f\n", costs['network'] + costs['generation'] - costs['revenue'];

printf "\nVERTEX\n";
printf "gen: generation (MW)\nsat: satisfied demand (MW)\nnot: unsatisfied demand (MW)\n\n";
printf " %-3s | %4s %4s %4s\n", "v", "gen", "sat", "not";
printf "----------------------\n";
printf{v in vertex}:
    " %-3s | %4s %4s %4s\n", 
    v, 
    if generation[v] > 0 then generation[v] else '', 
    if is_satisfied[v] > 0 then demand[v] * is_satisfied[v] else '', 
    if demand[v] * (1-is_satisfied[v]) > 0 then demand[v] * (1-is_satisfied[v]) else '';
printf "----------------------\n";
printf " %-3s | %4s %4s %4s\n",
    "Sum",
    sum{v in vertex} generation[v],
    sum{v in vertex} demand[v] * is_satisfied[v],
    sum{v in vertex} demand[v] * (1 - is_satisfied[v]);

printf "\nEDGE\n";
printf "cap: capacity (MW)\nflow: heat flow (MW, >0:v1->v2, <0:v2->v1)\n\n";
printf " %-2s, %-2s |%4s %4s\n", "v1", "v2", "cap", "flow";
printf "-------------------\n";
printf{(v1, v2) in edge: capacity[v1, v2] > 0}: 
    " %-2s%2s%2s |%4g %4g\n", 
        v1, 
        if flow[v1,v2] > 0 then '->' else '<-', 
        v2, 
        capacity[v1, v2], 
        flow[v1, v2];
    printf "\n";



# DATA
data; 

param revenue_heat := 80; # (EUR/MW)
param cost_investment_fix := 50; # (EUR/m)
param cost_investment_var := 4; # (EUR/MW/m)
param capacity_upper_limit := 15; # (MW)


#                (MW)   (MW)  (EUR/MW)
param: vertex: source demand cost_heat :=
       A            9      .         1
       B            .      2         .
       C            .      2         .
       D            9      .         2
       E            .      9         .
       F            3      .         3
       G            .      9         .
       H            2      .         2
       I            .      4         .
       J            .      1         . 
       K            9      .         1;
       
#               (m)
param: edge: length :=
       A B        5
       B C        4
       B E        3
       C D        3
       C F        3
       C G        3
       E F        2
       E I        2
       F G        2
       F I        2
       G J        3
       H I        4
       I J        3
       J K        4;

end;