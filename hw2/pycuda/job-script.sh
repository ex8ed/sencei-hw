#!/bin/bash

#SBATCH --job-name=pycuda-sencei
#SBATCH --output=output.log
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --gpus=1
#SBATCH --time=00:05:00
#SBATCH --constraint="type_a|type_b|type_c"

module purge

module load Python
module load nvidia_sdk/nvhpc/23.5
module load CUDA/11.7

conda deactivate
conda activate cuda_venv

python ./heat-pycuda.py 1024
