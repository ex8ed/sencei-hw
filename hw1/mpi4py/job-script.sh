#!/bin/bash

#SBATCH --job-name=mpi4py-sencei-sem
#SBATCH --output=./output-mpi4py.csv
#SBATCH --ntasks=16
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=8
#SBATCH --time=03:30:00
#SBATCH --constraint="type_a|type_b"

module load Python
conda deactivate
conda activate venv

mpirun -np ${SLURM_NTASKS} python3 ./mpi.py 1000000000
