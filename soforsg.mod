# SOforSG: Storage Optimization for Smart Grids
# Last updated: 14 November 2013
# Author: johannes.dorfner@tum.de
# License: CC0 <http://creativecommons.org/publicdomain/zero/1.0/>
#
# USAGE
# glpsol -m soforsg.mod
#
# OVERVIEW
# This model optimizes size (storage_capacity) and operation (storage_level[t]) 
# of a hypothetical lossless storage technology for electric energy. A given
# electricity demand[t] must be satisfied from 
# a) a cost-free (renewable) energy supply[t] with intermittent characteristic 
#    (RES) or from 
# b) electricity_purchase[t], i.e. buying of electricity from the grid for a 
#    time-dependent electricity_price[t].
#
# Fig. 1 Power system diagram
#
#     RES  Grid                Electricity
#      |     |                     |
#      |     |     +--------+      |
#      +-----------| Supply |----->+
#      |     |     +--------+      |       ,-----------------.
#      |     |                     +----->( Demand timeseries )
#      |     |   +------------+    |       `-----------------'
#      |     +<--| Buy / Sell |--->+
#      |     |   +------------+    |      ,<=======>. 
#      |     |                     +<---->| Storage |
#      |     |                     |      `-,......-´
#      |     |                     |
#

# SETS & PARAMETERS
set time;
param demand{time} >= 0; # (kWh/h)
param supply{time} >= 0; # (kWh/h)
param electricity_price{time}; # (EUR/kWh)
param storage_cost; # (EUR/kWh)
param selling_price_ratio; # (1) for sold energy, relative to electricity_price

# VARIABLES
var energy_balance{time}; # (kWh)
var storage_capacity >= 0; # (kWh)
var storage_level{time} >= 0; # (kWh)
var energy_purchase{time} >= 0; # (kWh)
var energy_sold{time} >= 0; # (kWh)
var costs;

# OBJECTIVE
minimize obj: costs;

# CONSTRAINTS

# total costs = investment for storage + purchased electricity
s.t. def_costs: 
        costs = 
        storage_cost * storage_capacity + 
        sum{t in time} electricity_price[t] * energy_purchase[t] -
        sum{t in time} electricity_price[t] * energy_sold[t] * selling_price_ratio;
        
# balance = supply - demand + purchase - sold 
s.t. def_balance{t in time}: 
        energy_balance[t] = supply[t] - demand[t] + 
                            energy_purchase[t] - energy_sold[t];
        
# new storage level = old storage level + balance
s.t. def_storage_state{t in time: t>1}: 
        storage_level[t] = storage_level[t-1] + energy_balance[t];
        
# storage is filled 50% at beginning 
s.t. def_storage_initial{t in time: t=1}: 
        storage_level[t] = 0.5 * storage_capacity;

# storage must be filled at least 50% in the end
s.t. res_storage_final{t in time: t=card(time)}: 
        storage_level[t] >= 0.5 * storage_capacity;
        
# storage may be filled at most to storage capacity
s.t. res_storage_capacity{t in time}: 
        storage_level[t] <= storage_capacity;

# limit sold energy to prevent unbounded model
s.t. res_energy_sold{t in time}:
        energy_sold[t] <= 999;

# SOLVE
solve;

# OUTPUT
printf "RESULT\n\n";
printf "Costs: %+5.1f EUR\n", costs;
printf "     ( %+5.1f EUR for %g kWh storage at %g EUR/kWh, \n", storage_cost*storage_capacity, storage_capacity, storage_cost;
printf "       %+5.1f EUR for purchasing %g kWh,\n", sum{t in time} electricity_price[t] * energy_purchase[t], sum{t in time} energy_purchase[t];
printf "       %+5.1f EUR from selling %g kWh)\n\n", - sum{t in time} selling_price_ratio * electricity_price[t] * energy_sold[t], sum{t in time} energy_sold[t];
printf "%2s:\t%6s\t%6s\t%5s | %5s\t%5s\t%5s\n", 
       "t", "demand", "supply", "price", "Level", "Purch", "Sold";
printf "------------------------------+----------------------\n";
printf{t in time}: "%2i:\t%6g\t%6g\t%5g | %5g\t%5g\t%5g\n", 
       t, demand[t], supply[t], electricity_price[t], storage_level[t], 
       energy_purchase[t], energy_sold[t];
printf "------------------------------+----------------------\n";
printf "%s:\t%6g\t%6g\t%5s | %5s\t%5g\t%5g\n", "Sum", 
       sum{t in time} demand[t], sum{t in time} supply[t], "---", "---",
       sum{t in time} energy_purchase[t], sum{t in time} energy_sold[t];
printf "%s:\t%6s\t%6s\t%5.1f | %5.1f\t%5s\t%5s\n", "Avg", 
       "---", "---", sum{t in time} electricity_price[t]/card(time), 
       sum{t in time} storage_level[t]/card(time), "---", "---";
printf "%s:\t%6i\t%6i\t%5i | %5i\t%5i\t%5i\n", "Min", 
       min{t in time} demand[t], min{t in time} supply[t],
       min{t in time} electricity_price[t], min{t in time} storage_level[t],
       min{t in time} energy_purchase[t], min{t in time} energy_sold[t];
printf "%s:\t%6i\t%6i\t%5i | %5i\t%5i\t%5i\n", "Max", 
       max{t in time} demand[t], max{t in time} supply[t],
       max{t in time} electricity_price[t], max{t in time} storage_level[t],
       max{t in time} energy_purchase[t], max{t in time} energy_sold[t];
printf "\n\n";
       
# DATA
data;

param storage_cost := 3; # storage capacity cost (EUR/kWh) 
param selling_price_ratio := 0.5; # ratio of electricity price (1) for sold energy

param: time: supply  demand electricity_price :=
       1     0       0      0
       2     0       1      2
       3     0       1      2
       4     0       1      2
       5     0       1      2
       6     0       1      2
       7     1       2      1 # supply begins
       8     3       5      2
       9     6       2      2
      10     5       1      1
      11     8       1      1
      12     9       5      2
      13     9       0      1
      14     6       0      1
      15     8       0      1
      16     7       0      1
      17     6       6      5 # demand peak, price peak begins
      18     3       9      5
      19     2       6      5 # price peak ends
      20     1       3      1 # supply ends
      21     0       4      1
      22     0       4      1
      23     0       1      1
      24     0       0      1;
end;

