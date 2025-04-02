#!/bin/bash

#SBATCH --job-name=cxxomp-sencei-sem
#SBATCH --output=output-cxxomp.csv
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --time=00:03:00
#SBATCH --constraint="type_a|type_b"

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

./main 1000000000
