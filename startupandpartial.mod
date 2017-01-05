# STARTUP & PARTIAL: a simple LP formulation of variable conversion efficiency
# Last updated: 18 Nov 2016
# Author: johannes.dorfner@tum.de
# License: CC0 <http://creativecommons.org/publicdomain/zero/1.0/>
#
# USAGE
# glpsol -m startupandpartial.mod
#
# OVERVIEW
# This linear programming (LP) optimisation model finds a minimum-cost
# capacity expansion and unit commitment solution to a given demand 
# timeseries for two sources of energy:
#
# A. fluctuating renewable energy source (RES), e.g. a wind park or solar farm
#    with investment, but without variable costs
# B. controllable power-plant (PP), e.g. coal or gas plant
#    with investment, fuel and startup costs and partial load efficiency
#
#
# Fig. 1 Power system diagram
#
#     Wind  Fuel             Electricity
#      |     |                    |
#      |     |       +-----+      |
#      +------------>| RES |----->+
#      |     |       +-----+      |     ,-----------------.
#      |     |                    +--->( Demand timeseries )
#      |     |       +-----+      |     `-----------------'
#      |     +------>| PP  |----->+
#      |     |       +-----+      |
#      |     |                    |
#
# The output of the RES power source is determined by the parameter wind[t] and
# the variable wind park capacity capacity_res.
# The output of the power-plant PP is controllable by the solver, but incurs 
# costs for
#  - installing a certain capacity in the first place (cost_invest, EUR/MW)
#  - buying fuel to burn (cost_fuel, EUR/MWh) and
#  - starting up the plant (cost_startup, EUR/MW).
#
# The latter cost is coupled to a strict LP formulation of the power plant
# conversion efficiency which depends on the operation point, i.e. which
# fraction of the "online capacity" is actually used. It bundles together the
# following behaviours:
#  - minimum partial load: PP must output at least a fraction partial_min of 
#    its online capacity
#  - startup costs: increasing the online capacity leads to startup costs, while
#    decreasing is for free
#  - partial load efficiency: efficiency at full operation (output equals online 
#    capacity) happens at full efficiency (efficiency_max) while operation at 
#    minimum partial load (output equals partial_min of current online capacity) 
#    happens with minimum efficiency (efficiency_min). In between, a linear
#    interpolation is valid which leads to a non-linear effective efficiency
#    behaviour.
#
# In practice, probably only the two extreme operation points "maximum load" and 
# "minimum partial load" are to be used. While the partial load efficiency makes
# it cheaper (fuel-wise) to always have the online capacity follow the PP
# output, the startup cost provide an incentive in the other direction.
#



# SETS & PARAMETERS

# time
param N;  # number of time steps
set time within 1..N;  # time steps

# economics
set cost_types := {'invest (res)', 'invest (pp)', 'startup', 'fuel'};

param cost_invest; # (EUR/MW) power-plant investment costs
param cost_fuel; # (EUR/MWh) power-plant fuel costs
param cost_startup; # (EUR/MW) power-plant startup costs
param cost_res; # (EUR/MW) renewable investment costs

# power-plant parameters
param efficiency_min; # (1) power-plant efficiency at minimum operation point
param efficiency_max; # (1) power-plant efficiency at maximum operation point
param partial_min; # (1) minimum operation point, relative to plant capacity

# timeseries
param demand{t in time} >= 0; # (MW) electricity demand
param wind{t in time} >= 0; # (1) normalised wind capacity factor



# VARIABLES

# capacities
var capacity_pp >= 0;
var capacity_res >= 0;

# power plant timeseries
var pp_inp{t in time} >= 0; # (MW) power-plant input power, i.e. fuel consumption
var pp_out{t in time} >= 0; # (MW) power-plant output power, i.e. elec generation
var cap_online{t in time} >= 0; # (MW) power-plant online capacity, i.e. activity
var cap_start{t in time} >= 0; # (MW) power-plant startup capacity
var res_out{t in time} >= 0; # (MW) RES fluctuating electricity output

# costs
var costs{ct in cost_types}; # (EUR) cost by type (invest, startup, fuel)



# OBJECTIVE

# total cost: sum of all costs by cost type
minimize obj: sum{ct in cost_types} costs[ct];

# invest (pp): PP capacity multiplied by PP investment cost parameter
s.t. def_costs_invest_pp:
    costs['invest (pp)'] = cost_invest * capacity_pp;

# invest (res): RES capacity multiplied by res investment cost parameter
s.t. def_costs_invest_res:
    costs['invest (res)'] = capacity_res * cost_res;

# startup cost: total startup capacity multiplied with startup cost parameter
s.t. def_costs_startup:
    costs['startup'] = cost_startup * sum{t in time} cap_start[t];

# fuel costs: total power-plant input multiplied with fuel cost parameter
s.t. def_costs_fuel:
    costs['fuel'] = cost_fuel * sum{t in time} pp_inp[t];
  


# CONSTRAINTS

# demand must be satisfied from either power-plant or RES output
s.t. res_demand{t in time}:
    demand[t] <= pp_out[t] + res_out[t];

# RES output is determined by product of RES timeseries and RES capacity
s.t. def_res_out{t in time}:
    res_out[t] = wind[t] * capacity_res;

# Power-plant output can in principle be chosen as desired, but is interlocked
# into multiple constraints...

# ... the first: the output is limited by the 'online' capacity, roughly 
# corresponding to the power-plant temperature
s.t. res_pp_out_max_by_capacity_online{t in time}:
    pp_out[t] <= cap_online[t];
    
# second, the output may not be lower than the minimum partial load fraction of 
# the online capacity
s.t. res_pp_out_min_by_capacity_online{t in time}:
    pp_out[t] >= cap_online[t] * partial_min;

# changes in the online capacity are to cause startup costs. These are triggered 
# by the startup capacity variable, which must become positive whenever the 
# online capacity increases (but not when it decreases!)
s.t. def_pp_startup{t in time}:
    cap_start[t] >= cap_online[t] - (if t > 1 then cap_online[t-1] else 0);

# the online capacity is limited by the total installed power-plant capacity
s.t. res_pp_cap_online{t in time}:
    cap_online[t] <= capacity_pp;

# finally, the fuel consumption of the power-plant is determined. This unhandy
# expression is a linear interpolation to achieve a non-constant fuel
# efficiency that ranges from efficiency_min when in partial operation
# (pp_out == partial_min * cap_online ) up to efficiency_max when in full 
# operation (pp_out == cap_online):
#
#
# Fig. 2 Power-plant input over power-plant output for partial load efficiency 
#
#                   ^ pp_inp
#        cap_online |                                                                   
#        ---------- +                   ,+                                   
#          eff_max  |               ,--'                                  
#                   |           ,--'                                  
#       p_min*c_onl |       ,--'                                  
#       ----------- +     +'                                  
#         eff_min   |                            
#                   |                           
#                   |                            
#                   +-----+--------------+-------> pp_out
#       
#                    partial_min *     cap_online
#                      cap_online  
#
#
# This expression is the "compiled" version of the resulting interpolation 
# expression, followed by some algebra to simplify the expression.
s.t. res_pp_partial_efficiency{t in time}:
    pp_inp[t] = (
        (efficiency_max - efficiency_min) * partial_min * cap_online[t] +
        (efficiency_min - partial_min * efficiency_max) * pp_out[t]
    ) / (
        (1 - partial_min) * efficiency_min * efficiency_max
    );




# SOLVE
solve;



# REPORTING PARAMETERS
param total_demand := sum{t in time} demand[t];
param total_cost := sum{ct in cost_types} costs[ct];
param share_pp := (sum{t in time} pp_out[t]) / total_demand;
param total_overprod := (
    sum{t in time} (
        pp_out[t] + res_out[t] - demand[t])
    ) / total_demand;
param pp_efficiency{t in time} := 
    if pp_inp[t] > 0 then pp_out[t] / pp_inp[t] else 0;


# REPORT PRINTING
printf "\n\nCOSTS\n\n";
printf "  %-17s %8s\n", "type", "EUR";
printf "  --------------------------\n";
printf {ct in cost_types} 
       "  %-17s %8.1f\n", ct, costs[ct];
printf "  --------------------------\n";
printf "  %-17s %8.1f\n", "sum", total_cost;

printf "\n\nSTATISTICS\n\n";
printf "  %-24s %-5s %-12s\n", "indicator", "value", "unit";
printf "  -----------------------------------\n";
printf "  %-24s %5.1f %-12s\n", "peak demand", max{t in time} demand[t], "(MW)";
printf "  %-24s %5.1f %-12s\n", "power-plant cap", capacity_pp, "(MW)";
printf "  %-24s %5.1f %-12s\n", "res capacity", capacity_res, "(MW)";
printf "  %-24s %5.1f %-12s\n", "share power-plant", 100 * share_pp, "(%)";
printf "  %-24s %5.1f %-12s\n", "share res", 100 * (1 - share_pp), "(%)";
printf "  %-24s %5.1f %-12s\n", "overproduction res", 100 * total_overprod, "(%)";

printf "\n\nSCHEDULE\n\n";
printf "  %-2s %3s = %4s + %-4s    %4s %3s %3s\n", 
       "t", "dem", "res", "pp_o",  "pp_i", "onl", "eff";
printf "  ------------------------------------\n";
printf {t in time} 
       "  %-2s %3g %1s %4g + %4g    %4g %3g %3d\n",
       t,
       demand[t],
       if demand[t] < res_out[t] + pp_out[t] then "<" else "=",
       round(res_out[t], 1),
       round(pp_out[t], 1),
       round(pp_inp[t], 1),
       round(cap_online[t], 1),
       100 * pp_efficiency[t];
printf "\n\n";



# DATA
data;

# economic parameters
param cost_invest   := 100; # (EUR/MW) power-plant investment costs
param cost_fuel     :=  80; # (EUR/MWh) power-plant fuel costs
param cost_startup  := 120; # (EUR/MW) power-plant startup costs
param cost_res      := 150; # (EUR/MW) renewable investment costs

# power-plant parameters
param efficiency_max := 0.50; # (1) power-plant efficiency at minimum operation point
param efficiency_min := 0.40; # (1) power-plant efficiency at maximum operation point
param partial_min    := 0.25; # (1) minimum operation point, relative to plant capacity

# timeseries
param N := 6; # number of time steps; must match with the table below
param : time : wind demand := 
        1      0.2       2
        2      0.2       1
        3      0.4       5  # peak demand
        4      0.2       1
        5      0.3       3
        6      0.1       5; # peak demand again

# END
end;

