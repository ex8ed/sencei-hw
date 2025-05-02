rm -f ./*.log
rm -f ./*.csv

echo "✅ All clean!"

echo "Calling sbatch ..."

sbatch job-script.sh