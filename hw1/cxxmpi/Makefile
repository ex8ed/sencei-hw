#!/bin/bash -i
MPI_COMP = mpicxx

run: setup-mpi
	@sbatch -A proj_1651 job-script.sh

setup-mpi: clear build-mpi

build-mpi:
	@echo "🔄 Starting build..."
	@module load openmpi/4.1.5_cuda12; \
	$(MPI_COMP) ./main.cxx -o main || exit 1;
	@echo "✅ Success CXXMPI build!"

clear:
	@rm -f ./main; \
	rm -f ./*.log;
	@echo "✅ Success clean!"

.PHONY:
	logs
	all
