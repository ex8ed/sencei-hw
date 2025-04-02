#!/bin/bash

#SBATCH --job-name=pyomp-sencei-sem
#SBATCH --output=output-pyomp.csv
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --time=00:03:00
#SBATCH --constraint="type_a|type_b"

module load Python
conda deactivate
conda activate venv

export NUMBA_NUM_THREADS=${SLURM_CPUS_PER_TASK}

python3 ./omp.py 1000000000
