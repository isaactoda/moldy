#!/bin/bash

## Run parameters script 	##
## version 1.0		##
## by Martin Uhrin		##

# Turn debugging on
#set -x

## File/directory settings ##

readonly tools_reldir="../../../tools"				# Path to directory where all the tools binaries are stored
readonly run_script="${tools_reldir}/run_steps.sh"		# Script to actually execute the timing runs
readonly param_set_script="replace_token.sh"			# The name of the script in the tools directory that sets the parameter to its new value
readonly param_token="nloops"					# Token of the parameter to be varied
readonly param_values=(500 250 175 88 44 22 11 5 2 1)		# Values 
that the parameter will take
readonly timing_out="timing.out"					# The file where timing data will be stored

declare -ir nloops_nsteps=1000					# The constant that c = nsteps * nloops
declare -r nloops_strain=0.1						# The total strain to apply over the sim. run i.e. k = strain * nloops

## Export all the settings ##
export moldy_exe="../../../build/moldy.noOMP.FeC"	# The moldy binary to use for running the sim, must be compiled for right potentialexport x_input_files=${input_files[*]}
export x_input_files="25^3.in" 		# Input files to use 
export num_repeats=3						# Number of repeats
export x_num_threads=1					# OMP_NUM_THREADS numbers to use
export custom_param=$param_token				# Export so run_steps creates column for nbrupdate in timout out
export RUNTIME_STRING="Simulationloops runtime:"		# The string printed by MOLDY preceeding the runtime

if [ ! -f $tools_reldir/$param_set_script ]; then
	echo "Parameter set script $tools_reldir/$param_set_script does not exist"
	exit
fi

## Variables ##
declare strain_rate
declare -i nsteps

for param_value in ${param_values[@]}
do
	strain_rate=$(echo "scale=4; ${nloops_strain}/${param_value}" | bc)	# Calculate the strain rate (per loop)
	nsteps=$(echo "scale=0; ${nloops_nsteps}/${param_value}" | bc)		# Calculate the number of steps

	# Set the strain rate and nsteps in params.in
	sh $tools_reldir/$param_set_script params.in nsteps $nsteps
	sh $tools_reldir/$param_set_script params.in straintensor_row1 "1.0 0.0 $strain_rate"
	sh $tools_reldir/$param_set_script params.in straintensor_row3 "-$strain_rate 0.0 1.0"

	# Set the parameter in the params.in file
	sh $tools_reldir/$param_set_script params.in $param_token $param_value

	# Write the value of the parameter to the timing file
	echo "$param_token = $param_value" >> $timing_out

	# Get the run script to put this value in the nbrupdates column in output file
	export custom_param_value=$param_value

	# Now execute the timing run
	sh $run_script
done

