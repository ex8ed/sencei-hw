#!/bin/bash

#SBATCH --job-name=cxxmpi
#SBATCH --output=./output-cxxmpi.csv
#SBATCH --ntasks=16
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=4
#SBATCH --time=03:30:00
#SBATCH --constraint="type_a|type_b"

srun  --nodes=4 --ntasks-per-node=4 --ntasks=16 --constraint="type_a|type_b" ./main 1000000000
