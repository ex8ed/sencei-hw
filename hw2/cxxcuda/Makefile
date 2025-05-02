#!/bin/bash -i
CUDA_COMPILE=nvcc


run: setup
	@sbatch job-script.sh

setup: clean build

build:
	@module load nvidia_sdk/nvhpc/23.5; \
	$(CUDA_COMPILE) ./heat.cu -o main -O2 || (echo "❌ Build shared-CUDA failed"; exit 1;)
	@echo "✅ Success shared-CUDA build!"

clean:
	@rm -f ./main; \
	rm -f ./output.log;
	@echo "✅ Success clean!"

.PHONY:
	logs
	cuda
