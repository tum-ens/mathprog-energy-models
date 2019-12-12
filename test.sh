#!/bin/bash

# small check that all models still compile
error_code=0
for model_file in *.mod;
do
    if !(_=$(glpsol -m $model_file 2>&1)); then
        printf "Error in '$model_file'\n"
	error_code=1
    fi
done
exit $error_code
