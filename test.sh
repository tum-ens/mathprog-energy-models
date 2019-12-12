#!/bin/bash

# small check that all models still compile
for model_file in *.mod;
do
    if !(_=$(glpsol -m $model_file 2>&1)); then
        printf "Error in '$model_file'\n"
    fi
done
