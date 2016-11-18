# EQUILIBRIUM: a minimal market equilibrium as LP model
# Last updated: 11 Nov 2016
# Author: johannes.dorfner@tum.de
# License: CC0 <http://creativecommons.org/publicdomain/zero/1.0/>

# USAGE
# glpsol -m equilibrium.mod

# OVERVIEW
#
#



# SETS 
set consumer; # energy demands
set producer; # power generator

# PARAMETERS
param amount{c in consumer}; # quantity of demand (MWh)
param util{c in consumer}; # utility of demand (EUR/MWh)

param capacity{p in producer}; # maximum power possible generation (MWh)
param varcost{p in producer}; # marginal costs (EUR/MWh)
param emissions{p in producer}; # specific GHG emissions (t/MWh)

param ghg_tax, default 0; # additional price for emissions (EUR/t)

# VARIABLES
var satisfied{c in consumer}, >= 0, <= 1; # fraction [0-1] of amount c that is satisfied
var generated{p in producer}, >= 0, <= 1; # part [0-1] of capacity p that is used
var production_cost;
var total_utility;

# OBJECTIVE
# minimize the sum of production costs minus total utility
minimize objective_function:
    production_cost - total_utility;
    
s.t. def_production_cost:
    production_cost = sum{p in producer}  
                          generated[p] * capacity[p] * 
                          (varcost[p] + ghg_tax * emissions[p]);
       
s.t. def_total_utility:
    total_utility = sum{c in consumer} 
                        satisfied[c] * amount[c] * 
                        util[c];

s.t. supply_equals_demand:
    sum{p in producer} generated[p] * capacity[p] =
    sum{c in consumer} satisfied[c] * amount[c];

# SOLVE
solve;

# OUTPUT
printf "\nRESULT\n";
printf "------\n";
printf "Objective val: %8.1g EUR\n", sum{p in producer} generated[p] * capacity[p] * (varcost[p] + ghg_tax * emissions[p]) - sum{c in consumer} satisfied[c] * amount[c] * util[c];
printf "Variable cost: %8.1g EUR (%4g MWh total production)\n", sum{p in producer} generated[p] * capacity[p] * varcost[p], sum{p in producer} generated[p] * capacity[p];
printf "Emission tax:  %8.1g EUR (%4g EUR/MWh)\n", sum{p in producer} generated[p] * capacity[p] * ghg_tax * emissions[p], ghg_tax;
printf "Utility:       %8.1g EUR (negative=good)\n", -sum{c in consumer} satisfied[c] * amount[c] * util[c];

printf "\nENERGY PRODUCED\n";
printf "---------------\n";
printf{p in producer: generated[p] > 0}: "%-3s: %3.0f\n", p, generated[p] * capacity[p];
printf "\nSATISFIED DEMAND\n";
printf "----------------\n";
printf{c in consumer: satisfied[c] > 0}: "%-3s: %3.0f\n", c, satisfied[c] * amount[c];
printf "\n";

# DATA
data;
param ghg_tax := 0;  # GHG tax (interesting value range: 0 to 4)

param: consumer: amount util:=
       c1            50   10   # necessary consumption
       c2            10    9   # basic convenience
       c3            20    8   # intermediate value
       c4             5    5
       c5           900    4;  # 'luxury' consumption;
      
param: producer: capacity varcost emissions:=
       p1              65       1         3   # cheap & dirt plant
       p2              50       2         2   # more expensive, cleaner
       p3              60       3         1   # high cost, almost GHG free
       p4              80       5         0;  # highest cost, GHG free
