#!/bin/bash -i
run: setup-omp
	@sbatch -A proj_1651 job-script.sh

setup-omp: clear build-omp

build-omp:
	@echo "🔄 Starting build..."
	@g++ main.cxx -o main -fopenmp -Ofast || exit 1;
	@echo "✅ Success CXX-OMP build!"

clear:
	@rm -f ./main; \
	rm -f ./output.log;
	@echo "✅ Success clean!"

.PHONY:
	logs
	all
