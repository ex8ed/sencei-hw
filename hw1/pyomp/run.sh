#!/bin/bash
rm -f ./*.log
rm -f ./*.csv

sbatch -A proj_1651 job-script.sh
