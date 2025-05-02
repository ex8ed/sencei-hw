#!/bin/bash

#SBATCH --job-name=cxxcuda-sencei-hw
#SBATCH --output=output.log
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --gpus=1
#SBATCH --time=00:05:00
#SBATCH --constraint="type_a|type_b|type_c"

./main 4096
