#!/bin/bash

# small check that all models still compile
error_code=0
for model_file in *.mod;
do
    glpk_output=$(glpsol -m $model_file 2>&1)
    if [ $? -ne 0 ]; then
	error_code=1
        printf "Error in '$model_file':\n"
	echo "----------------------------------------------------------------------------------"
	echo "${glpk_output}"
	echo "----------------------------------------------------------------------------------"
    fi
done
exit $error_code
