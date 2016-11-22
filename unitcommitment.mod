# UNITCOMMITMENT: a minimal MILP power plant scheduling with startup costs
# Last updated: 21 Nov 2016
# Author: johannes.dorfner@tum.de
# License: CC0 <http://creativecommons.org/publicdomain/zero/1.0/>
#
# USAGE
# glpsol -m unitcommitment.mod


# SETS & PARAMETERS
set time;
set plant;  # power plant technologies
set cost_types := {'fixed', 'variable', 'startup', 'shutdown'};

# economic
param c_var{plant};   # variable operational cost (EUR/MWh) by production
param c_fix{plant};   # fix operational cost (EUR) per step if plant on
param c_start{plant}; # startup cost of plant (EUR) per occurence
param c_stop{plant};  # shutdown cost of plant (EUR) per occurence

# plant
param cap_min{plant};    # minimum production capacity of plant (MW)
param cap_max{plant};    # maximum production capacity of plant (MW)

# time
param demand{time};      # demand timeseries (MW)

# VARIABLES
var costs{cost_types};  # objective value (EUR)

var production{time, plant}, >= 0;  # power production of plant (MW)

var on_off{time, plant}, binary;  # 1 if plant is on at time, 0 else
var startup{time, plant}, binary; # 1 if plant has started at time, 0 else
var shutdwn{time, plant}, binary; # 1 if plant has shut down at time, 0 else


# OBJECTIVE
minimize obj: sum{ct in cost_types} costs[ct];

s.t. def_costs_variable:
    costs['variable'] = 
        sum{t in time, p in plant} 
            (c_var[p] * production[t, p]);
                   
s.t. def_costs_fixed:
    costs['fixed'] = 
        sum{t in time, p in plant} 
            (c_fix[p] * on_off[t, p]);
                   
s.t. def_costs_startup:
    costs['startup'] = 
        sum{t in time, p in plant} 
            (c_start[p] * startup[t, p]);
                   
s.t. def_costs_shutdown:
    costs['shutdown'] = 
        sum{t in time, p in plant} 
            (c_stop[p] * shutdwn[t, p]);


# CONSTRAINTS
 
s.t. res_demand_satisfaction{t in time}:
        demand[t] = sum{p in plant} production[t, p];


s.t. def_startup_shutdown{t in time, p in plant}:
        startup[t, p] - shutdwn[t, p] 
            = 
        on_off[t, p] - (if t>1 then on_off[t-1,p] else 0);


s.t. res_production_minimum{t in time, p in plant}:
        production[t, p] >= on_off[t, p] * cap_min[p];


s.t. res_production_maximum{t in time, p in plant}:
        production[t, p] <= on_off[t, p] * cap_max[p];


# SOLVE
solve;

# REPORTING PARAMETERS
param plant_share{p in plant} := (sum{t in time} production[t, p]) /
                                 (sum{t in time} demand[t]) * 100;
param no_of_starts{p in plant} := sum{t in time} startup[t, p];
param no_of_stops{p in plant} := sum{t in time} shutdwn[t, p];

# OUTPUT
printf "RESULT\n";
printf "\n\nCOSTS\n\n";
printf "  %-12s %8s\n", "type", "kEUR";
printf "  ---------------------\n";
printf{ct in cost_types} "  %-12s %8.1f\n", ct, costs[ct]/1000;
printf "  ---------------------\n";
printf "  %-12s %8.1f\n", "total", sum{ct in cost_types} costs[ct]/1000;

printf "\n\nSCHEDULE\n\n";
printf "   t  "; # header line
    printf{p in plant}: " %8.8s", p;
    printf "  %8.8s\n", "Demand";
    printf "  "; printf{p in plant}: "---------"; printf "--------------"
printf "\n"; # table body
for{t in time} {
    printf "  %2s  ", t; # timestep number
    printf{p in plant}: " %8g", production[t, p]; # production by plant
    printf "  %8g ", demand[t]; # final column: demand
    printf{d in 500..demand[t] by 1000} "="; # demand barchart idea
    printf "\n";
}
printf "  "; printf{p in plant}: "---------"; printf "--------------"
printf "\n"; # footer line
printf "  %%   "; # share
    printf{p in plant}: " %8.1f", plant_share[p]; 
    printf "\n";
printf "  #on "; # number of starts
    printf{p in plant}: " %8.0f", no_of_starts[p]; 
    printf "\n";
printf "  #off"; # number of stops
    printf{p in plant}: " %8.0f", no_of_stops[p]; 
    printf "\n";        
printf "\n";


# DATA
data;

param: 
    plant:          c_var  c_fix c_start c_stop cap_min cap_max :=
    Nuclear             9    360    3600      1     400    1000
    Lignite            13    532    5320      1     400    1000 
    Coal               20    800    8000      1     400    1000 
    "Gas CombCycle"    33   1320   13200      1     400    1000 
    "Gas Turbine"      50   2000   20000      1     400    1000;      

param:
    time: demand :=
    1        500
    2       1000
    3       2000
    4       2000
    5       2000
    6       2000
    7       2000
    8       2000
    9       3000
    10      4000
    11      4000
    12      5000
    13      4000
    14      3000
    15      2000
    16      2000
    17      3000
    18      4000
    19      5000
    20      4000
    21      3000
    22      2000
    23      1000
    24      1000;

end;