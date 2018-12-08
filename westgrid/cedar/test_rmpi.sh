#!/bin/bash
#SBATCH --account=def-psolymos
#SBATCH --ntasks=8
#SBATCH --mem-per-cpu=2048M
#SBATCH --time=00:15:00
#SBATCH --job-name=test_rmpi
#SBATCH --output=%x-%j.out
#SBATCH --mail-user=solymos@ualberta.ca
#SBATCH --mail-type=ALL
module load r/3.5.0
module load openmpi/1.10.7
export R_LIBS=~/local/R_libs/
mpirun -np 1 R CMD BATCH test_rmpi.R test_rmpi.txt