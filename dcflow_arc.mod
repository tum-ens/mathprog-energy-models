set vertex;
set arc within vertex cross vertex;

param demand{vertex} >= 0;
param cap_gen{vertex} >= 0;
param costs{vertex};
param cap_tra{arc} >= 0;
param admittance{arc}; # MW/deg

var generation{v in vertex} >= 0, <= cap_gen[v];
var flow{(v1,v2) in arc} >= 0, <= cap_tra[v1,v2];
var angle{vertex};

minimize obj: sum{v in vertex} costs[v] * generation[v];

s.t. demand_satisfaction{v in vertex}:
    demand[v] <= generation[v]
      + sum{(other, v) in arc} flow[other, v]
      - sum{(v, other) in arc} flow[v, other];

s.t. dc_flow{(v1, v2) in arc}:
    flow[v1, v2] - flow[v2, v1] = admittance[v1, v2] 
      * (angle[v1] - angle[v2]);

solve;

printf "\nVERTEX BALANCE\n";
printf " %-3s:  %8s  %8s  %8s  %8s\n", "v", "gen", "dem", "angle", "nodal";
printf " %3s   %8s  %8s  %8s  %8s\n", "", "MW", "MW", "deg", "EUR/MWh";
printf "----------------------------------------------\n";
printf{v in vertex}: 
    " %-3s:  %8g  %8g  %8g  %8g\n", 
    v, generation[v], demand[v], angle[v], -demand_satisfaction[v].dual;

printf "\nARC BALANCE\n";
printf " %-3s, %-3s:  %8s\n", "v1", "v2", "flow";
printf "---------------------\n";
printf{(i,j) in arc: flow[i,j] <> 0}: 
    " %-3s, %-3s:  %8g\n", i, j, flow[i,j];
printf "\n";
      
data;


param: vertex: demand cap_gen costs :=
       v1           0     10    10
       v2           0      5    20
       v3           8      0     0;

param: arc   : cap_tra admittance:=
# original edges
       v1 v2       10          1
       v2 v3       10          1
       v1 v3       10          1
# reversed copies
       v2 v1       10          1
       v3 v2       10          1
       v3 v1       10          1;

end;

