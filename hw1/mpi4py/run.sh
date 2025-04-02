#!/bin/bash
rm -f ./*.log;

sbatch -A proj_1651 job-script.sh;
